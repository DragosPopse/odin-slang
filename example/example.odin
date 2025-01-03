package example

/*
	Credits go to https://github.com/wrapperup
*/

import "core:fmt"
import "core:os"
import "core:slice"
import "core:time"

import "vendor:glfw"
import vk "vendor:vulkan"

// Slang bindings
import sp "../slang"

slang_check :: #force_inline proc(#any_int result: int, loc := #caller_location) {
	result := sp.Result(result)
	if sp.FAILED(result) {
		code := sp.GET_RESULT_CODE(result)
		facility := sp.GET_RESULT_FACILITY(result)
		estr: string
		switch sp.Result(result) {
		case:
			estr = "Unknown error"
		case sp.E_NOT_IMPLEMENTED():
			estr = "E_NOT_IMPLEMENTED"
		case sp.E_NO_INTERFACE():
			estr = "E_NO_INTERFACE"
		case sp.E_ABORT():
			estr = "E_ABORT"
		case sp.E_INVALID_HANDLE():
			estr = "E_INVALID_HANDLE"
		case sp.E_INVALID_ARG():
			estr = "E_INVALID_ARG"
		case sp.E_OUT_OF_MEMORY():
			estr = "E_OUT_OF_MEMORY"
		case sp.E_BUFFER_TOO_SMALL():
			estr = "E_BUFFER_TOO_SMALL"
		case sp.E_UNINITIALIZED():
			estr = "E_UNINITIALIZED"
		case sp.E_PENDING():
			estr = "E_PENDING"
		case sp.E_CANNOT_OPEN():
			estr = "E_CANNOT_OPEN"
		case sp.E_NOT_FOUND():
			estr = "E_NOT_FOUND"
		case sp.E_INTERNAL_FAIL():
			estr = "E_INTERNAL_FAIL"
		case sp.E_NOT_AVAILABLE():
			estr = "E_NOT_AVAILABLE"
		case sp.E_TIME_OUT():
			estr = "E_TIME_OUT"
		}

		fmt.panicf("Failed with error: %v (%v) Facility: %v", estr, code, facility, loc = loc)
	}
}

diagnostics_check :: #force_inline proc(diagnostics: ^sp.IBlob, loc := #caller_location) {
	if diagnostics != nil {
		buffer := slice.bytes_from_ptr(
			diagnostics->getBufferPointer(),
			int(diagnostics->getBufferSize()),
		)
		assert(false, string(buffer), loc)
	}
}

// Compiles the triangle.slang shader and creates the pipeline (or re-creates it if it exists)
reload_shader_pipelines :: proc(renderer: ^Renderer, global_session: ^sp.IGlobalSession) {
	start_compile_time := time.tick_now()

	using sp
	code, diagnostics: ^IBlob
	r: Result

	target_desc := TargetDesc {
		structureSize = size_of(TargetDesc),
		format        = .SPIRV,
		flags         = {.GENERATE_SPIRV_DIRECTLY},
		profile       = global_session->findProfile("sm_6_0"),
	}

	compiler_option_entries := [?]CompilerOptionEntry{
		{name = .VulkanUseEntryPointName, value = {intValue0 = 1}},
	}
	session_desc := SessionDesc {
		structureSize            = size_of(SessionDesc),
		targets                  = &target_desc,
		targetCount              = 1,
		compilerOptionEntries    = &compiler_option_entries[0],
		compilerOptionEntryCount = 1,
	}

	session: ^ISession
	slang_check(global_session->createSession(session_desc, &session))
	defer session->release()

	blob: ^IBlob

	module: ^IModule = session->loadModule("example/triangle.slang", &diagnostics)
	if module == nil {
		fmt.println("Shader compile error!")
		return
	}
	defer module->release()
	diagnostics_check(diagnostics)

	vertex_entry: ^IEntryPoint
	r = module->findEntryPointByName("vertexmain", &vertex_entry)
	slang_check(r)

	fragment_entry: ^IEntryPoint
	r = module->findEntryPointByName("fragmentmain", &fragment_entry)
	slang_check(r)

	if vertex_entry == nil {
		fmt.println("Expected 'vertexmain' entry point")
		return;
	}
	if fragment_entry == nil {
		fmt.println("Expected 'fragmentmain' entry point")
		return;
	}

	components: [3]^IComponentType = {module, vertex_entry, fragment_entry}

	linked_program: ^IComponentType
	r = session->createCompositeComponentType(
		&components[0],
		len(components),
		&linked_program,
		&diagnostics,
	)
	diagnostics_check(diagnostics)
	slang_check(r)

	target_code: ^IBlob
	r = linked_program->getTargetCode(0, &target_code, &diagnostics)
	diagnostics_check(diagnostics)
	slang_check(r)

	code_size := target_code->getBufferSize()
	source_code := slice.bytes_from_ptr(target_code->getBufferPointer(), auto_cast code_size)

	info := vk.ShaderModuleCreateInfo {
		sType    = .SHADER_MODULE_CREATE_INFO,
		codeSize = len(source_code), // codeSize needs to be in bytes
		pCode    = raw_data(slice.reinterpret([]u32, source_code)), // code needs to be in 32bit words
	}

	vk_module: vk.ShaderModule
	vk_check(vk.CreateShaderModule(renderer.device, &info, nil, &vk_module))

	// Create pipelines and pipeline layouts
	pipeline_layout_create_info := vk.PipelineLayoutCreateInfo {
		sType                  = .PIPELINE_LAYOUT_CREATE_INFO,
		pNext                  = nil,
		flags                  = {},
		setLayoutCount         = 0,
		pSetLayouts            = nil,
		pushConstantRangeCount = 0,
		pPushConstantRanges    = nil,
	}

	if renderer.triangle_pipeline_layout != 0 {
		vk.DestroyPipelineLayout(renderer.device, renderer.triangle_pipeline_layout, nil)
	}

	vk_check(
		vk.CreatePipelineLayout(
			renderer.device,
			&pipeline_layout_create_info,
			nil,
			&renderer.triangle_pipeline_layout,
		),
	)

	pipelineInfo := vk.GraphicsPipelineCreateInfo {
		sType               = .GRAPHICS_PIPELINE_CREATE_INFO,
		pNext               = &vk.PipelineRenderingCreateInfo {
			sType = .PIPELINE_RENDERING_CREATE_INFO,
			colorAttachmentCount = 1,
			pColorAttachmentFormats = &renderer.draw_image.format,
			depthAttachmentFormat = renderer.depth_image.format,
		},
		pStages             = raw_data(
			[]vk.PipelineShaderStageCreateInfo {
				{
					sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
					stage = {.VERTEX},
					module = vk_module,
					pName = "vertexmain",
				},
				{
					sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
					stage = {.FRAGMENT},
					module = vk_module,
					pName = "fragmentmain",
				},
			},
		),
		stageCount          = 2,
		pVertexInputState   = &{sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO},
		pInputAssemblyState = &{
			sType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
			topology = .TRIANGLE_LIST,
			primitiveRestartEnable = false,
		},
		pViewportState      = &{
			sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
			viewportCount = 1,
			scissorCount = 1,
		},
		pRasterizationState = &{
			sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
			polygonMode = .FILL,
			lineWidth = 1,
			frontFace = .COUNTER_CLOCKWISE,
		},
		pMultisampleState   = &{
			sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
			sampleShadingEnable = false,
			rasterizationSamples = {._1},
			minSampleShading = 1.0,
			pSampleMask = nil,
			alphaToCoverageEnable = false,
			alphaToOneEnable = false,
		},
		pColorBlendState    = &{
			sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
			logicOpEnable = false,
			logicOp = .COPY,
			attachmentCount = 1,
			pAttachments = &vk.PipelineColorBlendAttachmentState {
				colorWriteMask = {.R, .G, .B, .A},
				blendEnable = false,
			},
		},
		pDepthStencilState  = &{
			sType = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
			depthTestEnable = true,
			depthWriteEnable = true,
			depthCompareOp = .LESS_OR_EQUAL,
			depthBoundsTestEnable = false,
			stencilTestEnable = false,
			front = {},
			back = {},
			minDepthBounds = 0.0,
			maxDepthBounds = 1.0,
		},
		layout              = renderer.triangle_pipeline_layout,
		pDynamicState       = &{
			sType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
			pDynamicStates = raw_data([]vk.DynamicState{.VIEWPORT, .SCISSOR}),
			dynamicStateCount = 2,
		},
	}

	triangle_pipeline: vk.Pipeline

	if vk.CreateGraphicsPipelines(renderer.device, 0, 1, &pipelineInfo, nil, &triangle_pipeline) !=
	   .SUCCESS {
		fmt.println("Couldn't create graphics pipeline!")
		return
	}

	if renderer.triangle_pipeline != 0 {
		vk.DestroyPipeline(renderer.device, renderer.triangle_pipeline, nil)
	}

	renderer.triangle_pipeline = triangle_pipeline

	// We don't need to keep the shader modules around
	vk.DestroyShaderModule(renderer.device, vk_module, nil)

	duration_msec := time.tick_since(start_compile_time)
	fmt.println("Loaded shader in", duration_msec)
}

