local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementDetails
local settlementSystem = GameInstance.player.settlementSystem
SettlementDetailsCtrl = HL.Class('SettlementDetailsCtrl', uiCtrl.UICtrl)
SettlementDetailsCtrl.m_settlementId = HL.Field(HL.String) << ""
SettlementDetailsCtrl.m_getFeatureCellFunc = HL.Field(HL.Function)
SettlementDetailsCtrl.m_rewardItemCache = HL.Field(HL.Forward("UIListCache"))
SettlementDetailsCtrl.m_costItemCache = HL.Field(HL.Forward("UIListCache"))
SettlementDetailsCtrl.m_featureCache = HL.Field(HL.Forward("UIListCache"))
SettlementDetailsCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SETTLEMENT_SYS_REFRESH] = '_OnSettlementSysRefresh', [MessageConst.ON_SETTLEMENT_CHAR_CLOSE] = '_OnCharPanelClose', [MessageConst.ON_SETTLEMENT_SUBMIT] = '_OnSettlementSysRefresh', }
SettlementDetailsCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnBack.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SettlementDetails)
    end)
    self.view.mask.onClick:AddListener(function()
    end)
    if not arg or not arg.settlementId or not arg.domainId then
        logger.error(ELogChannel.UI, "打开据点详情界面参数错误")
        return
    end
    local settlementId = arg.settlementId
    local settlementData = Tables.settlementBasicDataTable[settlementId]
    local domainId = arg.domainId
    local domainData = Tables.domainDataTable[domainId]
    self.m_settlementId = settlementId
    self.view.domainText.text = domainData.domainName
    self.view.domainIcon.spriteName = domainData.domainIcon
    self.view.nameText.text = settlementData.settlementName
    self.view.detailText.text = settlementSystem:GetSettlementDescription(settlementId)
    self:_RefreshOrder()
    self.view.btnSwitchOrder.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SettlementStrategy, { settlementId = self.m_settlementId, curOrderId = settlementSystem:GetSettlementOrderId(self.m_settlementId) })
    end)
    self:_RefreshExp()
    self.m_featureCache = UIUtils.genCellCache(self.view.content)
    self:UpdateFeatureCell()
    self:_RefreshOfficer()
    self.view.btnSwitchOfficer.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SettlementChar, self.m_settlementId)
    end)
    self.view.btnSetOfficer.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SettlementChar, self.m_settlementId)
    end)
end
SettlementDetailsCtrl.OnShow = HL.Override() << function(self)
    self:UpdateFeatureCell()
end
SettlementDetailsCtrl.UpdateFeatureCell = HL.Method() << function(self)
    self.m_featureCache:Refresh(#Tables.settlementBasicDataTable[self.m_settlementId].wantTagIdGroup, function(cell, index)
        self:_RefreshFeatureCell(cell, CSIndex(index))
    end)
end
SettlementDetailsCtrl._RefreshExp = HL.Method() << function(self)
    local settlementId = self.m_settlementId
    local level, exp, maxExp, nextMaxExp = settlementSystem:GetSettlementExp(settlementId)
    local maxLevel = settlementSystem:GetSettlementMaxLevel(settlementId)
    local orderId = settlementSystem:GetSettlementOrderId(settlementId)
    local orderData = Tables.settlementOrderDataTable[orderId]
    self.view.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_SETTLEMENT_DETAIL_LEVEL, string.format("pic_%s_%s", settlementId, level))
    local officerCharId = settlementSystem:GetSettlementOfficerId(settlementId)
    local settlementData = Tables.settlementBasicDataTable[settlementId]
    self.view.levelText.text = tostring(level)
    if level ~= maxLevel then
        self.view.expText.text = tostring(exp)
        self.view.maxExpText.text = tostring(maxExp)
        self.view.expSlider.value = exp / maxExp
        self.view.descriptionText.gameObject:SetActiveIfNecessary(true)
        if exp < maxExp then
            self.view.canLevelUpNode.gameObject:SetActiveIfNecessary(false)
            local expEnhanceRate = 0
            if officerCharId then
                local charData = Tables.characterTable[officerCharId]
                self.view.officerContent.gameObject:SetActiveIfNecessary(true)
                self.view.officerEmpty.gameObject:SetActiveIfNecessary(false)
                self.view.officerNameText.text = charData.name
                self.view.headIcon.spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. officerCharId
                for _, tagId in pairs(settlementData.wantTagIdGroup) do
                    local enhanceRate = settlementSystem:GetSettlementTagEnhanceRateByChar(tagId, officerCharId)
                    expEnhanceRate = expEnhanceRate + enhanceRate.Item1
                end
            end
            local intervalTime = 0
            local isAuto = settlementSystem:GetSettlementAutoSubmit(settlementId)
            if isAuto then
                intervalTime = Tables.settlementConst.stmIntervalTime
            else
                intervalTime = Tables.settlementConst.stmManualSubmitCD
            end
            local levelUpTime = math.ceil((maxExp - exp) / (orderData.stmExp * (1 + expEnhanceRate / 100)) * intervalTime / 60)
            self.view.descriptionText.text = string.format(Language.LUA_SETTLEMENT_PROGRESS_DESCRIPTION, levelUpTime)
        elseif exp < nextMaxExp then
            self.view.canLevelUpNode.gameObject:SetActiveIfNecessary(true)
            self.view.descriptionText.text = Language.LUA_SETTLEMENT_PROGRESS_COMPLETE
        else
            self.view.canLevelUpNode.gameObject:SetActiveIfNecessary(true)
            self.view.descriptionText.text = Language.LUA_SETTLEMENT_PROGRESS_LIMITED
        end
    else
        self.view.expText.text = "-"
        self.view.maxExpText.text = "-"
        self.view.expSlider.value = 0
        self.view.canLevelUpNode.gameObject:SetActiveIfNecessary(false)
        self.view.descriptionText.gameObject:SetActiveIfNecessary(false)
    end
