---@meta
-- Global type definitions and signatures for the UE4SS modding ecosystem.

-------------------------------------------------------------------------------
-- 1. Primitive Fallback Types & Unreal Engine C++ Structures
-------------------------------------------------------------------------------
---@alias int8 integer
---@alias int16 integer
---@alias int32 integer
---@alias int64 integer
---@alias uint8 integer
---@alias uint16 integer
---@alias uint32 integer
---@alias uint64 integer
---@alias float number
---@alias double number
---@alias FString string
---@alias FText string
---@alias void nil
---@alias RemoteUnrealParam any

---@class TArray
---@class TMap
---@class TSet
---@class TObjectPtr
---@class TLazyObjectPtr
---@class TWeakObjectPtr
---@class TSoftObjectPtr
---@class TSoftClassPtr
---@class TSubclassOf
---@class TFieldPath
---@class TScriptInterface

-------------------------------------------------------------------------------
-- 2. Core UE4SS API Classes
-------------------------------------------------------------------------------
---@class UObject
---@field [string] any # Allows dynamic access to reflected properties (e.g. Level.Actors)
UObject = {}

---Gets the memory address of this UObject
---@return integer
function UObject:GetAddress() end

---Gets the full name (Class.Path.Name) of this UObject
---@return string
function UObject:GetFullName() end

---@class UInterface : UObject
---@class UClass : UObject
---@class AActor : UObject
---@class APawn : AActor
---@class APlayerController : AActor
---@class UConsole : UObject
---@class UInputSettings : UObject
---@class FName
---@class FPackageName
FPackageName = {}

---@class UWorld : UObject
---@field PersistentLevel ULevel
UWorld = {}

---@class ULevel : UObject
---@field Actors UObject[]
ULevel = {}

---@class ModRef
---@field Name string The internal name of the current mod.
---@field ModDirectory string The absolute path to the mod's directory.

-------------------------------------------------------------------------------
-- 3. Enumerations & Reflection Constants
-------------------------------------------------------------------------------
---@enum EFindName
EFindName = {
    FNAME_Find = 0,
    FNAME_Add = 1,
    FNAME_Replace_With_Existing = 2
}

---@enum EObjectFlags
EObjectFlags = {
    RF_NoFlags = 0x00000000,
    RF_Public = 0x00000001,
    RF_Standalone = 0x00000002,
    RF_ArchetypeObject = 0x00000010,
    RF_Transactional = 0x00000020,
    RF_ClassDefaultObject = 0x00000040,
    RF_Transient = 0x00000200
}

---@enum EInternalObjectFlags
EInternalObjectFlags = {
    None = 0,
    ReachableInCluster = 1 << 23,
    ClusterRoot = 1 << 24,
    Native = 1 << 25,
    Async = 1 << 26,
    AsyncLoading = 1 << 27,
    Unreachable = 1 << 28,
    PendingKill = 1 << 29,
    Garbage = 1 << 30
}

---@class PropertyTypes
PropertyTypes = {
    XProperty = "XProperty",
    StructProperty = "StructProperty",
    ObjectProperty = "ObjectProperty",
    ArrayProperty = "ArrayProperty",
    MapProperty = "MapProperty",
    SetProperty = "SetProperty",
    ByteProperty = "ByteProperty",
    IntProperty = "IntProperty",
    FloatProperty = "FloatProperty",
    DoubleProperty = "DoubleProperty",
    BoolProperty = "BoolProperty",
    NameProperty = "NameProperty",
    StrProperty = "StrProperty",
    TextProperty = "TextProperty"
}

---@type FName
NAME_None = nil

---@class UnrealVersion
---@field Major integer
---@field Minor integer
---@field Patch integer
UnrealVersion = {}

-------------------------------------------------------------------------------
-- 4. Game State Context Variables (Injected / Dynamic Globals)
-------------------------------------------------------------------------------
---@type integer|nil
PlayerIndex = 0

---@type any|nil Generic object representing pre-battle events.
PreBattleEvent = nil

---@type UObject|nil Direct reference to a global Director singleton/manager.
Director = nil

---@type table Utility table for quick access to packaged Blueprints.
BP = {}

-------------------------------------------------------------------------------
-- 5. Object Search & Manipulation (Memory Scanner)
-------------------------------------------------------------------------------

---Finds any UObject by its full package path.
---@param ObjectName string The full object path.
---@param ... any Optional native flags.
---@return UObject # The found object.
function StaticFindObject(ObjectName, ...) end

---Finds a loaded object by class name and short object name.
---@param ClassName string|nil The matching class name.
---@param ObjectShortName string|nil The short name of the object.
---@param ExactClass boolean|nil Optional exact class match flag.
---@param BannedFlags integer|nil Optional flags to exclude.
---@return UObject # The found object.
function FindObject(ClassName, ObjectShortName, ExactClass, BannedFlags) end

---Scans game memory and returns an array of objects matching the given criteria.
---@param ClassName string|integer|nil The target class name.
---@param ObjectShortName string|nil The short name of the object.
---@param InTable table|nil Optional table to populate.
---@param MaxObjects integer|nil Optional max objects to return.
---@param BannedFlags integer|nil Optional flags to exclude.
---@param RequireExactClass boolean|nil Optional exact class match flag.
---@return UObject[] # A Lua array containing the found references.
function FindObjects(ClassName, ObjectShortName, InTable, MaxObjects, BannedFlags, RequireExactClass) end

