package slang

variable_getName                 :: proc(this: ^VariableReflection) -> cstring { return ReflectionVariable_GetName(this) }
variable_getType                 :: proc(this: ^VariableReflection) -> ^TypeReflection { return (^TypeReflection)(ReflectionVariable_GetType(this)) }
variable_findModifier            :: proc(this: ^VariableReflection, id: ModifierID) -> ^Modifier { return (^Modifier)(ReflectionVariable_FindModifier(this, (SlangModifierID)(id),)) }
variable_getUserAttributeCount   :: proc(this: ^VariableReflection) -> u32 { return ReflectionVariable_GetUserAttributeCount(this) }
variable_getUserAttributeByIndex :: proc(this: ^VariableReflection, index: u32) -> ^Attribute { return (^Attribute)(ReflectionVariable_GetUserAttribute(this, index,)) }
variable_findAttributeByName     :: proc(this: ^VariableReflection, globalSession: ^IGlobalSession, name: cstring,) -> ^Attribute { return (^Attribute)(ReflectionVariable_FindUserAttributeByName(this, globalSession, name,)) }
variable_getDefaultValueInt      :: proc(this: ^VariableReflection, value: ^i64) -> Result { return ReflectionVariable_GetDefaultValueInt(this, value) }

type_getName               :: proc(this: ^TypeReflection) -> cstring { return ReflectionType_GetName(this) }
type_getKind               :: proc(this: ^TypeReflection) -> TypeReflectionKind { return TypeReflectionKind(ReflectionType_GetKind(this)) }
type_getScalarType         :: proc(this: ^TypeReflection) -> TypeReflectionScalarType { return cast(TypeReflectionScalarType)ReflectionType_GetScalarType(this) }
type_getResourceResultType :: proc(this: ^TypeReflection) -> ^TypeReflection { return (^TypeReflection)(ReflectionType_GetResourceResultType(this)) }
type_getResourceShape      :: proc(this: ^TypeReflection) -> SlangResourceShape { return ReflectionType_GetResourceShape(this) }
type_getResourceAccess     :: proc(this: ^TypeReflection) -> SlangResourceAccess { return ReflectionType_GetResourceAccess(this) }
type_getFieldCount         :: proc(this: ^TypeReflection) -> u32 { return ReflectionType_GetFieldCount(this) }
type_getFieldByIndex       :: proc(this: ^TypeReflection, index: u32) -> ^VariableReflection { return (^VariableReflection)(ReflectionType_GetFieldByIndex(this, index)) }
type_getElementCount       :: proc(this: ^TypeReflection, reflection: ^ProgramLayout = nil) -> uint { return ReflectionType_GetSpecializedElementCount(this, reflection) }
type_getElementType        :: proc(this: ^TypeReflection) -> ^TypeReflection { return (^TypeReflection)(ReflectionType_GetElementType(this)) }
type_getRowCount           :: proc(this: ^TypeReflection) -> u32 { return ReflectionType_GetRowCount(this) }
type_getColumnCount        :: proc(this: ^TypeReflection) -> u32 { return ReflectionType_GetColumnCount(this) }
type_isArray               :: proc(this: ^TypeReflection) -> bool { return type_getKind(this) == .Array }
type_unwrapArray :: proc(this: ^TypeReflection) -> ^TypeReflection {
	type := this
	for type_isArray(type) {
		type = type_getElementType(type)
	}
	return type
}
type_getTotalArrayElementCount :: proc(this: ^TypeReflection) -> uint {
	if !type_isArray(this) { return 0 }
	result := uint(1)
	type := this
	for {
		if !type_isArray(type) { return result }
		c := type_getElementCount(type)
		if c == UNKNOWN_SIZE   { return UNKNOWN_SIZE   }
		if c == UNBOUNDED_SIZE { return UNBOUNDED_SIZE }
		result *= c
		type = type_getElementType(type)
	}
}
program_layout_getGlobalParamsVarLayout :: proc(this: ^ProgramLayout) -> ^VariableLayoutReflection { return (^VariableLayoutReflection)(Reflection_getGlobalParamsVarLayout(this)) }
@(deprecated="https://docs.shader-slang.org/en/latest/external/slang/docs/user-guide/09-reflection.html#id2") 
program_layout_getParameterCount        :: proc(this: ^ProgramLayout) -> u32 { return Reflection_GetParameterCount(this) }
program_layout_getTypeParameterCount    :: proc(this: ^ProgramLayout) -> u32 { return Reflection_GetTypeParameterCount(this) }
program_layout_findTypeParameter        :: proc(this: ^ProgramLayout, name: cstring) -> ^TypeParameterReflection { return Reflection_FindTypeParameter(this, name) }
program_layout_getEntryPointCount       :: proc(this: ^ProgramLayout) -> UInt { return Reflection_getEntryPointCount(this) }
program_layout_getEntryPointByIndex     :: proc(this: ^ProgramLayout, index: UInt) -> ^EntryPointReflection { return Reflection_getEntryPointByIndex(this, index) }
program_layout_getGlobalConstantBufferBinding :: proc(this: ^ProgramLayout) -> UInt { return Reflection_getGlobalConstantBufferBinding(this) }
program_layout_getGlobalConstantBufferSize    :: proc(this: ^ProgramLayout) -> uint { return Reflection_getGlobalConstantBufferSize(this) }
program_layout_findTypeByName       :: proc(this: ^ProgramLayout, name: cstring) -> ^TypeReflection { return Reflection_FindTypeByName(this, name) }
program_layout_findFunctionByName   :: proc(this: ^ProgramLayout, name: cstring) -> ^FunctionReflection { return Reflection_FindFunctionByName(this, name) }
program_layout_findEntryPointByName :: proc(this: ^ProgramLayout, name: cstring) -> ^EntryPointReflection { return Reflection_findEntryPointByName(this, name) }
program_layout_toJson               :: proc(this: ^ProgramLayout, outBlob: ^^IBlob) -> Result { return Reflection_ToJson(this, nil, outBlob) }

