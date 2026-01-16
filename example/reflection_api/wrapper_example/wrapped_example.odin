package reflection_wrapper_example

import "core:fmt"

import refl "../../../slang/reflection_wrapper"
import sp "../../../slang"
import ex "../../"

// ported from https://github.com/shader-slang/slang/tree/master/examples/reflection-api

main :: proc() {
	global_session: ^sp.IGlobalSession
	ensure(sp.createGlobalSession(sp.API_VERSION, &global_session) == sp.OK)
	defer sp.shutdown()

	target_desc := sp.TargetDesc {
		structureSize = size_of(sp.TargetDesc),
		format        = .SPIRV,
		flags         = {.GENERATE_SPIRV_DIRECTLY},
		profile       = global_session->findProfile("sm_6_0"),
	}

	session_desc := sp.SessionDesc {
		structureSize            = size_of(sp.SessionDesc),
		targets                  = &target_desc,
		targetCount              = 1,
	}

	session: ^sp.ISession
	global_session->createSession(session_desc, &session)
	defer session->release() 

	g_SourceFileNames = {
		"../compute-simple.slang",
		"../raster-simple.slang",
	}

	res := compileAndReflectPrograms(session)
	ex.slang_check(res)
	fmt.println("")
}

g_afterArrayElement: bool = true
g_indentation: int
g_metadataForEntryPoints: [dynamic]^sp.IMetadata
g_programLayout: refl.ProgramLayout
g_SourceFileNames: []cstring

printIndentation :: proc() {
	for _ in 1..<g_indentation {
		print(" ")
	}
}

common_print :: proc(args: ..any) {
	fmt.print(..args)
}

printf             :: fmt.printf
printResourceShape :: proc(shape: sp.SlangResourceShape) {
	SCOPED_OBJECT()
	key("base")
	common_print(shape & .BASE_SHAPE_MASK)
}
printComment :: proc(args: ..any) {
	printf("# %s",..args)
}

print                 :: common_print
printBool             :: common_print
printTypeKind         :: common_print
printScalarType       :: common_print
printResourceAccess   :: common_print
printLayoutUnit       :: common_print
printMatrixLayoutMode :: common_print
printStage            :: common_print
printTargetFormat     :: common_print

StageMask :: bit_set[sp.Stage; u32]

INDENT :: 4
beginObject :: proc() { g_indentation += INDENT }
endObject   :: proc() { g_indentation -= INDENT }
beginArray  :: proc() { g_indentation += INDENT }
endArray    :: proc() { g_indentation -= INDENT }

@(deferred_none=endObject)
SCOPED_OBJECT :: proc() {
	beginObject()
}

@(deferred_none=endArray)
WITH_ARRAY :: proc() {
	beginArray()
}

newLine :: proc() {
	print("\n")
	printIndentation()
}

key :: proc(key: cstring) {
	if !g_afterArrayElement {
		newLine()
	}
	g_afterArrayElement = false

	printf("%s: ", key)
}

element :: proc() {
	newLine()
	printf("- ")
	g_afterArrayElement = true
}

printQuotedString :: proc(text: cstring) {
	if text != "" {
		printf("\"%s\"", text)
	} else {
		print("null")
	}
}

printVariable :: proc(variable: refl.VariableReflection) {
	SCOPED_OBJECT()

	name := variable->getName()
	type := variable->getType()

	key("name")
	printQuotedString(name)
	key("type")
	printType(type)

	value: i64
	if sp.SUCCEEDED(variable->getDefaultValueInt(&value)){
		key("value")
		print(value)
	}
}



printCommonTypeInfo :: proc(type: refl.TypeReflection) {
	#partial switch type->getKind() {
	case .Scalar: 
		key("scalar type")
		printScalarType(type->getScalarType())
	case .Array:
		key("element count")
		printPossiblyUnbounded(type->getElementCount())
	case .Vector:
		key("element count")
		print(type->getElementCount())
	case .Matrix:
		key("row count")
		print(type->getRowCount())
		key("column count")
		print(type->getColumnCount())
	case .Resource:
		key("shape")
		printResourceShape(type->getResourceShape())
		key("access")
		printResourceAccess(type->getResourceAccess())
	case:
	}
}



