local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GenderSelectConfirmHolder
GenderSelectConfirmHolderCtrl = HL.Class('GenderSelectConfirmHolderCtrl', uiCtrl.UICtrl)
local PANEL_ASSET_PATH = "Assets/Beyond/DynamicAssets/Gameplay/UI/Prefabs/CreateRole/GenderSelectConfirmPanel.prefab"
GenderSelectConfirmHolderCtrl.m_node = HL.Field(HL.Table)
GenderSelectConfirmHolderCtrl.s_messages = HL.StaticField(HL.Table) << {}
GenderSelectConfirmHolderCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local prefab = self.loader:LoadGameObject(PANEL_ASSET_PATH)
    self.m_node = Utils.wrapLuaNode(self:_CreateWorldGameObject(prefab))
    self.m_node.canvas.worldCamera = CameraManager.mainCamera
    self:BindInputPlayerAction("common_cancel", function()
        AudioAdapter.PostEvent("Au_UI_Button_Cancel")
        self.m_phase:ChooseNone()
    end)
    self:_InitActionEvent()
end
GenderSelectConfirmHolderCtrl._InitActionEvent = HL.Method() << function(self)
    self.m_node.cancelBtn.onClick:AddListener(function()
        self.m_phase:ChooseNone()
    end)
    self.m_node.confirmBtn.onClick:AddListener(function()
        self.m_phase:ConfirmSelection()
    end)
end
GenderSelectConfirmHolderCtrl.GetRealPanelView = HL.Method().Return(HL.Table) << function(self, arg)
    return self.m_node
end
GenderSelectConfirmHolderCtrl.OnHide = HL.Override() << function(self)
    self.m_node.transform.gameObject:SetActive(false)
end
GenderSelectConfirmHolderCtrl.OnShow = HL.Override() << function(self)
    self.m_node.transform.gameObject:SetActive(true)
end
HL.Commit(GenderSelectConfirmHolderCtrl)