local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementBrief
local settlementSystem = GameInstance.player.settlementSystem
SettlementBriefCtrl = HL.Class('SettlementBriefCtrl', uiCtrl.UICtrl)
SettlementBriefCtrl.m_domainId = HL.Field(HL.String) << ""
SettlementBriefCtrl.m_dateCellCache = HL.Field(HL.Forward("UIListCache"))
SettlementBriefCtrl.m_contentCellCache = HL.Field(HL.Forward("UIListCache"))
SettlementBriefCtrl.m_levelCellCacheList = HL.Field(HL.Table)
SettlementBriefCtrl.m_costCellCacheList = HL.Field(HL.Table)
SettlementBriefCtrl.m_rewardCellCacheList = HL.Field(HL.Table)
SettlementBriefCtrl.s_messages = HL.StaticField(HL.Table) << {}
SettlementBriefCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnBack.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SettlementBrief)
    end)
    self.view.mask.onClick:AddListener(function()
    end)
    if not arg then
        logger.error(ELogChannel.UI, "打开据点日报界面参数错误")
        return
    end
    settlementSystem:CheckAndUpdateDailyReport()
    self.m_domainId = arg
    self.m_dateCellCache = UIUtils.genCellCache(self.view.dateNode)
    self.m_contentCellCache = UIUtils.genCellCache(self.view.contentNode)
    self.m_levelCellCacheList = {}
    self.m_costCellCacheList = {}
    self.m_rewardCellCacheList = {}
    local REPORT_SHOW_DAYS = 3
    self.m_dateCellCache:Refresh(REPORT_SHOW_DAYS, function(cell, index)
        self:_RefreshDateCell(cell, index - 1)
    end)
    self.m_contentCellCache:Refresh(REPORT_SHOW_DAYS, function(cell, index)
        self:_RefreshContentCell(cell, index - 1)
    end)
end
SettlementBriefCtrl._RefreshDateCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local date = os.date("!*t", DateTimeUtils.GetCurrentTimestampBySeconds() - index * 86400 - 3600 * 4 + Utils.getServerTimeZoneOffsetSeconds())
    cell.monthText.text = tostring(date.month)
    cell.dayText.text = tostring(date.day)
    cell.todayNode.gameObject:SetActiveIfNecessary(index == 0)
    if index == 1 then
        cell.earlierText.text = Language.LUA_SETTLEMENT_DATE_YESTERDAY
    elseif index == 2 then
        cell.earlierText.text = Language.LUA_SETTLEMENT_DATE_BEFORE
    end
end
SettlementBriefCtrl._RefreshContentCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    cell.darkBg.gameObject:SetActiveIfNecessary(index == 1)
    if self.m_levelCellCacheList[index] == nil then
        self.m_levelCellCacheList[index] = UIUtils.genCellCache(cell.levelNode)
    end
    if self.m_costCellCacheList[index] == nil then
        self.m_costCellCacheList[index] = UIUtils.genCellCache(cell.costItem)
    end
    if self.m_rewardCellCacheList[index] == nil then
        self.m_rewardCellCacheList[index] = UIUtils.genCellCache(cell.rewardItem)
    end
    local domainData = Tables.domainDataTable[self.m_domainId]
    local settlementIds = domainData.settlementGroup
    self.m_levelCellCacheList[index]:Refresh(settlementIds.Count, function(settlementCell, settlementIndex)
        self:_RefreshSettlementLevelCell(settlementCell, settlementIndex - 1, index)
    end)
    local costItemList = settlementSystem:GetDomainDailyConsume(self.m_domainId, index)
    if costItemList.Count > 0 then
        cell.normalCostNode.gameObject:SetActiveIfNecessary(true)
        cell.emptyCostNode.gameObject:SetActiveIfNecessary(false)
        self.m_costCellCacheList[index]:Refresh(costItemList.Count, function(costItemCell, costItemIndex)
            costItemCell:InitItem(costItemList[costItemIndex - 1], true)
        end)
    else
        cell.normalCostNode.gameObject:SetActiveIfNecessary(false)
        cell.emptyCostNode.gameObject:SetActiveIfNecessary(true)
    end
    local rewardItemList = settlementSystem:GetDomainDailyOutput(self.m_domainId, index)
    if rewardItemList.Count > 0 then
        cell.textReward.gameObject:SetActiveIfNecessary(true)
        cell.textNoReward.gameObject:SetActiveIfNecessary(false)
        cell.rewardEmptyNode.gameObject:SetActiveIfNecessary(false)
        self.m_rewardCellCacheList[index]:Refresh(rewardItemList.Count, function(rewardItemCell, rewardItemIndex)
            rewardItemCell:InitItem(rewardItemList[rewardItemIndex - 1], true)
        end)
    else
        cell.textReward.gameObject:SetActiveIfNecessary(false)
        cell.textNoReward.gameObject:SetActiveIfNecessary(true)
        cell.rewardEmptyNode.gameObject:SetActiveIfNecessary(true)
    end
