package slang_reflection_wrapper

import sp ".."

// The purpose of this package is an attempt at forward compatibility
// with the slang COM api. 
// It wraps the new helper methods (which have replaced the C api
// but haven't made it into the COM api yet) into vtables.
// With that, the usage is identical to the COM parts of the api and
// when the C api reflection procs get removed it should be possible to
// switch to their new counterparts with minimal changes to user code.

// Usage:
/*
	There is a couple of awkward "boundaries" where the existing COM api and reflection overlap
	namely the following 3 functions in slang.odin:
	
	getLayout:             proc "system"(this: ^IComponentType, targetIndex: Int, outDiagnostics: ^^IBlob) -> ^ProgramLayout,
	getModuleReflection:   proc "system"(this: ^IModule) -> ^DeclReflection,
	getFunctionReflection: proc "system"(this: ^IEntryPoint) -> ^FunctionReflection,
	
	we need to wrap these in the init proc, for example:
	Example:
		import refl "slang/reflection_wrapper"

		program_layout := program->getLayout(target_index, &diags)

		refl_program_layout := refl.init_program_layout(program_layout)
		
		// now everything we get through this wrapped program layout will have the correct methods
		refl_program_layout->getGlobalParamsVarLayout()
		entry_point_count := refl_program_layout->getEntryPointCount()
			
		for i in 0..<entry_point_count {
			entry_point := refl_program_layout->getEntryPointByIndex(i)

			scope_layout := entry_point->getVarLayout()

			result_variable_layout := entry_point->getResultVarLayout()

			result_type_layout := result_variable_layout->getTypeLayout()
	
	and so on..

*/

// Wrapper entry points
init_program_layout :: proc(this: ^sp.ProgramLayout) -> ProgramLayout {
	program_layout: ProgramLayout
	program_layout.vtable         = &g_ProgramLayout_Vtable
	program_layout.program_layout = this
	return program_layout
}

init_decl :: proc(this: ^sp.DeclReflection) -> DeclReflection {
	decl: DeclReflection
	decl.vtable = &g_DeclReflection_Vtable
	decl.decl   = this
	return decl
}

init_function :: proc(this: ^sp.FunctionReflection) -> FunctionReflection {
	function: FunctionReflection
	function.vtable   = &g_FunctionReflection_Vtable
	function.function = this
	return function
}

// Wrapper types store the original pointer and add the vtable of helper methods
VariableReflection :: struct {
	using vtable:   ^VariableReflection_Vtable,
	using variable: ^sp.VariableReflection,
}

TypeReflection :: struct {
	using vtable: ^TypeReflection_Vtable,
	using type:   ^sp.TypeReflection,
}

VariableLayoutReflection :: struct {
	using vtable:          ^VariableLayoutReflection_Vtable,
	using variable_layout: ^sp.VariableLayoutReflection,
}

TypeLayoutReflection :: struct {
	using vtable:      ^TypeLayoutReflection_Vtable,
	using type_layout: ^sp.TypeLayoutReflection,
}

EntryPointReflection :: struct {
	using vtable:      ^EntryPointReflection_Vtable,
	using entry_point: ^sp.EntryPointReflection,
}

ProgramLayout :: struct {
	using vtable:         ^ProgramLayout_Vtable,
	using program_layout: ^sp.ProgramLayout,
}

DeclReflection :: struct {
	using vtable: ^DeclReflection_Vtable,
	using decl:   ^sp.DeclReflection,
}

FunctionReflection :: struct {
	using vtable:   ^FunctionReflection_Vtable,
	using function: ^sp.FunctionReflection
}

GenericReflection :: struct {
	using vtable:  ^GenericReflection_Vtable,
	using generic: ^sp.GenericReflection
}

