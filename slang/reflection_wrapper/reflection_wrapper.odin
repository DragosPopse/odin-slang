#+private
package slang_reflection_wrapper

import sp ".."

// vtable globals
@(rodata)
g_VariableReflection_Vtable := VariableReflection_Vtable{
	getName                 = sp.variable_getName,
	getType                 = variable_getType,
	findModifier            = sp.variable_findModifier,
	getUserAttributeCount   = sp.variable_getUserAttributeCount,
	getUserAttributeByIndex = sp.variable_getUserAttributeByIndex,
	findAttributeByName     = sp.variable_findAttributeByName,
	getDefaultValueInt      = sp.variable_getDefaultValueInt,
}

@(rodata)
g_TypeReflection_Vtable := TypeReflection_Vtable{
	getName                   = sp.type_getName,
	getKind                   = sp.type_getKind,
	getScalarType             = sp.type_getScalarType,
	getResourceResultType     = type_getResourceResultType,
	getResourceShape          = sp.type_getResourceShape,
	getResourceAccess         = sp.type_getResourceAccess,
	getFieldCount             = sp.type_getFieldCount,
	getFieldByIndex           = type_getFieldByIndex,
	getElementCount           = sp.type_getElementCount,
	getElementType            = type_getElementType,
	getRowCount               = sp.type_getRowCount,
	getColumnCount            = sp.type_getColumnCount,
	isArray                   = sp.type_isArray,
	unwrapArray               = type_unwrapArray,
	getTotalArrayElementCount = sp.type_getTotalArrayElementCount,
}

@(rodata)
g_VariableLayoutReflection_Vtable := VariableLayoutReflection_Vtable{
	getVariable        = variable_layout_getVariable,
	getTypeLayout      = variable_layout_getTypeLayout,
	getName            = sp.variable_layout_getName,
	findModifier       = sp.variable_layout_findModifier,
	getCategory        = sp.variable_layout_getCategory,
	getCategoryCount   = sp.variable_layout_getCategoryCount,
	getCategoryByIndex = sp.variable_layout_getCategoryByIndex,
	getOffset          = sp.variable_layout_getOffset,
	getBindingIndex    = sp.variable_layout_getBindingIndex,
	getType            = variable_layout_getType,
	getBindingSpace    = sp.variable_layout_getBindingSpace,
	getImageFormat     = sp.variable_layout_getImageFormat,
	getSemanticName    = sp.variable_layout_getSemanticName,
	getSemanticIndex   = sp.variable_layout_getSemanticIndex,
	getStage           = sp.variable_layout_getStage,
}

