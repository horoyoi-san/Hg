logger = require("Common/Core/Logger")
print = logger.editorInfo
logger.info("Lua init started.")
Unity = CS.UnityEngine
Debug = Unity.Debug
Vector2 = Unity.Vector2
Vector3 = Unity.Vector3
Vector4 = Unity.Vector4
Color = Unity.Color
Quaternion = Unity.Quaternion
GameObject = Unity.GameObject
Transform = Unity.Transform
Input = Unity.Input
Input.simulateMouseWithTouches = false
Screen = Unity.Screen
Camera = Unity.Camera
Time = Unity.Time
Physics = Unity.Physics
LayoutRebuilder = Unity.UI.LayoutRebuilder
Canvas = Unity.Canvas
RectTransform = Unity.RectTransform
CSUtils = CS.Beyond.Lua.UtilsForLua
UnityExtensions = CS.Beyond.UnityExtensions
LuaResourceManager = CS.Beyond.Lua.LuaResourceManager
IsNull = function(obj)
    return obj == nil or (type(obj) == "userdata" and CSUtils.IsNull(obj))
end
NotNull = function(obj)
    return not IsNull(obj)
end
enum_to_int = xlua.enum_to_int
GlobalConsts = CS.Beyond.GlobalConsts
DeviceInfo = CS.Beyond.DeviceInfo
GameInstance = CS.Beyond.Gameplay.GameInstance
LuaManagerInst = CS.Beyond.GlobalContext.luaManager
InputManager = CS.Beyond.Input.InputManager
InputManagerInst = CS.Beyond.Input.InputManager.instance
InputTimingType = CS.Beyond.Input.InputTimingType
AudioManager = CS.Beyond.Gameplay.Audio.AudioManager
CameraManager = GameInstance.cameraManager
VideoManager = GameInstance.videoManager
VoiceManager = GameInstance.voiceManager
FacCoreNS = CS.Beyond.Gameplay.Factory.Core
FacBuildingType = FacCoreNS.FactoryBuildingSystem.BuildingType
GEnums = CS.Beyond.GEnums
CSFactoryUtil = CS.Beyond.Gameplay.Factory.FactoryUtil
CSPlayerDataUtil = CS.Beyond.Gameplay.Core.PlayerDataUtil
DOTween = CS.DG.Tweening.DOTween
RTManager = CS.HG.Rendering.Runtime.RenderTextureManager
TimeManagerInst = CS.Beyond.TimeManager.instance
NetClient = CS.Beyond.Network.NetClient
GameAction = CS.Beyond.Gameplay.Actions.GameAction
ItemBundle = CS.Beyond.ItemBundle
PropertyKeys = CS.Beyond.PropertyKeys
GameLevelEvent = CS.Beyond.Gameplay.Core.GameLevelEvent
ScreenCaptureUtils = CS.Beyond.UI.ScreenCaptureUtils
ScriptBridge = CS.HG.Rendering.ScriptBridge
AudioAdapter = CS.Beyond.Audio.AudioAdapter
Misc = CS.Beyond.Misc
DateTimeUtils = CS.Beyond.DateTimeUtils
EventLogManagerInst = CS.Beyond.SDK.EventLogManager.instance
ELogChannel = CS.Beyond.ELogChannel
VoiceUtils = CS.Beyond.Gameplay.Audio.VoiceUtils
ResourceManager = CS.Beyond.Resource.ResourceManager
DialogUtils = CS.Beyond.Gameplay.Core.DialogUtils
VoiceCallbackUtil = CS.Beyond.Gameplay.Audio.VoiceCallbackUtil
ClientDataManagerInst = CS.Beyond.Gameplay.Core.ClientDataManager.instance
GameUtil = CS.Beyond.Gameplay.GameUtil
CameraUtils = CS.Beyond.Gameplay.View.CameraUtils
UICharUtils = CS.Beyond.Gameplay.UICharUtils
NarrativeUtils = CS.Beyond.Gameplay.NarrativeUtils
FacLogicFrameRate = 60
DataManager = CS.Beyond.Gameplay.DataManager.instance
I18nUtils = CS.Beyond.I18n.I18nUtils
ScopeUtil = CS.Beyond.Gameplay.ScopeUtil
ForbidType = CS.Beyond.Gameplay.ForbidType
FMVUtils = CS.Beyond.Gameplay.Core.FMVUtils
PreloadManagerIns = CS.Beyond.Resource.Runtime.PreloadManager.instance
Cfg = require("Common/Core/LuaCfg")
Tables = Cfg.Tables
loadstring = loadstring or load
unpack = unpack or table.unpack
require("Common/Core/GlobalFunctions")
lume = require_ex("Common/ThirdParty/Lume")
realInspect = require_ex("Common/ThirdParty/Inspect")
local inspectWrapper = nil
if DEVELOPMENT_BUILD or UNITY_EDITOR then
    inspectWrapper = realInspect
