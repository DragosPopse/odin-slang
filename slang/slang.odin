package slang

import "core:c"

foreign import libslang "lib/slang.lib"
foreign import libslangrt "lib/slang-rt.lib"

// Note(Dragos): This is defined to be "pointer size". So ummmm check later
Int :: int
UInt :: uint
Bool :: bool
Result :: i32

API_VERSION :: 0

IUnknown_UUID := UUID{0x00000000, 0x0000, 0x0000, {0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46}}


PassThrough :: enum i32 {
	None,
	FXC,
	DXC,
	GLSLANG,
	SPIRV_DIS,
	CLANG,
	VISUAL_STUDIO,
	GCC,
	GENERIC_C_CPP,
	NVRTC,
	LLVM,
	SPIRV_OPT,
	METAL,
	TINT,
}


CompileTarget :: enum i32 {
	UNKNOWN,
	None,
	GLSL,
	GLSL_VULKAN_DEPRECATED,
	GLSL_VULKAN_ONE_DESC_DEPRECATED,
	HLSL,
	SPIRV,
	SPIRV_ASM,
	DXBC,
	DXBC_ASM,
	DXIL,
	DXIL_ASM,
	C_SOURCE,
	CPP_SOURCE,
	HOST_EXECUTABLE,
	SHADER_SHARED_LIBRARY,
	SHADER_HOST_CALLABLE,
	CUDA_SOURCE,
	PTX,
	CUDA_OBJECT_CODE,
	OBJECT_CODE,
	HOST_CPP_SOURCE,
	HOST_HOST_CALLABLE,
	CPP_PYTORCH_BINDINGS,
	METAL,
	METAL_LIB,
	METAL_LIB_ASM,
	HOST_SHARED_LIBRARY,
	WGSL,
	WGSL_SPIRV_ASM,
	WGSL_SPIRGV,
}

ContainerFormat :: enum i32 {
	NONE,
	CONTAINER_FORMAT_SLANG_MODULE,
}

ArchiveType :: enum i32 {
	UNDEFINED,
	ZIP,
	RIFF,
	RIFF_DEFLATE,
	RIFF_LZ4,
}

// TODO(Dragos): check correctness of the generated bitset
// Note(Dragos): the SlangCompileFlags are defined as 1 << n, so declaring things like this makes it slightly incompatible. This needs to be checked in practice
CompileFlag :: enum u32 {
	NO_MANGLING = 3,
	NO_CODEGEN = 4,
	OBFUSCATE = 5,
	// NO_CHECKING = 0,
	// SPLIT_MIXED_TYPES = 0,
}
CompileFlags :: bit_set[CompileFlag; u32]

TargetFlag :: enum u32 {
	/* [deprecated] */ PARAMETER_BLOCK_USE_REGISTER_SPACE = 4, // This behavior is now enabled unconditionally
	GENERATE_WHOLE_PROGRAM = 8,
	DUMP_IR = 9,
	GENERATE_SPIRV_DIRECTLY = 10,
}
TargetFlags :: bit_set[TargetFlag; u32]

kDefaultTargetFlags :: TargetFlags {
	.GENERATE_SPIRV_DIRECTLY,
}

FloatingPointMode :: enum u32 {
	DEFAULT,
	FAST,
	PRECISE,
}

LineDirectiveMode :: enum u32 {
	DEFAULT,
	NONE,
	STANDARD,
	GLSL,
	SOURCE_MAP,
}

SourceLanguage :: enum i32 {
	Unknown,
	SLANG,
	HLSL,
	GLSL,
	C,
	CPP,
	CUDA,
	SPIRV,
	METAL,
	WGSL,
}

ProfileID :: enum u32 { 
	Unknown,
}

CapabilityID :: enum i32 {
	UNKNOWN,
}

MatrixLayoutMode :: enum u32 {
	UNKNOWN,
	ROW_MAJOR,
	COLUMN_MAJOR,
}

Stage :: enum u32 {
	NONE,
	VERTEX,
	HULL,
	DOMAIN,
	GEOMETRY,
	FRAGMENT,
	COMPUTE,
	RAY_GENERATION,
	INTERSECTION,
	ANY_HIT,
	CLOSEST_HIT,
	MISS,
	CALLABLE,
	MESH,
	AMPLIFICATION,
	PIXEL = FRAGMENT, // alias
}

DebugInfoLevel :: enum u32 {
	NONE,
	MINIMAL,
	STANDARD,
	MAXIMAL,
}

DebugInfoFormat :: enum u32 {
	DEFAULT,
	C7,
	PDB,
	STABS,
	COFF,
	DWARF,
}

OptimizationLevel :: enum u32 {
	NONE,
	DEFAULT,
	HIGH,
	MAXIMAL,
}

// Note(Dragos): the enum integral is not specified here
EmitSpirvMethod :: enum {
	DEFAULT,
	VIA_GLSL,
	DIRECTLY,
}

