local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementSwitchRegionPopup
SettlementSwitchRegionPopupCtrl = HL.Class('SettlementSwitchRegionPopupCtrl', uiCtrl.UICtrl)
SettlementSwitchRegionPopupCtrl.m_curDomainId = HL.Field(HL.String) << ""
SettlementSwitchRegionPopupCtrl.m_unlockedDomainIds = HL.Field(HL.Table)
SettlementSwitchRegionPopupCtrl.m_regionCells = HL.Field(HL.Forward("UIListCache"))
SettlementSwitchRegionPopupCtrl.s_messages = HL.StaticField(HL.Table) << {}
SettlementSwitchRegionPopupCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnCancel.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SettlementSwitchRegionPopup)
    end)
    if arg == nil or arg.curDomainId == nil or arg.unlockedDomainIds == nil then
        logger.error(ELogChannel.UI, "打开切换区域界面参数错误")
        return
    end
    self.m_curDomainId = arg.curDomainId
    self.m_unlockedDomainIds = {}
    for i = 1, #arg.unlockedDomainIds do
        if not string.isEmpty(arg.unlockedDomainIds[i]) then
            local _, curDomainData = Tables.domainDataTable:TryGetValue(arg.unlockedDomainIds[i])
            if curDomainData then
                if curDomainData.settlementGroup.Count > 0 then
                    table.insert(self.m_unlockedDomainIds, arg.unlockedDomainIds[i])
                end
            end
        end
    end
    table.sort(self.m_unlockedDomainIds, function(a, b)
        local _, domainDataA = Tables.domainDataTable:TryGetValue(a)
        local _, domainDataB = Tables.domainDataTable:TryGetValue(b)
        return domainDataA.sortId < domainDataB.sortId
    end)
    self.view.btnConfirm.onClick:AddListener(function()
        if arg.onConfirm then
            arg.onConfirm(self.m_curDomainId)
        end
        PhaseManager:PopPhase(PhaseId.SettlementSwitchRegionPopup)
    end)
    self.m_regionCells = UIUtils.genCellCache(self.view.regionTemplate)
    self:_RefreshRegionCells()
end
SettlementSwitchRegionPopupCtrl._RefreshRegionCells = HL.Method() << function(self)
    local domainData = Tables.domainDataTable[self.m_curDomainId]
    self.view.curDomainName.text = domainData.domainName
    self.view.decoImage.spriteName = domainData.domainDeco
    self.view.colorBg.color = UIUtils.getColorByString(domainData.domainColor)
    self.m_regionCells:Refresh(#self.m_unlockedDomainIds, function(cell, index)
        local domainId = self.m_unlockedDomainIds[index]
        local domainData = Tables.domainDataTable[domainId]
        cell.selectedState.gameObject:SetActiveIfNecessary(domainId == self.m_curDomainId)
        cell.domainName.text = domainData.domainName
        cell.domainPic.spriteName = domainData.domainPic
        cell.domainIcon.spriteName = domainData.domainIcon
        cell.button.onClick:RemoveAllListeners()
        cell.button.onClick:AddListener(function()
            if domainId ~= self.m_curDomainId then
                self.m_curDomainId = domainId
                self:_RefreshRegionCells()
            end
        end)
    end)
end
HL.Commit(SettlementSwitchRegionPopupCtrl)