VariableReflection_Vtable :: struct {
	getName                 : proc(this: ^sp.VariableReflection) -> cstring,
	getType                 : proc(this: ^sp.VariableReflection) -> TypeReflection,
	findModifier            : proc(this: ^sp.VariableReflection, id: sp.ModifierID) -> ^sp.Modifier,
	getUserAttributeCount   : proc(this: ^sp.VariableReflection) -> u32,
	getUserAttributeByIndex : proc(this: ^sp.VariableReflection, index: u32) -> ^sp.Attribute,
	findAttributeByName     : proc(this: ^sp.VariableReflection, globalSession: ^sp.IGlobalSession, name: cstring,) -> ^sp.Attribute,
	getDefaultValueInt      : proc(this: ^sp.VariableReflection, value: ^i64) -> sp.Result,

}

TypeReflection_Vtable :: struct {
	getName               : proc(this: ^sp.TypeReflection) -> cstring,
	getKind               : proc(this: ^sp.TypeReflection) -> sp.TypeReflectionKind,
	getScalarType         : proc(this: ^sp.TypeReflection) -> sp.TypeReflectionScalarType,
	getResourceResultType : proc(this: ^sp.TypeReflection) -> TypeReflection,
	getResourceShape      : proc(this: ^sp.TypeReflection) -> sp.SlangResourceShape,
	getResourceAccess     : proc(this: ^sp.TypeReflection) -> sp.SlangResourceAccess,
	getFieldCount         : proc(this: ^sp.TypeReflection) -> u32,
	getFieldByIndex       : proc(this: ^sp.TypeReflection, index: u32) -> VariableReflection,
	getElementCount       : proc(this: ^sp.TypeReflection, reflection: ^sp.ProgramLayout = nil) -> uint,
	getElementType        : proc(this: ^sp.TypeReflection) -> TypeReflection,
	getRowCount           : proc(this: ^sp.TypeReflection) -> u32,
	getColumnCount        : proc(this: ^sp.TypeReflection) -> u32,
	isArray               : proc(this: ^sp.TypeReflection) -> bool,
	unwrapArray               : proc(this: ^sp.TypeReflection) -> TypeReflection,
	getTotalArrayElementCount : proc(this: ^sp.TypeReflection) -> uint,
}