CompilerOptionName :: enum {
	MacroDefine, // stringValue0: macro name;  stringValue1: macro value
	DepFile,
	EntryPointName,
	Specialize,
	Help,
	HelpStyle,
	Include, // stringValue: additional include path.
	Language,
	MatrixLayoutColumn,         // bool
	MatrixLayoutRow,            // bool
	ZeroInitialize,             // bool
	IgnoreCapabilities,         // bool
	RestrictiveCapabilityCheck, // bool
	ModuleName,                 // stringValue0: module name.
	Output,
	Profile, // intValue0: profile
	Stage,   // intValue0: stage
	Target,  // intValue0: CodeGenTarget
	Version,
	WarningsAsErrors, // stringValue0: "all" or comma separated list of warning codes or names.
	DisableWarnings,  // stringValue0: comma separated list of warning codes or names.
	EnableWarning,    // stringValue0: warning code or name.
	DisableWarning,   // stringValue0: warning code or name.
	DumpWarningDiagnostics,
	InputFilesRemain,
	EmitIr,                        // bool
	ReportDownstreamTime,          // bool
	ReportPerfBenchmark,           // bool
	ReportCheckpointIntermediates, // bool
	SkipSPIRVValidation,           // bool
	SourceEmbedStyle,
	SourceEmbedName,
	SourceEmbedLanguage,
	DisableShortCircuit,            // bool
	MinimumSlangOptimization,       // bool
	DisableNonEssentialValidations, // bool
	DisableSourceMap,               // bool
	UnscopedEnum,                   // bool
	PreserveParameters, // bool: preserve all resource parameters in the output code.
	// Target
	Capability,                // intValue0: CapabilityName
	DefaultImageFormatUnknown, // bool
	DisableDynamicDispatch,    // bool
	DisableSpecialization,     // bool
	FloatingPointMode,         // intValue0: FloatingPointMode
	DebugInformation,          // intValue0: DebugInfoLevel
	LineDirectiveMode,
	Optimization, // intValue0: OptimizationLevel
	Obfuscate,    // bool
	VulkanBindShift, // intValue0 (higher 8 bits): kind; intValue0(lower bits): set; intValue1:
					 // shift
	VulkanBindGlobals,       // intValue0: index; intValue1: set
	VulkanInvertY,           // bool
	VulkanUseDxPositionW,    // bool
	VulkanUseEntryPointName, // bool
	VulkanUseGLLayout,       // bool
	VulkanEmitReflection,    // bool
	GLSLForceScalarLayout,   // bool
	EnableEffectAnnotations, // bool
	EmitSpirvViaGLSL,     // bool (will be deprecated)
	EmitSpirvDirectly,    // bool (will be deprecated)
	SPIRVCoreGrammarJSON, // stringValue0: json path
	IncompleteLibrary,    // bool, when set, will not issue an error when the linked program has
						  // unresolved extern function symbols.
	// Downstream
	CompilerPath,
	DefaultDownstreamCompiler,
	DownstreamArgs, // stringValue0: downstream compiler name. stringValue1: argument list, one
					// per line.
	PassThrough,
	// Repro
	DumpRepro,
	DumpReproOnError,
	ExtractRepro,
	LoadRepro,
	LoadReproDirectory,
	ReproFallbackDirectory,
	// Debugging
	DumpAst,
	DumpIntermediatePrefix,
	DumpIntermediates, // bool
	DumpIr,            // bool
	DumpIrIds,
	PreprocessorOutput,
	OutputIncludes,
	ReproFileSystem,
	SerialIr,    // bool
	SkipCodeGen, // bool
	ValidateIr,  // bool
	VerbosePaths,
	VerifyDebugSerialIr,
	NoCodeGen, // Not used.
	// Experimental
	FileSystem,
	Heterogeneous,
	NoMangle,
	NoHLSLBinding,
	NoHLSLPackConstantBufferElements,
	ValidateUniformity,
	AllowGLSL,
	EnableExperimentalPasses,
	// Internal
	ArchiveType,
	CompileCoreModule,
	Doc,
	IrCompression,
	LoadCoreModule,
	ReferenceModule,
	SaveCoreModule,
	SaveCoreModuleBinSource,
	TrackLiveness,
	LoopInversion, // bool, enable loop inversion optimization
	// Deprecated
	ParameterBlocksUseRegisterSpaces,
	CountOfParsableOptions,
	// Used in parsed options only.
	DebugInformationFormat,  // intValue0: DebugInfoFormat
	VulkanBindShiftAll,      // intValue0: kind; intValue1: shift
	GenerateWholeProgram,    // bool
	UseUpToDateBinaryModule, // bool, when set, will only load
							 // precompiled modules if it is up-to-date with its source.
	EmbedDownstreamIR,       // bool
	ForceDXLayout,           // bool
	// Add this new option to the end of the list to avoid breaking ABI as much as possible.
	// Setting of EmitSpirvDirectly or EmitSpirvViaGLSL will turn into this option internally.
	EmitSpirvMethod, // enum SlangEmitSpirvMethod
}

CompilerOptionValueKind :: enum {
	Int,
	String,
}