variable_layout_getVariable        :: proc(this: ^VariableLayoutReflection) -> ^VariableReflection { return ReflectionVariableLayout_GetVariable(this) }
variable_layout_getTypeLayout      :: proc(this: ^VariableLayoutReflection) -> ^TypeLayoutReflection { return ReflectionVariableLayout_GetTypeLayout(this) }
variable_layout_getName            :: proc(this: ^VariableLayoutReflection) -> cstring { return variable_getName(variable_layout_getVariable(this)) }
variable_layout_findModifier       :: proc(this: ^VariableLayoutReflection, id: ModifierID) -> ^Modifier { return variable_findModifier(variable_layout_getVariable(this), id) }
variable_layout_getCategory        :: proc(this: ^VariableLayoutReflection) -> ParameterCategory { return type_layout_getParameterCategory(variable_layout_getTypeLayout(this)) }
variable_layout_getCategoryCount   :: proc(this: ^VariableLayoutReflection) -> u32 { return type_layout_getCategoryCount(variable_layout_getTypeLayout(this)) }
variable_layout_getCategoryByIndex :: proc(this: ^VariableLayoutReflection, index: u32) -> LayoutUnit { return type_layout_getCategoryByIndex(variable_layout_getTypeLayout(this), index) }
variable_layout_getOffset          :: proc(this: ^VariableLayoutReflection, category: LayoutUnit) -> uint { return ReflectionVariableLayout_GetOffset(this, ParameterCategory(category)) }
variable_layout_getBindingIndex    :: proc(this: ^VariableLayoutReflection) -> u32 { return ReflectionParameter_GetBindingIndex(this) }
variable_layout_getType            :: proc(this: ^VariableLayoutReflection) -> ^TypeReflection { return variable_getType(variable_layout_getVariable(this) ) }