printType :: proc(type: refl.TypeReflection) {
	SCOPED_OBJECT()
	name := type->getName()
	kind := type->getKind()

	key("name")
	printQuotedString(name)
	key("kind")
	printTypeKind(kind)

	printCommonTypeInfo(type)

	#partial switch type->getKind() {
	case .Struct:
		key("fields")
		fieldCount := type->getFieldCount()
		
		WITH_ARRAY(); for f in 0..<fieldCount {
			element()
			field := type->getFieldByIndex(f)
			printVariable(field)
		}
	case .Array, .Vector, .Matrix:
		key("element type")
		printType(type->getElementType())
	case .Resource:
		key("result type")
		printType(type->getResourceResultType())
	case .ConstantBuffer, .ParameterBlock, .TextureBuffer, .ShaderStorageBuffer:
	// "single-element containers" 
	// https://docs.shader-slang.org/en/latest/external/slang/docs/user-guide/09-reflection.html#pitfalls-to-avoid    
		key("element type")
		printType(type->getElementType())
	case:
	}	
}

printPossiblyUnbounded :: proc(value: uint) {
	if value == sp.UNBOUNDED_SIZE {
		printf("unbounded")
	} else {
		printf("%d", value)
	}
}

printVariableLayout :: proc(variableLayout: refl.VariableLayoutReflection, accessPath: AccessPath) {
	SCOPED_OBJECT()

	key("name")
	printQuotedString(variableLayout->getName())

	printOffsets(variableLayout, accessPath)

	printVaryingParameterInfo(variableLayout)

	variablePath: ExtendedAccessPath
	initExtendedAccessPath(&variablePath, accessPath, variableLayout)

	key("type layout")
	printTypeLayout(variableLayout->getTypeLayout(), variablePath)
}

initExtendedAccessPath :: proc(
	eap:            ^ExtendedAccessPath,
	accessPath:     AccessPath,
	variableLayout: refl.VariableLayoutReflection
) {
	if !accessPath.valid {
		return 
	}

	eap.accessPath = accessPath
	eap.element.variableLayout = variableLayout
	eap.element.outer = accessPath.leaf
	eap.leaf = &eap.element
}

AccessPath :: struct {
	valid: bool,
	deepestConstantBufer : ^AccessPathNode,
	deepestParameterBlock: ^AccessPathNode,
	leaf: ^AccessPathNode,
}

ExtendedAccessPath :: struct {
	using accessPath: AccessPath,
	element:          AccessPathNode,
}

AccessPathNode :: struct {
	variableLayout: refl.VariableLayoutReflection,
	outer:          ^AccessPathNode,
}

printVaryingParameterInfo :: proc(variableLayout: refl.VariableLayoutReflection) {
	semanticName := variableLayout->getSemanticName()
	if semanticName != "" {
		key("semantic")
		SCOPED_OBJECT()
		key("name")
		printQuotedString(semanticName)
		key("index")
		print(variableLayout->getSemanticIndex())
	}
}

printCumulativeOffsets :: proc(
	variableLayout: refl.VariableLayoutReflection,
	accessPath: AccessPath,
) {
	key("cumulative")

	usedLayoutUnitCount := variableLayout->getCategoryCount()
	WITH_ARRAY(); for i in 0..<usedLayoutUnitCount {
		element()
		layoutUnit := variableLayout->getCategoryByIndex(i)
		printCumulativeOffset(variableLayout, layoutUnit, accessPath)
	}
}	

printCumulativeOffset :: proc(
	variableLayout: refl.VariableLayoutReflection,
	layoutUnit:     sp.LayoutUnit,
	accessPath:     AccessPath
) {
	cumulativeOffset := calculateCumulativeOffset(variableLayout, layoutUnit, accessPath)
	printOffset(layoutUnit, cumulativeOffset.value, cumulativeOffset.space)
}

CumulativeOffset :: struct {
	value: uint,
	space: uint,
}