@(rodata)
g_TypeLayoutReflection_Vtable := TypeLayoutReflection_Vtable{
	getType                                        = type_layout_getType,
	getKind                                        = sp.type_layout_getKind,
	getSize                                        = sp.type_layout_getSize,
	getStride                                      = sp.type_layout_getStride,
	getAlignment                                   = sp.type_layout_getAlignment,
	getFieldCount                                  = sp.type_layout_getFieldCount,
	getFieldByIndex                                = type_layout_getFieldByIndex,
	findFieldIndexByName                           = sp.type_layout_findFieldIndexByName,
	getExplicitCounter                             = type_layout_getExplicitCounter,
	isArray                                        = sp.type_layout_isArray,
	unwrapArray                                    = type_layout_unwrapArray,
	getTotalArrayElementCount                      = sp.type_layout_getTotalArrayElementCount,
	getElementCount                                = sp.type_layout_getElementCount,
	getElementStride                               = sp.type_layout_getElementStride,
	getElementTypeLayout                           = type_layout_getElementTypeLayout,
	getElementVarLayout                            = type_layout_getElementVarLayout,
	getContainerVarLayout                          = type_layout_getContainerVarLayout,
	getParameterCategory                           = sp.type_layout_getParameterCategory,
	getCategoryCount                               = sp.type_layout_getCategoryCount,
	getCategoryByIndex                             = sp.type_layout_getCategoryByIndex,
	getRowCount                                    = sp.type_layout_getRowCount,
	getColumnCount                                 = sp.type_layout_getColumnCount,
	getScalarType                                  = sp.type_layout_getScalarType,
	getResourceResultType                          = type_layout_getResourceResultType,
	getResourceShape                               = sp.type_layout_getResourceShape,
	getResourceAccess                              = sp.type_layout_getResourceAccess,
	getName                                        = sp.type_layout_getName,
	getMatrixLayoutMode                            = sp.type_layout_getMatrixLayoutMode,
	getGenericParamIndex                           = sp.type_layout_getGenericParamIndex,
	getBindingRangeCount                           = sp.type_layout_getBindingRangeCount,
	getBindingRangeType                            = sp.type_layout_getBindingRangeType,
	isBindingRangeSpecializable                    = sp.type_layout_isBindingRangeSpecializable,
	getBindingRangeBindingCount                    = sp.type_layout_getBindingRangeBindingCount,
	getFieldBindingRangeOffset                     = sp.type_layout_getFieldBindingRangeOffset,
	getExplicitCounterBindingRangeOffset           = sp.type_layout_getExplicitCounterBindingRangeOffset,
	getBindingRangeLeafTypeLayout                  = type_layout_getBindingRangeLeafTypeLayout,
	getBindingRangeLeafVariable                    = type_layout_getBindingRangeLeafVariable,
	getBindingRangeImageFormat                     = sp.type_layout_getBindingRangeImageFormat,
	getBindingRangeDescriptorSetIndex              = sp.type_layout_getBindingRangeDescriptorSetIndex,
	getBindingRangeFirstDescriptorRangeIndex       = sp.type_layout_getBindingRangeFirstDescriptorRangeIndex,
	getBindingRangeDescriptorRangeCount            = sp.type_layout_getBindingRangeDescriptorRangeCount,
	getDescriptorSetCount                          = sp.type_layout_getDescriptorSetCount,
	getDescriptorSetSpaceOffset                    = sp.type_layout_getDescriptorSetSpaceOffset,
	getDescriptorSetDescriptorRangeCount           = sp.type_layout_getDescriptorSetDescriptorRangeCount,
	getDescriptorSetDescriptorRangeIndexOffset     = sp.type_layout_getDescriptorSetDescriptorRangeIndexOffset,
	getDescriptorSetDescriptorRangeDescriptorCount = sp.type_layout_getDescriptorSetDescriptorRangeDescriptorCount,
	getDescriptorSetDescriptorRangeType            = sp.type_layout_getDescriptorSetDescriptorRangeType,
	getDescriptorSetDescriptorRangeCategory        = sp.type_layout_getDescriptorSetDescriptorRangeCategory,
	getSubObjectRangeCount                         = sp.type_layout_getSubObjectRangeCount,
	getSubObjectRangeBindingRangeIndex             = sp.type_layout_getSubObjectRangeBindingRangeIndex,
	getSubObjectRangeSpaceOffset                   = sp.type_layout_getSubObjectRangeSpaceOffset,
	getSubObjectRangeOffset                        = type_layout_getSubObjectRangeOffset,
}

@(rodata)
g_EntryPointReflection_Vtable := EntryPointReflection_Vtable{
	getName                   = sp.entry_point_getName,
	getNameOverride           = sp.entry_point_getNameOverride,
	getStage                  = sp.entry_point_getStage,
	getFunction               = entry_point_getFunction,
	getComputeThreadGroupSize = sp.entry_point_getComputeThreadGroupSize,
	getComputeWaveSize        = sp.entry_point_getComputeWaveSize,
	usesAnySampleRateInput    = sp.entry_point_usesAnySampleRateInput,
	getVarLayout              = entry_point_getVarLayout,
	getTypeLayout             = entry_point_getTypeLayout,
	getResultVarLayout        = entry_point_getResultVarLayout,
	hasDefaultConstantBuffer  = sp.entry_point_hasDefaultConstantBuffer,
}

@(rodata)
g_ProgramLayout_Vtable := ProgramLayout_Vtable{
	getGlobalParamsVarLayout       = program_layout_getGlobalParamsVarLayout,
	getTypeParameterCount          = sp.program_layout_getTypeParameterCount,
	findTypeParameter              = sp.program_layout_findTypeParameter,
	getEntryPointCount             = sp.program_layout_getEntryPointCount,
	getEntryPointByIndex           = program_layout_getEntryPointByIndex,
	getGlobalConstantBufferBinding = sp.program_layout_getGlobalConstantBufferBinding,
	getGlobalConstantBufferSize    = sp.program_layout_getGlobalConstantBufferSize,
	findTypeByName                 = program_layout_findTypeByName,
	findFunctionByName             = program_layout_findFunctionByName,
	findEntryPointByName           = program_layout_findEntryPointByName,
	toJson                         = sp.program_layout_toJson,
}