variable_layout_getBindingSpace :: proc(this: ^VariableLayoutReflection, category: LayoutUnit) -> uint {
	if category == .None {
		return cast(uint)variable_layout_getBindingSpace_bytes(this),
	} else {
		return variable_layout_getBindingSpace_as_unit(this, category),
	}
}

variable_layout_getBindingSpace_bytes   :: proc(this: ^VariableLayoutReflection) -> u32 { return ReflectionParameter_GetBindingSpace(this) }
variable_layout_getBindingSpace_as_unit :: proc(this: ^VariableLayoutReflection, category: LayoutUnit) -> uint { return ReflectionVariableLayout_GetSpace(this, ParameterCategory(category)) }
variable_layout_getImageFormat          :: proc(this: ^VariableLayoutReflection) -> ImageFormat { return ReflectionVariableLayout_GetImageFormat(this) }
variable_layout_getSemanticName         :: proc(this: ^VariableLayoutReflection) -> cstring { return ReflectionVariableLayout_GetSemanticName(this) }
variable_layout_getSemanticIndex        :: proc(this: ^VariableLayoutReflection) -> uint { return ReflectionVariableLayout_GetSemanticIndex(this) }
variable_layout_getStage                :: proc(this: ^VariableLayoutReflection) -> Stage { return ReflectionVariableLayout_getStage(this) }

function_getName                 :: proc(this: ^FunctionReflection) -> cstring { return ReflectionFunction_GetName(this) }
function_getReturnType           :: proc(this: ^FunctionReflection) -> ^TypeReflection { return ReflectionFunction_GetResultType(this) }
function_getParameterCount       :: proc(this: ^FunctionReflection) -> u32 { return ReflectionFunction_GetParameterCount(this) }
function_getUserAttributeCount   :: proc(this: ^FunctionReflection) -> u32 { return ReflectionFunction_GetUserAttributeCount(this) }
function_getUserAttributeByIndex :: proc(this: ^FunctionReflection, index: u32) -> ^Attribute { return ReflectionFunction_GetUserAttribute(this, index) }
function_findAttributeByName     :: proc(this: ^FunctionReflection, globalSession: ^IGlobalSession, name: cstring) -> ^Attribute { return ReflectionFunction_FindUserAttributeByName(this, globalSession, name) }
function_findUserAttributeByName :: proc(this: ^FunctionReflection, globalSession: ^IGlobalSession, name: cstring) -> ^Attribute{ return function_findAttributeByName(this, globalSession, name) }
function_isOverloaded            :: proc(this: ^FunctionReflection) -> bool { return ReflectionFunction_isOverloaded(this) }
function_getOverloadCount        :: proc(this: ^FunctionReflection) -> u32 { return ReflectionFunction_getOverloadCount(this) }
function_findModifier            :: proc(this: ^FunctionReflection, id: ModifierID) -> ^Modifier { return ReflectionFunction_FindModifier((this), cast(SlangModifierID)id) }
function_getGenericContainer     :: proc(this: ^FunctionReflection) -> ^GenericReflection { return ReflectionFunction_GetGenericContainer(this) }
function_applySpecializations    :: proc(this: ^FunctionReflection, generic: ^GenericReflection) -> ^FunctionReflection { return ReflectionFunction_applySpecializations(this, generic) }
function_specializeWithArgTypes  :: proc(this: ^FunctionReflection, argCount: u32, types: ^TypeReflection) -> ^FunctionReflection { return ReflectionFunction_specializeWithArgTypes(this, int(argCount), types) }
function_getOverload             :: proc(this: ^FunctionReflection, index: u32) -> ^FunctionReflection { return ReflectionFunction_getOverload(this, index) }