TypeLayoutReflection_Vtable :: struct {
	getType              : proc(this: ^sp.TypeLayoutReflection) -> TypeReflection,
	getKind              : proc(this: ^sp.TypeLayoutReflection) -> sp.TypeReflectionKind,
	getSize              : proc(this: ^sp.TypeLayoutReflection, category: sp.LayoutUnit) -> uint,
	getStride            : proc(this: ^sp.TypeLayoutReflection, category: sp.LayoutUnit) -> uint,
	getAlignment         : proc(this: ^sp.TypeLayoutReflection, category: sp.LayoutUnit) -> i32,
	getFieldCount        : proc(this: ^sp.TypeLayoutReflection) -> u32,
	getFieldByIndex      : proc(this: ^sp.TypeLayoutReflection, index: u32) -> VariableLayoutReflection,
	findFieldIndexByName : proc(this: ^sp.TypeLayoutReflection, nameBegin: cstring, nameEnd: cstring) -> sp.Int,
	getExplicitCounter   : proc(this: ^sp.TypeLayoutReflection) -> VariableLayoutReflection,
	isArray              : proc(this: ^sp.TypeLayoutReflection) -> bool,
	unwrapArray          : proc(this: ^sp.TypeLayoutReflection) -> TypeLayoutReflection,
	getTotalArrayElementCount   : proc(this: ^sp.TypeLayoutReflection) -> uint,
	getElementCount             : proc(this: ^sp.TypeLayoutReflection, reflection: ^sp.ProgramLayout) -> uint,
	getElementStride            : proc(this: ^sp.TypeLayoutReflection, category: sp.ParameterCategory) -> uint,
	getElementTypeLayout        : proc(this: ^sp.TypeLayoutReflection) -> TypeLayoutReflection,
	getElementVarLayout         : proc(this: ^sp.TypeLayoutReflection) -> VariableLayoutReflection,
	getContainerVarLayout       : proc(this: ^sp.TypeLayoutReflection) -> VariableLayoutReflection,
	getParameterCategory        : proc(this: ^sp.TypeLayoutReflection) -> sp.LayoutUnit,
	getCategoryCount            : proc(this: ^sp.TypeLayoutReflection) -> u32,
	getCategoryByIndex          : proc(this: ^sp.TypeLayoutReflection, index: u32) -> sp.LayoutUnit,
	getRowCount                 : proc(this: ^sp.TypeLayoutReflection) -> u32,
	getColumnCount              : proc(this: ^sp.TypeLayoutReflection) -> u32,
	getScalarType               : proc(this: ^sp.TypeLayoutReflection) -> sp.TypeReflectionScalarType,
	getResourceResultType       : proc(this: ^sp.TypeLayoutReflection) -> TypeReflection,
	getResourceShape            : proc(this: ^sp.TypeLayoutReflection) -> sp.SlangResourceShape,
	getResourceAccess           : proc(this: ^sp.TypeLayoutReflection) -> sp.SlangResourceAccess,
	getName                     : proc(this: ^sp.TypeLayoutReflection) -> cstring,
	getMatrixLayoutMode         : proc(this: ^sp.TypeLayoutReflection) -> sp.MatrixLayoutMode,
	getGenericParamIndex        : proc(this: ^sp.TypeLayoutReflection) -> i32,
	getBindingRangeCount        : proc(this: ^sp.TypeLayoutReflection) -> sp.Int,
	getBindingRangeType         : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> sp.BindingType,
	isBindingRangeSpecializable : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> bool,
	getBindingRangeBindingCount                    : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> sp.Int,
	getFieldBindingRangeOffset                     : proc(this: ^sp.TypeLayoutReflection, fieldIndex: sp.Int) -> sp.Int,
	getExplicitCounterBindingRangeOffset           : proc(this: ^sp.TypeLayoutReflection) -> sp.Int,
	getBindingRangeLeafTypeLayout                  : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> TypeLayoutReflection,
	getBindingRangeLeafVariable                    : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> VariableReflection,
	getBindingRangeImageFormat                     : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> sp.ImageFormat,
	getBindingRangeDescriptorSetIndex              : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> sp.Int,
	getBindingRangeFirstDescriptorRangeIndex       : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> sp.Int,
	getBindingRangeDescriptorRangeCount            : proc(this: ^sp.TypeLayoutReflection, index: sp.Int) -> sp.Int,
	getDescriptorSetCount                          : proc(this: ^sp.TypeLayoutReflection) -> sp.Int,
	getDescriptorSetSpaceOffset                    : proc(this: ^sp.TypeLayoutReflection, setIndex: sp.Int) -> sp.Int,
	getDescriptorSetDescriptorRangeCount           : proc(this: ^sp.TypeLayoutReflection, setIndex: sp.Int) -> sp.Int,
	getDescriptorSetDescriptorRangeIndexOffset     : proc(this: ^sp.TypeLayoutReflection, setIndex: sp.Int, rangeIndex: sp.Int) -> sp.Int,
	getDescriptorSetDescriptorRangeDescriptorCount : proc(this: ^sp.TypeLayoutReflection, setIndex: sp.Int, rangeIndex: sp.Int) -> sp.Int,
	getDescriptorSetDescriptorRangeType            : proc(this: ^sp.TypeLayoutReflection, setIndex: sp.Int, rangeIndex: sp.Int) -> sp.BindingType,
	getDescriptorSetDescriptorRangeCategory        : proc(this: ^sp.TypeLayoutReflection, setIndex: sp.Int, rangeIndex: sp.Int) -> sp.ParameterCategory,
	getSubObjectRangeCount                         : proc(this: ^sp.TypeLayoutReflection) -> sp.Int,
	getSubObjectRangeBindingRangeIndex             : proc(this: ^sp.TypeLayoutReflection, subObjectRangeIndex: sp.Int) -> sp.Int,
	getSubObjectRangeSpaceOffset                   : proc(this: ^sp.TypeLayoutReflection, subObjectRangeIndex: sp.Int) -> sp.Int,
	getSubObjectRangeOffset                        : proc(this: ^sp.TypeLayoutReflection, subObjectRangeIndex: sp.Int) -> VariableLayoutReflection,
}


