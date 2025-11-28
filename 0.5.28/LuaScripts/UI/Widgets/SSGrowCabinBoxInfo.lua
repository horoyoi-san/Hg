local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SSGrowCabinBoxInfo = HL.Class('SSGrowCabinBoxInfo', UIWidgetBase)
SSGrowCabinBoxInfo.m_roomId = HL.Field(HL.String) << ""
SSGrowCabinBoxInfo.m_boxId = HL.Field(HL.Number) << -1
SSGrowCabinBoxInfo.m_ctrl = HL.Field(HL.Userdata) << nil
SSGrowCabinBoxInfo.m_onBtnAddClick = HL.Field(HL.Function)
SSGrowCabinBoxInfo._OnFirstTimeInit = HL.Override() << function(self)
    self.view.btnAdd.onClick:AddListener(function()
        if self.m_onBtnAddClick then
            self.m_onBtnAddClick(self.m_boxId, false)
        end
    end)
    local cultureCultivation = self.view.cultureCultivation
    cultureCultivation.receiveBtn.onClick:AddListener(function()
        GameInstance.player.spaceship:GrowCabinHarvest(self.m_roomId, self.m_boxId)
    end)
    cultureCultivation.cancelBtn.onClick:AddListener(function()
        self:_OnCancelBtnClick()
    end)
    local culture = self.view.culture
    culture.button.onClick:AddListener(function()
        if self.m_onBtnAddClick then
            self.m_onBtnAddClick(self.m_boxId, true)
        end
    end)
    culture.bubble.onClick:AddListener(function()
        self:_OnBubbleBtnClick()
    end)
    culture.cantBubble.onClick:AddListener(function()
        self:_OnCantBubbleBtnClick()
    end)
end
SSGrowCabinBoxInfo._ShowPopUp = HL.Method(HL.Table) << function(self, args)
    Notify(MessageConst.SHOW_POP_UP, { content = args.content, subContent = args.subContent, items = args.items, onConfirm = args.onConfirm, onCancel = args.onCancel, })
end
SSGrowCabinBoxInfo._OnCancelBtnClick = HL.Method() << function(self)
    local spaceship = GameInstance.player.spaceship
    local boxes = spaceship:GetGrowCabinBoxes(self.m_roomId)
    local succ, box = boxes:TryGetValue(self.m_boxId)
    if succ then
        local formula = Tables.spaceshipGrowCabinFormulaTable[box.scdMsg.RecipeId]
        local itemData = Tables.itemTable[formula.outcomeItemId]
        local args = {
            content = string.format(Language.LUA_SPACESHIP_ROOM_GROW_CABIN_BOX_CANCEL_SOW_CONFIRM_FORMAT, itemData.name),
            subContent = Language.LUA_SPACESHIP_ROOM_GROW_CABIN_BOX_CANCEL_SOW_CONFIRM_SUB_DESC,
            onConfirm = function()
                GameInstance.player.spaceship:GrowCabinCancel(self.m_roomId, self.m_boxId)
            end,
        }
        self:_ShowPopUp(args)
    end
end
SSGrowCabinBoxInfo._OnBubbleBtnClick = HL.Method() << function(self)
    local spaceship = GameInstance.player.spaceship
    local boxes = spaceship:GetGrowCabinBoxes(self.m_roomId)
    local succ, box = boxes:TryGetValue(self.m_boxId)
    if succ then
        local formula = Tables.spaceshipGrowCabinFormulaTable[box.scdMsg.PreviewRecipeId]
        local seedItemData = Tables.itemTable[formula.seedItemId]
        local outcomeItemData = Tables.itemTable[formula.outcomeItemId]
        local args = {
            content = string.format(Language.LUA_SPACESHIP_ROOM_GROW_CABIN_CONTINUE_SOW_CONFIRM_FORMAT, outcomeItemData.name),
            subContent = string.format(Language.LUA_SPACESHIP_ROOM_GROW_CABIN_CONTINUE_SOW_CONFIRM_SUB_FORMAT, seedItemData.name, formula.seedItemCount),
            items = { { id = seedItemData.id, needCount = formula.seedItemCount, count = Utils.getItemCount(seedItemData.id) } },
            onConfirm = function()
                GameInstance.player.spaceship:GrowCabinSow(self.m_roomId, self.m_boxId, box.scdMsg.PreviewRecipeId)
            end,
        }
        self:_ShowPopUp(args)
    end