CompileCoreModuleFlag :: enum u32 {
	WriteDocumentation = 0x1,
}

CompileCoreModuleFlags :: bit_set[CompileCoreModuleFlag; u32]

FAILED :: #force_inline proc "contextless"(#any_int status: int) -> bool { return status < 0 }
SUCCEEDED :: #force_inline proc "contextless"(#any_int status: int) -> bool { return status >= 0 }
// Note(Dragos): is Result the correct type for these?
GET_RESULT_FACILITY :: #force_inline proc "contextless"(r: Result) -> i32 { return  (i32(r) >> 16) & 0x7fff }
GET_RESULT_CODE :: #force_inline proc "contextless"(r: Result) -> i32 { return i32(r) & 0xffff }

// TODO(Dragos): submit some issue related to i32(0x80000000)
// TODO(Dragos): check correctness of this, it seems fucked
MAKE_ERROR :: #force_inline proc "contextless"(fac: i32, code: i32) -> i32 { return (fac << 16) | i32(cast(u32)code | u32(0x80000000)) }
MAKE_SUCCESS :: #force_inline proc "contextless"(fac: i32, code: i32) -> i32 { return (fac << 16) | code }


// Note(Dragos): should we add an enum for these? Are these "macros" used often?
FACILITY_WIN_GENERAL :: 0
FACILITY_WIN_INTERFACE :: 4
FACILITY_WIN_API :: 7
FACILITY_BASE :: 0x200
FACILITY_CORE :: FACILITY_BASE
FACILITY_INTERNAL :: FACILITY_BASE + 1
FACILITY_EXTERNAL_BASE :: 0x210

OK :: 0
FAIL :: #force_inline proc "contextless"() -> i32 { return MAKE_ERROR(FACILITY_WIN_GENERAL, 0x4005) } 
MAKE_WIN_GENERAL_ERROR :: #force_inline proc "contextless"(code: i32) -> i32 { return MAKE_ERROR(FACILITY_WIN_GENERAL, code)}

// Note(dragos): We can hardcode these and put them in an enum. This is not the way.
E_NOT_IMPLEMENTED :: #force_inline proc "contextless"() -> i32 { return MAKE_WIN_GENERAL_ERROR(0x4001) }
E_NO_INTERFACE :: #force_inline proc "contextless"() -> i32 { return MAKE_WIN_GENERAL_ERROR(0x4002) }
E_ABORT :: #force_inline proc "contextless"() ->  i32 { return MAKE_WIN_GENERAL_ERROR(0x4004) }
E_INVALID_HANDLE :: #force_inline proc "contextless"() -> i32 { return MAKE_ERROR(FACILITY_WIN_API, 6) }
E_INVALID_ARG :: #force_inline proc "contextless"() -> i32 { return MAKE_ERROR(FACILITY_WIN_API, 0x57) }
E_OUT_OF_MEMORY :: #force_inline proc "contextless"() -> i32 { return MAKE_ERROR(FACILITY_WIN_API, 0xe) }

MAKE_CORE_ERROR :: #force_inline proc "contextless"(code: i32) -> i32 { return MAKE_ERROR(FACILITY_CORE, code) }

E_BUFFER_TOO_SMALL :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(1) }
E_UNINITIALIZED :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(2) }
E_PENDING :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(3) }
E_CANNOT_OPEN :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(4) }
E_NOT_FOUND :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(5) }
E_INTERNAL_FAIL :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(6) }
E_NOT_AVAILABLE :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(7) }
E_TIME_OUT :: #force_inline proc "contextless"() -> i32 { return MAKE_CORE_ERROR(8) }

CompilerOptionValue :: struct {
	kind: CompilerOptionValueKind,
	intValue: i32,
	intValue1: i32,
	stringValue0: cstring,
	stringValue1: cstring,
}

CompilerOptionEntry :: struct {
	name: CompilerOptionName,
	value: CompilerOptionValue,
}

IUnknown_VTable :: struct {
	
}

UUID :: struct {
	data1: u32,
	data2: u16,
	data3: u16,
	data4: [8]u8,
}

IUnknown :: struct {
	using vtable: ^struct {
		queryInterface: proc "stdcall" (this: ^IUnknown, #by_ptr uuid: UUID, outObject: ^rawptr) -> Result,
		addRef:         proc "stdcall" (this: ^IUnknown) -> u32,
		release:        proc "stdcall" (this: ^IUnknown) -> u32,
	},
}

ICastable :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^struct {
		castAs: proc "stdcall" (this: ^ICastable, #by_ptr guid: UUID) -> rawptr,
	},
}

IClonable :: struct #raw_union {
	#subtype icastable: ICastable,
	using vtable: ^struct {
		clone: proc "stdcall" (this: ^IClonable, #by_ptr guid: UUID) -> rawptr,
	},
}

IBlob :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^struct {
		getBufferPointer: proc "stdcall"(this: ^IBlob) -> rawptr,
		getBufferSize   : proc "stdcall"(this: ^IBlob) -> uint,
	},
}