main :: proc() {
	renderer: Renderer

	glfw.Init()

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)

	renderer.window = glfw.CreateWindow(800, 600, "Hello Triangle", nil, nil)

	init_vulkan(&renderer)

	global_session: ^sp.IGlobalSession
	assert(sp.createGlobalSession(sp.API_VERSION, &global_session) == sp.OK)

	// Load shaders
	reload_shader_pipelines(&renderer, global_session)
	assert(renderer.triangle_pipeline != 0, "Couldn't load shaders!")

	current_last_write_time, ok := os.last_write_time_by_name("example/triangle.slang")
	assert(ok == nil)

	// Create index buffer
	indices := [?]u32{0, 1, 2, 2, 3, 0}

	indices_buffer := create_buffer(
		&renderer,
		auto_cast size_of(indices),
		{.INDEX_BUFFER, .TRANSFER_DST},
	)
	staging_write_buffer_slice(&renderer, &indices_buffer, indices[:])

	for !glfw.WindowShouldClose(renderer.window) {
		glfw.PollEvents()

		last_write_time, err := os.last_write_time_by_name("example/triangle.slang")

		// Check if the triangle shader changed and reload the pipelines if so.
		if err == nil && current_last_write_time != last_write_time {
			for i in 0 ..< FRAME_OVERLAP {
				vk_check(
					vk.WaitForFences(
						renderer.device,
						1,
						&renderer.frames[i].render_fence,
						true,
						1_000_000_000,
					),
				)
			}

			reload_shader_pipelines(&renderer, global_session)
			current_last_write_time = last_write_time
		}

		vk_check(
			vk.WaitForFences(
				renderer.device,
				1,
				&current_frame(&renderer).render_fence,
				true,
				1_000_000_000,
			),
		)

		vk_check(
			vk.AcquireNextImageKHR(
				renderer.device,
				renderer.swapchain,
				1_000_000_000,
				current_frame(&renderer).swapchain_semaphore,
				0,
				&renderer.swapchain_image_index,
			),
		)

		renderer.draw_extent.width = renderer.draw_image.extent.width
		renderer.draw_extent.height = renderer.draw_image.extent.height

		vk_check(vk.ResetFences(renderer.device, 1, &current_frame(&renderer).render_fence))
		vk_check(
			vk.ResetCommandBuffer(
				current_frame(&renderer).main_command_buffer,
				{.RELEASE_RESOURCES},
			),
		)

		cmd := current_frame(&renderer).main_command_buffer

		cmd_begin_info := vk.CommandBufferBeginInfo {
			sType            = .COMMAND_BUFFER_BEGIN_INFO,
			pNext            = nil,
			pInheritanceInfo = nil,
			flags            = {.ONE_TIME_SUBMIT},
		}
		vk_check(vk.BeginCommandBuffer(cmd, &cmd_begin_info))

		// Start drawing

		// Geometry pass
		transition_image(cmd, renderer.draw_image.image, .UNDEFINED, .COLOR_ATTACHMENT_OPTIMAL)
		transition_image(cmd, renderer.depth_image.image, .UNDEFINED, .DEPTH_ATTACHMENT_OPTIMAL)

		// This also clears both the color and depth images.
		render_info := vk.RenderingInfo {
			sType = .RENDERING_INFO,
			layerCount = 1,
			renderArea = {extent = renderer.draw_extent},
			pDepthAttachment = &{
				sType = .RENDERING_ATTACHMENT_INFO,
				imageView = renderer.depth_image.image_view,
				imageLayout = .DEPTH_ATTACHMENT_OPTIMAL,
				loadOp = .CLEAR,
				storeOp = .STORE,
				clearValue = {depthStencil = {depth = 1.0}},
			},
			pColorAttachments = &vk.RenderingAttachmentInfo {
				sType = .RENDERING_ATTACHMENT_INFO,
				imageView = renderer.draw_image.image_view,
				imageLayout = .COLOR_ATTACHMENT_OPTIMAL,
				loadOp = .CLEAR,
				storeOp = .STORE,
				clearValue = {color = {float32 = {0, 0, 0, 1}}},
			},
			colorAttachmentCount = 1,
		}
		vk.CmdBeginRenderingKHR(cmd, &render_info)

		viewport := vk.Viewport {
			x        = 0,
			y        = 0,
			width    = f32(renderer.draw_extent.width),
			height   = f32(renderer.draw_extent.height),
			minDepth = 0.0,
			maxDepth = 1.0,
		}
		vk.CmdSetViewport(cmd, 0, 1, &viewport)

		scissor := vk.Rect2D {
			offset = {x = 0, y = 0},
			extent = {renderer.draw_extent.width, renderer.draw_extent.height},
		}
		vk.CmdSetScissor(cmd, 0, 1, &scissor)

		vk.CmdBindPipeline(cmd, .GRAPHICS, renderer.triangle_pipeline)
		vk.CmdBindIndexBuffer(cmd, indices_buffer.buffer, 0, .UINT32)

		// Draw triangle
		vk.CmdDrawIndexed(cmd, 3, 1, 0, 0, 0)

		vk.CmdEndRenderingKHR(cmd)
		// End Geometry Pass

		// End drawing

		transition_image(
			cmd,
			renderer.draw_image.image,
			.COLOR_ATTACHMENT_OPTIMAL,
			.TRANSFER_SRC_OPTIMAL,
		)
		transition_image(
			cmd,
			renderer.swapchain_images[renderer.swapchain_image_index],
			.UNDEFINED,
			.TRANSFER_DST_OPTIMAL,
		)

		blit_region := vk.ImageBlit2 {
			sType = .IMAGE_BLIT_2,
			pNext = nil,
			srcSubresource = {
				aspectMask = {.COLOR},
				baseArrayLayer = 0,
				layerCount = 1,
				mipLevel = 0,
			},
			srcOffsets = {
				1 = {
					x = i32(renderer.draw_extent.width),
					y = i32(renderer.draw_extent.height),
					z = 1,
				},
			},
			dstSubresource = {
				aspectMask = {.COLOR},
				baseArrayLayer = 0,
				layerCount = 1,
				mipLevel = 0,
			},
			dstOffsets = {
				1 = {
					x = i32(renderer.swapchain_extent.width),
					y = i32(renderer.swapchain_extent.height),
					z = 1,
				},
			},
		}

		blit_info := vk.BlitImageInfo2 {
			sType          = .BLIT_IMAGE_INFO_2,
			pNext          = nil,
			dstImage       = renderer.swapchain_images[renderer.swapchain_image_index],
			dstImageLayout = .TRANSFER_DST_OPTIMAL,
			srcImage       = renderer.draw_image.image,
			srcImageLayout = .TRANSFER_SRC_OPTIMAL,
			filter         = .LINEAR,
			regionCount    = 1,
			pRegions       = &blit_region,
		}

		vk.CmdBlitImage2KHR(cmd, &blit_info)

		transition_image(
			cmd,
			renderer.swapchain_images[renderer.swapchain_image_index],
			.TRANSFER_DST_OPTIMAL,
			.PRESENT_SRC_KHR,
		)

		vk_check(vk.EndCommandBuffer(cmd))

		cmd_info := vk.CommandBufferSubmitInfo {
			sType         = .COMMAND_BUFFER_SUBMIT_INFO,
			pNext         = nil,
			commandBuffer = cmd,
			deviceMask    = 0,
		}

		wait_info := vk.SemaphoreSubmitInfo {
			sType       = .SEMAPHORE_SUBMIT_INFO,
			pNext       = nil,
			semaphore   = current_frame(&renderer).swapchain_semaphore,
			stageMask   = {.COLOR_ATTACHMENT_OUTPUT},
			deviceIndex = 0,
			value       = 1,
		}

		signal_info := vk.SemaphoreSubmitInfo {
			sType       = .SEMAPHORE_SUBMIT_INFO,
			pNext       = nil,
			semaphore   = current_frame(&renderer).render_semaphore,
			stageMask   = {.ALL_GRAPHICS},
			deviceIndex = 0,
			value       = 1,
		}

		submit := vk.SubmitInfo2 {
			sType                    = .SUBMIT_INFO_2,
			pNext                    = nil,
			waitSemaphoreInfoCount   = 1,
			pWaitSemaphoreInfos      = &wait_info,
			signalSemaphoreInfoCount = 1,
			pSignalSemaphoreInfos    = &signal_info,
			commandBufferInfoCount   = 1,
			pCommandBufferInfos      = &cmd_info,
		}

		vk_check(
			vk.QueueSubmit2KHR(
				renderer.graphics_queue,
				1,
				&submit,
				current_frame(&renderer).render_fence,
			),
		)

		present_info := vk.PresentInfoKHR {
			sType              = .PRESENT_INFO_KHR,
			pSwapchains        = &renderer.swapchain,
			swapchainCount     = 1,
			pWaitSemaphores    = &current_frame(&renderer).render_semaphore,
			waitSemaphoreCount = 1,
			pImageIndices      = &renderer.swapchain_image_index,
		}

		vk_check(vk.QueuePresentKHR(renderer.graphics_queue, &present_info))

		renderer.frame_number += 1
	}

	// Cleanup our stuff
	vk.DeviceWaitIdle(renderer.device)

	vk.DestroyBuffer(renderer.device, indices_buffer.buffer, nil)
	vk.FreeMemory(renderer.device, indices_buffer.memory, nil)

	vk.DestroyPipeline(renderer.device, renderer.triangle_pipeline, nil)
	vk.DestroyPipelineLayout(renderer.device, renderer.triangle_pipeline_layout, nil)

	// Cleanup rest of vulkan
	vulkan_shutdown(&renderer)
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Vulkan impl