end
SSGrowCabinBoxInfo._OnCantBubbleBtnClick = HL.Method() << function(self)
    local spaceship = GameInstance.player.spaceship
    local boxes = spaceship:GetGrowCabinBoxes(self.m_roomId)
    local succ, box = boxes:TryGetValue(self.m_boxId)
    if succ then
        local formulaId = box.scdMsg.PreviewRecipeId
        local formula = Tables.spaceshipGrowCabinFormulaTable[formulaId]
        local seedItemData = Tables.itemTable[formula.seedItemId]
        local args = {
            content = string.format(Language.LUA_SPACESHIP_ROOM_GROW_CABIN_CONTINUE_SOW_TO_BREED_CONFIRM_FORMAT, seedItemData.name),
            items = { { id = seedItemData.id, needCount = formula.seedItemCount, count = Utils.getItemCount(seedItemData.id) } },
            onConfirm = function()
                self.m_ctrl:JumpToBreed(formulaId)
            end,
        }
        self:_ShowPopUp(args)
    end
end
SSGrowCabinBoxInfo.InitSSGrowCabinBoxInfo = HL.Method(HL.Userdata, HL.String, HL.Number, HL.Any, HL.Function) << function(self, ctrl, roomId, boxId, lineCell, onBtnAddClick)
    self:_FirstTimeInit()
    self.m_roomId = roomId
    self.m_boxId = boxId
    self.m_onBtnAddClick = onBtnAddClick
    self.m_ctrl = ctrl
    self.view.culture.gameObject:SetActiveIfNecessary(false)
    self.view.cultureCultivation.gameObject:SetActiveIfNecessary(false)
    self.view.locked.gameObject:SetActiveIfNecessary(false)
    self.view.btnAdd.gameObject:SetActiveIfNecessary(false)
    self:Refresh(lineCell)