IFileSystem :: struct #raw_union {
	#subtype icastable: ICastable,
	using vtable: ^struct {
		loadFile: proc "stdcall"(this: ^IFileSystem, path: cstring) -> Result,
	}
}

// Todo(Dragos): Should this be a rawptr?
FuncPtr :: #type proc "c"()

// TODO(Dragos): findFuncByName is a FORCE_INLINE with no stdcall calconv. Does that mean it's not part of the COM interface?
ISharedLibrary :: struct #raw_union {
	#subtype icastable: ICastable,
	using vtable: ^struct {
		findSymbolByName: proc "stdcall" (this: ^IFileSystem, name: cstring) -> rawptr,
	},
}

ISharedLibraryLoader :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^struct {
		loadSharedLibrary: proc "stdcall" (this: ^ISharedLibraryLoader, path: cstring, sharedLibraryOut: ^^ISharedLibrary) -> Result,
	},
}

PathType :: enum u32 {
	DIRECTORY,
	FILE,
}

FileSystemContentsCallback :: #type proc(pathType: PathType, name: cstring, userData: rawptr)

OSPathKind :: enum u8 {
	None,
	Direct,
	OperatingSystem,
}

PathKind :: enum {
	Simplified,
	Canonical,
	Display,
	OperatingSystem,
}

// TODO(Dragos): should we replace #subtype with using?
IFileSystemExt :: struct #raw_union {
	#subtype ifilesystem: IFileSystem,
	using vtable: ^struct {
		getFileUniqueIdentity: proc "stdcall"(this: ^IFileSystemExt, path: cstring, outUniqueIdentity: ^^IBlob) -> Result,
		calcCombinedPath     : proc "stdcall"(this: ^IFileSystemExt, fromPath, path: cstring, pathOut: ^^IBlob) -> Result,
		getPathType          : proc "stdcall"(this: ^IFileSystemExt, path: cstring, pathTypeOut: ^PathType) -> Result,
		getPath              : proc "stdcall"(this: ^IFileSystemExt, path: cstring, outPath: ^^IBlob) -> Result,
		enumeratePathContents: proc "stdcall"(this: ^IFileSystemExt, path: cstring, callback: FileSystemContentsCallback, userData: rawptr) -> Result,
		getOSPathKind        : proc "stdcall"(this: ^IFileSystemExt) -> OSPathKind,
	},
}

IMutableFileSystem :: struct #raw_union {
	#subtype ifilesystext: IFileSystemExt,
	using vtable: ^struct {
		saveFile       : proc "stdcall"(this: ^IMutableFileSystem, path: cstring, data: rawptr, size: uint) -> Result,
		saveFileBlob   : proc "stdcall"(this: ^IMutableFileSystem, path: cstring, dataBlob: ^IBlob) -> Result,
		remove         : proc "stdcall"(this: ^IMutableFileSystem, path: cstring) -> Result,
		createDirectory: proc "stdcall"(this: ^IMutableFileSystem, path: cstring) -> Result,
	},
}

WriterChannel :: enum u32 {
	DIAGNOSTIC,
	STD_OUTPUT,
	STD_ERROR,
}

WriterMode :: enum u32 {
	TEXT,
	BINARY,
}

IWriter :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^struct {
		beginAppendBuffer: proc "stdcall"(this: ^IWriter, maxNumChars: uint) -> [^]byte,
		endAppendBuffer  : proc "stdcall"(this: ^IWriter, buffer: [^]byte, numChars: uint) -> Result,
		write            : proc "stdcall"(this: ^IWriter, chars: [^]byte, numChars: uint) -> Result,
		flush            : proc "stdcall"(this: ^IWriter),
		isConsole        : proc "stdcall"(this: ^IWriter) -> Bool,
		setMode          : proc "stdcall"(this: ^IWriter, mode: WriterMode) -> Result,
	},
}

IProfiler :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^struct {
		getEntryCount: proc "stdcall"(this: ^IProfiler) -> uint,
		getEntryName: proc "stdcall"(this: ^IProfiler, index: u32) -> cstring,
		getEntryTimeMS: proc "stdcall"(this: ^IProfiler, index: u32) -> c.long,
		getEntryInvocationTimes: proc "stdcall"(this: ^IProfiler, index: u32) -> u32,
	},
}

DiagnosticsCallback :: #type proc "c"(message: cstring, userData: rawptr)




ProgramLayout :: struct {

}

FunctionReflection :: struct {

}

DeclReflection :: struct {
	
}

