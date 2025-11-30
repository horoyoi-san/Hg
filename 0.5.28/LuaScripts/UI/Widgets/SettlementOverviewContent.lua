local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SettlementOverviewContent = HL.Class('SettlementOverviewContent', UIWidgetBase)
SettlementOverviewContent.m_timer = HL.Field(HL.Any)
SettlementOverviewContent.m_lastRemainTime = HL.Field(HL.Number) << -1
SettlementOverviewContent.m_settlementId = HL.Field(HL.String) << ""
SettlementOverviewContent.m_inOverAnimation = HL.Field(HL.Boolean) << false
SettlementOverviewContent._OnFirstTimeInit = HL.Override() << function(self)
end
SettlementOverviewContent._UpdateTime = HL.Method() << function(self)
    if not self.m_settlementId then
        return
    end
    local remainTime = GameInstance.player.settlementSystem:GetOrderRemainTimeInSeconds(self.m_settlementId)
    self.m_lastRemainTime = remainTime
    local isAuto = GameInstance.player.settlementSystem:GetSettlementAutoSubmit(self.m_settlementId)
    if remainTime <= 0 and not isAuto then
        if self.m_inOverAnimation then
            return
        end
        self.view.goodsGetBtn.gameObject:SetActive(true)
        self.view.timeNode.gameObject:SetActive(false)
        self.view.timeOverNode.gameObject:SetActive(false)
        self.view.lackNode.gameObject:SetActive(false)
        return
    end
    local intervalTime = 0
    if isAuto then
        intervalTime = Tables.settlementConst.stmIntervalTime
    else
        intervalTime = Tables.settlementConst.stmManualSubmitCD
    end
    if remainTime < 0 then
        remainTime = remainTime % intervalTime
    end
    self.view.slider.fillAmount = (1 - remainTime / intervalTime)
    local remainTimeText = UIUtils.getRemainingTextToMinute(remainTime)
    self.view.remainTimeText.text = remainTimeText