import "base:runtime"
import "core:c"
import "core:math/linalg"
import "core:math/linalg/hlsl"
import "core:mem"
import "core:reflect"

// Set required features to enable here. These are used to pick the physical device as well.
REQUIRED_FEATURES := vk.PhysicalDeviceFeatures2 {
	sType    = .PHYSICAL_DEVICE_FEATURES_2,
	pNext    = &REQUIRED_VK_11_FEATURES,
	features = {},
}

REQUIRED_VK_11_FEATURES := vk.PhysicalDeviceVulkan11Features {
	sType                         = .PHYSICAL_DEVICE_VULKAN_1_1_FEATURES,
	pNext                         = &REQUIRED_VK_12_FEATURES,
	variablePointers              = true,
	variablePointersStorageBuffer = true,
}

REQUIRED_VK_12_FEATURES := vk.PhysicalDeviceVulkan12Features {
	sType = .PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
	pNext = &REQUIRED_VK_13_FEATURES,
}

REQUIRED_VK_13_FEATURES := vk.PhysicalDeviceVulkan13Features {
	sType            = .PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
	dynamicRendering = true,
	synchronization2 = true,
}

// Set required extensions to support.
DEVICE_EXTENSIONS := []cstring {
	vk.KHR_SWAPCHAIN_EXTENSION_NAME,
	vk.KHR_SYNCHRONIZATION_2_EXTENSION_NAME,        // Enabled by default in 1.3
	vk.KHR_COPY_COMMANDS_2_EXTENSION_NAME,          // Enabled by default in 1.3
	vk.KHR_DYNAMIC_RENDERING_EXTENSION_NAME,        // Enabled by default in 1.3
	vk.KHR_SHADER_NON_SEMANTIC_INFO_EXTENSION_NAME, // Enabled by default in 1.3
}
// Set validation layers to enable.
VALIDATION_LAYERS := []cstring{"VK_LAYER_KHRONOS_validation"}

