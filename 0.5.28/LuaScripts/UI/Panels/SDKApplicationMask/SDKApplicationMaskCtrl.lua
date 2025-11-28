local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SDKApplicationMask
SDKApplicationMaskCtrl = HL.Class('SDKApplicationMaskCtrl', uiCtrl.UICtrl)
SDKApplicationMaskCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CLOSE_WEB_APPLICATION] = 'OnCloseWebApplication', }
SDKApplicationMaskCtrl.m_curOpenedWebNameDic = HL.Field(HL.Table)
SDKApplicationMaskCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_curOpenedWebNameDic = {}
end
SDKApplicationMaskCtrl.OnStartWebApplication = HL.StaticMethod(HL.Table) << function(args)
    local key = unpack(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    self.m_curOpenedWebNameDic[key] = true
end
SDKApplicationMaskCtrl.OnCloseWebApplication = HL.Method(HL.Table) << function(self, args)
    local key = unpack(args)
    self.m_curOpenedWebNameDic[key] = nil
    if not next(self.m_curOpenedWebNameDic) then
        self:Hide()
    end
end
HL.Commit(SDKApplicationMaskCtrl)