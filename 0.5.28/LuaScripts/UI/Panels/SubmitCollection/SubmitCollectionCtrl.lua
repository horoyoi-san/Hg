local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SubmitCollection
SubmitCollectionCtrl = HL.Class('SubmitCollectionCtrl', uiCtrl.UICtrl)
SubmitCollectionCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SUBMIT_ETHER_SUCC] = 'OnSubmitEtherSucc', }
SubmitCollectionCtrl.m_curSelectedIndex = HL.Field(HL.Number) << -1
SubmitCollectionCtrl.m_maxLv = HL.Field(HL.Number) << 0
SubmitCollectionCtrl.m_getLvCellFunc = HL.Field(HL.Function)
SubmitCollectionCtrl.m_genRewardCellsMap = HL.Field(HL.Table)
SubmitCollectionCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_genRewardCellsMap = {}
    self.view.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SubmitCollection)
    end)
    self.view.helpBtn.onClick:AddListener(function()
        UIManager:Open(PanelId.InstructionBook, "collection_submit")
    end)
    self.view.submitNode.submitBtn.onClick:AddListener(function()
        self:_OnClickSubmit()
    end)
    self.m_getLvCellFunc = UIUtils.genCachedCellFunction(self.view.lvScrollList)
    self.view.lvScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_getLvCellFunc(obj)
        self:_OnRefreshLvCell(cell, LuaIndex(csIndex))
    end)
    self.m_maxLv = #Tables.etherSubmitTable + 1
    self.m_curSelectedIndex = math.min(GameInstance.player.inventory.curEtherLevel, #Tables.etherSubmitTable)
    self:_RefreshLvInfo(true)
    self:_UpdateCurLvPosHint()
    self.view.lvScroll.onValueChanged:AddListener(function()
        self:_UpdateCurLvPosHint()
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
SubmitCollectionCtrl.ShowSubmitEther = HL.StaticMethod(HL.Opt(HL.Table)) << function(args)
    PhaseManager:OpenPhase(PhaseId.SubmitCollection)
end
SubmitCollectionCtrl._RefreshLvInfo = HL.Method(HL.Opt(HL.Boolean)) << function(self, isInit)
    self.view.lvScrollList:UpdateCount(self.m_maxLv - 1)
    self:_RefreshContent(true)
end
SubmitCollectionCtrl._OnRefreshLvCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local curLv = GameInstance.player.inventory.curEtherLevel
    local isLocked = index > curLv
    local haveGotReward = index < curLv
    local isCurLv = index == curLv
    cell.lvTxt.text = index
    cell.lockedIcon.gameObject:SetActive(isLocked)
    cell.arrow.gameObject:SetActive(isCurLv)
    if index == self.m_maxLv - 1 and curLv == self.m_maxLv then
        cell.arrow.gameObject:SetActive(true)
    end
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        self:_OnClickLvCell(index)
    end)
    local data = Tables.etherSubmitTable[index]
    local needCount = data.count
    local curCount = 0
    if haveGotReward then
        curCount = needCount
    elseif isCurLv then
        curCount = GameInstance.player.inventory.curSubmitEtherCount
    end
    cell.progressTxt.text = string.format("%d/%d", curCount, needCount)
    cell.progressSlider.value = curCount / needCount
    local rewardData = Tables.rewardTable[data.rewardID]
    local itemBundles = rewardData.itemBundles
    local genCells = self.m_genRewardCellsMap[cell]
    if genCells == nil then
        genCells = UIUtils.genCellCache(cell.rewardItem)
        self.m_genRewardCellsMap[cell] = genCells
    end
    genCells:Refresh(itemBundles.Count, function(rewardCell, luaIndex)
        rewardCell:InitItem(itemBundles[CSIndex(luaIndex)], true)
        rewardCell.view.button.clickHintTextId = "virtual_mouse_hint_view"
    end)
    cell.gotHint.gameObject:SetActive(haveGotReward)
    self:_UpdateLvCellSelected(cell, index == self.m_curSelectedIndex, true)
    cell.animator:SetBool("IsDim", isLocked)
end
SubmitCollectionCtrl._UpdateLvCellSelected = HL.Method(HL.Table, HL.Boolean, HL.Opt(HL.Boolean)) << function(self, cell, isSelect, fast)
end
SubmitCollectionCtrl._OnClickLvCell = HL.Method(HL.Number) << function(self, index)
    local obj = self.view.lvScrollList:Get(CSIndex(self.m_curSelectedIndex))
    local oldCell = self.m_getLvCellFunc(obj)
    self:_UpdateLvCellSelected(oldCell, false)
    self.m_curSelectedIndex = index
    obj = self.view.lvScrollList:Get(CSIndex(self.m_curSelectedIndex))
    local newCell = self.m_getLvCellFunc(obj)
    self:_UpdateLvCellSelected(newCell, true)
end
SubmitCollectionCtrl._RefreshContent = HL.Method(HL.Opt(HL.Boolean)) << function(self, isInit)
    local curLv = GameInstance.player.inventory.curEtherLevel
    local submitNode = self.view.submitNode
    submitNode.gameObject:SetActive(true)
    local isMax = curLv == self.m_maxLv
    if isMax then
        submitNode.completeNode.gameObject:SetActive(true)
        submitNode.normalNode.gameObject:SetActive(false)
        submitNode.levelTxt.text = string.format("%d", self.m_maxLv - 1)
    else
        submitNode.completeNode.gameObject:SetActive(false)
        submitNode.normalNode.gameObject:SetActive(true)
        submitNode.levelTxt.text = string.format("%d", curLv)
        local curEtherCount = GameInstance.player.inventory.curEtherCount
        submitNode.curCountTxt.text = string.format("%d", curEtherCount)
        submitNode.emptyNode.gameObject:SetActive(curEtherCount == 0)
        submitNode.submitBtn.gameObject:SetActive(curEtherCount > 0)
    end
    local csIndex = CSIndex(self.m_curSelectedIndex)
    local obj = self.view.lvScrollList:Get(csIndex)
    local cell = self.m_getLvCellFunc(obj)
    self.view.lvScrollList:ScrollToIndex(csIndex, true, CS.Beyond.UI.UIScrollList.ScrollAlignType.Top)
    if cell ~= nil then
        InputManagerInst:MoveVirtualMouseTo(cell.transform, self.uiCamera)
    end
end
SubmitCollectionCtrl._UpdateCurLvPosHint = HL.Method() << function(self)
end
SubmitCollectionCtrl.m_oldLv = HL.Field(HL.Number) << -1
SubmitCollectionCtrl._OnClickSubmit = HL.Method() << function(self)
    self.m_oldLv = GameInstance.player.inventory.curEtherLevel
    GameInstance.player.inventory:SubmitEther()
end
SubmitCollectionCtrl.OnSubmitEtherSucc = HL.Method() << function(self)
    self.m_curSelectedIndex = math.min(GameInstance.player.inventory.curEtherLevel, self.m_maxLv - 1)
    self:_RefreshLvInfo()
    local items = {}
    local isEmpty = true
    for i = self.m_oldLv, GameInstance.player.inventory.curEtherLevel - 1 do
        local data = Tables.etherSubmitTable[i]
        local rewardData = Tables.rewardTable[data.rewardID]
        for _, v in pairs(rewardData.itemBundles) do
            table.insert(items, v)
            isEmpty = false
        end
    end
    if not isEmpty then
        Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = Language.LUA_SUBMIT_COLLECTION_REWARD_TITLE, items = items, })
    end
end
HL.Commit(SubmitCollectionCtrl)