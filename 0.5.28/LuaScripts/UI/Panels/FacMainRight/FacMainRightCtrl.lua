local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacMainRight
FacMainRightCtrl = HL.Class('FacMainRightCtrl', uiCtrl.UICtrl)
FacMainRightCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ENTER_BUILDING_MODE] = 'OnEnterBuildingMode', [MessageConst.ON_ENTER_LOGISTIC_MODE] = 'OnEnterLogisticMode', [MessageConst.ON_EXIT_FACTORY_MODE] = 'ClearLastBuildId', [MessageConst.ON_SYSTEM_UNLOCK] = 'UpdateEquipBtn', }
FacMainRightCtrl.m_isBuilding = HL.Field(HL.Boolean) << false
FacMainRightCtrl.m_lastBuildItemId = HL.Field(HL.String) << ''
FacMainRightCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.buildBtn.onClick:AddListener(function()
        Notify(MessageConst.OPEN_FAC_BUILD_MODE_SELECT)
    end)
    self.view.destroyBtn.onClick:AddListener(function()
        Notify(MessageConst.FAC_ENTER_DESTROY_MODE)
    end)
    self.view.equipBtn.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.EquipProducer)
    end)
    if self.view.lastBuildNode then
        self.view.lastBuildNode.button.onClick:AddListener(function()
            self:_OnCLickLastBuild()
        end)
        self:_UpdateLastBuildNode()
    end
    self:_InitBtnRedDot()
end
FacMainRightCtrl.OnShow = HL.Override() << function(self)
    self:_UpdateLastBuildNode()
    self:UpdateEquipBtn()
end
FacMainRightCtrl.UpdateEquipBtn = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self.view.equipBtn.gameObject:SetActive(PhaseManager:CheckCanOpenPhase(PhaseId.EquipProducer))
end
FacMainRightCtrl.ClearLastBuildId = HL.Method(HL.Opt(HL.Any)) << function(self)
    self.m_lastBuildItemId = ""
    self:_UpdateLastBuildNode()
end
FacMainRightCtrl.OnEnterBuildingMode = HL.Method(HL.String) << function(self, id)
    local count = Utils.getItemCount(id)
    if count == 0 then
        return
    end
    self.m_lastBuildItemId = id
    self.m_isBuilding = true
    self:_UpdateLastBuildNode()
end
FacMainRightCtrl.OnEnterLogisticMode = HL.Method(HL.String) << function(self, id)
    self.m_lastBuildItemId = id
    self.m_isBuilding = false
    self:_UpdateLastBuildNode()
end
FacMainRightCtrl._InitBtnRedDot = HL.Method() << function(self)
    if Utils.isInBlackbox() then
        self.view.buildBtnRedDot.gameObject:SetActive(false)
        self.view.equipBtnRedDot.gameObject:SetActive(false)
        return
    end
    self.view.buildBtnRedDot:InitRedDot("FacBuildModeMenuLogisticTab")
    self.view.equipBtnRedDot:InitRedDot("EquipProducer")
end
FacMainRightCtrl._UpdateLastBuildNode = HL.Method() << function(self)
    local node = self.view.lastBuildNode
    if not node then
        return
    end
    if string.isEmpty(self.m_lastBuildItemId) or (self.m_isBuilding and Utils.getItemCount(self.m_lastBuildItemId) == 0) then
        node.gameObject:SetActive(false)
        return
    end
    node.gameObject:SetActive(true)
    local data = Tables.itemTable[self.m_lastBuildItemId]
    local sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, data.iconId)
    node.itemIcon.sprite = sprite
    node.itemIconShadow.sprite = sprite
end
FacMainRightCtrl._OnCLickLastBuild = HL.Method() << function(self)
    local itemId = self.m_lastBuildItemId
    if self.m_isBuilding then
        local count, backpackCount = Utils.getItemCount(itemId)
        if count == 0 then
            return
        end
    end
    if self.m_isBuilding then
        Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { itemId = itemId, fromDepot = backpackCount == 0, })
    else
        Notify(MessageConst.FAC_ENTER_LOGISTIC_MODE, { itemId = itemId, })
    end
end
HL.Commit(FacMainRightCtrl)