// Set validation features to enable.
VALIDATION_FEATURES := []vk.ValidationFeatureEnableEXT{.DEBUG_PRINTF}

// Number of frames to provide in flight.
FRAME_OVERLAP :: 2

vk_check :: proc(result: vk.Result, loc := #caller_location) {
	p := context.assertion_failure_proc
	if result != .SUCCESS {
		when ODIN_DEBUG {
			p("vk_check failed", reflect.enum_string(result), loc)
		} else {
			p("vk_check failed", "NOT SUCCESS", loc)
		}
	}
}

debug_callback :: proc "system" (
	message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
	message_types: vk.DebugUtilsMessageTypeFlagsEXT,
	callback_data: ^vk.DebugUtilsMessengerCallbackDataEXT,
	user_data: rawptr,
) -> b32 {
	context = runtime.default_context()
	fmt.println(callback_data.pMessage)

	for i in 0 ..< callback_data.objectCount {
		name := callback_data.pObjects[i].pObjectName

		if len(name) > 0 {
			fmt.println(" -", callback_data.pObjects[i].pObjectName)
		}
	}

	return false
}


Renderer :: struct {
	window:                   glfw.WindowHandle,
	debug_messenger:          vk.DebugUtilsMessengerEXT,
	enable_logs:              bool,
	instance:                 vk.Instance,
	physical_device:          vk.PhysicalDevice,
	device:                   vk.Device,

	// Queues
	graphics_queue:           vk.Queue,
	graphics_queue_family:    u32,
	surface:                  vk.SurfaceKHR,

	// Swapchain
	swapchain:                vk.SwapchainKHR,
	swapchain_images:         []vk.Image,
	swapchain_image_index:    u32,
	swapchain_image_views:    []vk.ImageView,
	swapchain_image_format:   vk.Format,
	swapchain_extent:         vk.Extent2D,

	// Command Pool/Buffer
	frames:                   [FRAME_OVERLAP]FrameData,
	frame_number:             int,

	// Immediate submit
	imm_fence:                vk.Fence,
	imm_command_buffer:       vk.CommandBuffer,
	imm_command_pool:         vk.CommandPool,

	// Draw resources
	draw_image:               GPUImage,
	depth_image:              GPUImage,
	draw_extent:              vk.Extent2D,
	msaa_samples:             vk.SampleCountFlag,

	// Application resources
	triangle_pipeline_layout: vk.PipelineLayout,
	triangle_pipeline:        vk.Pipeline,
}

FrameData :: struct {
	swapchain_semaphore, render_semaphore: vk.Semaphore,
	render_fence:                          vk.Fence,
	command_pool:                          vk.CommandPool,
	main_command_buffer:                   vk.CommandBuffer,
}

GPUImage :: struct {
	image:      vk.Image,
	image_view: vk.ImageView,
	memory:     vk.DeviceMemory,
	extent:     vk.Extent3D,
	format:     vk.Format,
}

GPUBuffer :: struct {
	buffer: vk.Buffer,
	memory: vk.DeviceMemory,
	size:   vk.DeviceSize,
}

current_frame :: proc(renderer: ^Renderer) -> ^FrameData {
	return &renderer.frames[renderer.frame_number % FRAME_OVERLAP]
}

begin_immediate_submit :: proc(renderer: ^Renderer) -> vk.CommandBuffer {
	vk_check(vk.ResetFences(renderer.device, 1, &renderer.imm_fence))
	vk_check(vk.ResetCommandBuffer(renderer.imm_command_buffer, {}))

	cmd := renderer.imm_command_buffer

	cmd_begin_info := vk.CommandBufferBeginInfo {
		sType            = .COMMAND_BUFFER_BEGIN_INFO,
		pNext            = nil,
		pInheritanceInfo = nil,
		flags            = {.ONE_TIME_SUBMIT},
	}
	vk_check(vk.BeginCommandBuffer(cmd, &cmd_begin_info))

	return cmd
}

end_immediate_submit :: proc(renderer: ^Renderer) {
	cmd := renderer.imm_command_buffer

	vk_check(vk.EndCommandBuffer(cmd))

	cmd_info := vk.CommandBufferSubmitInfo {
		sType         = .COMMAND_BUFFER_SUBMIT_INFO,
		pNext         = nil,
		commandBuffer = cmd,
		deviceMask    = 0,
	}

	submit := vk.SubmitInfo2 {
		sType                    = .SUBMIT_INFO_2,
		pNext                    = nil,
		waitSemaphoreInfoCount   = 0,
		pWaitSemaphoreInfos      = nil,
		signalSemaphoreInfoCount = 0,
		pSignalSemaphoreInfos    = nil,
		commandBufferInfoCount   = 1,
		pCommandBufferInfos      = &cmd_info,
	}


	// submit command buffer to the queue and execute it.
	//  _renderFence will now block until the graphic commands finish execution
	vk_check(vk.QueueSubmit2KHR(renderer.graphics_queue, 1, &submit, renderer.imm_fence))

	vk_check(vk.WaitForFences(renderer.device, 1, &renderer.imm_fence, true, 9_999_999_999))
}

