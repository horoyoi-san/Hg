local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonHoverTip
CommonHoverTipCtrl = HL.Class('CommonHoverTipCtrl', uiCtrl.UICtrl)
CommonHoverTipCtrl.m_coroutine = HL.Field(HL.Thread)
CommonHoverTipCtrl.m_delayCoroutine = HL.Field(HL.Thread)
CommonHoverTipCtrl.m_isShown = HL.Field(HL.Boolean) << false
CommonHoverTipCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_COMMON_HOVER_TIP] = '_OnHideTip', }
CommonHoverTipCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.tipContent.gameObject:SetActiveIfNecessary(false)
end
CommonHoverTipCtrl._OnShowTip = HL.StaticMethod(HL.Table) << function(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    if self.m_delayCoroutine ~= nil then
        self:_ClearCoroutine(self.m_delayCoroutine)
        self.m_delayCoroutine = nil
    end
    if type(args.delay) == "number" and args.delay > 0 then
        self.m_delayCoroutine = self:_StartCoroutine(function()
            coroutine.wait(args.delay)
            self.m_delayCoroutine = nil
            self:_ShowTip(args)
        end)
        return
    end
    self:_ShowTip(args)
end
CommonHoverTipCtrl._ShowTip = HL.Method(HL.Table) << function(self, args)
    self.m_isShown = true
    self.view.tipContent:PlayInAnimation()
    self.view.tipContent.gameObject:SetActiveIfNecessary(true)
    local mainText = args.mainText
    local subText = args.subText
    local itemId = args.itemId
    if not string.isEmpty(itemId) then
        local itemData = Tables.itemTable[itemId]
        local itemTypeData = Tables.itemTypeTable[itemData.type]
        mainText = itemData.name
        subText = itemTypeData.name
        self.view.rarityLine.gameObject:SetActiveIfNecessary(true)
        UIUtils.setItemRarityImage(self.view.rarityLine, itemData.rarity)
    else
        self.view.rarityLine.gameObject:SetActiveIfNecessary(false)
    end
    self.view.mainText.text = mainText
    if subText ~= nil then
        self.view.subText.gameObject:SetActiveIfNecessary(true)
        self.view.subText.text = subText
    else
        self.view.subText.gameObject:SetActiveIfNecessary(false)
    end
    local posType = args.posType or UIConst.UI_TIPS_POS_TYPE.RightTop
    if InputManager.cursorVisible then
        self.m_coroutine = self:_StartCoroutine(function()
            while true do
                local mousePos = InputManager.mousePosition
                local xRate = self.view.rectTransform.rect.width / Screen.width
                local yRate = self.view.rectTransform.rect.height / Screen.height
                local xOffset = CS.Beyond.UI.UIUtils.GetCursorTipOffsetX(self.view.config.DEFAULT_OFFSET_X)
                self.view.cursorRect.anchoredPosition = Vector2(mousePos.x * xRate + xOffset, mousePos.y * yRate)
                UIUtils.updateTipsPosition(self.view.tipContent.transform, self.view.cursorRect, self.view.rectTransform, self.uiCamera, posType, args.padding)
                coroutine.step()
            end
        end)
    else
        UIUtils.updateTipsPosition(self.view.tipContent.transform, args.targetRect, self.view.rectTransform, self.uiCamera, posType, args.padding)
    end
    self:ToTop()
end
CommonHoverTipCtrl._OnHideTip = HL.Method() << function(self)
    if self.m_delayCoroutine ~= nil then
        self:_ClearCoroutine(self.m_delayCoroutine)
        self.m_delayCoroutine = nil
    end
    if not self.m_isShown then
        return
    end
    self.m_isShown = false
    self.view.tipContent:PlayOutAnimation(function()
        self.view.tipContent.gameObject:SetActiveIfNecessary(false)
        if self.m_coroutine ~= nil then
            self:_ClearCoroutine(self.m_coroutine)
            self.m_coroutine = nil
        end
    end)
end
HL.Commit(CommonHoverTipCtrl)