IComponentType :: struct #raw_union {
	#subtype iunknown: ^IUnknown,
	using vtable: ^struct {
		getSession                 : proc "stdcall"(this: ^IComponentType) -> ^ISession,
		getLayout                  : proc "stdcall"(this: ^IComponentType, targetIndex: Int, outDiagnostics: ^^IBlob) -> ^ProgramLayout,
		getSpecializationParamCount: proc "stdcall"(this: ^IComponentType) -> Int,
		getEntryPointCode          : proc "stdcall"(this: ^IComponentType, entryPointIndex: Int, targetIndex: Int, outCode: ^^IBlob, outDiagnostics: ^^IBlob) -> Result,
		getResultAsFileSystem      : proc "stdcall"(this: ^IComponentType, entryPointIndex: Int, targetIndex: Int, outFileSystem: ^^IMutableFileSystem) -> Result,
		getEntryPointHash          : proc "stdcall"(this: ^IComponentType, entryPointIndex, targetIndex: Int, outHash: ^^IBlob),
		specialize                 : proc "stdcall"(this: ^IComponentType, specializationArgs: [^]SpecializationArg, specializationArgCount: Int, outSpecializedComponentType: ^^IComponentType, outDiagnostics: ^^IBlob) -> Result,
		link                       : proc "stdcall"(this: ^IComponentType, outLinkedComponentType: ^^IComponentType, outDiagnostics: ^^IBlob) -> Result,
		getEntryPointHostCallable  : proc "stdcall"(this: ^IComponentType, entryPointIndex, targetIndex: i32, outSharedLibrary: ^^ISharedLibrary, outDiagnostics: ^^IBlob) -> Result,
		renameEntryPoint           : proc "stdcall"(this: ^IComponentType, newName: cstring, outEntryPoint: ^^IComponentType) -> Result,
		linkWithOptions            : proc "stdcall"(this: ^IComponentType, outLinkedComponentType: ^^IComponentType, compilerOptionEntryCount: u32, compilerOptionEntries: [^]CompilerOptionEntry, outDiagnostics: ^^IBlob) -> Result,
		getTargetCode              : proc "stdcall"(this: ^IComponentType, targetIndex: Int, outCode: ^^IBlob, outDiagnostics: ^^IBlob) -> Result,
		getTargetMetadata          : proc "stdcall"(this: ^IComponentType, targetIndex: Int, outMetadata: ^^IMetadata, outDiagnostics: ^^IBlob) -> Result,
		getEntryPointMetadata      : proc "stdcall"(this: ^IComponentType, entryPointIndex: Int, targetIndex: Int, outMetadata: ^^IMetadata, outDiagnostics: ^^IBlob) -> Result,
	},
}

IEntryPoint :: struct #raw_union {
	#subtype icomponenttype: IComponentType,
	using vtable: ^struct {
		getFunctionReflection: proc "stdcall"(this: ^IEntryPoint) -> ^FunctionReflection,
	},
}

ITypeConformance :: struct #raw_union {
	#subtype icomponenttype: IComponentType,
}

IModule :: struct #raw_union {
	#subtype icomponenttype: IComponentType,
	using vtable: ^struct {
		findEntryPointByName     : proc "stdcall"(this: ^IModule, name: cstring, outEntryPoint: ^^IEntryPoint) -> Result,
		getDefinedEntryPointCount: proc "stdcall"(this: ^IModule) -> i32,
		getDefinedEntryPoint     : proc "stdcall"(this: ^IModule, index: i32, outEntryPoint: ^^IEntryPoint) -> Result,
		serialize                : proc "stdcall"(this: ^IModule, outSerializedBlob: ^^IBlob) -> Result,
		writeToFile              : proc "stdcall"(this: ^IModule, fileName: cstring) -> Result,
		getName                  : proc "stdcall"(this: ^IModule) -> cstring,
		getFilePath              : proc "stdcall"(this: ^IModule) -> cstring,
		getUNiqueIdentity        : proc "stdcall"(this: ^IModule) -> cstring,
		findAndCheckEntryPoint   : proc "stdcall"(this: ^IModule, name: cstring, stage: Stage, outEntryPoint: ^^IEntryPoint, outDiagnostics: ^^IBlob) -> Result,
		getDependencyFileCount   : proc "stdcall"(this: ^IModule) -> i32,
		getDependencyFilePath    : proc "stdcall"(this: ^IModule, index: i32) -> cstring,
		getModuleReflection      : proc "stdcall"(this: ^IModule) -> ^DeclReflection,
	},
}

SpecializationArgKind :: enum i32 {
	Unknown,
	Type,
}

// TODO(Dragos): implement SpecializationArg::fromType
SpecializationArg :: struct {
	kind: SpecializationArgKind,
	using _: struct #raw_union {
		type: ^TypeReflection,
	},
}


SessionDesc :: struct {

}

ReflectionGenericArgType :: enum {
	TYPE,
	INT,
	BOOL,
}

TypeKind :: enum u32 {
	NONE,
	STRUCT,
	ARRAY,
	MATRIX,
	VECTOR,
	SCALAR,
	CONSTANT_BUFFER,
	RESOURCE,
	SAMPLER_STATE,
	TEXTURE_BUFFER,
	SHADER_STORAGE_BUFFER,
	PARAMETER_BLOCK,
	GENERIC_TYPE_PARAMETER,
	INTERFACE,
	OUTPUT_STREAM,
	MESH_OUTPUT,
	SPECIALIZED,
	FEEDBACK,
	POINTER,
	DYNAMIC_RESOURCE,
}