end
SettlementOverviewContent.InitContent = HL.Method(HL.String, HL.String, HL.Opt(HL.Boolean)) << function(self, settlementId, domainId, isSubmit)
    self:_FirstTimeInit()
    self.view.gameObject:GetComponent("CanvasGroup").alpha = 1
    self.m_settlementId = settlementId
    if not self.m_timer then
        self.m_timer = self:_StartCoroutine(function()
            while true do
                local isAuto = GameInstance.player.settlementSystem:GetSettlementAutoSubmit(self.m_settlementId)
                if isAuto then
                end
                coroutine.wait(1)
            end
        end)
    end
    self.view.centerNode.gameObject:SetActive(true)
    local settlementSystem = GameInstance.player.settlementSystem
    local level, exp, maxExp = settlementSystem:GetSettlementExp(settlementId)
    if level == 0 then
        self.view.normalState.gameObject:SetActiveIfNecessary(false)
        self.view.emptyState.gameObject:SetActiveIfNecessary(true)
    else
        self.view.normalState.gameObject:SetActiveIfNecessary(true)
        self.view.emptyState.gameObject:SetActiveIfNecessary(false)
        local settlementData = Tables.settlementBasicDataTable[settlementId]
        local maxLevel = settlementSystem:GetSettlementMaxLevel(settlementId)
        self.view.domainText.text = Tables.domainDataTable[domainId].domainName
        self.view.nameText.text = settlementData.settlementName
        self.view.levelText.text = tostring(level)
        if level ~= maxLevel then
            self.view.expText.text = tostring(exp)
            self.view.maxExpText.text = tostring(maxExp)
            self.view.levelSlider.value = exp / maxExp
        else
            self.view.expText.text = "-"
            self.view.maxExpText.text = "-"
            self.view.levelSlider.value = 0
        end
        local officerCharId = settlementSystem:GetSettlementOfficerId(settlementId)
        if officerCharId ~= nil then
            self.view.headIconNormal.gameObject:SetActiveIfNecessary(true)
            self.view.headIconEmpty.gameObject:SetActiveIfNecessary(false)
            self.view.headIconImage.spriteName = UIConst.UI_ROUND_CHAR_HEAD_PREFIX .. officerCharId
        else
            self.view.headIconNormal.gameObject:SetActiveIfNecessary(false)
            self.view.headIconEmpty.gameObject:SetActiveIfNecessary(true)
        end
        local orderId = settlementSystem:GetSettlementOrderId(settlementId)
        local orderData = Tables.settlementOrderDataTable[orderId]
        self.view.orderNameText.text = orderData.name
        self.view.centerNode:InitSettlementOrderItem(settlementId)
        self.view.typeConTogAuto.onValueChanged:RemoveAllListeners()
        self.view.typeConTogManual.onValueChanged:RemoveAllListeners()
        local isAuto = settlementSystem:GetSettlementAutoSubmit(settlementId)
        self.view.timeNode.gameObject:SetActive(true)
        self.view.mask.gameObject:SetActive(true)
        self.view.goodsGetBtn.gameObject:SetActive(false)
        if isAuto then
            self.view.typeConTogAuto.isOn = true
            self.view.typeConTogManual.isOn = false
            self:_UpdateTime()
        else
            self.view.typeConTogAuto.isOn = false
            self.view.typeConTogManual.isOn = true
            self.view.goodsGetBtn.onClick:RemoveAllListeners()
            self.view.goodsGetBtn.onClick:AddListener(function()
                local orderId = settlementSystem:GetSettlementOrderId(settlementId)
                if orderId then
                    local orderData = Tables.settlementOrderDataTable[orderId]
                    for _, itemBundles in pairs(orderData.costItems) do
                        local itemData = Tables.itemTable[itemBundles.id]
                        local nowCount = Utils.getDepotItemCount(itemData.id, nil, domainId)
                        if nowCount < itemBundles.count then
                            self.view.goodsGetBtn.gameObject:SetActive(false)
                            self.view.timeNode.gameObject:SetActive(true)
                            self.view.mask.gameObject:SetActive(false)
                            self.view.timeOverNode.gameObject:SetActive(true)
                            self.view.lackNode.gameObject:SetActive(true)
                            self.m_inOverAnimation = true
                            self.view.timeNode:Play("order_time_over", function()
                                self.m_inOverAnimation = false
                                self.view.timeOverNode.gameObject:SetActive(false)
                                self.view.lackNode.gameObject:SetActive(false)
                                self:_UpdateTime()
                            end)
                            return
                        end
                    end
                end
                GameInstance.player.settlementSystem:ManualSubmitOrder(settlementId)
            end)
            self:_UpdateTime()
        end
        self.view.typeConTogAuto.onValueChanged:AddListener(function(isOn)
            if isOn then
                settlementSystem:SetSubmitAuto(settlementId, true)
                self:_UpdateTime()
            end
            self.view.lineTypeImage01.gameObject:SetActive(isOn)
        end)
        self.view.typeConTogManual.onValueChanged:AddListener(function(isOn)
            if isOn then
                settlementSystem:SetSubmitAuto(settlementId, false)
                self:_UpdateTime()
            end
            self.view.lineTypeImage02.gameObject:SetActive(isOn)
        end)
        self.view.typeGroup.onClick:RemoveAllListeners()
        self.view.typeGroup.onClick:AddListener(function()
            local isAuto = settlementSystem:GetSettlementAutoSubmit(settlementId)
            if isAuto then
                self.view.typeNode:Play("btn_toggle_to_right")
                self.view.typeConTogManual.isOn = true
            else
                local submitState = Utils.getOrderSubmitStateBySettlementId(domainId, settlementId, {})
                if submitState == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Zero then
                    Notify(MessageConst.SHOW_TOAST, Language.LUA_SETTLEMENT_NOT_ENOUGH_AUTO_SUBMIT)
                    return
                end
                self.view.typeNode:Play("btn_toggle_to_left")
                self.view.typeConTogAuto.isOn = true
            end
        end)
        local isAuto = settlementSystem:GetSettlementAutoSubmit(settlementId)
        self.view.lineTypeImage02.gameObject:SetActive(not isAuto)
        self.view.lineTypeImage01.gameObject:SetActive(isAuto)
        self.view.detailBtn.onClick:RemoveAllListeners()
        self.view.detailBtn.onClick:AddListener(function()
            PhaseManager:OpenPhase(PhaseId.SettlementDetails, { settlementId = settlementId, domainId = domainId })
        end)
        local isAuto = settlementSystem:GetSettlementAutoSubmit(settlementId)
        local _, tipsCtrl = UIManager:IsOpen(PanelId.SettlemenReportTips)
        local state = tipsCtrl:GetSettlementState(settlementId)
        self.view.upperLimit.gameObject:SetActive(state == tipsCtrl.defineState.allMax and isAuto)
        self.view.slow.gameObject:SetActive(state == tipsCtrl.defineState.allSlow and isAuto)
        self.view.stagnate.gameObject:SetActive(state == tipsCtrl.defineState.allStop and isAuto)
        self.view.triCon.gameObject:SetActive(state == tipsCtrl.defineState.normal or state == tipsCtrl.defineState.initial)
        if isSubmit then
            local state = settlementSystem:GetSettlementSubmitState(settlementId)
            self.view.goodsGetBtn.gameObject:SetActive(false)
            if state == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Max then
                self.view.gameObject:GetComponent("UIAnimationWrapper"):Play("settlementmaintipsgetdone_in", function()
                    self.view.goodsGetBtn.gameObject:SetActive(false)
                    self.view.gameObject:GetComponent("UIAnimationWrapper"):Play("settlementmaintipsgetdone_out", function()
                    end)
                end)
            elseif state == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All then
                self.view.gameObject:GetComponent("UIAnimationWrapper"):Play("settlementmaintipsget_in", function()
                    CS.Beyond.Gameplay.Conditions.OnSettlementOrderSubmitFinished.Trigger()
                end)
                self.view.info:Play("settlementmainexpglow_in")
            elseif state == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Zero then
                local remainTime = GameInstance.player.settlementSystem:GetOrderRemainTimeInSeconds(self.m_settlementId)
                if not isAuto and remainTime > 0 then
                    return
                end
                self.view.timeNode.gameObject:SetActive(true)
                self.view.timeOverNode.gameObject:SetActive(true)
                self.view.lackNode.gameObject:SetActive(true)
                self.m_inOverAnimation = true
                self.view.timeNode:Play("order_time_over", function()
                    self.view.timeOverNode.gameObject:SetActive(false)
                    self.view.lackNode.gameObject:SetActive(false)
                    self.m_inOverAnimation = false
                    self:_UpdateTime()
                end)
            end
        end
    end
end
HL.Commit(SettlementOverviewContent)
return SettlementOverviewContent