find_memory_type :: proc(
	physical_device: vk.PhysicalDevice,
	type_filter: u32,
	properties: vk.MemoryPropertyFlags,
) -> u32 {
	mem_properties: vk.PhysicalDeviceMemoryProperties
	vk.GetPhysicalDeviceMemoryProperties(physical_device, &mem_properties)

	i: u32
	for i in 0 ..< mem_properties.memoryTypeCount {
		if (type_filter & (1 << i)) != 0 &&
		   (mem_properties.memoryTypes[i].propertyFlags & properties) == properties {
			return i
		}
	}

	assert(false, "Couldn't find memory type.")
	return 0
}

create_image :: proc(
	renderer: ^Renderer,
	format: vk.Format,
	extent: vk.Extent3D,
	image_usage_flags: vk.ImageUsageFlags,
	properties: vk.MemoryPropertyFlags = {.DEVICE_LOCAL},
	tiling: vk.ImageTiling = .OPTIMAL,
	flags: vk.ImageCreateFlags = {},
) -> GPUImage {
	img_info := vk.ImageCreateInfo {
		sType       = .IMAGE_CREATE_INFO,
		imageType   = .D2,
		format      = format,
		extent      = extent,
		mipLevels   = 1,
		arrayLayers = 1,
		tiling      = tiling,
		usage       = image_usage_flags,
		flags       = flags,
		samples     = {._1},
	}

	gpu_image := GPUImage {
		format = format,
		extent = extent,
	}

	vk_check(vk.CreateImage(renderer.device, &img_info, nil, &gpu_image.image))

	mem_requirements: vk.MemoryRequirements
	vk.GetImageMemoryRequirements(renderer.device, gpu_image.image, &mem_requirements)

	alloc_info := vk.MemoryAllocateInfo {
		sType           = .MEMORY_ALLOCATE_INFO,
		allocationSize  = mem_requirements.size,
		memoryTypeIndex = find_memory_type(
			renderer.physical_device,
			mem_requirements.memoryTypeBits,
			properties,
		),
	}

	vk_check(vk.AllocateMemory(renderer.device, &alloc_info, nil, &gpu_image.memory))

	vk.BindImageMemory(renderer.device, gpu_image.image, gpu_image.memory, 0)

	return gpu_image
}

create_buffer :: proc(
	renderer: ^Renderer,
	alloc_size: vk.DeviceSize,
	usage: vk.BufferUsageFlags,
	properties: vk.MemoryPropertyFlags = {.DEVICE_LOCAL},
	loc := #caller_location,
) -> GPUBuffer {
	buffer_info := vk.BufferCreateInfo {
		sType       = .BUFFER_CREATE_INFO,
		size        = alloc_size,
		usage       = usage,
		sharingMode = .EXCLUSIVE,
	}

	gpu_buffer := GPUBuffer {
		size = alloc_size,
	}
	vk_check(vk.CreateBuffer(renderer.device, &buffer_info, nil, &gpu_buffer.buffer))

	mem_requirements: vk.MemoryRequirements
	vk.GetBufferMemoryRequirements(renderer.device, gpu_buffer.buffer, &mem_requirements)

	alloc_info := vk.MemoryAllocateInfo {
		sType           = .MEMORY_ALLOCATE_INFO,
		allocationSize  = mem_requirements.size,
		memoryTypeIndex = find_memory_type(
			renderer.physical_device,
			mem_requirements.memoryTypeBits,
			properties,
		),
	}

	vk_check(vk.AllocateMemory(renderer.device, &alloc_info, nil, &gpu_buffer.memory))

	vk.BindBufferMemory(renderer.device, gpu_buffer.buffer, gpu_buffer.memory, 0)

	return gpu_buffer
}

// Writes to the buffer with the input slice at offset.
write_buffer_slice :: proc(
	renderer: ^Renderer,
	buffer: ^GPUBuffer,
	in_data: []$T,
	offset: vk.DeviceSize = 0,
	loc := #caller_location,
) {
	size := size_of(T) * len(in_data)
	assert(
		buffer.size >= vk.DeviceSize(u64(size) + u64(offset)),
		"The size of the slice and offset is larger than the buffer",
		loc,
	)

	data: [^]u8
	vk.MapMemory(renderer.device, buffer.memory, 0, buffer.size, {}, cast(^rawptr)&data)
	mem.copy(data[offset:], raw_data(in_data), size)
	vk.UnmapMemory(renderer.device, buffer.memory)
}

// Uploads the data via a staging buffer. This is useful if your buffer is GPU only.
staging_write_buffer_slice :: proc(
	renderer: ^Renderer,
	buffer: ^GPUBuffer,
	in_data: []$T,
	offset: vk.DeviceSize = 0,
	loc := #caller_location,
) {
	size := size_of(T) * len(in_data)
	assert(
		buffer.size >= vk.DeviceSize(u64(size) + u64(offset)),
		"The size of the slice and offset is larger than the buffer",
		loc,
	)

	staging := create_buffer(
		renderer,
		vk.DeviceSize(size),
		{.TRANSFER_SRC},
		{.HOST_VISIBLE, .HOST_COHERENT},
	)
	defer {
		vk.DestroyBuffer(renderer.device, staging.buffer, nil)
		vk.FreeMemory(renderer.device, staging.memory, nil)
	}

	write_buffer_slice(renderer, &staging, in_data, loc = loc)

	{
		cmd := begin_immediate_submit(renderer)
		region := vk.BufferCopy {
			dstOffset = offset,
			srcOffset = 0,
			size      = vk.DeviceSize(size),
		}

		vk.CmdCopyBuffer(cmd, staging.buffer, buffer.buffer, 1, &region)
		end_immediate_submit(renderer)
	}
}

create_image_view :: proc(device: vk.Device, image: ^GPUImage, aspect_flags: vk.ImageAspectFlags) {
	info := vk.ImageViewCreateInfo {
		sType = .IMAGE_VIEW_CREATE_INFO,
		viewType = .D2,
		image = image.image,
		format = image.format,
		subresourceRange = {
			baseMipLevel = 0,
			levelCount = 1,
			baseArrayLayer = 0,
			layerCount = 1,
			aspectMask = aspect_flags,
		},
	}

	vk_check(vk.CreateImageView(device, &info, nil, &image.image_view))
}