end
SettlementDetailsCtrl._RefreshOrder = HL.Method() << function(self)
    local orderId = settlementSystem:GetSettlementOrderId(self.m_settlementId)
    local orderData = Tables.settlementOrderDataTable[orderId]
    self.view.orderNameText.text = orderData.name
    self.view.orderItemNode:InitSettlementOrderItem(self.m_settlementId)
end
SettlementDetailsCtrl._RefreshOfficer = HL.Method() << function(self)
    local settlementId = self.m_settlementId
    local officerCharId = settlementSystem:GetSettlementOfficerId(settlementId)
    local settlementData = Tables.settlementBasicDataTable[settlementId]
    self:UpdateFeatureCell()
    if officerCharId ~= nil then
        local charData = Tables.characterTable[officerCharId]
        self.view.officerContent.gameObject:SetActiveIfNecessary(true)
        self.view.officerEmpty.gameObject:SetActiveIfNecessary(false)
        self.view.officerNameText.text = charData.name
        self.view.headIcon.spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. officerCharId
        local expEnhanceRate = 0
        local rewardEnhanceRate = 0
        for _, tagId in pairs(settlementData.wantTagIdGroup) do
            local enhanceRate = settlementSystem:GetSettlementTagEnhanceRateByChar(tagId, officerCharId)
            expEnhanceRate = expEnhanceRate + enhanceRate.Item1
            rewardEnhanceRate = rewardEnhanceRate + enhanceRate.Item2
        end
        self.view.officerEffectText.text = ""
        if expEnhanceRate > 0 then
            self.view.officerEffectText.text = UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHARACTER_EXP_EFFECT, expEnhanceRate))
        end
        if rewardEnhanceRate > 0 then
            self.view.officerEffectText.text = self.view.officerEffectText.text .. "\n" .. UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHARACTER_REWARD_EFFECT, rewardEnhanceRate))
        end
        if rewardEnhanceRate == 0 and expEnhanceRate == 0 then
            self.view.officerEffectText.text = Language.LUA_SETTLEMENT_CHARACTER_NO_EFFECT
        end
    else
        self.view.officerContent.gameObject:SetActiveIfNecessary(false)
        self.view.officerEmpty.gameObject:SetActiveIfNecessary(true)
    end
end
SettlementDetailsCtrl._RefreshFeatureCell = HL.Method(HL.Any, HL.Number) << function(self, cell, csIndex)
    local tagId = Tables.settlementBasicDataTable[self.m_settlementId].wantTagIdGroup[csIndex]
    local tagData = Tables.settlementTagTable[tagId]
    local officerId = settlementSystem:GetSettlementOfficerId(self.m_settlementId)
    local enhanceRate = settlementSystem:GetSettlementTagEnhanceRate(tagId)
    local charEnhance = settlementSystem:GetSettlementTagEnhanceRateByChar(tagId, officerId)
    cell.activeState.gameObject:SetActiveIfNecessary(charEnhance.Item1 > 0 or charEnhance.Item2 > 0)
    local extendText = ""
    if enhanceRate.Item1 > 0 then
        extendText = "\n" .. UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHAR_ENHANCE_EXP, enhanceRate.Item1))
    end
    if enhanceRate.Item2 > 1 then
        extendText = extendText .. "\n" .. UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHAR_ENHANCE_REWARD, enhanceRate.Item2))
    end
    cell.featureNormalText.text = tagData.settlementTagName
    cell.featureLockedText.text = tagData.settlementTagName
    cell.detailNormalText.text = tagData.desc .. extendText
    cell.detailLockText.text = tagData.desc .. extendText
end
SettlementDetailsCtrl._OnCharPanelClose = HL.Method() << function(self)
    self:_RefreshOfficer()
    self:_RefreshOrder()
    self:_RefreshExp()
end
SettlementDetailsCtrl._OnSettlementSysRefresh = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    self:_RefreshOrder()
    self:_RefreshExp()
end
HL.Commit(SettlementDetailsCtrl)