VariableLayoutReflection_Vtable :: struct {
	getVariable             : proc(this: ^sp.VariableLayoutReflection) -> VariableReflection,
	getTypeLayout           : proc(this: ^sp.VariableLayoutReflection) -> TypeLayoutReflection,
	getName                 : proc(this: ^sp.VariableLayoutReflection) -> cstring,
	findModifier            : proc(this: ^sp.VariableLayoutReflection, id: sp.ModifierID) -> ^sp.Modifier,
	getCategory             : proc(this: ^sp.VariableLayoutReflection) -> sp.LayoutUnit,
	getCategoryCount        : proc(this: ^sp.VariableLayoutReflection) -> u32,
	getCategoryByIndex      : proc(this: ^sp.VariableLayoutReflection, index: u32) -> sp.LayoutUnit,
	getOffset               : proc(this: ^sp.VariableLayoutReflection, category: sp.LayoutUnit) -> uint,
	getBindingIndex         : proc(this: ^sp.VariableLayoutReflection) -> u32,
	getType                 : proc(this: ^sp.VariableLayoutReflection) -> TypeReflection,
	getBindingSpace         : proc(this: ^sp.VariableLayoutReflection, category: sp.LayoutUnit) -> uint,
	getImageFormat          : proc(this: ^sp.VariableLayoutReflection) -> sp.ImageFormat,
	getSemanticName         : proc(this: ^sp.VariableLayoutReflection) -> cstring,
	getSemanticIndex        : proc(this: ^sp.VariableLayoutReflection) -> uint,
	getStage                : proc(this: ^sp.VariableLayoutReflection) -> sp.Stage,
}


EntryPointReflection_Vtable :: struct {
	getName                   : proc(this: ^sp.EntryPointReflection) -> cstring,
	getNameOverride           : proc(this: ^sp.EntryPointReflection) -> cstring,
	getStage                  : proc(this: ^sp.EntryPointReflection) -> sp.Stage,
	getFunction               : proc(this: ^sp.EntryPointReflection) -> FunctionReflection,
	getComputeThreadGroupSize : proc(this: ^sp.EntryPointReflection, axisCount: sp.UInt, outSizeAlongAxis: ^sp.UInt),
	getComputeWaveSize        : proc(this: ^sp.EntryPointReflection, outWaveSize: ^sp.UInt),
	usesAnySampleRateInput    : proc(this: ^sp.EntryPointReflection) -> bool,
	getVarLayout              : proc(this: ^sp.EntryPointReflection) -> VariableLayoutReflection,
	getTypeLayout             : proc(this: ^sp.EntryPointReflection) -> TypeLayoutReflection,
	getResultVarLayout        : proc(this: ^sp.EntryPointReflection) -> VariableLayoutReflection,
	hasDefaultConstantBuffer  : proc(this: ^sp.EntryPointReflection) -> bool,
}


