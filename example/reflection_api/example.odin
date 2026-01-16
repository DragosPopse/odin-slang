package reflection_example

import "core:fmt"

import sp "../../slang"

import ex ".."

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
		"compute-simple.slang",
		"raster-simple.slang",
	}

	res := compileAndReflectPrograms(session)
	ex.slang_check(res)
	fmt.println("")
}

g_afterArrayElement: bool = true
g_indentation: int
g_metadataForEntryPoints: [dynamic]^sp.IMetadata
g_programLayout: ^sp.ProgramLayout
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

printVariable :: proc(variable: ^sp.VariableReflection) {
	SCOPED_OBJECT()

	name := sp.variable_getName(variable)
	type := sp.variable_getType(variable)

	key("name")
	printQuotedString(name)
	key("type")
	printType(type)

	value: i64
	if sp.SUCCEEDED(sp.variable_getDefaultValueInt(variable, &value)){
		key("value")
		print(value)
	}
}



printCommonTypeInfo :: proc(type: ^sp.TypeReflection) {
	#partial switch sp.type_getKind(type) {
	case .Scalar: 
		key("scalar type")
		printScalarType(sp.type_getScalarType(type))
	case .Array:
		key("element count")
		printPossiblyUnbounded(sp.type_getElementCount(type))
	case .Vector:
		key("element count")
		print(sp.type_getElementCount(type))
	case .Matrix:
		key("row count")
		print(sp.type_getRowCount(type))
		key("column count")
		print(sp.type_getColumnCount(type))
	case .Resource:
		key("shape")
		printResourceShape(sp.type_getResourceShape(type))
		key("access")
		printResourceAccess(sp.type_getResourceAccess(type))
	case:
	}
}



printType :: proc(type: ^sp.TypeReflection) {
	SCOPED_OBJECT()
	name := sp.type_getName(type)
	kind := sp.type_getKind(type)

	key("name")
	printQuotedString(name)
	key("kind")
	printTypeKind(kind)

	printCommonTypeInfo(type)

	#partial switch sp.type_getKind(type) {
	case .Struct:
		key("fields")
		fieldCount := sp.type_getFieldCount(type)
		
		WITH_ARRAY(); for f in 0..<fieldCount {
			element()
			field := sp.type_getFieldByIndex(type, f)
			printVariable(field)
		}
	case .Array, .Vector, .Matrix:
		key("element type")
		printType(sp.type_getElementType(type))
	case .Resource:
		key("result type")
		printType(sp.type_getResourceResultType(type))
	case .ConstantBuffer, .ParameterBlock, .TextureBuffer, .ShaderStorageBuffer:
	// "single-element containers" 
	// https://docs.shader-slang.org/en/latest/external/slang/docs/user-guide/09-reflection.html#pitfalls-to-avoid    
		key("element type")
		printType(sp.type_getElementType(type))
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

printVariableLayout :: proc(variableLayout: ^sp.VariableLayoutReflection, accessPath: AccessPath) {
	SCOPED_OBJECT()

	key("name")
	printQuotedString(sp.variable_layout_getName(variableLayout))

	printOffsets(variableLayout, accessPath)

	printVaryingParameterInfo(variableLayout)

	variablePath: ExtendedAccessPath
	initExtendedAccessPath(&variablePath, accessPath, variableLayout)

	key("type layout")
	printTypeLayout(sp.variable_layout_getTypeLayout(variableLayout), variablePath)
}

initExtendedAccessPath :: proc(
	eap:            ^ExtendedAccessPath,
	accessPath:     AccessPath,
	variableLayout: ^sp.VariableLayoutReflection
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
	variableLayout: ^sp.VariableLayoutReflection,
	outer:          ^AccessPathNode,
}

printVaryingParameterInfo :: proc(variableLayout: ^sp.VariableLayoutReflection) {
	semanticName := sp.variable_layout_getSemanticName(variableLayout)
	if semanticName != "" {
		key("semantic")
		SCOPED_OBJECT()
		key("name")
		printQuotedString(semanticName)
		key("index")
		print(sp.variable_layout_getSemanticIndex(variableLayout))
	}
}

printCumulativeOffsets :: proc(
	variableLayout: ^sp.VariableLayoutReflection,
	accessPath: AccessPath,
) {
	key("cumulative")

	usedLayoutUnitCount := sp.variable_layout_getCategoryCount(variableLayout)
	WITH_ARRAY(); for i in 0..<usedLayoutUnitCount {
		element()
		layoutUnit := sp.variable_layout_getCategoryByIndex(variableLayout, i)
		printCumulativeOffset(variableLayout, layoutUnit, accessPath)
	}
}	

printCumulativeOffset :: proc(
	variableLayout: ^sp.VariableLayoutReflection,
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
			result.value += sp.variable_layout_getOffset(node.variableLayout, layoutUnit)
		}
	// #### Bytes
	//
	case .Uniform:
		for node := accessPath.leaf; node != accessPath.deepestConstantBufer; node = node.outer {
			result.value += sp.variable_layout_getOffset(node.variableLayout, layoutUnit)
		}
	// #### Layout Units That Care About Spaces
	//
	case .ConstantBuffer, .ShaderResource, .UnorderedAccess, .SamplerState, .DescriptorTableSlot:
		for node := accessPath.leaf; node != accessPath.deepestParameterBlock; node = node.outer {
			result.value += sp.variable_layout_getOffset(node.variableLayout, layoutUnit)
			result.space += sp.variable_layout_getBindingSpace(node.variableLayout, layoutUnit)
		}
		for node := accessPath.deepestParameterBlock; node != nil; node = node.outer {
			result.space += sp.variable_layout_getOffset(node.variableLayout, .SubElementRegisterSpace)
		}
	}
	return result
}

