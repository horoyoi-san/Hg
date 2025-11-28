local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementStrategy
local settlementSystem = GameInstance.player.settlementSystem
SettlementStrategyCtrl = HL.Class('SettlementStrategyCtrl', uiCtrl.UICtrl)
SettlementStrategyCtrl.m_settlementId = HL.Field(HL.String) << ""
SettlementStrategyCtrl.m_curOrderId = HL.Field(HL.String) << ""
SettlementStrategyCtrl.m_selectedOrderId = HL.Field(HL.String) << ""
SettlementStrategyCtrl.m_contentCellCache = HL.Field(HL.Forward("UIListCache"))
SettlementStrategyCtrl.m_waitMsgToClose = HL.Field(HL.Boolean) << false
SettlementStrategyCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SETTLEMENT_ORDER_CHANGE] = '_OnSettlementOrderChange', }
SettlementStrategyCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnCancel.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SettlementStrategy)
    end)
    self.view.mask.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SettlementStrategy)
    end)
    if arg == nil or arg.settlementId == nil or arg.curOrderId == nil then
        logger.error(ELogChannel.UI, "打开切换订单界面参数错误")
        return
    end
    self.m_settlementId = arg.settlementId
    self.m_curOrderId = arg.curOrderId
    self.m_selectedOrderId = arg.curOrderId
    self.view.btnConfirm.onClick:AddListener(function()
        if self.m_curOrderId ~= self.m_selectedOrderId then
            settlementSystem:SetOrderId(self.m_settlementId, self.m_selectedOrderId)
            self.m_waitMsgToClose = true
        else
            PhaseManager:PopPhase(PhaseId.SettlementStrategy)
        end
    end)
    self.m_contentCellCache = UIUtils.genCellCache(self.view.content)
    self:_RefreshContent()
end
SettlementStrategyCtrl._RefreshContent = HL.Method() << function(self)
    local settlementData = Tables.settlementBasicDataTable[self.m_settlementId]
    local level = settlementSystem:GetSettlementLevel(self.m_settlementId)
    local orderIds = settlementData.settlementLevelMap[level].orderIdGroup
    local count = math.max(#orderIds, 2)
    self.m_contentCellCache:Refresh(count, function(cell, index)
        cell.gameObject.name = "Content" .. index
        if index > #orderIds then
            cell.selectedNode.gameObject:SetActiveIfNecessary(false)
            cell.normalNode.gameObject:SetActiveIfNecessary(false)
            cell.emptyNode.gameObject:SetActiveIfNecessary(true)
            cell.curNode.gameObject:SetActiveIfNecessary(false)
            cell.button.enabled = false
        else
            local orderId = orderIds[index - 1]
            local domainId = settlementSystem:GetSettlementDomainId(self.m_settlementId)
            cell.emptyNode.gameObject:SetActiveIfNecessary(false)
            cell.curNode.gameObject:SetActiveIfNecessary(orderId == self.m_curOrderId)
            if orderId == self.m_selectedOrderId then
                cell.selectedNode.gameObject:SetActiveIfNecessary(true)
                cell.normalNode.gameObject:SetActiveIfNecessary(false)
                cell.selectedNode:InitOrderContent(orderId, index, domainId)
            else
                cell.selectedNode.gameObject:SetActiveIfNecessary(false)
                cell.normalNode.gameObject:SetActiveIfNecessary(true)
                cell.normalNode:InitOrderContent(orderId, index, domainId)
            end
            cell.button.enabled = true
            cell.button.onClick:RemoveAllListeners()
            cell.button.onClick:AddListener(function()
                if self.m_selectedOrderId ~= orderId then
                    self.m_selectedOrderId = orderId
                    self:_RefreshContent()
                end
            end)
        end
    end)
end
SettlementStrategyCtrl._OnSettlementOrderChange = HL.Method() << function(self)
    if self.m_waitMsgToClose then
        self.m_waitMsgToClose = false
        Notify(MessageConst.SHOW_TOAST, Language.LUA_SETTLEMENT_SWITCH_ORDER_SUCC)
        PhaseManager:PopPhase(PhaseId.SettlementStrategy)
    end
end
HL.Commit(SettlementStrategyCtrl)