---Locates the first active, non-CDO instance of the given class in memory.
---@param ShortClassName string The short class name.
---@return UObject # The live runtime instance.
function FindFirstOf(ShortClassName) end

---Scans memory and returns a table of all live non-CDO instances matching the class.
---@param ShortClassName string The short class name.
---@return UObject[] # A numerically-indexed table of instances.
function FindAllOf(ShortClassName) end

---Checks whether a UObject is properly allocated and safe to use.
---@param Object UObject|nil The object to validate.
---@return boolean # Returns true if the object is safe to manipulate.
function IsValid(Object) end

-------------------------------------------------------------------------------
-- 6. Instantiation & Engine Lifecycle System
-------------------------------------------------------------------------------

---Natively constructs a new instance of an Unreal Engine object type in memory.
---@param Class UClass The C++ or Blueprint class type to instantiate.
---@param Outer UObject The Outer object that will manage this object's lifecycle.
---@param ... any Additional optional native initialization parameters, Name, or flags.
---@return UObject # The newly created object instance.
function StaticConstructObject(Class, Outer, ...) end

---Loads an Engine Asset by its internal path.
---@param AssetPath string The full logical asset path.
---@param ... any Optional loading flags.
---@return UObject # The loaded asset as a UObject wrapper.
function LoadAsset(AssetPath, ...) end

-------------------------------------------------------------------------------
-- 7. Hook System & Dynamic Events
-------------------------------------------------------------------------------

---Intercepts a UFunction when executed by the engine.
---@param UFunctionName string The full path to the UFunction identifier.
---@param Callback fun(self: UObject, ...: any) The first parameter is always the 'self' context.
---@return integer # The unique hook ID.
function RegisterHook(UFunctionName, Callback) end

---Removes an active function hook previously registered via RegisterHook.
---@param HookId integer The ID originally returned by RegisterHook.
---@param ... any Optional extra unregistration params.
---@return boolean # Returns true if the hook was successfully removed.
function UnregisterHook(HookId, ...) end

---Fires a callback automatically whenever a new instance of the designated class is constructed.
---@param UClassName string The full class name to monitor.
---@param Callback fun(constructedObject: UObject) Receives the object before game-side initialization.
function NotifyOnNewObject(UClassName, Callback) end

---Registers a persistent callback fired immediately after a map change/load completes.
---@overload fun(Callback: fun(Engine: UObject, World: PropertyWrapper))
---@param MapPath string The target map path or name pattern.
---@param Callback fun(Engine: UObject, World: PropertyWrapper) Function executed on transition completion.
function RegisterLoadMapPostHook(MapPath, Callback) end

---Registers a hook to capture the post-initialization BeginPlay event of a given class.
---@overload fun(Callback: fun(ContextParam: PropertyWrapper))
---@param ClassName string The target class name.
---@param Callback fun(ContextParam: PropertyWrapper) Receives the wrapper containing the instance.
function RegisterBeginPlayPostHook(ClassName, Callback) end

---Configuration table for dynamically injecting custom properties into a class at runtime.
---@class CustomPropertyConfig
---@field Name string The name of the new property.
---@field Type string A valid value mapped in `PropertyTypes`.
---@field BelongsToClass string The full path of the class receiving the property.
---@field OffsetInternal integer The memory offset.
---@field ArrayProperty table|nil Nested config if Type is ArrayProperty.

---Dynamically inserts a custom property into a class at runtime.
---@param config CustomPropertyConfig The configuration table for the property.
function RegisterCustomProperty(config) end

---Registers and injects a custom event into a reflection class's scope.
---@param EventName string The name of the event to expose.
---@param Callback fun(ParamContext: PropertyWrapper, ...: PropertyWrapper) The event handler receiving parameter wrappers.
function RegisterCustomEvent(EventName, Callback) end

-------------------------------------------------------------------------------
-- 8. Thread Management & Delayed Actions
-------------------------------------------------------------------------------

---Forces safe execution of a callback on the Unreal Engine's Game Thread.
---@param Callback fun() The function to be queued.
function ExecuteInGameThread(Callback) end

---Schedules a callback execution with a millisecond-based delay.
---@param Delay integer The wait time (in ms) before firing.
---@param Callback fun() The scheduled callback function.
function ExecuteWithDelay(Delay, Callback) end

-------------------------------------------------------------------------------
-- 9. Input System & Keybinds
-------------------------------------------------------------------------------