ScalarType :: enum u32 {
	NONE,
	VOID,
	BOOL,
	INT32,
	UINT32,
	INT64,
	UINT64,
	FLOAT16,
	FLOAT32,
	FLOAT64,
	INT8,
	UINT8,
	INT16,
	UINT16,
	INTPTR,
	UINTPTR,
}

DeclKind :: enum u32 {
	UNSUPPORTED_FOR_REFLECTION,
	STRUCT,
	FUNC,
	MODULE,
	GENERIC,
	VARIABLE,
	NAMESPACE,
}

SlangResourceShape :: enum u32 {
	BASE_SHAPE_MASK              = 0x0F,
	NONE                         = 0x00,
	TEXTURE_1D                   = 0x01,
	TEXTURE_2D                   = 0x02,
	TEXTURE_3D                   = 0x03,
	TEXTURE_CUBE                 = 0x04,
	TEXTURE_BUFFER               = 0x05,
	STRUCTURED_BUFFER            = 0x06,
	BYTE_ADDRESS_BUFFER          = 0x07,
	RESOURCE_UNKNOWN             = 0x08,
	ACCELERATION_STRUCTURE       = 0x09,
	TEXTURE_SUBPASS              = 0x0A,
	RESOURCE_EXT_SHAPE_MASK      = 0xF0,
	TEXTURE_FEEDBACK_FLAG        = 0x10,
	TEXTURE_SHADOW_FLAG          = 0x20,
	TEXTURE_ARRAY_FLAG           = 0x40,
	TEXTURE_MULTISAMPLE_FLAG     = 0x80,
	TEXTURE_1D_ARRAY             = TEXTURE_1D | TEXTURE_ARRAY_FLAG,
	TEXTURE_2D_ARRAY             = TEXTURE_2D | TEXTURE_ARRAY_FLAG,
	TEXTURE_CUBE_ARRAY           = TEXTURE_CUBE | TEXTURE_ARRAY_FLAG,
	TEXTURE_2D_MULTISAMPLE       = TEXTURE_2D | TEXTURE_MULTISAMPLE_FLAG,
	TEXTURE_2D_MULTISAMPLE_ARRAY = TEXTURE_2D | TEXTURE_MULTISAMPLE_FLAG | TEXTURE_ARRAY_FLAG,
	TEXTURE_SUBPASS_MULTISAMPLE  = TEXTURE_SUBPASS | TEXTURE_MULTISAMPLE_FLAG,
}

ResourceAccess :: enum u32 {
	NONE,
	READ,
	READ_WRITE,
	RASTER_ORDERED,
	APPEND,
	CONSUME,
	WRITE,
	FEEDBACK,
	UNKNOWN = 0x7FFFFFFF,
}

ParameterCategory :: enum u32 {
	NONE,
	MIXED,
	CONSTANT_BUFFER,
	SHADER_RESOURCE,
	UNORDERED_ACCESS,
	VARYING_INPUT,
	VARYING_OUTPUT,
	SAMPLER_STATE,
	UNIFORM,
	DESCRIPTOR_TABLE_SLOT,
	SPECIALIZATION_CONSTANT,
	PUSH_CONSTANT_BUFFER,
	// HLSL register `space`, Vulkan GLSL `set`
	REGISTER_SPACE,
	// TODO: Ellie, Both APIs treat mesh outputs as more or less varying output,
	// Does it deserve to be represented here??
	// A parameter whose type is to be specialized by a global generic type argument
	GENERIC,
	RAY_PAYLOAD,
	HIT_ATTRIBUTES,
	CALLABLE_PAYLOAD,
	SHADER_RECORD,
	// An existential type parameter represents a "hole" that
	// needs to be filled with a concrete type to enable
	// generation of specialized code.
	//
	// Consider this example:
	//
	//      struct MyParams
	//      {
	//          IMaterial material;
	//          ILight lights[3];
	//      };
	//
	// This `MyParams` type introduces two existential type parameters:
	// one for `material` and one for `lights`. Even though `lights`
	// is an array, it only introduces one type parameter, because
	// we need to hae a *single* concrete type for all the array
	// elements to be able to generate specialized code.
	//
	EXISTENTIAL_TYPE_PARAM,
	// An existential object parameter represents a value
	// that needs to be passed in to provide data for some
	// interface-type shader paameter.
	//
	// Consider this example:
	//
	//      struct MyParams
	//      {
	//          IMaterial material;
	//          ILight lights[3];
	//      };
	//
	// This `MyParams` type introduces four existential object parameters:
	// one for `material` and three for `lights` (one for each array
	// element). This is consistent with the number of interface-type
	// "objects" that are being passed through to the shader.
	//
	EXISTENTIAL_OBJECT_PARAM,
	// The register space offset for the sub-elements that occupies register spaces.
	SUB_ELEMENT_REGISTER_SPACE,
	// The input_attachment_index subpass occupancy tracker
	SUBPASS,
	// Metal tier-1 argument buffer element [[id]].
	METAL_ARGUMENT_BUFFER_ELEMENT,
	// Metal [[attribute]] inputs.
	METAL_ATTRIBUTE,
	// Metal [[payload]] inputs
	METAL_PAYLOAD,
}