calculateCumulativeOffset2 :: proc(
	layoutUnit: sp.LayoutUnit,
	accessPath: AccessPath,
) -> CumulativeOffset {
	result: CumulativeOffset
	#partial switch layoutUnit {
	// #### Layout Units That Don't Require Special Handling
	//
	case:
		for node := accessPath.leaf; node != nil; node = node.outer {
			result.value += node.variableLayout->getOffset(layoutUnit)
		}
	// #### Bytes
	//
	case .Uniform:
		for node := accessPath.leaf; node != accessPath.deepestConstantBufer; node = node.outer {
			result.value += node.variableLayout->getOffset(layoutUnit)
		}
	// #### Layout Units That Care About Spaces
	//
	case .ConstantBuffer, .ShaderResource, .UnorderedAccess, .SamplerState, .DescriptorTableSlot:
		for node := accessPath.leaf; node != accessPath.deepestParameterBlock; node = node.outer {
			result.value += node.variableLayout->getOffset(layoutUnit)
			result.space += node.variableLayout->getBindingSpace(layoutUnit)
		}
		for node := accessPath.deepestParameterBlock; node != nil; node = node.outer {
			result.space += node.variableLayout->getOffset(.SubElementRegisterSpace)
		}
	}
	return result
}

calculateCumulativeOffset :: proc(
	variableLayout: refl.VariableLayoutReflection,
	layoutUnit:     sp.LayoutUnit,
	accessPath:     AccessPath,
) -> CumulativeOffset {
	result := calculateCumulativeOffset2(layoutUnit, accessPath)
	result.value += variableLayout->getOffset(layoutUnit)
	result.space += variableLayout->getBindingSpace(layoutUnit)
	return result
}

printOffsets :: proc(variableLayout: refl.VariableLayoutReflection, accessPath: AccessPath) {
	key("offset")
	{
		SCOPED_OBJECT()
		printRelativeOffsets(variableLayout)

		if accessPath.valid {
			printCumulativeOffsets(variableLayout, accessPath)
		}
	}


	if accessPath.valid {
		printStageUsage(variableLayout, accessPath)
	}
}

calculateStageMask :: proc(
	variableLayout: refl.VariableLayoutReflection,
	accessPath: AccessPath,
) -> StageMask {
	mask: StageMask

	usedLayoutUnitCount := variableLayout->getCategoryCount()
	for i in 0..<usedLayoutUnitCount {
		layoutUnit := variableLayout->getCategoryByIndex(i)
		offset := calculateCumulativeOffset(variableLayout, layoutUnit, accessPath)

		mask |= calculateParameterStageMask(layoutUnit, offset)
	}

	return mask
}

 calculateParameterStageMask :: proc(
	layoutUnit: sp.LayoutUnit ,
	offset: CumulativeOffset ,
) -> StageMask {
	mask := StageMask{}
	entryPointCount := len(g_metadataForEntryPoints)
	for i in 0..<entryPointCount {
		isUsed := false
		g_metadataForEntryPoints[i]->isParameterLocationUsed(
			sp.SlangParameterCategory(layoutUnit),
			offset.space,
			offset.value,
			&isUsed
		)
		if isUsed {
			entryPointStage := g_programLayout->getEntryPointByIndex(uint(i))->getStage()
			mask += {entryPointStage}
		}
	}
	return mask
}

printStageUsage :: proc(variableLayout: refl.VariableLayoutReflection, accessPath: AccessPath) {
	stageMask := calculateStageMask(variableLayout, accessPath)

	key("used by stages")
	WITH_ARRAY(); for stage in stageMask {
		if stage in stageMask {
			element()
			printStage(stage)
		}
	}

	g_afterArrayElement = false
}

printOffset :: proc {
	printOffset1,
	printOffset2,
}

printOffset1 :: proc(
	variableLayout: refl.VariableLayoutReflection,
	layoutUnit: sp.LayoutUnit
) {
	printOffset2(
		layoutUnit,
		variableLayout->getOffset(layoutUnit),
		variableLayout->getBindingSpace(layoutUnit)
	)
}