generic_asDecl                 :: proc(this: ^GenericReflection) -> ^DeclReflection { return ReflectionGeneric_asDecl(this) }
generic_getName                :: proc(this: ^GenericReflection) -> cstring { return ReflectionGeneric_GetName(this) }
generic_getTypeParameterCount  :: proc(this: ^GenericReflection) -> u32 { return ReflectionGeneric_GetTypeParameterCount(this) }
generic_getValueParameterCount :: proc(this: ^GenericReflection) -> u32 { return ReflectionGeneric_GetValueParameterCount(this) }
generic_getInnerDecl           :: proc(this: ^GenericReflection) -> ^DeclReflection { return ReflectionGeneric_GetInnerDecl(this) }
generic_getInnerKind           :: proc(this: ^GenericReflection) -> DeclKind { return ReflectionGeneric_GetInnerKind(this) }

entry_point_getName                   :: proc(this: ^EntryPointReflection) -> cstring { return ReflectionEntryPoint_getName(this) }
entry_point_getNameOverride           :: proc(this: ^EntryPointReflection) -> cstring { return ReflectionEntryPoint_getNameOverride(this) }
@(deprecated="https://docs.shader-slang.org/en/latest/external/slang/docs/user-guide/09-reflection.html#id3") 
entry_point_getParameterCount         :: proc(this: ^EntryPointReflection) -> u32 { return ReflectionEntryPoint_getParameterCount(this) }
entry_point_getStage                  :: proc(this: ^EntryPointReflection) -> Stage { return ReflectionEntryPoint_getStage(this) }
entry_point_getFunction               :: proc(this: ^EntryPointReflection) -> ^FunctionReflection { return ReflectionEntryPoint_getFunction(this) }
@(deprecated="https://docs.shader-slang.org/en/latest/external/slang/docs/user-guide/09-reflection.html#id3") 
entry_point_getParameterByIndex       :: proc(this: ^EntryPointReflection, index: u32) -> ^VariableLayoutReflection { return ReflectionEntryPoint_getParameterByIndex(this, index) }
entry_point_getComputeThreadGroupSize :: proc(this: ^EntryPointReflection, axisCount: UInt, outSizeAlongAxis: ^UInt) { ReflectionEntryPoint_getComputeThreadGroupSize(this, axisCount, outSizeAlongAxis) }
entry_point_getComputeWaveSize        :: proc(this: ^EntryPointReflection, outWaveSize: ^UInt) { ReflectionEntryPoint_getComputeWaveSize(this, outWaveSize) }
entry_point_usesAnySampleRateInput    :: proc(this: ^EntryPointReflection) -> bool { return 0 != ReflectionEntryPoint_usesAnySampleRateInput(this) }
entry_point_getVarLayout              :: proc(this: ^EntryPointReflection) -> ^VariableLayoutReflection { return ReflectionEntryPoint_getVarLayout(this) }
entry_point_getTypeLayout             :: proc(this: ^EntryPointReflection) -> ^TypeLayoutReflection { return variable_layout_getTypeLayout(entry_point_getVarLayout(this)) }
entry_point_getResultVarLayout        :: proc(this: ^EntryPointReflection) -> ^VariableLayoutReflection { return ReflectionEntryPoint_getResultVarLayout(this) }
entry_point_hasDefaultConstantBuffer  :: proc(this: ^EntryPointReflection) -> bool { return ReflectionEntryPoint_hasDefaultConstantBuffer(this) != 0 }