ProgramLayout_Vtable :: struct {
	getGlobalParamsVarLayout       : proc(this: ^sp.ProgramLayout) -> VariableLayoutReflection,
	getTypeParameterCount          : proc(this: ^sp.ProgramLayout) -> u32,
	findTypeParameter              : proc(this: ^sp.ProgramLayout, name: cstring) -> ^sp.TypeParameterReflection,
	getEntryPointCount             : proc(this: ^sp.ProgramLayout) -> sp.UInt,
	getEntryPointByIndex           : proc(this: ^sp.ProgramLayout, index: sp.UInt) -> EntryPointReflection,
	getGlobalConstantBufferBinding : proc(this: ^sp.ProgramLayout) -> sp.UInt,
	getGlobalConstantBufferSize    : proc(this: ^sp.ProgramLayout) -> uint,
	findTypeByName                 : proc(this: ^sp.ProgramLayout, name: cstring) -> TypeReflection,
	findFunctionByName             : proc(this: ^sp.ProgramLayout, name: cstring) -> FunctionReflection,
	findEntryPointByName           : proc(this: ^sp.ProgramLayout, name: cstring) -> EntryPointReflection,
	toJson                         : proc(this: ^sp.ProgramLayout, outBlob: ^^sp.IBlob) -> sp.Result,
}


DeclReflection_Vtable :: struct {
	getName          : proc(this: ^sp.DeclReflection) -> cstring,
	getKind          : proc(this: ^sp.DeclReflection) -> sp.DeclKind,
	getChildrenCount : proc(this: ^sp.DeclReflection) -> u32,
	getChild         : proc(this: ^sp.DeclReflection, index: u32) -> DeclReflection,
	getType          : proc(this: ^sp.DeclReflection) -> TypeReflection,
	asVariable       : proc(this: ^sp.DeclReflection) -> VariableReflection,
	asFunction       : proc(this: ^sp.DeclReflection) -> FunctionReflection,
	asGeneric        : proc(this: ^sp.DeclReflection) -> GenericReflection,
	getParent        : proc(this: ^sp.DeclReflection) -> DeclReflection,
	findModifier     : proc(this: ^sp.DeclReflection, id: sp.ModifierID) -> ^sp.Modifier,
}


FunctionReflection_Vtable :: struct {
	getName                 : proc(this: ^sp.FunctionReflection) -> cstring,
	getReturnType           : proc(this: ^sp.FunctionReflection) -> TypeReflection,
	getParameterCount       : proc(this: ^sp.FunctionReflection) -> u32,
	getUserAttributeCount   : proc(this: ^sp.FunctionReflection) -> u32,
	getUserAttributeByIndex : proc(this: ^sp.FunctionReflection, index: u32) -> ^sp.Attribute,
	findAttributeByName     : proc(this: ^sp.FunctionReflection, globalSession: ^sp.IGlobalSession, name: cstring) -> ^sp.Attribute,
	findUserAttributeByName : proc(this: ^sp.FunctionReflection, globalSession: ^sp.IGlobalSession, name: cstring) -> ^sp.Attribute,
	isOverloaded            : proc(this: ^sp.FunctionReflection) -> bool,
	getOverloadCount        : proc(this: ^sp.FunctionReflection) -> u32,
	findModifier            : proc(this: ^sp.FunctionReflection, id: sp.ModifierID) -> ^sp.Modifier,
	getGenericContainer     : proc(this: ^sp.FunctionReflection) -> GenericReflection,
	applySpecializations    : proc(this: ^sp.FunctionReflection, generic: ^sp.GenericReflection) -> FunctionReflection,
	specializeWithArgTypes  : proc(this: ^sp.FunctionReflection, argCount: u32, types: ^sp.TypeReflection) -> FunctionReflection,
	getOverload             : proc(this: ^sp.FunctionReflection, index: u32) -> FunctionReflection,
}

GenericReflection_Vtable :: struct {
	asDecl                 : proc(this: ^sp.GenericReflection) -> DeclReflection,
	getName                : proc(this: ^sp.GenericReflection) -> cstring,
	getTypeParameterCount  : proc(this: ^sp.GenericReflection) -> u32,
	getValueParameterCount : proc(this: ^sp.GenericReflection) -> u32,
	getInnerDecl           : proc(this: ^sp.GenericReflection) -> DeclReflection,
	getInnerKind           : proc(this: ^sp.GenericReflection) -> sp.DeclKind,
}