end
SettlementBriefCtrl._RefreshSettlementLevelCell = HL.Method(HL.Table, HL.Number, HL.Number) << function(self, settlementCell, csIndex, dayIndex)
    local domainData = Tables.domainDataTable[self.m_domainId]
    local settlementIds = domainData.settlementGroup
    if #settlementIds < csIndex or not settlementSystem:IsSettlementUnlocked(settlementIds[csIndex]) then
        settlementCell.normalNode.gameObject:SetActiveIfNecessary(false)
        settlementCell.emptyNode.gameObject:SetActiveIfNecessary(true)
    else
        local settlementId = settlementIds[csIndex]
        local settlementData = Tables.settlementBasicDataTable[settlementId]
        local dailyReport = settlementSystem:GetSettlementDailyReport(settlementId, dayIndex)
        if dailyReport.isValid then
            settlementCell.normalNode.gameObject:SetActiveIfNecessary(true)
            settlementCell.emptyNode.gameObject:SetActiveIfNecessary(false)
            local levelData = settlementData.settlementLevelMap[dailyReport.postLevel]
            settlementCell.nameText.text = settlementData.settlementName
            settlementCell.postLevelText.text = tostring(dailyReport.postLevel)
            settlementCell.maxExpText.text = tostring(levelData.levelUpExp)
            if dailyReport.postLevel == dailyReport.preLevel then
                settlementCell.levelUpNode.gameObject:SetActiveIfNecessary(false)
                settlementCell.postLevelText.color = self.view.config.normalTextColor
                settlementCell.preExpText.text = tostring(dailyReport.preExp)
                if dailyReport.postExp - dailyReport.preExp > 0 then
                    settlementCell.deltaExpText.gameObject:SetActiveIfNecessary(true)
                    settlementCell.deltaExpText.text = "+" .. tostring(dailyReport.postExp - dailyReport.preExp)
                else
                    settlementCell.deltaExpText.gameObject:SetActiveIfNecessary(false)
                end
                settlementCell.preBar.fillAmount = dailyReport.preExp / levelData.levelUpExp
                settlementCell.postBar.fillAmount = dailyReport.postExp / levelData.levelUpExp
            else
                settlementCell.levelUpNode.gameObject:SetActiveIfNecessary(true)
                settlementCell.postLevelText.color = self.view.config.yellowTextColor
                settlementCell.preLevelText.text = tostring(dailyReport.preLevel)
                settlementCell.preExpText.text = "0"
                if dailyReport.postExp > 0 then
                    settlementCell.deltaExpText.gameObject:SetActiveIfNecessary(true)
                    settlementCell.deltaExpText.text = "+" .. tostring(dailyReport.postExp)
                else
                    settlementCell.deltaExpText.gameObject:SetActiveIfNecessary(false)
                end
                settlementCell.preBar.fillAmount = 0
                settlementCell.postBar.fillAmount = dailyReport.postExp / levelData.levelUpExp
            end
            local maxLevel = settlementSystem:GetSettlementMaxLevel(settlementId)
            settlementCell.upgradeStateText.gameObject:SetActiveIfNecessary(true)
            if dailyReport.postLevel == maxLevel then
                settlementCell.upgradeStateText.text = Language.LUA_SETTLEMENT_LEVEL_MAX
                settlementCell.upgradeStateText.color = self.view.config.normalTextColor
                settlementCell.preExpText.text = "-"
                settlementCell.maxExpText.text = "-"
            elseif dailyReport.postExp >= levelData.levelUpExp then
                settlementCell.upgradeStateText.text = Language.LUA_SETTLEMENT_CAN_LEVEL_UP
                settlementCell.upgradeStateText.color = self.view.config.yellowTextColor
            elseif dailyReport.postLevel > dailyReport.preLevel then
                settlementCell.upgradeStateText.text = string.format(Language.LUA_SETTLEMENT_HAS_LEVEL_UP, dailyReport.postLevel)
                settlementCell.upgradeStateText.color = self.view.config.normalTextColor
            else
                settlementCell.upgradeStateText.gameObject:SetActiveIfNecessary(false)
            end
        else
            settlementCell.normalNode.gameObject:SetActiveIfNecessary(false)
            settlementCell.emptyNode.gameObject:SetActiveIfNecessary(true)
        end
    end
end
HL.Commit(SettlementBriefCtrl)