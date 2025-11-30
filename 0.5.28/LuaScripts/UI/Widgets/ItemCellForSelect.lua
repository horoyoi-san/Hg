local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ItemCellForSelect = HL.Class('ItemCellForSelect', UIWidgetBase)
ItemCellForSelect.m_pressBtnCoroutine = HL.Field(HL.Thread)
ItemCellForSelect.curNum = HL.Field(HL.Number) << 1
ItemCellForSelect.m_max = HL.Field(HL.Number) << 1
ItemCellForSelect.m_onNumChanged = HL.Field(HL.Function)
ItemCellForSelect.m_tryChangeNum = HL.Field(HL.Function)
ItemCellForSelect._OnFirstTimeInit = HL.Override() << function(self)
    local addBtn = self.view.item.view.button
    addBtn.onPressStart:AddListener(function()
        self:_OnPressStart(true)
    end)
    addBtn.onPressEnd:AddListener(function()
        self:_OnPressEnd(true)
    end)
    self.view.btnMinus.onPressStart:AddListener(function()
        self:_OnPressStart(false)
    end)
    self.view.btnMinus.onPressEnd:AddListener(function()
        self:_OnPressEnd(false)
    end)
end
ItemCellForSelect.InitItemCellForSelect = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    self.view.item:InitItem(args.itemBundle)
    self.view.item.view.button.enabled = true
    self.curNum = args.curNum
    self.m_max = args.itemBundle.count
    self.m_onNumChanged = args.onNumChanged
    self.m_tryChangeNum = args.tryChangeNum
    self:_UpdateCountShow()
end
ItemCellForSelect.m_needTriggerOnClick = HL.Field(HL.Boolean) << false
ItemCellForSelect.m_startPressMousePos = HL.Field(Vector3)
local DRAG_MIN_DIST = 10
ItemCellForSelect._OnPressStart = HL.Method(HL.Boolean) << function(self, isAdd)
    if InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse1) then
        return
    end
    local diff = isAdd and 1 or -1
    self.m_needTriggerOnClick = true
    self.m_pressBtnCoroutine = self:_ClearCoroutine(self.m_pressBtnCoroutine)
    self.m_startPressMousePos = InputManager.mousePosition
    self.m_pressBtnCoroutine = self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.NUMBER_SELECTOR_COUNT_REFRESH_INTERVAL)
            self.m_needTriggerOnClick = false
            if Vector3.Distance(self.m_startPressMousePos - InputManager.mousePosition) >= DRAG_MIN_DIST then
                self:_OnPressEnd(isAdd)
                return
            end
            local nextNumber = (math.floor(self.curNum / UIConst.NUMBER_SELECTOR_COUNT_REFRESH_AMOUNT) + diff) * UIConst.NUMBER_SELECTOR_COUNT_REFRESH_AMOUNT
            self:_UpdateCount(nextNumber)
            if not isAdd and self.curNum == 0 then
                self:_OnPressEnd(isAdd)
                return
            end
        end
    end)
end
ItemCellForSelect._OnPressEnd = HL.Method(HL.Boolean) << function(self, isAdd)
    self.m_pressBtnCoroutine = self:_ClearCoroutine(self.m_pressBtnCoroutine)
    if self.m_needTriggerOnClick then
        self.m_needTriggerOnClick = false
        if self.m_startPressMousePos and Vector3.Distance(self.m_startPressMousePos - InputManager.mousePosition) < DRAG_MIN_DIST then
            local diff = isAdd and 1 or -1
            self:_UpdateCount(self.curNum + diff)
        end
    end
end
ItemCellForSelect._OnDisable = HL.Override() << function(self)
    self:_OnPressEnd(true)
    self:_OnPressEnd(false)
end
ItemCellForSelect._UpdateCount = HL.Method(HL.Number) << function(self, curNum)
    curNum = lume.clamp(curNum, 0, self.m_max)
    if curNum == self.curNum then
        return
    end
    if self.m_tryChangeNum then
        local valid, newNum = self.m_tryChangeNum(curNum)
        if not valid then
            return
        end
        if newNum then
            curNum = newNum
        end
    end
    self.curNum = curNum
    self:_UpdateCountShow()
    if self.m_onNumChanged then
        self.m_onNumChanged(curNum)
    end
end
ItemCellForSelect._UpdateCountShow = HL.Method() << function(self)
    local isSelected = self.curNum > 0
    self.view.selectNode.gameObject:SetActive(isSelected)
    if isSelected then
        self.view.selectCount.text = self.curNum
    end
end
HL.Commit(ItemCellForSelect)
return ItemCellForSelect