calculateCumulativeOffset :: proc(
	variableLayout: ^sp.VariableLayoutReflection,
	layoutUnit:     sp.LayoutUnit,
	accessPath:     AccessPath,
) -> CumulativeOffset {
	result := calculateCumulativeOffset2(layoutUnit, accessPath)
	result.value += sp.variable_layout_getOffset(variableLayout, layoutUnit)
	result.space += sp.variable_layout_getBindingSpace(variableLayout, layoutUnit)
	return result
}

printOffsets :: proc(variableLayout: ^sp.VariableLayoutReflection, accessPath: AccessPath) {
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
	variableLayout: ^sp.VariableLayoutReflection,
	accessPath: AccessPath,
) -> StageMask {
	mask: StageMask

	usedLayoutUnitCount := sp.variable_layout_getCategoryCount(variableLayout)
	for i in 0..<usedLayoutUnitCount {
		layoutUnit := sp.variable_layout_getCategoryByIndex(variableLayout, i)
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
			entryPointStage := sp.entry_point_getStage(sp.program_layout_getEntryPointByIndex(g_programLayout, uint(i)))
			mask += {entryPointStage}
		}
	}
	return mask
}

printStageUsage :: proc(variableLayout: ^sp.VariableLayoutReflection, accessPath: AccessPath) {
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
	variableLayout: ^sp.VariableLayoutReflection,
	layoutUnit: sp.LayoutUnit
) {
	printOffset(
		layoutUnit,
		sp.variable_layout_getOffset(variableLayout, layoutUnit),
		sp.variable_layout_getBindingSpace(variableLayout, layoutUnit)
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

printRelativeOffsets :: proc(variableLayout: ^sp.VariableLayoutReflection) {
	key("relative")
	usedLayoutUnitCount := sp.variable_layout_getCategoryCount(variableLayout)
	
	WITH_ARRAY(); for i in 0..<usedLayoutUnitCount {
		element()

		layoutUnit := sp.variable_layout_getCategoryByIndex(variableLayout, i)
		printOffset(variableLayout, layoutUnit)
	}
}

printKindSpecificInfo :: proc(typeLayout: ^sp.TypeLayoutReflection, accessPath: AccessPath) {
	#partial switch sp.type_layout_getKind(typeLayout) {
	case .Struct:
		key("fields")
		fieldCount := sp.type_layout_getFieldCount(typeLayout)
		WITH_ARRAY(); for f in 0..<fieldCount {
			element()
			field := sp.type_layout_getFieldByIndex(typeLayout, f)
			printVariableLayout(field, accessPath)
		}
	case .Array, .Vector:
		key("element type layout")
		printTypeLayout(sp.type_layout_getElementTypeLayout(typeLayout), {})
	case .Matrix:
		// Note that the concepts of “row” and “column” as employed by Slang are the opposite of how Vulkan,
		// SPIR-V, GLSL, and OpenGL use those terms. When Slang reflects a matrix as using row-major layout,
		// the corresponding matrix in generated SPIR-V will have a ColMajor decoration.
		// For an explanation of why these conventions differ, please see the relevant appendix.
		// https://docs.shader-slang.org/en/latest/external/slang/docs/user-guide/a1-01-matrix-layout.html
		key("matrix layout mode")
		printMatrixLayoutMode(sp.type_layout_getMatrixLayoutMode(typeLayout))

		key("element type layout")
		printTypeLayout(sp.type_layout_getElementTypeLayout(typeLayout), {})
	case .ConstantBuffer, .ParameterBlock, .TextureBuffer, .ShaderStorageBuffer:
		containerVarLayout := sp.type_layout_getContainerVarLayout(typeLayout)
		elementVarLayout := sp.type_layout_getElementVarLayout(typeLayout)

		innerOffsets := accessPath
		innerOffsets.deepestConstantBufer = innerOffsets.leaf
		if sp.type_layout_getSize(sp.variable_layout_getTypeLayout(containerVarLayout), .SubElementRegisterSpace) != 0 {
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
			printTypeLayout(sp.variable_layout_getTypeLayout(elementVarLayout), elementOffsets)
		}
	case .Resource:
		resource_shape := sp.type_layout_getResourceShape(typeLayout)
		if u32(resource_shape & .BASE_SHAPE_MASK) ==
			u32(sp.SlangResourceShape(.STRUCTURED_BUFFER)) {
			key("element type layout")
			printTypeLayout(sp.type_layout_getElementTypeLayout(typeLayout), accessPath)
		} else {
			key("result type")
			printType(sp.type_layout_getResourceResultType(typeLayout))
		}	
	case: 
	}
}

printTypeLayout :: proc(typeLayout: ^sp.TypeLayoutReflection, accessPath: AccessPath) {
	SCOPED_OBJECT()

	key("name")
	printQuotedString(sp.type_layout_getName(typeLayout))
	key("kind")
	printTypeKind(sp.type_layout_getKind(typeLayout))
	printCommonTypeInfo(sp.type_layout_getType(typeLayout))

	printSizes(typeLayout)

	printKindSpecificInfo(typeLayout, accessPath)

}

printSize :: proc {
	printSize1,
	printSize2,
}

printSize1 :: proc(typeLayout: ^sp.TypeLayoutReflection, layoutUnit: sp.LayoutUnit) {
	printSize(layoutUnit, sp.type_layout_getSize(typeLayout, layoutUnit))
}

printSize2 :: proc(layoutUnit: sp.LayoutUnit, size: uint) {
	SCOPED_OBJECT()

	key("value")
	printPossiblyUnbounded(size)
	key("unit")
	printLayoutUnit(layoutUnit)
}

printSizes :: proc(typeLayout: ^sp.TypeLayoutReflection) {
	key("size")
	usedLayoutUnitCount := sp.type_layout_getCategoryCount(typeLayout)
	
	WITH_ARRAY(); for i in 0..<usedLayoutUnitCount {
		element()

		layoutUnit := sp.type_layout_getCategoryByIndex(typeLayout, i)
		printSize(typeLayout, layoutUnit)
	}
}

// ### Global Scope
//
printScope :: proc(scopeVarLayout: ^sp.VariableLayoutReflection, accessPath: AccessPath) {
	scopeOffsets: ExtendedAccessPath
	initExtendedAccessPath(&scopeOffsets, accessPath, scopeVarLayout)

	scopeTypeLayout := sp.variable_layout_getTypeLayout(scopeVarLayout)
	#partial switch sp.type_layout_getKind(scopeTypeLayout) {
	// #### Parameters are Grouped Into a Structure
	//
	case .Struct:
		key("parameters")

		paramCount := sp.type_layout_getFieldCount(scopeTypeLayout)
		for i in 0..<paramCount {
			element()
			param := sp.type_layout_getFieldByIndex(scopeTypeLayout, i)
			printVariableLayout(param, scopeOffsets)
		}
	

	// #### Wrapped in a Constant Buffer If Needed
	//
	case .ConstantBuffer:
		key("automatically-introduced constant buffer")
		{
			SCOPED_OBJECT()
			printOffsets(sp.type_layout_getContainerVarLayout(scopeTypeLayout), scopeOffsets)
		}

		printScope(sp.type_layout_getElementVarLayout(scopeTypeLayout), scopeOffsets)

	// #### Wrapped in a Parameter Block If Needed
	//
	case .ParameterBlock:
		key("automatically-introduced parameter block")
		{
			SCOPED_OBJECT()
			printOffsets(sp.type_layout_getContainerVarLayout(scopeTypeLayout), scopeOffsets)
		}

		printScope(sp.type_layout_getElementVarLayout(scopeTypeLayout), scopeOffsets)

	case:
	// Note that this default case is never expected to
	// arise with the current Slang compiler and reflection
	// API, but we include it here as a kind of failsafe.
	//
		key("variable layout")
		printVariableLayout(scopeVarLayout, accessPath)
	}

}