type_layout_getType              :: proc(this: ^TypeLayoutReflection) -> ^TypeReflection { return ReflectionTypeLayout_GetType(this) }
type_layout_getKind              :: proc(this: ^TypeLayoutReflection) -> TypeReflectionKind { return cast(TypeReflectionKind)ReflectionTypeLayout_getKind(this) }
type_layout_getSize              :: proc(this: ^TypeLayoutReflection, category: LayoutUnit = .None) -> uint { return ReflectionTypeLayout_GetSize(this, ParameterCategory(category)) }
type_layout_getStride            :: proc(this: ^TypeLayoutReflection, category: LayoutUnit = .None) -> uint { return ReflectionTypeLayout_GetStride(this, ParameterCategory(category)) }
type_layout_getAlignment         :: proc(this: ^TypeLayoutReflection, category: LayoutUnit = .None) -> i32 { return ReflectionTypeLayout_getAlignment(this, ParameterCategory(category)) }
type_layout_getFieldCount        :: proc(this: ^TypeLayoutReflection) -> u32 { return ReflectionTypeLayout_GetFieldCount(this) }
type_layout_getFieldByIndex      :: proc(this: ^TypeLayoutReflection, index: u32) -> ^VariableLayoutReflection { return ReflectionTypeLayout_GetFieldByIndex(this, index) }
type_layout_findFieldIndexByName :: proc(this: ^TypeLayoutReflection, nameBegin: cstring, nameEnd: cstring) -> Int { return ReflectionTypeLayout_findFieldIndexByName(this, nameBegin, nameEnd) }
type_layout_getExplicitCounter   :: proc(this: ^TypeLayoutReflection) -> ^VariableLayoutReflection { return ReflectionTypeLayout_GetExplicitCounter(this) }
type_layout_isArray              :: proc(this: ^TypeLayoutReflection) -> bool { return type_isArray(type_layout_getType(this)) }
type_layout_unwrapArray :: proc(this: ^TypeLayoutReflection) -> ^TypeLayoutReflection {
	type_layout := this
	for type_layout_isArray(type_layout) {
		type_layout = type_layout_getElementTypeLayout(type_layout)
	}
	return type_layout
}
type_layout_getTotalArrayElementCount   :: proc(this: ^TypeLayoutReflection) -> uint { return type_getTotalArrayElementCount(type_layout_getType(this)) }
type_layout_getElementCount             :: proc(this: ^TypeLayoutReflection, reflection: ^ProgramLayout = nil) -> uint { return type_getElementCount(type_layout_getType(this), reflection) }
type_layout_getElementStride            :: proc(this: ^TypeLayoutReflection, category: ParameterCategory) -> uint { return ReflectionTypeLayout_GetElementStride(this, category) }
type_layout_getElementTypeLayout        :: proc(this: ^TypeLayoutReflection) -> ^TypeLayoutReflection { return ReflectionTypeLayout_GetElementTypeLayout(this) }
type_layout_getElementVarLayout         :: proc(this: ^TypeLayoutReflection) -> ^VariableLayoutReflection { return ReflectionTypeLayout_GetElementVarLayout(this) }
type_layout_getContainerVarLayout       :: proc(this: ^TypeLayoutReflection) -> ^VariableLayoutReflection { return ReflectionTypeLayout_getContainerVarLayout(this) }
type_layout_getParameterCategory        :: proc(this: ^TypeLayoutReflection) -> ParameterCategory { return ReflectionTypeLayout_GetParameterCategory(this) }
type_layout_getCategoryCount            :: proc(this: ^TypeLayoutReflection) -> u32 { return ReflectionTypeLayout_GetCategoryCount(this) }
type_layout_getCategoryByIndex          :: proc(this: ^TypeLayoutReflection, index: u32) -> LayoutUnit { return ReflectionTypeLayout_GetCategoryByIndex(this, index) }
type_layout_getRowCount                 :: proc(this: ^TypeLayoutReflection) -> u32 { return type_getRowCount(type_layout_getType(this)) }
type_layout_getColumnCount              :: proc(this: ^TypeLayoutReflection) -> u32 { return type_getColumnCount(type_layout_getType(this)) }
type_layout_getScalarType               :: proc(this: ^TypeLayoutReflection) -> TypeReflectionScalarType { return type_getScalarType(type_layout_getType(this)) }
type_layout_getResourceResultType       :: proc(this: ^TypeLayoutReflection) -> ^TypeReflection { return type_getResourceResultType(type_layout_getType(this)) }
type_layout_getResourceShape            :: proc(this: ^TypeLayoutReflection) -> SlangResourceShape { return type_getResourceShape(type_layout_getType(this)) }
type_layout_getResourceAccess           :: proc(this: ^TypeLayoutReflection) -> SlangResourceAccess { return type_getResourceAccess(type_layout_getType(this)) }
type_layout_getName                     :: proc(this: ^TypeLayoutReflection) -> cstring { return type_getName(type_layout_getType(this)) }
type_layout_getMatrixLayoutMode         :: proc(this: ^TypeLayoutReflection) -> MatrixLayoutMode { return ReflectionTypeLayout_GetMatrixLayoutMode(this) }
type_layout_getGenericParamIndex        :: proc(this: ^TypeLayoutReflection) -> i32 { return ReflectionTypeLayout_getGenericParamIndex(this) }
type_layout_getBindingRangeCount        :: proc(this: ^TypeLayoutReflection) -> Int { return ReflectionTypeLayout_getBindingRangeCount(this) }
type_layout_getBindingRangeType         :: proc(this: ^TypeLayoutReflection, index: Int) -> BindingType { return ReflectionTypeLayout_getBindingRangeType(this, index) }
type_layout_isBindingRangeSpecializable :: proc(this: ^TypeLayoutReflection, index: Int) -> bool { return cast(bool)ReflectionTypeLayout_isBindingRangeSpecializable(this, index) }
type_layout_getBindingRangeBindingCount                    :: proc(this: ^TypeLayoutReflection, index: Int) -> Int { return ReflectionTypeLayout_getBindingRangeBindingCount(this, index) }
// @(deprecated="commented out in slang now")
// type_layout_getBindingRangeIndexOffset                     :: proc(this: ^TypeLayoutReflection, index: Int) -> Int { return ReflectionTypeLayout_getBindingRangeIndexOffset(this, index) }
// type_layout_getBindingRangeSpaceOffset                     :: proc(this: ^TypeLayoutReflection, index: Int) -> Int { return ReflectionTypeLayout_getBindingRangeSpaceOffset(this, index) }
type_layout_getFieldBindingRangeOffset                     :: proc(this: ^TypeLayoutReflection, fieldIndex: Int) -> Int { return ReflectionTypeLayout_getFieldBindingRangeOffset(this, fieldIndex) }
type_layout_getExplicitCounterBindingRangeOffset           :: proc(this: ^TypeLayoutReflection) -> Int { return ReflectionTypeLayout_getExplicitCounterBindingRangeOffset(this) }
type_layout_getBindingRangeLeafTypeLayout                  :: proc(this: ^TypeLayoutReflection, index: Int) -> ^TypeLayoutReflection { return ReflectionTypeLayout_getBindingRangeLeafTypeLayout(this, index) }
type_layout_getBindingRangeLeafVariable                    :: proc(this: ^TypeLayoutReflection, index: Int) -> ^VariableReflection { return ReflectionTypeLayout_getBindingRangeLeafVariable(this, index) }
type_layout_getBindingRangeImageFormat                     :: proc(this: ^TypeLayoutReflection, index: Int) -> ImageFormat { return ReflectionTypeLayout_getBindingRangeImageFormat(this, index) }
type_layout_getBindingRangeDescriptorSetIndex              :: proc(this: ^TypeLayoutReflection, index: Int) -> Int { return ReflectionTypeLayout_getBindingRangeDescriptorSetIndex(this, index) }
type_layout_getBindingRangeFirstDescriptorRangeIndex       :: proc(this: ^TypeLayoutReflection, index: Int) -> Int { return ReflectionTypeLayout_getBindingRangeFirstDescriptorRangeIndex(this, index) }
type_layout_getBindingRangeDescriptorRangeCount            :: proc(this: ^TypeLayoutReflection, index: Int) -> Int { return ReflectionTypeLayout_getBindingRangeDescriptorRangeCount(this, index) }
type_layout_getDescriptorSetCount                          :: proc(this: ^TypeLayoutReflection) -> Int { return ReflectionTypeLayout_getDescriptorSetCount(this) }
type_layout_getDescriptorSetSpaceOffset                    :: proc(this: ^TypeLayoutReflection, setIndex: Int) -> Int { return ReflectionTypeLayout_getDescriptorSetSpaceOffset(this, setIndex) }
type_layout_getDescriptorSetDescriptorRangeCount           :: proc(this: ^TypeLayoutReflection, setIndex: Int) -> Int { return ReflectionTypeLayout_getDescriptorSetDescriptorRangeCount(this, setIndex) }
type_layout_getDescriptorSetDescriptorRangeIndexOffset     :: proc(this: ^TypeLayoutReflection, setIndex: Int, rangeIndex: Int) -> Int { return ReflectionTypeLayout_getDescriptorSetDescriptorRangeIndexOffset(this, setIndex, rangeIndex) }
type_layout_getDescriptorSetDescriptorRangeDescriptorCount :: proc(this: ^TypeLayoutReflection, setIndex: Int, rangeIndex: Int) -> Int { return ReflectionTypeLayout_getDescriptorSetDescriptorRangeDescriptorCount(this, setIndex, rangeIndex) }
type_layout_getDescriptorSetDescriptorRangeType            :: proc(this: ^TypeLayoutReflection, setIndex: Int, rangeIndex: Int) -> BindingType { return ReflectionTypeLayout_getDescriptorSetDescriptorRangeType(this, setIndex, rangeIndex) }
type_layout_getDescriptorSetDescriptorRangeCategory        :: proc(this: ^TypeLayoutReflection, setIndex: Int, rangeIndex: Int) -> ParameterCategory { return ReflectionTypeLayout_getDescriptorSetDescriptorRangeCategory(this, setIndex, rangeIndex) }
type_layout_getSubObjectRangeCount                         :: proc(this: ^TypeLayoutReflection) -> Int { return ReflectionTypeLayout_getSubObjectRangeCount(this) }
type_layout_getSubObjectRangeBindingRangeIndex             :: proc(this: ^TypeLayoutReflection, subObjectRangeIndex: Int) -> Int { return ReflectionTypeLayout_getSubObjectRangeBindingRangeIndex(this, subObjectRangeIndex) }
type_layout_getSubObjectRangeSpaceOffset                   :: proc(this: ^TypeLayoutReflection, subObjectRangeIndex: Int) -> Int { return ReflectionTypeLayout_getSubObjectRangeSpaceOffset(this, subObjectRangeIndex) }
type_layout_getSubObjectRangeOffset                        :: proc(this: ^TypeLayoutReflection, subObjectRangeIndex: Int) -> ^VariableLayoutReflection { return ReflectionTypeLayout_getSubObjectRangeOffset(this, subObjectRangeIndex) }