printOffset2 :: proc(layoutUnit: sp.LayoutUnit, offset, spaceOffset: uint) {
	SCOPED_OBJECT()
	key("value")
	print(offset)
	key("unit")
	printLayoutUnit(layoutUnit)

	// #### Spaces / Sets
	#partial switch layoutUnit {
	case .ConstantBuffer, .ShaderResource, .UnorderedAccess, .SamplerState, .DescriptorTableSlot:
		key("space")
		print(spaceOffset)
	case:
	}
}

printRelativeOffsets :: proc(variableLayout: refl.VariableLayoutReflection) {
	key("relative")
	usedLayoutUnitCount := variableLayout->getCategoryCount()
	
	WITH_ARRAY(); for i in 0..<usedLayoutUnitCount {
		element()

		layoutUnit := variableLayout->getCategoryByIndex(i)
		printOffset(variableLayout, layoutUnit)
	}
}

printKindSpecificInfo :: proc(typeLayout: refl.TypeLayoutReflection, accessPath: AccessPath) {
	#partial switch typeLayout->getKind() {
	case .Struct:
		key("fields")
		fieldCount := typeLayout->getFieldCount()
		WITH_ARRAY(); for f in 0..<fieldCount {
			element()
			field := typeLayout->getFieldByIndex(f)
			printVariableLayout(field, accessPath)
		}
	case .Array, .Vector:
		key("element type layout")
		printTypeLayout(typeLayout->getElementTypeLayout(), {})
	case .Matrix:
		// Note that the concepts of “row” and “column” as employed by Slang are the opposite of how Vulkan,
		// SPIR-V, GLSL, and OpenGL use those terms. When Slang reflects a matrix as using row-major layout,
		// the corresponding matrix in generated SPIR-V will have a ColMajor decoration.
		// For an explanation of why these conventions differ, please see the relevant appendix.
		// https://docs.shader-slang.org/en/latest/external/slang/docs/user-guide/a1-01-matrix-layout.html
		key("matrix layout mode")
		printMatrixLayoutMode(typeLayout->getMatrixLayoutMode())

		key("element type layout")
		printTypeLayout(typeLayout->getElementTypeLayout(), {})
	case .ConstantBuffer, .ParameterBlock, .TextureBuffer, .ShaderStorageBuffer:
		containerVarLayout := typeLayout->getContainerVarLayout()
		elementVarLayout := typeLayout->getElementVarLayout()

		innerOffsets := accessPath
		innerOffsets.deepestConstantBufer = innerOffsets.leaf
		if containerVarLayout->getTypeLayout()->getSize(.SubElementRegisterSpace) != 0 {
			innerOffsets.deepestParameterBlock = innerOffsets.leaf
		}

		key("container")
		{
			SCOPED_OBJECT()
			printOffsets(containerVarLayout, innerOffsets)
		}

		key("content")
		{
			SCOPED_OBJECT()
			printOffsets(elementVarLayout, innerOffsets)

			elementOffsets: ExtendedAccessPath
			initExtendedAccessPath(&elementOffsets, innerOffsets, elementVarLayout)

			key("type layout")
			printTypeLayout(elementVarLayout->getTypeLayout(), elementOffsets)
		}
	case .Resource:
		resource_shape := typeLayout->getResourceShape()
		if u32(resource_shape & .BASE_SHAPE_MASK) ==
			u32(sp.SlangResourceShape(.STRUCTURED_BUFFER)) {
			key("element type layout")
			printTypeLayout(typeLayout->getElementTypeLayout(), accessPath)
		} else {
			key("result type")
			printType(typeLayout->getResourceResultType())
		}	
	case: 
	}
}

printTypeLayout :: proc(typeLayout: refl.TypeLayoutReflection, accessPath: AccessPath) {
	SCOPED_OBJECT()

	key("name")
	printQuotedString(typeLayout->getName())
	key("kind")
	printTypeKind(typeLayout->getKind())
	printCommonTypeInfo(typeLayout->getType())

	printSizes(typeLayout)

	printKindSpecificInfo(typeLayout, accessPath)

}

printSize :: proc {
	printSize1,
	printSize2,
}

printSize1 :: proc(typeLayout: refl.TypeLayoutReflection, layoutUnit: sp.LayoutUnit) {
	printSize(layoutUnit, typeLayout->getSize(layoutUnit))
}

