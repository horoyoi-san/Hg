local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MapRegionToast
local ELevelAreaPriority = CS.Beyond.Gameplay.ELevelAreaPriority
MapRegionToastCtrl = HL.Class('MapRegionToastCtrl', uiCtrl.UICtrl)
local MAP_REGION_MAIN_HUD_TOAST_TYPE = "MapRegionToast"
MapRegionToastCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.INTERRUPT_MAIN_HUD_TOAST] = "OnToastInterrupted", }
MapRegionToastCtrl.RequestShowMapRegionToast = HL.StaticMethod(HL.Table) << function(args)
    local priority, isFirst, mainTitle, subTitle, depthText = unpack(args)
    local toastInfo = { priority = priority, isFirst = isFirst, mainTitle = mainTitle, subTitle = subTitle, depthText = depthText }
    LuaSystemManager.mainHudToastSystem:AddRequest(MAP_REGION_MAIN_HUD_TOAST_TYPE, function()
        MapRegionToastCtrl._OnShowMapRegionToast(toastInfo)
    end)
end
MapRegionToastCtrl.ClearAllMapRegionToast = HL.StaticMethod() << function()
    if LuaSystemManager.mainHudToastSystem then
        LuaSystemManager.mainHudToastSystem:RemoveToastsOfType(MAP_REGION_MAIN_HUD_TOAST_TYPE)
    end
end
MapRegionToastCtrl._OnShowMapRegionToast = HL.StaticMethod(HL.Table) << function(toastInfo)
    local self = UIManager:AutoOpen(PANEL_ID)
    self:DisplayToast(toastInfo)
end
MapRegionToastCtrl.OnToastInterrupted = HL.Method() << function(self)
    self.view.animationWrapper:ClearTween(false)
    self:Close()
end
MapRegionToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
end
MapRegionToastCtrl.OnClose = HL.Override() << function(self)
end
MapRegionToastCtrl.DisplayToast = HL.Method(HL.Table) << function(self, toastInfo)
    local toastView = self.view.bigMapNode
    local toastAnimName = "map_toast_inout"
    if toastInfo.priority == ELevelAreaPriority.Override then
        toastAnimName = "map_region_toast_normal_inout"
        toastView = self.view.smallMapNode
        if toastInfo.isFirst then
            toastAnimName = "map_region_toast_first_inout"
            toastView = self.view.firstSmallMapNode
        end
        toastView.numberTxt.text = toastInfo.depthText
    end
    toastView.nameTxt.text = toastInfo.mainTitle
    toastView.descTxt.text = toastInfo.subTitle
    self.view.animationWrapper:Play(toastAnimName, function()
        Notify(MessageConst.ON_ONE_MAIN_HUD_TOAST_FINISH, MAP_REGION_MAIN_HUD_TOAST_TYPE)
    end)
end
HL.Commit(MapRegionToastCtrl)