BindingType :: enum u32 {
	UNKNOWN = 0,
	SAMPLER,
	TEXTURE,
	CONSTANT_BUFFER,
	PARAMETER_BLOCK,
	TYPED_BUFFER,
	RAW_BUFFER,
	COMBINED_TEXTURE_SAMPLER,
	INPUT_RENDER_TARGET,
	INLINE_UNIFORM_DATA,
	RAY_TRACING_ACCELERATION_STRUCTURE,
	VARYING_INPUT,
	VARYING_OUTPUT,
	EXISTENTIAL_VALUE,
	PUSH_CONSTANT,
	MUTABLE_FLAG = 0x100,

	// TODO(Dragos): fix typo in main repo SLANG_BINDING_TYPE_MUTABLE_TETURE
	MUTABLE_TEXTURE = TEXTURE | MUTABLE_FLAG,
   	MUTABLE_TYPED_BUFFER = TYPED_BUFFER | MUTABLE_FLAG,
	MUTABLE_RAW_BUFFER = RAW_BUFFER | MUTABLE_FLAG,

	BASE_MASK = 0x00FF,
	EXT_MASK = 0xFF00,
}

SlangModifierID :: enum u32 {
	SHARED,
	NO_DIFF,
	STATIC,
	CONST,
	EXPORT,
	EXTERN,
	DIFFERENTIABLE,
	MUTATING,
	IN,
	OUT,
	INOUT,
}

ImageFormat :: u32 {
	// TODO(Dragos): see slang-image-format-defs.h
}

UNBOUNDED_SIZE :: ~uint(0)

TypeReflection :: struct {

}

LayoutRules :: enum u32 {
	DEFAULT,
	METAL_ARGUMENT_BUFFER_TIER_2,
}

TypeLayoutReflection :: struct {
	
}

ContainerType :: enum {
	None,
	UnsizedArray,
	StructuredBuffer,
	ConstantBuffer,
	ParameterBlock,
}


ISession :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^struct {
		getGlobalSession                     : proc "stdcall"(this: ^ISession) -> ^IGlobalSession,
		loadModule                           : proc "stdcall"(this: ^ISession, moduleName: cstring, outDiagnostics: ^^IBlob) -> ^IModule,
		loadModuleFromSource                 : proc "stdcall"(this: ^ISession, moduleName: cstring, path: cstring, source: ^IBlob, outDiagnostics: ^^IBlob) -> ^IModule,
		createCompositeComponentType         : proc "stdcall"(this: ^ISession, componentTypes: [^]^IComponentType, outCompositeComponentType: ^^IComponentType, outDiagnostics: ^^IBlob) -> Result,
		specializeType                       : proc "stdcall"(this: ^ISession, type: ^TypeReflection, specializationArgs: [^]SpecializationArg, specializationArgCount: Int, outDiagnostics: ^^IBlob) -> ^TypeReflection,
		getTypeLayout                        : proc "stdcall"(this: ^ISession, type: ^TypeReflection, targetIndex: Int, rules: LayoutRules, outDiagnostics: ^^IBlob) -> ^TypeLayoutReflection,
		getContainerType                     : proc "stdcall"(this: ^ISession, elementType: ^TypeReflection, containerType: ContainerType, outDiagnostics: ^^IBlob) -> ^TypeReflection,
		getDynamicType                       : proc "stdcall"(this: ^ISession) -> ^TypeReflection,
		getTypeRTTIMangledName               : proc "stdcall"(this: ^ISession, type: ^TypeReflection, outNameBlob: ^^IBlob) -> Result,
		getTypeConformanceWitnessMangledName : proc "stdcall"(this: ^ISession, type: ^TypeReflection, interfaceType: ^TypeReflection, outNameBlob: ^^IBlob) -> Result,
		getTypeConformanceWitnessSequentialID: proc "stdcall"(this: ^ISession, type: ^TypeReflection, interfaceType: ^TypeReflection, outId: ^u32) -> Result,
		createCompilerRequest                : proc "stdcall"(this: ^ISession, outCompileRequest: ^^ICompileRequest) -> Result,
		createTypeConformanceComponentType   : proc "stdcall"(this: ^ISession, type: ^TypeReflection, interfaceType: ^TypeReflection, outConformance: ^^ITypeConformance, conformanceIdOverride: Int, outDiagnostics: ^^IBlob) -> Result,
		loadModuleFromIRBlob                 : proc "stdcall"(this: ^ISession, moduleName: cstring, path: cstring, source: ^IBlob, outDiagnostics: ^^IBlob) -> ^IModule,
		getLoadedModuleCount                 : proc "stdcall"(this: ^ISession) -> Int,
		getLoadedModule                      : proc "stdcall"(this: ^ISession, indxe: Int) -> ^IModule,
		isBinaryModuleUpToDate               : proc "stdcall"(this: ^ISession, modulePath: cstring, binaryModuleBlob: ^IBlob) -> bool,
		loadModuleFromSourceString           : proc "stdcall"(this: ^ISession, moduleName, path, str: cstring, outDiagnostics: ^^IBlob) -> ^IModule,
	},
}