@(rodata)
g_DeclReflection_Vtable := DeclReflection_Vtable{
	getName          = sp.decl_getName,
	getKind          = sp.decl_getKind,
	getChildrenCount = sp.decl_getChildrenCount,
	getChild         = decl_getChild,
	getType          = decl_getType,
	asVariable       = decl_asVariable,
	asFunction       = decl_asFunction,
	asGeneric        = decl_asGeneric,
	getParent        = decl_getParent,
	findModifier     = sp.decl_findModifier,
}

@(rodata)
g_FunctionReflection_Vtable := FunctionReflection_Vtable{
	getName                 = sp.function_getName,
	getReturnType           = function_getReturnType,
	getParameterCount       = sp.function_getParameterCount,
	getUserAttributeCount   = sp.function_getUserAttributeCount,
	getUserAttributeByIndex = sp.function_getUserAttributeByIndex,
	findAttributeByName     = sp.function_findAttributeByName,
	findUserAttributeByName = sp.function_findUserAttributeByName,
	isOverloaded            = sp.function_isOverloaded,
	getOverloadCount        = sp.function_getOverloadCount,
	findModifier            = sp.function_findModifier,
	getGenericContainer     = function_getGenericContainer,
	applySpecializations    = function_applySpecializations,
	specializeWithArgTypes  = function_specializeWithArgTypes,
	getOverload             = function_getOverload,
}