printProgramLayout :: proc(programLayout: ^sp.ProgramLayout, targetFormat: sp.CompileTarget) {
	{
		SCOPED_OBJECT()

		// g_metadataForEntryPoints: [dynamic]^sp.IMetadata
		g_programLayout = programLayout

		key("target")
		printTargetFormat(targetFormat)

		rootOffsets: AccessPath
		rootOffsets.valid = true

		key("global scope")
		{
			SCOPED_OBJECT()
			printScope(sp.program_layout_getGlobalParamsVarLayout(programLayout), rootOffsets)
		}

		key("entry points")
		entryPointCount := sp.program_layout_getEntryPointCount(programLayout)
		
		WITH_ARRAY(); for i in 0..<entryPointCount {
			element()
			printEntryPointLayout(sp.program_layout_getEntryPointByIndex(programLayout, i), rootOffsets)
		}
	}
	clear(&g_metadataForEntryPoints)
	shrink(&g_metadataForEntryPoints)
}

printEntryPointLayout :: proc(
	entryPointLayout: ^sp.EntryPointReflection,
	accessPath:       AccessPath,
) {
	SCOPED_OBJECT()

	key("stage")
	printStage(sp.entry_point_getStage(entryPointLayout))

	printStageSpecificInfo(entryPointLayout)

	printScope(sp.entry_point_getVarLayout(entryPointLayout), accessPath)

	resultVariableLayout := sp.entry_point_getResultVarLayout(entryPointLayout)
	cond := sp.type_layout_getKind(sp.variable_layout_getTypeLayout(resultVariableLayout)) != .None
	if cond {
		key("result")
		printVariableLayout(resultVariableLayout, accessPath)
	}
}

// #### Stage-Specific Information
//
printStageSpecificInfo :: proc(entryPointLayout: ^sp.EntryPointReflection) {
	#partial switch (sp.entry_point_getStage(entryPointLayout)) {
	case:
	case .COMPUTE:
		kAxisCount :: 3
		sizes: [kAxisCount]uint
		sp.entry_point_getComputeThreadGroupSize(entryPointLayout, kAxisCount, &sizes[0])

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
		printBool(sp.entry_point_usesAnySampleRateInput(entryPointLayout))
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
	d := module->getModuleReflection()
	WITH_ARRAY(); for idx in 0..<sp.decl_getChildrenCount(d) {
		decl := sp.decl_getChild(d, idx)
		if varDecl := sp.decl_asVariable(decl); varDecl != nil &&
		      sp.variable_findModifier(varDecl, .Const) != nil &&
		      sp.variable_findModifier(varDecl, .Static) != nil
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
		printQuotedString(sp.function_getName(entryPoint->getFunctionReflection()))

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

		g_programLayout = programLayout
		printProgramLayout(programLayout, .SPIRV)
	}

	return result
}