printSize2 :: proc(layoutUnit: sp.LayoutUnit, size: uint) {
	SCOPED_OBJECT()

	key("value")
	printPossiblyUnbounded(size)
	key("unit")
	printLayoutUnit(layoutUnit)
}

printSizes :: proc(typeLayout: refl.TypeLayoutReflection) {
	key("size")
	usedLayoutUnitCount := typeLayout->getCategoryCount()
	
	WITH_ARRAY(); for i in 0..<usedLayoutUnitCount {
		element()

		layoutUnit := typeLayout->getCategoryByIndex(i)
		printSize(typeLayout, layoutUnit)
	}
}

// ### Global Scope
//
printScope :: proc(scopeVarLayout: refl.VariableLayoutReflection, accessPath: AccessPath) {
	scopeOffsets: ExtendedAccessPath
	initExtendedAccessPath(&scopeOffsets, accessPath, scopeVarLayout)

	scopeTypeLayout := scopeVarLayout->getTypeLayout()
	#partial switch scopeTypeLayout->getKind() {
	// #### Parameters are Grouped Into a Structure
	//
	case .Struct:
		key("parameters")

		paramCount := scopeTypeLayout->getFieldCount()
		for i in 0..<paramCount {
			element()
			param := scopeTypeLayout->getFieldByIndex(i)
			printVariableLayout(param, scopeOffsets)
		}
	

	// #### Wrapped in a Constant Buffer If Needed
	//
	case .ConstantBuffer:
		key("automatically-introduced constant buffer")
		{
			SCOPED_OBJECT()
			printOffsets(scopeTypeLayout->getContainerVarLayout(), scopeOffsets)
		}

		printScope(scopeTypeLayout->getElementVarLayout(), scopeOffsets)

	// #### Wrapped in a Parameter Block If Needed
	//
	case .ParameterBlock:
		key("automatically-introduced parameter block")
		{
			SCOPED_OBJECT()
			printOffsets(scopeTypeLayout->getContainerVarLayout(), scopeOffsets)
		}

		printScope(scopeTypeLayout->getElementVarLayout(), scopeOffsets)

	case:
	// Note that this default case is never expected to
	// arise with the current Slang compiler and reflection
	// API, but we include it here as a kind of failsafe.
	//
		key("variable layout")
		printVariableLayout(scopeVarLayout, accessPath)
	}

}

printProgramLayout :: proc(programLayout: refl.ProgramLayout, targetFormat: sp.CompileTarget) {
	{
		SCOPED_OBJECT()

		key("target")
		printTargetFormat(targetFormat)

		rootOffsets: AccessPath
		rootOffsets.valid = true

		key("global scope")
		{
			SCOPED_OBJECT()
			printScope(programLayout->getGlobalParamsVarLayout(), rootOffsets)
		}

		key("entry points")
		entryPointCount := programLayout->getEntryPointCount()
		
		WITH_ARRAY(); for i in 0..<entryPointCount {
			element()
			printEntryPointLayout(programLayout->getEntryPointByIndex(i), rootOffsets)
		}
	}
	clear(&g_metadataForEntryPoints)
	shrink(&g_metadataForEntryPoints)
}

printEntryPointLayout :: proc(
	entryPointLayout: refl.EntryPointReflection,
	accessPath:       AccessPath,
) {
	SCOPED_OBJECT()

	key("stage")
	printStage(entryPointLayout->getStage())

	printStageSpecificInfo(entryPointLayout)

	printScope(entryPointLayout->getVarLayout(), accessPath)

	resultVariableLayout := entryPointLayout->getResultVarLayout()
	cond := resultVariableLayout->getTypeLayout()->getKind() != .None
	if cond {
		key("result")
		printVariableLayout(resultVariableLayout, accessPath)
	}
}