@(rodata)
g_GenericReflection_Vtable := GenericReflection_Vtable{
	asDecl                 = generic_asDecl,
	getName                = sp.generic_getName,
	getTypeParameterCount  = sp.generic_getTypeParameterCount,
	getValueParameterCount = sp.generic_getValueParameterCount,
	getInnerDecl           = generic_getInnerDecl,
	getInnerKind           = sp.generic_getInnerKind,
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns variable

type_getFieldByIndex :: proc(this: ^sp.TypeReflection, index: u32) -> VariableReflection {
	variable: VariableReflection
	variable.vtable   = &g_VariableReflection_Vtable
	variable.variable = (^VariableReflection)(sp.ReflectionType_GetFieldByIndex(this, index)) 
	return variable
}

variable_layout_getVariable :: proc(this: ^sp.VariableLayoutReflection) -> VariableReflection {
	variable: VariableReflection
	variable.vtable   = &g_VariableReflection_Vtable
	variable.variable = sp.ReflectionVariableLayout_GetVariable(this)
	return variable
}

type_layout_getBindingRangeLeafVariable :: proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> VariableReflection {
	variable: VariableReflection
	variable.vtable   = &g_VariableReflection_Vtable
	variable.variable = sp.ReflectionTypeLayout_getBindingRangeLeafVariable(this, index)
	return variable
}

decl_asVariable :: proc(this: ^sp.DeclReflection) -> VariableReflection {
	variable: VariableReflection
	variable.vtable   = &g_VariableReflection_Vtable
	variable.variable = sp.ReflectionDecl_castToVariable(this) 
	return variable
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns type

variable_getType :: proc(this: ^sp.VariableReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.ReflectionVariable_GetType(this)
	return type
}

type_getResourceResultType :: proc(this: ^sp.TypeReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.ReflectionType_GetResourceResultType(this)
	return type
	
}

type_getElementType :: proc(this: ^sp.TypeReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable  = &g_TypeReflection_Vtable
	type.type    = sp.ReflectionType_GetElementType(this)
	return type
}

type_unwrapArray :: proc(this: ^sp.TypeReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.type_unwrapArray(this)
	return type
}

program_layout_findTypeByName :: proc(this: ^sp.ProgramLayout, name: cstring) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.Reflection_FindTypeByName(this, name)
	return type
}

variable_layout_getType :: proc(this: ^sp.VariableLayoutReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.variable_getType(variable_layout_getVariable(this))
	return type
}

function_getReturnType :: proc(this: ^sp.FunctionReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.ReflectionFunction_GetResultType(this)
	return type
}

type_layout_getType :: proc(this: ^sp.TypeLayoutReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.ReflectionTypeLayout_GetType(this)
	return type
}

type_layout_getResourceResultType :: proc(this: ^sp.TypeLayoutReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = type_getResourceResultType(type_layout_getType(this))
	return type
}

decl_getType :: proc(this: ^sp.DeclReflection) -> TypeReflection {
	type: TypeReflection
	type.vtable = &g_TypeReflection_Vtable
	type.type   = sp.Reflection_getTypeFromDecl(this)
	return type
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns type layout

variable_layout_getTypeLayout      :: proc(this: ^sp.VariableLayoutReflection) -> TypeLayoutReflection {
	type_layout: TypeLayoutReflection
	type_layout.vtable      = &g_TypeLayoutReflection_Vtable
	type_layout.type_layout = sp.ReflectionVariableLayout_GetTypeLayout(this)
	return type_layout
}

entry_point_getTypeLayout :: proc(this: ^sp.EntryPointReflection) -> TypeLayoutReflection {
	type_layout: TypeLayoutReflection
	type_layout.vtable      = &g_TypeLayoutReflection_Vtable
	type_layout.type_layout = sp.variable_layout_getTypeLayout(sp.entry_point_getVarLayout(this))
	return type_layout
}

type_layout_unwrapArray :: proc(this: ^sp.TypeLayoutReflection) -> TypeLayoutReflection {
	type_layout: TypeLayoutReflection
	type_layout.vtable      = &g_TypeLayoutReflection_Vtable
	type_layout.type_layout = sp.type_layout_unwrapArray(this)
	return type_layout

}

type_layout_getElementTypeLayout :: proc(this: ^sp.TypeLayoutReflection) -> TypeLayoutReflection {
	type_layout: TypeLayoutReflection
	type_layout.vtable      = &g_TypeLayoutReflection_Vtable
	type_layout.type_layout = sp.ReflectionTypeLayout_GetElementTypeLayout(this)
	return type_layout
}

type_layout_getBindingRangeLeafTypeLayout :: proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> TypeLayoutReflection {
	type_layout: TypeLayoutReflection
	type_layout.vtable      = &g_TypeLayoutReflection_Vtable
	type_layout.type_layout = sp.ReflectionTypeLayout_getBindingRangeLeafTypeLayout(this, index)
	return type_layout
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns variable layout

program_layout_getGlobalParamsVarLayout :: proc(this: ^sp.ProgramLayout) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.Reflection_getGlobalParamsVarLayout(this)
	return variable_layout
}

entry_point_getVarLayout :: proc(this: ^sp.EntryPointReflection) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.ReflectionEntryPoint_getVarLayout(this)
	return variable_layout
}

entry_point_getResultVarLayout :: proc(this: ^sp.EntryPointReflection) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.ReflectionEntryPoint_getResultVarLayout(this)
	return variable_layout
}

type_layout_getFieldByIndex :: proc(this: ^sp.TypeLayoutReflection, index: u32) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.ReflectionTypeLayout_GetFieldByIndex(this, index)
	return variable_layout
}

type_layout_getExplicitCounter :: proc(this: ^sp.TypeLayoutReflection) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.ReflectionTypeLayout_GetExplicitCounter(this)
	return variable_layout
}

type_layout_getElementVarLayout :: proc(this: ^sp.TypeLayoutReflection) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.ReflectionTypeLayout_GetElementVarLayout(this)
	return variable_layout
}

type_layout_getContainerVarLayout :: proc(this: ^sp.TypeLayoutReflection) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.ReflectionTypeLayout_getContainerVarLayout(this)
	return variable_layout

}