end
SSGrowCabinBoxInfo.Refresh = HL.Method(HL.Any) << function(self, lineCell)
    local spaceship = GameInstance.player.spaceship
    local boxes = spaceship:GetGrowCabinBoxes(self.m_roomId)
    local boxProducing = spaceship:IsGrowCabinBoxStateProducing(self.m_roomId, self.m_boxId)
    lineCell.gameObject:SetActiveIfNecessary(boxProducing)
    if not self.m_ctrl.m_trainAudioPlayed and boxProducing then
        AudioManager.PostEvent("Au_UI_Event_GrowCabin_Train")
        self.m_ctrl.m_trainAudioPlayed = true
    end
    local succ, box = boxes:TryGetValue(self.m_boxId)
    if succ then
        local hasFormula = box.hasFormula
        local sustainable = box.sustainable
        self.view.btnAdd.gameObject:SetActiveIfNecessary(not hasFormula and not sustainable)
        self.view.cultureCultivation.gameObject:SetActiveIfNecessary(hasFormula)
        self.view.culture.gameObject:SetActiveIfNecessary(sustainable)
        if hasFormula then
            local cultureCultivation = self.view.cultureCultivation
            local canReceive = box.scdMsg.IsReady
            cultureCultivation.pauseNode.gameObject:SetActiveIfNecessary(not boxProducing)
            cultureCultivation.schedule.gameObject:SetActiveIfNecessary(not canReceive)
            cultureCultivation.timeNode.gameObject:SetActiveIfNecessary(not canReceive)
            cultureCultivation.cancelBtn.gameObject:SetActiveIfNecessary(not canReceive)
            cultureCultivation.canBeClaimed.gameObject:SetActiveIfNecessary(canReceive)
            cultureCultivation.deco.gameObject:SetActiveIfNecessary(canReceive)
            cultureCultivation.bgFrame.gameObject:SetActiveIfNecessary(canReceive)
            cultureCultivation.bgFrameGlow.gameObject:SetActiveIfNecessary(canReceive)
            local formula = Tables.spaceshipGrowCabinFormulaTable[box.scdMsg.RecipeId]
            local itemId = formula.outcomeItemId
            cultureCultivation.ccItem:InitItem({ id = itemId }, true)
            local haveCharSkill = spaceship:IsRoomAttrHaveCharSkill(self.m_roomId, formula.roomAttrType, false)
            cultureCultivation.accNode.gameObject:SetActiveIfNecessary(haveCharSkill)
            self:RefreshTimeSchedule()
        end
        if sustainable then
            local culture = self.view.culture
            local formula = Tables.spaceshipGrowCabinFormulaTable[box.scdMsg.PreviewRecipeId]
            local seedItemData = Tables.itemTable[formula.seedItemId]
            local outcomeItemData = Tables.itemTable[formula.outcomeItemId]
            local canBubble = Utils.getItemCount(formula.seedItemId) >= formula.seedItemCount
            culture.cItem:InitItem({ id = outcomeItemData.id, count = formula.outcomeItemCount })
            culture.bubble.gameObject:SetActiveIfNecessary(canBubble)
            culture.cantBubble.gameObject:SetActiveIfNecessary(not canBubble)
            local icon = self:LoadSprite(UIConst.UI_SPRITE_ITEM, seedItemData.iconId)
            culture.canIcon.sprite = icon
            culture.cantIcon.sprite = icon
        end
    else
        local unlockLevel = Tables.spaceshipGrowCabinBoxIdToUnlockLevelTable[self.m_boxId]
        self.view.unlockTxt.text = string.format(Language.LUA_SPACESHIP_ROOM_GROW_CABIN_BOX_UNLOCK_CONDITION_FORMAT, unlockLevel)
    end
    self.view.locked.gameObject:SetActiveIfNecessary(not succ)
    self.view.unlock.gameObject:SetActiveIfNecessary(succ)
end
SSGrowCabinBoxInfo.RefreshTimeSchedule = HL.Method() << function(self)
    local spaceship = GameInstance.player.spaceship
    local boxes = spaceship:GetGrowCabinBoxes(self.m_roomId)
    local succ, box = boxes:TryGetValue(self.m_boxId)
    if not succ or string.isEmpty(box.scdMsg.RecipeId) or box.scdMsg.IsReady then
        return
    end
    local boxProducing = spaceship:IsGrowCabinBoxStateProducing(self.m_roomId, self.m_boxId)
    local cultureCultivation = self.view.cultureCultivation
    local diffTime = boxProducing and DateTimeUtils.GetCurrentTimestampBySeconds() - box.lastSyncTime or 0
    local formula = Tables.spaceshipGrowCabinFormulaTable[box.scdMsg.RecipeId]
    local produceRate = spaceship:GetRoomProduceRate(self.m_roomId, formula.roomAttrType)
    local totalProgress = formula.totalProgress
    local curProgress = box.scdMsg.Progress + produceRate * diffTime
    cultureCultivation.schedule.fillAmount = curProgress / totalProgress
    cultureCultivation.timeTxt.text = UIUtils.getLeftTimeToSecondFull(math.max(totalProgress - curProgress, 0) / produceRate)
    cultureCultivation.pauseNode.gameObject:SetActive(spaceship:IsGrowCabinStateShutDown(self.m_roomId))
end
HL.Commit(SSGrowCabinBoxInfo)
return SSGrowCabinBoxInfo