// Helper function for adding image barriers, otherwise it becomes very verbose...
transition_image :: proc(
	cmd: vk.CommandBuffer,
	image: vk.Image,
	current_layout: vk.ImageLayout,
	new_layout: vk.ImageLayout,
) {
	dep_info := vk.DependencyInfo {
		sType                   = .DEPENDENCY_INFO,
		pNext                   = nil,
		imageMemoryBarrierCount = 1,
		pImageMemoryBarriers    = &vk.ImageMemoryBarrier2 {
			sType = .IMAGE_MEMORY_BARRIER_2,
			pNext = nil,
			srcStageMask = {.ALL_COMMANDS},
			srcAccessMask = {.MEMORY_WRITE},
			dstStageMask = {.ALL_COMMANDS},
			dstAccessMask = {.MEMORY_WRITE, .MEMORY_READ},
			oldLayout = current_layout,
			newLayout = new_layout,
			image = image,
			subresourceRange = {
				aspectMask = (new_layout == .DEPTH_ATTACHMENT_OPTIMAL || new_layout == .DEPTH_READ_ONLY_OPTIMAL) ? {.DEPTH} : {.COLOR},
				baseMipLevel = 0,
				levelCount = vk.REMAINING_MIP_LEVELS,
				baseArrayLayer = 0,
				layerCount = vk.REMAINING_ARRAY_LAYERS,
			},
		},
	}

	vk.CmdPipelineBarrier2KHR(cmd, &dep_info)
}