else
    inspectWrapper = function(root, options)
        return root
    end
end
inspect = inspectWrapper
rapidjson = require("rapidjson")
pb = require("pb")
protoc = require_ex("Common/ThirdParty/protoc")
HL = require("Common/Core/HyperLuaInit")
LuaUtils = require("LuaUtils")
string.format = LuaUtils.StrGenFormatEx(string.format)
local inspectVariant = function(root, options, depth)
    options = options or {}
    options.depth = depth
    return inspect(root, options)
end
inspect1 = function(root, options)
    return inspectVariant(root, options, 1)
end
inspect2 = function(root, options)
    return inspectVariant(root, options, 2)
end
inspect3 = function(root, options)
    return inspectVariant(root, options, 3)
end
Language = require_ex("Common/Utils/Language")
JsonConst = require_ex("Common/Utils/JsonConst")
Types = require_ex("Const/Types")
Const = require_ex("Const/Const")
UIConst = require_ex("Const/UIConst")
PhaseConst = require_ex("Const/PhaseConst")
MessageConst = require_ex("Const/MessageConst")
LoginCheckConst = require_ex("Const/LoginCheckConst")
LevelConst = require_ex("Const/LevelConst")
FacConst = require_ex("Const/FacConst")
SpaceshipConst = require_ex("Const/SpaceshipConst")
InteractOptionConst = require_ex("Const/InteractOptionConst")
MapConst = require_ex("Const/MapConst")
EquipTechConst = require_ex("Const/EquipTechConst")
WikiConst = require_ex("Const/WikiConst")
LuaUpdate = require_ex("Common/Core/LuaUpdate")()
TimerManager = require_ex("Common/Core/TimerManager")()
require_ex("Common/Core/Coroutine")
CoroutineManager = require_ex("Common/Core/CoroutineManager")()
MessageManager = require_ex("Common/Core/MessageManager")()
UIUtils = require_ex("Common/Utils/UIUtils")
Utils = require_ex("Common/Utils/Utils")
FormatUtils = require_ex("Common/Utils/FormatUtils")
CharInfoUtils = require_ex("Common/Utils/CharInfoUtils")
WeaponUtils = require_ex("Common/Utils/WeaponUtils")
AttributeUtils = require_ex("Common/Utils/AttributeUtils")
FilterUtils = require_ex("Common/Utils/FilterUtils")
FactoryUtils = require_ex("Common/Utils/FactoryUtils")
SpaceshipUtils = require_ex("Common/Utils/SpaceshipUtils")
SNSUtils = require_ex("Common/Utils/SNSUtils")
DungeonUtils = require_ex("Common/Utils/DungeonUtils")
Json = require_ex("Common/Tools/json")
RedDotUtils = require_ex("Common/Utils/RedDotUtils")
EquipTechUtils = require_ex("Common/Utils/EquipTechUtils")
WikiUtils = require_ex("Common/Utils/WikiUtils")
MapUtils = require_ex("Common/Utils/MapUtils")
LuaObjectMemoryLeakChecker = require_ex("Common/Core/LuaObjectMemoryLeakChecker")()
Register = function(msg, action, groupKey)
    MessageManager:Register(msg, action, groupKey)
end
CSNotify = function(msg, arg)
    MessageManager:Send(MessageConst[msg], arg)
end
Notify = function(msg, arg)
    MessageManager:Send(msg, arg)
end
UIManager = require_ex("Common/Core/UIManager")()
PanelId = UIManager.ids
PhaseManager = require_ex("Common/Core/PhaseManager")()
PhaseId = PhaseManager.phaseIds
UIManager:InitPanelConfigs()
UIWorldFreezeManager = require_ex("Common/Core/UIWorldFreezeManager")()
PhaseManager:InitPhaseConfigs()
RedDotManager = require_ex("UI/RedDot/RedDotManager")()
UIWidgetManager = require_ex("Common/Core/UIWidgetManager")()
WrapUIWidget = function(t, name, component)
    if component.table then
        t[name] = component.table[1]
    else
        t[name] = UIWidgetManager:Wrap(component)
    end
end
CSBindLuaRef = function(t, name, luaRef)
    local ref = Utils.bindLuaRef(luaRef)
    UIUtils.initLuaCustomConfig(ref)
    t[name] = ref
end
LuaSystemManager = require_ex("LuaSystem/LuaSystemManager")()
logger.info("Lua init finished.")
Notify(MessageConst.ON_LUA_INIT_FINISHED)