IMetadata :: struct #raw_union {
	#subtype icastable: ICastable,
	using vtable: ^struct {
		isParameterLocationUsed: proc "stdcall"(this: ^IMetadata, category: ParameterCategory, spaceIndex, registerIndex: UInt, outUsed: ^bool) -> Result,
	},
}

IGlobalSession :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^struct {
		createSession                     : proc "stdcall"(this: ^IGlobalSession, #by_ptr desc: SessionDesc, outSession: ^^ISession) -> Result,
		findProfile                       : proc "stdcall"(this: ^IGlobalSession, name: cstring) -> ProfileID,
		setDownstreamCompierPath          : proc "stdcall"(this: ^IGlobalSession, passThrough: PassThrough, path: cstring),
		setDownstreamCompilerPrelude      : proc "stdcall"(this: ^IGlobalSession, passThrough: PassThrough, preduleText: cstring),
		getDownstreamCompilerPrelude      : proc "stdcall"(this: ^IGlobalSession, passThrough: PassThrough, outPrelude: ^^IBlob),
		getBuildTagString                 : proc "stdcall"(this: ^IGlobalSession) -> cstring,
		setDefaultDownstreamCompiler      : proc "stdcall"(this: ^IGlobalSession, sourceLanguage: SourceLanguage, defaultCompiler: PassThrough) -> Result,
		getDefaultDownstreamCompiler      : proc "stdcall"(this: ^IGlobalSession, sourceLanguage: SourceLanguage) -> PassThrough,
		setLanguagePrelude                : proc "stdcall"(this: ^IGlobalSession, sourceLanguage: SourceLanguage, preludeText: cstring),
		getLanguagePrelude                : proc "stdcall"(this: ^IGlobalSession, sourceLanguage: SourceLanguage, outPrelude: ^^IBlob),
		createCompilerRequest             : proc "stdcall"(this: ^IGlobalSession, outCompilerRequest: ^^ICompileRequest) -> Result, /* [deprecated] */ 
		addBuiltins                       : proc "stdcall"(this: ^IGlobalSession, sourcePath: cstring, sourceString: cstring),
		setSharedLibraryLoader            : proc "stdcall"(this: ^IGlobalSession, loader: ^ISharedLibraryLoader),
		getSharedLibraryLoader            : proc "stdcall"(this: ^IGlobalSession) -> ^ISharedLibraryLoader,
		checkCompileTargetSupport         : proc "stdcall"(this: ^IGlobalSession, target: CompileTarget) -> Result,
		checkPassThroughSupport           : proc "stdcall"(this: ^IGlobalSession, passThrough: PassThrough) -> Result,
		compileCoreModule                 : proc "stdcall"(this: ^IGlobalSession, flags: CompileCoreModuleFlags) -> Result,
		loadCoreModule                    : proc "stdcall"(this: ^IGlobalSession, coreModule: rawptr, coreModuleSizeInBytes: uint) -> Result,
		saveCoreModule                    : proc "stdcall"(this: ^IGlobalSession, archiveType: ArchiveType, outBlob: ^^IBlob) -> Result,
		findCapability                    : proc "stdcall"(this: ^IGlobalSession, name: cstring) -> CapabilityID,
		setDownstreamCompilerForTransition: proc "stdcall"(this: ^IGlobalSession, source: CompileTarget, target: CompileTarget, compiler: PassThrough),
		getDownstreamCompilerForTransition: proc "stdcall"(this: ^IGlobalSession, source, target: CompileTarget) -> PassThrough,
		getCompilerElapsedTime            : proc "stdcall"(this: ^IGlobalSession, outTotalTime, outDownstreamTime: ^f64),
		setSPIRVCoreGrammar               : proc "stdcall"(this: ^IGlobalSession, jsonPath: cstring) -> Result,
		parseCommandLineArguments         : proc "stdcall"(this: ^IGlobalSession, argc: i32, argv: [^]cstring, outSessionDesc: ^SessionDesc, outAuxAllocation: ^^IUnknown) -> Result,
		getSessionDescDigest              : proc "stdcall"(this: ^IGlobalSession, sessionDesc: ^SessionDesc, outBlob: ^^IBlob) -> Result,
	},
}

@(link_prefix="slang_")
@(default_calling_convention="c")
foreign libslang {
	createGlobalSession :: proc(apiVersion: Int, outGlobalSession: ^^IGlobalSession) -> Result ---
	shutdown :: proc() ---
}

// NOTE(Dragos): sp functions seem to want to become deprecated, but some still exist
@(link_prefix="sp")
@(default_calling_convention="c")
foreign libslang {

}