init_vulkan :: proc(renderer: ^Renderer) {
	// Loads vulkan api functions needed to create an instance
	vk.load_proc_addresses(rawptr(glfw.GetInstanceProcAddress))
	assert(vk.GetInstanceProcAddr != nil)

	glfw_extensions := glfw.GetRequiredInstanceExtensions()
	extension_count := len(glfw_extensions)

	extensions: [dynamic]cstring
	resize(&extensions, extension_count)

	for ext, i in glfw_extensions {
		extensions[i] = ext
	}

	when ODIN_OS == .Darwin {
		append(&extensions, vk.KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME)
	}
	append(&extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
	defer delete(extensions)

	create_info := vk.InstanceCreateInfo {
		sType                   = .INSTANCE_CREATE_INFO,
		pNext                   = &vk.DebugUtilsMessengerCreateInfoEXT {
			sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
			messageSeverity = {.WARNING, .ERROR, .INFO},
			messageType = {.GENERAL, .VALIDATION, .PERFORMANCE},
			pfnUserCallback = debug_callback,
			pNext = &vk.ValidationFeaturesEXT {
				sType = .VALIDATION_FEATURES_EXT,
				pEnabledValidationFeatures = raw_data(VALIDATION_FEATURES),
				enabledValidationFeatureCount = u32(len(VALIDATION_LAYERS)),
			},
		},
		pApplicationInfo        = &{
			sType = .APPLICATION_INFO,
			pApplicationName = "Hello Triangle",
			applicationVersion = vk.MAKE_VERSION(0, 0, 1),
			pEngineName = "No Engine",
			engineVersion = vk.MAKE_VERSION(1, 0, 0),
			apiVersion = vk.API_VERSION_1_3,
		},
		ppEnabledExtensionNames = raw_data(extensions),
		enabledExtensionCount   = cast(u32)len(extensions),
		enabledLayerCount       = u32(len(VALIDATION_LAYERS)),
		ppEnabledLayerNames     = raw_data(VALIDATION_LAYERS),
	}

	when ODIN_OS == .Darwin {
		create_info.flags = {vk.InstanceCreateFlag.ENUMERATE_PORTABILITY_KHR}
	}

	vk_check(vk.CreateInstance(&create_info, nil, &renderer.instance))

	// Load instance-specific procedures
	vk.load_proc_addresses_instance(renderer.instance)

	n_ext: u32
	vk.EnumerateInstanceExtensionProperties(nil, &n_ext, nil)

	extension_props := make([]vk.ExtensionProperties, n_ext)
	defer delete(extension_props)

	vk.EnumerateInstanceExtensionProperties(nil, &n_ext, raw_data(extension_props))

	for &ext in &extension_props {
		fmt.println(" -", cstring(&ext.extensionName[0]))
	}

	debug_utils_create_info := vk.DebugUtilsMessengerCreateInfoEXT {
		sType           = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
		messageSeverity = {.VERBOSE, .WARNING, .INFO, .ERROR},
		messageType     = {.GENERAL, .VALIDATION},
		pfnUserCallback = debug_callback,
		pUserData       = nil,
	}

	vk_check(
		vk.CreateDebugUtilsMessengerEXT(
			renderer.instance,
			&debug_utils_create_info,
			nil,
			&renderer.debug_messenger,
		),
	)

	vk_check(glfw.CreateWindowSurface(renderer.instance, renderer.window, nil, &renderer.surface))

	device_extensions: [dynamic]cstring
	resize(&device_extensions, len(DEVICE_EXTENSIONS))
	for ext, i in DEVICE_EXTENSIONS {
		device_extensions[i] = ext
	}

	{
		device_count: u32 = 0
		vk.EnumeratePhysicalDevices(renderer.instance, &device_count, nil)

		devices := make([]vk.PhysicalDevice, device_count)
		defer delete(devices)
		vk.EnumeratePhysicalDevices(renderer.instance, &device_count, raw_data(devices))

		// Pick a fallback GPU, if you don't have a discrete GPU.
		if len(devices) > 0 {
			renderer.physical_device = devices[0]
		}

		for device in devices {
			// This is a really crude check, this does NOT check for features. Don't do this in real programs.
			// We're just going to assume your discrete GPU supports the ones we use for this example.
			properties: vk.PhysicalDeviceProperties
			vk.GetPhysicalDeviceProperties(device, &properties)
			if properties.deviceType == .DISCRETE_GPU {
				renderer.physical_device = device
				break
			}
		}

		if renderer.physical_device == nil {
			panic("No GPU found that supports all required features.")
		}

		// In accordance with the Vulkan specification, if VK_KHR_portability_subset
		// is in the device extensions, then it must be part of the enabled extensions
		// when creating the device.
		//
		// We check here to see if that extension is present, and then add it to our
		// list of enabled device extensions if it is.
		//
		// This is required for Vulkan support on macOS via MoltenVK.

		n_dev_ext: u32
		vk.EnumerateDeviceExtensionProperties(renderer.physical_device, nil, &n_dev_ext, nil)

		dev_extension_props := make([]vk.ExtensionProperties, n_dev_ext)
		defer delete(dev_extension_props)

		vk.EnumerateDeviceExtensionProperties(renderer.physical_device, nil, &n_dev_ext, raw_data(dev_extension_props))

		for &ext in &dev_extension_props {
			// NOTE: `KHR_PORTABILITY_SUBSET_EXTENSION_NAME` is not defined by
			//       vendor:vulkan because vulkan_beta.h is not used by the wrapper
			//       generator at this time, so we use the raw name string instead.
			if cstring(&ext.extensionName[0]) == "VK_KHR_portability_subset" {
				append(&device_extensions, "VK_KHR_portability_subset")
				break
			}
		}
	}

	{
		queue_family_count: u32
		vk.GetPhysicalDeviceQueueFamilyProperties(
			renderer.physical_device,
			&queue_family_count,
			nil,
		)

		queue_families := make([]vk.QueueFamilyProperties, queue_family_count)
		defer delete(queue_families)
		vk.GetPhysicalDeviceQueueFamilyProperties(
			renderer.physical_device,
			&queue_family_count,
			raw_data(queue_families),
		)

		has_graphics := false

		for queue_family, i in &queue_families {
			if .GRAPHICS in queue_family.queueFlags {
				renderer.graphics_queue_family = u32(i)
				has_graphics = true
			}
		}

		assert(has_graphics)
	}

	{
		queue_priority: f32 = 1.0

		queue_create_info: vk.DeviceQueueCreateInfo
		queue_create_info.sType = .DEVICE_QUEUE_CREATE_INFO
		queue_create_info.queueFamilyIndex = renderer.graphics_queue_family
		queue_create_info.queueCount = 1
		queue_create_info.pQueuePriorities = &queue_priority

		device_create_info := vk.DeviceCreateInfo {
			sType                   = .DEVICE_CREATE_INFO,
			pNext                   = &REQUIRED_FEATURES,
			pQueueCreateInfos       = &queue_create_info,
			queueCreateInfoCount    = 1,
			ppEnabledExtensionNames = raw_data(device_extensions),
			enabledExtensionCount   = u32(len(device_extensions)),
		}

		vk_check(
			vk.CreateDevice(renderer.physical_device, &device_create_info, nil, &renderer.device),
		)

		assert(renderer.device != nil)

		vk.GetDeviceQueue(
			renderer.device,
			renderer.graphics_queue_family,
			0,
			&renderer.graphics_queue,
		)
	}

	SwapChainSupportDetails :: struct {
		capabilities:  vk.SurfaceCapabilitiesKHR,
		formats:       []vk.SurfaceFormatKHR,
		present_modes: []vk.PresentModeKHR,
	}

	// This allocates format and present_mode slices.
	query_swapchain_support :: proc(renderer: ^Renderer) -> SwapChainSupportDetails {
		details: SwapChainSupportDetails

		vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(
			renderer.physical_device,
			renderer.surface,
			&details.capabilities,
		)

		{
			format_count: u32
			vk.GetPhysicalDeviceSurfaceFormatsKHR(
				renderer.physical_device,
				renderer.surface,
				&format_count,
				nil,
			)

			formats := make([]vk.SurfaceFormatKHR, format_count)
			vk.GetPhysicalDeviceSurfaceFormatsKHR(
				renderer.physical_device,
				renderer.surface,
				&format_count,
				raw_data(formats),
			)

			details.formats = formats
		}

		{
			present_mode_count: u32
			vk.GetPhysicalDeviceSurfacePresentModesKHR(
				renderer.physical_device,
				renderer.surface,
				&present_mode_count,
				nil,
			)

			present_modes := make([]vk.PresentModeKHR, present_mode_count)
			vk.GetPhysicalDeviceSurfacePresentModesKHR(
				renderer.physical_device,
				renderer.surface,
				&present_mode_count,
				raw_data(present_modes),
			)

			details.present_modes = present_modes
		}

		return details
	}

	// This returns true if a surface format was found that matches the requirements.
	// Otherwise, this returns the first surface format and false if one wasn't found.
	choose_swap_surface_format :: proc(
		available_formats: []vk.SurfaceFormatKHR,
	) -> (
		vk.SurfaceFormatKHR,
		bool,
	) {
		for surface_format in available_formats {
			if surface_format.format == .B8G8R8A8_UNORM &&
			   surface_format.colorSpace == .SRGB_NONLINEAR {
				return surface_format, true
			}
		}

		return available_formats[0], false
	}

	choose_swap_present_mode :: proc(
		available_present_modes: []vk.PresentModeKHR,
	) -> vk.PresentModeKHR {
		return .FIFO
	}

	choose_swap_extent :: proc(
		window: glfw.WindowHandle,
		capabilities: ^vk.SurfaceCapabilitiesKHR,
	) -> vk.Extent2D {
		if (capabilities.currentExtent.width != max(u32)) {
			return capabilities.currentExtent
		} else {
			width, height := glfw.GetFramebufferSize(window)

			actual_extent := vk.Extent2D{u32(width), u32(height)}

			actual_extent.width = clamp(
				actual_extent.width,
				capabilities.minImageExtent.width,
				capabilities.maxImageExtent.width,
			)
			actual_extent.height = clamp(
				actual_extent.height,
				capabilities.minImageExtent.height,
				capabilities.maxImageExtent.height,
			)

			return actual_extent
		}
	}

	{
		swapchain_support := query_swapchain_support(renderer)
		defer {
			delete(swapchain_support.formats)
			delete(swapchain_support.present_modes)
		}

		surface_format, _ := choose_swap_surface_format(swapchain_support.formats)
		present_mode := choose_swap_present_mode(swapchain_support.present_modes)
		extent := choose_swap_extent(renderer.window, &swapchain_support.capabilities)

		image_count := swapchain_support.capabilities.minImageCount + 1

		if swapchain_support.capabilities.maxImageCount > 0 &&
		   image_count > swapchain_support.capabilities.maxImageCount {
			image_count = swapchain_support.capabilities.maxImageCount
		}

		create_info := vk.SwapchainCreateInfoKHR {
			sType                 = .SWAPCHAIN_CREATE_INFO_KHR,
			surface               = renderer.surface,
			minImageCount         = image_count,
			imageFormat           = surface_format.format,
			imageColorSpace       = surface_format.colorSpace,
			imageExtent           = extent,
			imageArrayLayers      = 1,
			imageUsage            = {.COLOR_ATTACHMENT, .TRANSFER_DST},

			// TODO: Support multiple queues?
			imageSharingMode      = .EXCLUSIVE,
			queueFamilyIndexCount = 0, // Optional
			pQueueFamilyIndices   = nil, // Optional
			preTransform          = swapchain_support.capabilities.currentTransform,
			compositeAlpha        = {.OPAQUE},
			presentMode           = present_mode,
			clipped               = true,
			oldSwapchain          = {},
		}

		vk_check(vk.CreateSwapchainKHR(renderer.device, &create_info, nil, &renderer.swapchain))

		vk.GetSwapchainImagesKHR(renderer.device, renderer.swapchain, &image_count, nil)
		renderer.swapchain_images = make([]vk.Image, image_count)
		vk.GetSwapchainImagesKHR(
			renderer.device,
			renderer.swapchain,
			&image_count,
			raw_data(renderer.swapchain_images),
		)

		renderer.swapchain_image_format = surface_format.format
		renderer.swapchain_extent = extent

		renderer.swapchain_image_views = make([]vk.ImageView, len(renderer.swapchain_images))

		for i in 0 ..< len(renderer.swapchain_images) {
			create_info := vk.ImageViewCreateInfo {
				sType = .IMAGE_VIEW_CREATE_INFO,
				image = renderer.swapchain_images[i],
				viewType = .D2,
				format = renderer.swapchain_image_format,
				components = {r = .IDENTITY, g = .IDENTITY, b = .IDENTITY, a = .IDENTITY},
				subresourceRange = {
					aspectMask = {.COLOR},
					baseMipLevel = 0,
					levelCount = 1,
					baseArrayLayer = 0,
					layerCount = 1,
				},
			}

			vk_check(
				vk.CreateImageView(
					renderer.device,
					&create_info,
					nil,
					&renderer.swapchain_image_views[i],
				),
			)
		}
	}

	{
		x, y := glfw.GetWindowSize(renderer.window)

		draw_image_format: vk.Format = .R32G32B32A32_SFLOAT
		draw_image_extent := vk.Extent3D{u32(x), u32(y), 1}
		draw_image_usages := vk.ImageUsageFlags {
			.TRANSFER_SRC,
			.TRANSFER_DST,
			.STORAGE,
			.COLOR_ATTACHMENT,
		}

		renderer.draw_image = create_image(
			renderer,
			draw_image_format,
			draw_image_extent,
			draw_image_usages,
		)
		create_image_view(renderer.device, &renderer.draw_image, {.COLOR})

		renderer.depth_image = create_image(
			renderer,
			.D32_SFLOAT,
			draw_image_extent,
			{.DEPTH_STENCIL_ATTACHMENT},
		)
		create_image_view(renderer.device, &renderer.depth_image, {.DEPTH})
	}

	{
		command_pool_info := vk.CommandPoolCreateInfo {
			sType            = .COMMAND_POOL_CREATE_INFO,
			pNext            = nil,
			flags            = {.RESET_COMMAND_BUFFER},
			queueFamilyIndex = renderer.graphics_queue_family,
		}

		for i in 0 ..< FRAME_OVERLAP {
			vk_check(
				vk.CreateCommandPool(
					renderer.device,
					&command_pool_info,
					nil,
					&renderer.frames[i].command_pool,
				),
			)

			cmd_alloc_info := vk.CommandBufferAllocateInfo {
				sType              = .COMMAND_BUFFER_ALLOCATE_INFO,
				pNext              = nil,
				commandPool        = renderer.frames[i].command_pool,
				commandBufferCount = 1,
				level              = .PRIMARY,
			}

			vk_check(
				vk.AllocateCommandBuffers(
					renderer.device,
					&cmd_alloc_info,
					&renderer.frames[i].main_command_buffer,
				),
			)
		}

		vk_check(
			vk.CreateCommandPool(
				renderer.device,
				&command_pool_info,
				nil,
				&renderer.imm_command_pool,
			),
		)

		cmd_alloc_info := vk.CommandBufferAllocateInfo {
			sType              = .COMMAND_BUFFER_ALLOCATE_INFO,
			pNext              = nil,
			commandPool        = renderer.imm_command_pool,
			commandBufferCount = 1,
			level              = .PRIMARY,
		}

		vk_check(
			vk.AllocateCommandBuffers(
				renderer.device,
				&cmd_alloc_info,
				&renderer.imm_command_buffer,
			),
		)
	}

	{
		fence_create_info := vk.FenceCreateInfo {
			sType = .FENCE_CREATE_INFO,
			flags = {.SIGNALED},
		}
		semaphore_create_info := vk.SemaphoreCreateInfo {
			sType = .SEMAPHORE_CREATE_INFO,
			flags = {},
		}

		for &frame in renderer.frames {
			vk_check(vk.CreateFence(renderer.device, &fence_create_info, nil, &frame.render_fence))

			vk_check(
				vk.CreateSemaphore(
					renderer.device,
					&semaphore_create_info,
					nil,
					&frame.swapchain_semaphore,
				),
			)
			vk_check(
				vk.CreateSemaphore(
					renderer.device,
					&semaphore_create_info,
					nil,
					&frame.render_semaphore,
				),
			)
		}

		vk.CreateFence(renderer.device, &fence_create_info, nil, &renderer.imm_fence)

	}
	// End bootstrapping
}

vulkan_shutdown :: proc(renderer: ^Renderer) {
	vk.DeviceWaitIdle(renderer.device)

	vk.DestroyImage(renderer.device, renderer.draw_image.image, nil)
	vk.DestroyImageView(renderer.device, renderer.draw_image.image_view, nil)
	vk.FreeMemory(renderer.device, renderer.draw_image.memory, nil)

	vk.DestroyImage(renderer.device, renderer.depth_image.image, nil)
	vk.DestroyImageView(renderer.device, renderer.depth_image.image_view, nil)
	vk.FreeMemory(renderer.device, renderer.depth_image.memory, nil)

	for &frame in renderer.frames {
		vk.DestroyCommandPool(renderer.device, frame.command_pool, nil)

		vk.DestroyFence(renderer.device, frame.render_fence, nil)
		vk.DestroySemaphore(renderer.device, frame.render_semaphore, nil)
		vk.DestroySemaphore(renderer.device, frame.swapchain_semaphore, nil)
	}

	vk.DestroyCommandPool(renderer.device, renderer.imm_command_pool, nil)
	vk.DestroyFence(renderer.device, renderer.imm_fence, nil)

	vk.DestroySwapchainKHR(renderer.device, renderer.swapchain, nil)

	// We don't need to delete the swapchain images, it was created by the driver
	// However, we did create the views, so we will destroy those now.
	for &image_view in renderer.swapchain_image_views {
		vk.DestroyImageView(renderer.device, image_view, nil)
	}

	delete(renderer.swapchain_image_views)
	delete(renderer.swapchain_images)

	vk.DestroySurfaceKHR(renderer.instance, renderer.surface, nil)
	vk.DestroyDevice(renderer.device, nil)

	vk.DestroyDebugUtilsMessengerEXT(renderer.instance, renderer.debug_messenger, nil)

	vk.DestroyInstance(renderer.instance, nil)
}