// #### Stage-Specific Information
//
printStageSpecificInfo :: proc(entryPointLayout: refl.EntryPointReflection) {
	#partial switch (entryPointLayout->getStage()) {
	case:
	case .COMPUTE:
		kAxisCount :: 3
		sizes: [kAxisCount]uint
		entryPointLayout->getComputeThreadGroupSize(kAxisCount, &sizes[0])

		key("thread group size")
		SCOPED_OBJECT()
		key("x")
		print(sizes[0])
		key("y")
		print(sizes[1])
		key("z")
		print(sizes[2])
	case .FRAGMENT:
		key("uses any sample-rate inputs")
		printBool(entryPointLayout->usesAnySampleRateInput())
	}
}

collectEntryPointMetadata :: proc(
	program: ^sp.IComponentType,
	targetIndex: int,
	entryPointCount: int
) -> sp.Result {
	resize(&g_metadataForEntryPoints, entryPointCount)
	for entryPointIndex in 0..< entryPointCount {
		entryPointMetadata: ^sp.IMetadata
		diags: ^sp.IBlob
		result := program->getEntryPointMetadata(
			entryPointIndex,
			targetIndex,
			&entryPointMetadata,
			&diags,
		)
		ex.diagnostics_check(diags)
		if sp.FAILED(result) do return result

		g_metadataForEntryPoints[entryPointIndex] = entryPointMetadata
	}
	return sp.OK
}

compileAndReflectPrograms :: proc(session: ^sp.ISession) -> (result: sp.Result){
	result = sp.OK
	g_afterArrayElement = true
	WITH_ARRAY(); for fileName in g_SourceFileNames {
		element()
		programResult := compileAndReflectProgram(session, fileName)
		if sp.FAILED(programResult) do return programResult
	}

	newLine()
	return

}

compileAndReflectProgram :: proc(session: ^sp.ISession, sourceFileName: cstring) -> (result: sp.Result) {
	g_afterArrayElement = false
	SCOPED_OBJECT()
	printComment("program")
	key("file name")
	printQuotedString(sourceFileName)
	sourceFilePath := sourceFileName

	diags: ^sp.IBlob
	result = sp.OK

	module := session->loadModule(sourceFilePath, &diags)
	ex.diagnostics_check(diags)
	defer if diags != nil { diags->release() }

	if module == nil do return sp.FAIL()

	componentsToLink: [dynamic]^sp.IComponentType

	key("global constants")
	base_decl := refl.init_decl(module->getModuleReflection())
	WITH_ARRAY(); for idx in 0..<base_decl->getChildrenCount() {
		decl := base_decl->getChild(idx)
		if varDecl := decl->asVariable(); varDecl != {} &&
			varDecl->findModifier(.Const) != nil &&
			varDecl->findModifier(.Static) != nil 
			{
			element()
			printVariable(varDecl)		
		}
	}

	key("defined entry points")
	definedEntryPointCount := module->getDefinedEntryPointCount()

	WITH_ARRAY(); for i in 0..<definedEntryPointCount {
		entryPoint: ^sp.IEntryPoint
		_ = module->getDefinedEntryPoint(i, &entryPoint)

		element()
		SCOPED_OBJECT()
		key("name")
		functionReflection := refl.init_function(entryPoint->getFunctionReflection())
		printQuotedString(functionReflection->getName())

		append(&componentsToLink, entryPoint)
	}

	composed: ^sp.IComponentType
	result = session->createCompositeComponentType(
		raw_data(componentsToLink),
		len(componentsToLink),
		&composed,
		&diags,
	)
	ex.diagnostics_check(diags)
	

	program: ^sp.IComponentType
	result = composed->link(&program, &diags)
	ex.diagnostics_check(diags)
	if sp.FAILED(result) do return result

	key("layouts")
	kTargetCount := 1
	WITH_ARRAY(); for targetIndex in 0..<kTargetCount {
		element()

		// ### Getting the Program Layout
		//
		programLayout := program->getLayout(targetIndex, &diags)
		ex.diagnostics_check(diags)
		if programLayout == nil {
			result = sp.FAIL()
			continue
		}

		ex.slang_check(collectEntryPointMetadata(
			program, targetIndex, int(definedEntryPointCount)))

		g_programLayout = refl.init_program_layout(programLayout)
		printProgramLayout(g_programLayout, .SPIRV)
	}

	return result
}
