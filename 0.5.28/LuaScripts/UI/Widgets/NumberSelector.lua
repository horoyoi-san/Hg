local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
NumberSelector = HL.Class('NumberSelector', UIWidgetBase)
NumberSelector.curNumber = HL.Field(HL.Number) << 1
NumberSelector.m_min = HL.Field(HL.Number) << 1
NumberSelector.m_max = HL.Field(HL.Number) << 1
NumberSelector.m_remainingCount = HL.Field(HL.Number) << 1
NumberSelector.m_showRemaining = HL.Field(HL.Boolean) << false
NumberSelector.m_onNumberChanged = HL.Field(HL.Function)
NumberSelector.m_onBtnClick = HL.Field(HL.Function)
NumberSelector.m_addBtnPressCoroutine = HL.Field(HL.Thread)
NumberSelector.m_reduceBtnPressCoroutine = HL.Field(HL.Thread)
NumberSelector._OnFirstTimeInit = HL.Override() << function(self)
    self.view.minButton.onClick:AddListener(function()
        self:_Refresh(self.m_min, true)
    end)
    self.view.maxButton.onClick:AddListener(function()
        self:_Refresh(self.m_max, true)
    end)
    self.view.addButton.onPressStart:AddListener(function()
        if InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse1) then
            return
        end
        self:_Refresh(self.curNumber + 1, true)
        if not self.view.addButton.interactable then
            return
        end
        self.m_addBtnPressCoroutine = self:_ClearCoroutine(self.m_addBtnPressCoroutine)
        self.m_addBtnPressCoroutine = self:_StartCoroutine(function()
            while true do
                coroutine.wait(UIConst.NUMBER_SELECTOR_COUNT_REFRESH_INTERVAL)
                local nextNumber = math.min((math.floor(self.curNumber / UIConst.NUMBER_SELECTOR_COUNT_REFRESH_AMOUNT) + 1) * UIConst.NUMBER_SELECTOR_COUNT_REFRESH_AMOUNT, self.m_max)
                self:_Refresh(nextNumber, true)
            end
        end)
    end)
    self.view.addButton.onPressEnd:AddListener(function()
        self.m_addBtnPressCoroutine = self:_ClearCoroutine(self.m_addBtnPressCoroutine)
    end)
    self.view.reduceButton.onPressStart:AddListener(function()
        if InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse1) then
            return
        end
        self:_Refresh(self.curNumber - 1, true)
        if not self.view.reduceButton.interactable then
            return
        end
        self.m_reduceBtnPressCoroutine = self:_ClearCoroutine(self.m_reduceBtnPressCoroutine)
        self.m_reduceBtnPressCoroutine = self:_StartCoroutine(function()
            while true do
                coroutine.wait(UIConst.NUMBER_SELECTOR_COUNT_REFRESH_INTERVAL)
                local nextNumber = math.max((math.ceil(self.curNumber / UIConst.NUMBER_SELECTOR_COUNT_REFRESH_AMOUNT) - 1) * UIConst.NUMBER_SELECTOR_COUNT_REFRESH_AMOUNT, self.m_min)
                self:_Refresh(nextNumber, true)
            end
        end)
    end)
    self.view.reduceButton.onPressEnd:AddListener(function()
        self.m_reduceBtnPressCoroutine = self:_ClearCoroutine(self.m_reduceBtnPressCoroutine)
    end)
    local slider = self.view.slider
    if self.view.config.USE_SLIDER then
        slider.gameObject:SetActive(true)
        slider.onValueChanged:AddListener(function(newNum)
            self:_Refresh(newNum, true)
        end)
    else
        slider.gameObject:SetActive(false)
    end
end
NumberSelector.InitNumberSelector = HL.Method(HL.Number, HL.Number, HL.Number, HL.Opt(HL.Function, HL.Boolean, HL.Number, HL.Function)) << function(self, curNumber, min, max, onNumberChanged, showRemaining, remainingCount, onBtnClick)
    self:_FirstTimeInit()
    self.view.remainingCount = remainingCount or self.m_max
    self.m_onNumberChanged = onNumberChanged
    self.m_onBtnClick = onBtnClick
    self.m_showRemaining = showRemaining == true
    self.m_min = min or 1
    self.m_max = max or math.maxinteger
    self:_UpdateMinMax()
    self:_Refresh(curNumber, false, true)
end
NumberSelector._Refresh = HL.Method(HL.Opt(HL.Number, HL.Boolean, HL.Boolean)) << function(self, curNumber, isChangeByBtn, isInit)
    curNumber = lume.clamp(curNumber or self.curNumber or 1, self.m_min, self.m_max)
    if curNumber == self.curNumber and not isChangeByBtn and not isInit then
        return
    end
    self.view.addButton.interactable = curNumber < self.m_max
    self.view.reduceButton.interactable = curNumber > self.m_min
    self.view.maxButton.interactable = curNumber < self.m_max
    self.view.minButton.interactable = curNumber > self.m_min
    self.curNumber = curNumber
    self.view.slider:SetValueWithoutNotify(curNumber)
    if self.view.config.NUMBER_USE_X then
        self.view.numberText.text = string.format("×%d", curNumber), self.m_max <= 0
    else
        self.view.numberText.text = string.format("%d", curNumber), self.m_max <= 0
    end
    if self.m_onNumberChanged then
        isChangeByBtn = isChangeByBtn or false
        self.m_onNumberChanged(curNumber, isChangeByBtn)
    end
    if self.m_onBtnClick and isChangeByBtn then
        self.m_onBtnClick()
    end
    if self.m_showRemaining then
        self.view.remaining.gameObject:SetActive(true)
        self.view.remaining.text = string.format(Language.LUA_REMAINING_TIPS, self.view.remainingCount - curNumber)
    else
        self.view.remaining.gameObject:SetActive(false)
    end
    if not self.view.addButton.interactable then
        self.m_addBtnPressCoroutine = self:_ClearCoroutine(self.m_addBtnPressCoroutine)
    end
    if not self.view.reduceButton.interactable then
        self.m_reduceBtnPressCoroutine = self:_ClearCoroutine(self.m_reduceBtnPressCoroutine)
    end
    if isChangeByBtn then
        AudioManager.PostEvent("au_ui_g_small_switch")
    end
end
NumberSelector.RefreshNumber = HL.Method(HL.Number, HL.Opt(HL.Number, HL.Number)) << function(self, curNumber, min, max)
    self.m_min = min or self.m_min or 1
    self.m_max = max or self.m_max or math.maxinteger
    self:_UpdateMinMax()
    self:_Refresh(curNumber)
end
NumberSelector._UpdateMinMax = HL.Method() << function(self)
    self.view.minText.text = self.m_min
    self.view.maxText.text = self.m_max
    local slider = self.view.slider
    if self.view.config.USE_SLIDER then
        slider.minValue = self.m_min
        slider.maxValue = self.m_max
    end
    self.view.addButton.interactable = self.curNumber < self.m_max
    self.view.reduceButton.interactable = self.curNumber > self.m_min
    self.view.maxButton.interactable = self.curNumber < self.m_max
    self.view.minButton.interactable = self.curNumber > self.m_min
end
HL.Commit(NumberSelector)
return NumberSelector