type_layout_getSubObjectRangeOffset :: proc(this: ^sp.TypeLayoutReflection, subObjectRangeIndex: sp.Int) -> VariableLayoutReflection {
	variable_layout: VariableLayoutReflection
	variable_layout.vtable          = &g_VariableLayoutReflection_Vtable
	variable_layout.variable_layout = sp.ReflectionTypeLayout_getSubObjectRangeOffset(this, subObjectRangeIndex)
	return variable_layout
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns entry point

program_layout_getEntryPointByIndex :: proc(this: ^sp.ProgramLayout, index: sp.UInt) -> EntryPointReflection {
	entry_point: EntryPointReflection
	entry_point.vtable      = &g_EntryPointReflection_Vtable
	entry_point.entry_point = sp.Reflection_getEntryPointByIndex(this, index)
	return entry_point
}

program_layout_findEntryPointByName :: proc(this: ^sp.ProgramLayout, name: cstring) -> EntryPointReflection {
	entry_point: EntryPointReflection
	entry_point.vtable      = &g_EntryPointReflection_Vtable
	entry_point.entry_point = sp.Reflection_findEntryPointByName(this, name)
	return entry_point
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns decl

generic_asDecl :: proc(this: ^sp.GenericReflection) -> DeclReflection {
	decl: DeclReflection
	decl.vtable = &g_DeclReflection_Vtable
	decl.decl   = sp.ReflectionGeneric_asDecl(this)
	return decl
}

generic_getInnerDecl :: proc(this: ^sp.GenericReflection) -> DeclReflection { 
	decl: DeclReflection
	decl.vtable = &g_DeclReflection_Vtable
	decl.decl   = sp.ReflectionGeneric_GetInnerDecl(this)
	return decl
}

decl_getChild :: proc(this: ^sp.DeclReflection, index: u32) -> DeclReflection {
	decl: DeclReflection
	decl.vtable = &g_DeclReflection_Vtable
	decl.decl   = sp.ReflectionDecl_getChild(this, index)
	return decl
}

decl_getParent :: proc(this: ^sp.DeclReflection) -> DeclReflection {
	decl: DeclReflection
	decl.vtable = &g_DeclReflection_Vtable
	decl.decl   = sp.ReflectionDecl_getParent(this)
	return decl
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns function

program_layout_findFunctionByName   :: proc(this: ^sp.ProgramLayout, name: cstring) -> FunctionReflection {
	function: FunctionReflection
	function.vtable   = &g_FunctionReflection_Vtable
	function.function = sp.Reflection_FindFunctionByName(this, name)
	return function
}

function_applySpecializations :: proc(this: ^sp.FunctionReflection, generic: ^sp.GenericReflection) -> FunctionReflection {
	function: FunctionReflection
	function.vtable   = &g_FunctionReflection_Vtable
	function.function = sp.ReflectionFunction_applySpecializations(this, generic)
	return function
 }

function_specializeWithArgTypes :: proc(this: ^sp.FunctionReflection, argCount: u32, types: ^sp.TypeReflection) -> FunctionReflection {
	function: FunctionReflection
	function.vtable   = &g_FunctionReflection_Vtable
	function.function = sp.ReflectionFunction_specializeWithArgTypes(this, int(argCount), types)
	return function
}

function_getOverload :: proc(this: ^sp.FunctionReflection, index: u32) -> FunctionReflection {
	function: FunctionReflection
	function.vtable   = &g_FunctionReflection_Vtable
	function.function = sp.ReflectionFunction_getOverload(this, index)
	return function
}

entry_point_getFunction :: proc(this: ^sp.EntryPointReflection) -> FunctionReflection {
	function: FunctionReflection
	function.vtable   = &g_FunctionReflection_Vtable
	function.function = sp.ReflectionEntryPoint_getFunction(this)
	return function
}

decl_asFunction :: proc(this: ^sp.DeclReflection) -> FunctionReflection {
	function: FunctionReflection
	function.vtable   = &g_FunctionReflection_Vtable
	function.function = sp.ReflectionDecl_castToFunction(this)
	return function
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// returns generic

function_getGenericContainer :: proc(this: ^sp.FunctionReflection) -> GenericReflection {
	generic: GenericReflection
	generic.vtable  = &g_GenericReflection_Vtable
	generic.generic = sp.ReflectionFunction_GetGenericContainer(this)
	return generic
}

decl_asGeneric :: proc(this: ^sp.DeclReflection) -> GenericReflection {
	generic: GenericReflection
	generic.vtable  = &g_GenericReflection_Vtable
	generic.generic = sp.ReflectionDecl_castToGeneric(this)
	return generic
}