---@enum Key
Key = {
    BACKSPACE = "BACKSPACE",
    TAB = "TAB",
    ENTER = "ENTER",
    PAUSE = "PAUSE",
    CAPSLOCK = "CAPSLOCK",
    ESC = "ESC",
    SPACE = "SPACE",
    PAGE_UP = "PAGE_UP",
    PAGE_DOWN = "PAGE_DOWN",
    END = "END",
    HOME = "HOME",
    LEFT = "LEFT",
    UP = "UP",
    RIGHT = "RIGHT",
    DOWN = "DOWN",
    PRINT_SCREEN = "PRINT_SCREEN",
    INSERT = "INSERT",
    DELETE = "DELETE",
    INS = "INSERT", -- Alias
    NUM_ZERO = "NUM_ZERO",
    NUM_ONE = "NUM_ONE",
    NUM_TWO = "NUM_TWO",
    NUM_THREE = "NUM_THREE",
    NUM_FOUR = "NUM_FOUR",
    NUM_FIVE = "NUM_FIVE",
    NUM_SIX = "NUM_SIX",
    NUM_SEVEN = "NUM_SEVEN",
    NUM_EIGHT = "NUM_EIGHT",
    NUM_NINE = "NUM_NINE",
    A = "A",
    B = "B",
    C = "C",
    D = "D",
    E = "E",
    F = "F",
    G = "G",
    H = "H",
    I = "I",
    J = "J",
    K = "K",
    L = "L",
    M = "M",
    N = "N",
    O = "O",
    P = "P",
    Q = "Q",
    R = "R",
    S = "S",
    T = "T",
    U = "U",
    V = "V",
    W = "W",
    X = "X",
    Y = "Y",
    Z = "Z",
    F1 = "F1",
    F2 = "F2",
    F3 = "F3",
    F4 = "F4",
    F5 = "F5",
    F6 = "F6",
    F7 = "F7",
    F8 = "F8",
    F9 = "F9",
    F10 = "F10",
    F11 = "F11",
    F12 = "F12",
    LEFT_MOUSE_BUTTON = "LEFT_MOUSE_BUTTON",
    RIGHT_MOUSE_BUTTON = "RIGHT_MOUSE_BUTTON",
    MIDDLE_MOUSE_BUTTON = "MIDDLE_MOUSE_BUTTON"
}

---@enum ModifierKey
ModifierKey = {
    CONTROL = "CONTROL",
    SHIFT = "SHIFT",
    ALT = "ALT"
}

---Registers a synchronous keybind that listens for user input on the Game Thread.
---@overload fun(key: Key, callback: fun())
---@param key Key The primary key.
---@param modifierKeys ModifierKey[] A table of modifier keys required.
---@param callback fun() The handler triggered.
function RegisterKeyBind(key, modifierKeys, callback) end

---Registers an asynchronous keybind.
---@param key Key The primary key.
---@param modifierKeys ModifierKey[] A table of modifier keys required.
---@param callback fun() The async handler triggered.
function RegisterKeyBindAsync(key, modifierKeys, callback) end

---Checks if a keybind is already registered.
---@param key Key The primary key.
---@param modifierKeys ModifierKey[] A table of modifier keys required.
---@return boolean # True if registered.
function IsKeyBindRegistered(key, modifierKeys) end

-------------------------------------------------------------------------------
-- 10. UE4SS Dynamic Array & Property Wrappers
-------------------------------------------------------------------------------

---Wrapper for Unreal Engine TArray properties.
---@class TArray
TArray = {}

---Iterates over the array elements, providing the index and a property wrapper.
---@param callback fun(index: integer, elem: PropertyWrapper)
function TArray:ForEach(callback) end

---Wrapper for individual properties returned in arrays or dynamic reflections.
---@class PropertyWrapper
PropertyWrapper = {}

---Retrieves the actual value from the wrapper. Can be a UObject, UClass, or primitive.
---@return any
function PropertyWrapper:get() end

---Sets the value of the property wrapper.
---@param value any The value to set.
function PropertyWrapper:set(value) end

-------------------------------------------------------------------------------
-- 11. Diagnostics, Dumps & Filesystem Utilities
-------------------------------------------------------------------------------

---Generates a text file containing a complete dump of all active Actors in the current world.
function DumpAllActors() end

---Generates a text file containing the address mapping of all loaded UObjects in memory.
function DumpAllObjects() end

---Exports the complete list and metadata of all Static Mesh instances referenced in the level.
function DumpStaticMeshes() end

---Generates a .USMAP file containing property mapping metadata for external tools.
function DumpUSMAP() end

---Runs the native automated generator to create the full Lua SDK bindings.
function GenerateSDK() end

---Generates simulated C++ header files (.h) compatible with UHT.
function GenerateUHTCompatibleHeaders() end

---Instantiates and ensures creation of the internal logical directory for UE4SS Logic Mods.
function CreateLogicModsDirectory() end

---Iterates over active mod-loading directories. If no callback is provided, it may return a table of directories.
---@overload fun(): table
---@param Callback fun(DirectoryPath: string) Receives the absolute path.
---@return table|nil # A table of directories if called without a callback.
function IterateGameDirectories(Callback) end

---Injects a custom command handler into the native Unreal Engine console.
---@overload fun(Callback: fun(FullCommand: string, Parameters: string[], Ar: any): boolean)
---@param CommandName string The text command to expose.
---@param Callback fun(FullCommand: string, Parameters: string[], Ar: any): boolean Receives the full command, parsed parameters, and output device. Return true to consume.
function RegisterConsoleCommandHandler(CommandName, Callback) end