decl_getName          :: proc(this: ^DeclReflection) -> cstring { return ReflectionDecl_getName(this) }
decl_getKind          :: proc(this: ^DeclReflection) -> DeclKind { return ReflectionDecl_getKind(this) }
decl_getChildrenCount :: proc(this: ^DeclReflection) -> u32 { return ReflectionDecl_getChildrenCount(this) }
decl_getChild         :: proc(this: ^DeclReflection, index: u32) -> ^DeclReflection { return ReflectionDecl_getChild(this, index) }
decl_getType          :: proc(this: ^DeclReflection) -> ^TypeReflection { return Reflection_getTypeFromDecl(this) }
decl_asVariable       :: proc(this: ^DeclReflection) -> ^VariableReflection { return ReflectionDecl_castToVariable(this) }
decl_asFunction       :: proc(this: ^DeclReflection) -> ^FunctionReflection { return ReflectionDecl_castToFunction(this) }
decl_asGeneric        :: proc(this: ^DeclReflection) -> ^GenericReflection { return ReflectionDecl_castToGeneric(this) }
decl_getParent        :: proc(this: ^DeclReflection) -> ^DeclReflection { return ReflectionDecl_getParent(this) }
decl_findModifier     :: proc(this: ^DeclReflection, id: ModifierID) -> ^Modifier { return ReflectionDecl_findModifier(this, cast(SlangModifierID)id) }
// decl_getChildren // not really applicable to odin, maybe a custom iterator?