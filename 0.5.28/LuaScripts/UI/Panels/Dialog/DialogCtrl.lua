local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Dialog
DialogCtrl = HL.Class('DialogCtrl', uiCtrl.UICtrl)
DialogCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.UI_DIALOG_TEXT_STOPPED] = 'OnDialogTextStopped', [MessageConst.ON_DIALOG_TRUNK_TEXT_FADE] = 'OnDialogTextFade', [MessageConst.ON_DIALOG_TRUNK_RADIO_FADE] = 'OnDialogRadioFade', [MessageConst.ON_DIALOG_CHANGE_CENTER_IMAGE] = 'OnDialogChangeCenterImage', [MessageConst.ON_DIALOG_DISABLE_CLICK_END] = 'OnDialogDisableClickEnd', [MessageConst.SWITCH_DIALOG_CAN_SKIP] = 'OnSwitchDialogCanSkip', [MessageConst.SWITCH_DIALOG_SHOW_LOG] = 'OnSwitchDialogShowLog', [MessageConst.ON_INPUT_DEVICE_TYPE_CHANGED] = '_OnInputDeviceChanged', [MessageConst.DIALOG_REFRESH_AUTO_MODE] = '_RefreshAutoMode', }
DialogCtrl.m_optionCells = HL.Field(HL.Forward("UIListCache"))
DialogCtrl.m_trunkNodeData = HL.Field(CS.Beyond.Gameplay.DTTrunkNodeData)
DialogCtrl.m_currSelectedOptionIndex = HL.Field(HL.Number) << 1
DialogCtrl.m_canSkip = HL.Field(HL.Boolean) << true
DialogCtrl.m_centerImageTween = HL.Field(HL.Userdata)
DialogCtrl.m_radioName = HL.Field(HL.String) << ""
DialogCtrl.m_curTrunkId = HL.Field(HL.String) << ""
DialogCtrl.m_clickCount = HL.Field(HL.Number) << 0
DialogCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_optionCells = UIUtils.genCellCache(self.view.panelOptionCell)
    self.view.buttonBack.onClick:RemoveAllListeners()
    self.view.buttonBack.onClick:AddListener(function()
        self:Notify(MessageConst.P_ON_COMMON_BACK_CLICKED)
    end)
    self.view.buttonNext.onClick:RemoveAllListeners()
    self.view.buttonNext.onClick:AddListener(function()
        self:OnBtnNextClick()
    end)
    self.view.buttonSkip.onClick:RemoveAllListeners()
    self.view.buttonSkip.onClick:AddListener(function()
        self:OnBtnSkipClick()
    end)
    self.view.buttonAuto.onClick:RemoveAllListeners()
    self.view.buttonAuto.onClick:AddListener(function()
        self:OnBtnAutoClick()
    end)
    self.view.buttonLog.onClick:RemoveAllListeners()
    self.view.buttonLog.onClick:AddListener(function()
        self:Notify(MessageConst.P_OPEN_DIALOG_RECORD)
    end)
    self.view.buttonStop.onClick:RemoveAllListeners()
    self.view.buttonStop.onClick:AddListener(function()
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_FEATURE_NOT_AVAILABLE)
    end)
    self:_InitDialogController()
end
DialogCtrl.OnShow = HL.Override() << function(self)
    self:_RefreshCanSkip()
    self:_RefreshAutoMode()
    self:OnDialogTextFade({ 0, 0 })
    self.view.debugNode.gameObject:SetActive(false)
    if NarrativeUtils.ShouldShowNarrativeDebugNode() then
        self.view.debugNode.gameObject:SetActive(true)
        self.view.textDialogId.text = GameInstance.world.dialogManager.dialogId
    end
end
DialogCtrl._CheckTextPlaying = HL.Method().Return(HL.Boolean) << function(self)
    if self.view.textTalk.gameObject.activeInHierarchy and self.view.textTalk.playing then
        return true
    end
    if self.view.textTalkCenter.gameObject.activeInHierarchy and self.view.textTalkCenter.playing then
        return true
    end
    return false
end
DialogCtrl.OnBtnNextClick = HL.Method() << function(self)
    self.m_clickCount = self.m_clickCount + 1
    if self:_CheckTextPlaying() then
        self.view.textTalk:SeekToEnd()
        self.view.textTalkCenter:SeekToEnd()
    else
        self:_UpdateClickRecord()
        GameInstance.world.dialogManager:Next()
    end
end
DialogCtrl.OnDialogTextStopped = HL.Method() << function(self)
    self.view.optionList.gameObject:SetActive(true)
    local showWait = self.m_optionCells:GetCount() <= 0
    self:_TrySetWaitNode(showWait)
end
DialogCtrl.OnDialogDisableClickEnd = HL.Method() << function(self)
    local showWait = self.m_optionCells:GetCount() <= 0
    self:_TrySetWaitNode(showWait)
end
DialogCtrl.OnDialogTextFade = HL.Method(HL.Table) << function(self, arg)
    local duration, alpha = unpack(arg)
    self:_UpdateClickRecord()
    self.m_clickCount = 0
    self.m_curTrunkId = GameInstance.world.dialogManager.trunkId
    self.view.bottomLayout:DOKill()
    self.view.bottomLayout:DOFade(alpha, duration)
    if self.view.textTalkCenterNode.gameObject.activeSelf then
        self.view.textTalkCenterNode:DOKill()
        self.view.textTalkCenterNode:DOFade(alpha, duration)
    end
end
DialogCtrl.OnDialogRadioFade = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    local radioNode = self.view.radioNode
    if radioNode.gameObject.activeSelf then
        radioNode:PlayOutAnimation(function()
            radioNode.gameObject:SetActive(false)
        end)
    end
end
DialogCtrl._ClearCenterImageTween = HL.Method() << function(self)
    if self.m_centerImageTween then
        self.m_centerImageTween:Kill()
        self.m_centerImageTween = nil
    end
end
DialogCtrl.OnDialogChangeCenterImage = HL.Method(HL.Table) << function(self, data)
    local enable, sprite = unpack(data)
    self:_ClearCenterImageTween()
    if enable then
        self.view.bgBlack.gameObject:SetActive(true)
        self.view.bgBlack.alpha = 0
        local finalSprite = self:_GetRealSprite("", sprite)
        self.view.itemImage.sprite = self:LoadSprite(finalSprite)
        self.m_centerImageTween = self.view.bgBlack:DOFade(1, 0.3)
        self.m_centerImageTween:OnComplete(function()
            self:_ClearCenterImageTween()
        end)
    else
        self.m_centerImageTween = self.view.bgBlack:DOFade(0, 0.3)
        self.m_centerImageTween:OnComplete(function()
            self:_ClearCenterImageTween()
            self.view.bgBlack.gameObject:SetActive(false)
        end)
    end
end
DialogCtrl.OnSwitchDialogCanSkip = HL.Method(HL.Table) << function(self, arg)
    self:_RefreshCanSkip()
end
DialogCtrl.OnSwitchDialogShowLog = HL.Method(HL.Table) << function(self, arg)
    local show = unpack(arg)
    self.view.buttonLog.gameObject:SetActive(show)
end
DialogCtrl._RefreshCanSkip = HL.Method() << function(self)
    self.m_canSkip = GameInstance.world.dialogManager.canSkip
    self.view.buttonSkip.gameObject:SetActive(self.m_canSkip)
end
DialogCtrl._RefreshAutoMode = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self.view.textAuto.gameObject:SetActive(GameInstance.world.dialogManager.autoMode)
    self:_SwitchControllerAutoPlayHint()
end
DialogCtrl._TrySetWaitNode = HL.Method(HL.Boolean) << function(self, active)
    if active then
        local disableClick = GameInstance.world.dialogManager.disableClick
        local playing = self.view.textTalk.playing and self.view.textTalkCenter.playing
        local canShowWait = not disableClick and not playing
        self.view.waitNode.gameObject:SetActive(canShowWait)
        self.view.centerWaitNode.gameObject:SetActive(canShowWait)
    else
        self.view.waitNode.gameObject:SetActive(active)
        self.view.centerWaitNode.gameObject:SetActive(active)
    end
end
DialogCtrl.OnOptionClick = HL.Method(HL.Number) << function(self, index)
    GameInstance.world.dialogManager:SelectIndex(CSIndex(index))
end
DialogCtrl.OnBtnSkipClick = HL.Method() << function(self)
    self:Notify(MessageConst.P_OPEN_DIALOG_SKIP_POP_UP)
end
DialogCtrl.OnBtnAutoClick = HL.Method() << function(self)
    local auto = not GameInstance.world.dialogManager.autoMode
    GameInstance.world.dialogManager:SetAutoMode(auto)
    self:_RefreshAutoMode()
end
DialogCtrl._CloseAutoMode = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self.view.textAuto.gameObject:SetActive(false)
    GameInstance.world.dialogManager:SetAutoMode(false)
    self:_SwitchControllerAutoPlayHint()
end
DialogCtrl.OnClose = HL.Override() << function(self)
    self.view.bgSprite:DOKill()
    self.view.bgBlack:DOKill()
    self.view.bottomLayout:DOKill()
    self.view.textTalkCenterNode:DOKill()
    self.view.buttonBack.onClick:RemoveAllListeners()
    self.view.buttonNext.onClick:RemoveAllListeners()
    self.view.buttonSkip.onClick:RemoveAllListeners()
    self.view.buttonAuto.onClick:RemoveAllListeners()
end
DialogCtrl.SetTrunk = HL.Method(HL.Userdata, HL.Opt(HL.Boolean, HL.Any, HL.Any)) << function(self, trunkNodeData, fastMode, npcId, npcGroupId)
    self.m_trunkNodeData = trunkNodeData
    local hideBg = trunkNodeData.hideBg
    local bgSprite = self:_GetRealSprite(UIConst.UI_SPRITE_DIALOG_BG, trunkNodeData.bgSprite or "")
    local trunkId = trunkNodeData.overrideTrunkId
    if string.isEmpty(trunkId) then
        trunkId = trunkNodeData.trunkId
    end
    self:_UpdateClickRecord()
    self.m_curTrunkId = trunkId
    local name = ""
    local hint
    local hideHint = false
    local dialogText = ""
    local res, trunkTbData = Tables.dialogTextTable:TryGetValue(trunkId)
    if res then
        if not string.isEmpty(trunkTbData.actorName) then
            name = trunkTbData.actorName
        end
        hint = trunkTbData.hint
        hideHint = trunkTbData.hideHint
        dialogText = trunkTbData.dialogText
    end
    local text = UIUtils.resolveTextCinematic(dialogText)
    local singleTrunk = string.isEmpty(name)
    self.view.bottomLayout:DOKill()
    self.view.bottomLayout.alpha = 1
    self.view.textTalkCenterNode.alpha = 1
    self.view.textTalkCenterNode.gameObject:SetActive(singleTrunk)
    self.view.bottomLayout.gameObject:SetActive(not singleTrunk)
    self.view.imageBG.gameObject:SetActive(not hideBg)
    if singleTrunk then
        self.view.textTalkCenter:SetText(text)
        if fastMode then
            self.view.textTalkCenter:SeekToEnd()
        else
            self.view.textTalkCenter:Play()
        end
    else
        local richName = UIUtils.resolveTextCinematic(name)
        self.view.textName.text = UIUtils.removePattern(richName, UIConst.NARRATIVE_ANONYMITY_PATTERN)
        self.view.textName.gameObject:SetActive(true)
        local title = ""
        if npcGroupId then
            local hasNpc, npcGroupData = Tables.npcGroupTable:TryGetValue(npcGroupId)
            if hasNpc then
                title = npcGroupData.title
            end
        end
        if npcId then
            local hasNpc, npcData = CS.Beyond.Gameplay.Core.NpcManager.TryGetValue(npcId)
            if hasNpc then
                title = npcData.title
            end
        end
        if not string.isEmpty(hint) then
            title = hint
        end
        self.view.textHint.text = UIUtils.resolveTextStyle(title)
        self.view.textHint.gameObject:SetActive(not hideHint)
        self.view.textTalk:SetText(text)
        if fastMode or not self:IsShow() then
            self.view.textTalk:SeekToEnd()
        else
            self.view.textTalk:Play()
        end
    end
    if not string.isEmpty(bgSprite) then
        self.view.bgSprite.sprite = self:LoadSprite(UIConst.UI_SPRITE_DIALOG_BG, bgSprite)
        self.view.bgSprite.gameObject:SetActive(true)
    else
        self.view.bgSprite.gameObject:SetActive(false)
    end
    local useRadio = trunkNodeData.useRadio
    local radioNode = self.view.radioNode
    if useRadio then
        radioNode.gameObject:SetActive(useRadio)
        local charSpriteName
        if not string.isEmpty(trunkNodeData.radioIcon) then
            charSpriteName = trunkNodeData.radioIcon
        else
            local entity = GameInstance.world.dialogManager:GetEntity(trunkNodeData.actorIndex)
            local charId = entity.templateData.id
            charSpriteName = UIConst.UI_CHAR_HEAD_SQUARE_PREFIX .. charId
        end
        self.view.charImage.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD_RECTANGLE, charSpriteName)
        self.view.blueMask.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD_RECTANGLE, charSpriteName)
        local radioName
        if not string.isEmpty(trunkNodeData.radioNameId) then
            radioName = Language.trunkNodeData.radioNameId
        else
            radioName = name
        end
        if radioName ~= self.m_radioName then
            radioNode:ClearTween(false)
            radioNode:PlayInAnimation()
        end
        self.m_radioName = radioName
    else
        if radioNode.gameObject.activeSelf then
            radioNode:ClearTween(false)
            radioNode:PlayOutAnimation(function()
                radioNode.gameObject:SetActive(useRadio)
            end)
        end
        self.m_radioName = ""
    end
    self.view.textDes.gameObject:SetActive(false)
    self:SetCtrlButtonVisible(true)
    self:_TrySetWaitNode(false)
    self:_RefreshCanSkip()
end
DialogCtrl._UpdateClickRecord = HL.Method() << function(self)
    GameInstance.world.dialogManager:UpdateClickRecord(self.m_curTrunkId, self.m_clickCount)
    self.m_clickCount = 0
end
DialogCtrl.RefreshTrunk = HL.Method() << function(self)
    self.view.textTalk:RefreshText()
    self.view.textTalk:Play()
    self.view.textTalkCenter:RefreshText()
    self.view.textTalkCenter:Play()
end
DialogCtrl.SetTrunkOption = HL.Method(HL.Userdata) << function(self, optionData)
    if self:IsHide() then
        self:Show()
        self.view.textTalkCenterNode.gameObject:SetActive(false)
        self.view.radioNode.gameObject:SetActive(false)
        self.view.bottomLayout.gameObject:SetActive(false)
    end
    local count = optionData.Count
    if count == 0 then
        self:_DisableDialogControllerOption()
        self.m_optionCells:PlayAllOut()
        self:_SwitchFriendshipShow(false)
    else
        self.m_optionCells:ClearAllTween(false)
        self.m_optionCells:Refresh(count, function(cell, luaIndex)
            local option = optionData[CSIndex(luaIndex)]
            local data = { optionId = option.optionId, index = luaIndex, text = UIUtils.resolveTextStyle(option.optionText or ""), iconType = option.iconType, icon = option.optionIcon, color = option.useExOptionColor and option.optionIconColor or nil, }
            cell:InitDialogOptionCell(data, function()
                self:OnOptionClick(luaIndex)
            end)
            cell.view.animationWrapper:PlayInAnimation()
        end)
        self:_EnableDialogControllerOption()
        local workFriendship = GameInstance.world.dialogManager.showSpaceshipCharFriendship
        self:_SwitchFriendshipShow(workFriendship)
    end
    self.view.optionList.gameObject:SetActive(true)
    self:_RefreshCanSkip()
    local showWait = count <= 0
    self:_TrySetWaitNode(showWait)
end
DialogCtrl.GetTouchPanel = HL.Method().Return(CS.Beyond.UI.UITouchPanel) << function(self)
    return self.view.touchPanel
end
DialogCtrl._GetRealSprite = HL.Method(HL.String, HL.String).Return(HL.String) << function(self, folder, spriteName)
    local gender = Utils.getPlayerGender()
    local finalSprite = spriteName
    if gender == CS.Proto.GENDER.GenMale then
        local subName = finalSprite
        if string.endWith(spriteName, UIConst.DIALOG_IMAGE_FEMALE_SUFFIX) then
            subName = string.sub(spriteName, 0, string.len(spriteName) - 2)
        end
        local maleSpriteName = subName .. UIConst.DIALOG_IMAGE_MALE_SUFFIX
        local maleSpritePath = maleSpriteName
        if not string.isEmpty(folder) then
            maleSpritePath = UIUtils.getSpritePath(folder, maleSpriteName)
        else
            maleSpritePath = UIUtils.getSpritePath(maleSpriteName)
        end
        local res = ResourceManager.CheckExists(maleSpritePath)
        if res then
            finalSprite = maleSpriteName
        end
    end
    return finalSprite
end
DialogCtrl.SetFullBg = HL.Method(CS.Beyond.Gameplay.DialogFullBgActionData) << function(self, actionData)
    local bgSprite = self:_GetRealSprite(UIConst.UI_SPRITE_DIALOG_BG, actionData.bgSprite)
    local textId = actionData.textId
    local pos = actionData.pos
    local alpha = actionData.alpha
    local duration = actionData.duration
    local useCurve = actionData.useCurve
    local curve = actionData.curve
    self.view.bgSprite:DOKill()
    if not string.isEmpty(bgSprite) then
        self.view.bgSprite.sprite = self:LoadSprite(UIConst.UI_SPRITE_DIALOG_BG, bgSprite)
        self.view.bgSprite.gameObject:SetActive(true)
        UIUtils.changeAlpha(self.view.bgSprite, 1 - alpha)
        local tween = self.view.bgSprite:DOFade(alpha, duration)
        if useCurve and curve then
            tween:SetEase(curve)
        end
    else
        self.view.bgSprite.gameObject:SetActive(false)
    end
    if string.isEmpty(textId) then
        self.view.textDes.gameObject:SetActive(false)
    else
        self.view.textDes.gameObject:SetActive(true)
        self.view.textDes.text = UIUtils.resolveTextStyle(Language[textId])
        self.view.textDes.transform.localPosition = pos
        self.view.textDes.transform.localPosition = pos
    end
    self.view.imageBG.gameObject:SetActive(false)
    self.view.optionList.gameObject:SetActive(false)
    self.view.bottomLayout.gameObject:SetActive(false)
    self.view.textTalkCenterNode.gameObject:SetActive(false)
    self.view.radioNode.gameObject:SetActive(false)
    self:SetCtrlButtonVisible(false)
end
DialogCtrl.SetCtrlButtonVisible = HL.Method(HL.Boolean) << function(self, visible)
    self.view.topRight.gameObject:SetActive(visible)
    self.view.topLeft.gameObject:SetActive(visible)
    self.view.top.gameObject:SetActive(visible)
end
DialogCtrl.m_controllerOptionGroupId = HL.Field(HL.Number) << 1
DialogCtrl._OnInputDeviceChanged = HL.Method(HL.Any) << function(self, arg)
    local type = unpack(arg)
    if not type then
        return
    end
    if type == DeviceInfo.InputType.Controller then
        self:_EnableDialogControllerOption()
    else
        self:_DisableDialogControllerOption()
    end
    UIManager:CalcOtherSystemPropertyByPanelOrder()
end
DialogCtrl._InitDialogController = HL.Method() << function(self)
    self:_SwitchControllerAutoPlayHint()
    self.m_controllerOptionGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
    UIUtils.bindInputPlayerAction("dialog_select_option_up", function()
        self:_RefreshDialogControllerSelectedOption(self.m_currSelectedOptionIndex - 1)
    end, self.m_controllerOptionGroupId)
    UIUtils.bindInputPlayerAction("dialog_select_option_down", function()
        self:_RefreshDialogControllerSelectedOption(self.m_currSelectedOptionIndex + 1)
    end, self.m_controllerOptionGroupId)
    UIUtils.bindInputPlayerAction("dialog_select_option", function()
        local optionCell = self.m_optionCells:GetItem(self.m_currSelectedOptionIndex)
        if optionCell ~= nil and optionCell.optionOnClickFunc ~= nil then
            optionCell.optionOnClickFunc()
        end
    end, self.m_controllerOptionGroupId)
    InputManagerInst:ToggleGroup(self.m_controllerOptionGroupId, false)
end
DialogCtrl._EnableDialogControllerOption = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    local optionCount = self.m_optionCells:GetCount()
    if optionCount == 0 then
        return
    end
    InputManagerInst:ToggleGroup(self.m_controllerOptionGroupId, true)
    self:_RefreshDialogControllerSelectedOption(1)
end
DialogCtrl._DisableDialogControllerOption = HL.Method() << function(self)
    InputManagerInst:ToggleGroup(self.m_controllerOptionGroupId, false)
    self:_RefreshDialogControllerSelectedOption(0, true)
end
DialogCtrl._RefreshDialogControllerSelectedOption = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, selectedIndex, forceRefresh)
    local optionCount = self.m_optionCells:GetCount()
    if optionCount == 0 then
        return
    end
    if forceRefresh then
        self.m_currSelectedOptionIndex = selectedIndex
    else
        self.m_currSelectedOptionIndex = math.max(1, selectedIndex)
        self.m_currSelectedOptionIndex = math.min(optionCount, self.m_currSelectedOptionIndex)
    end
    for index = 1, optionCount do
        local optionCell = self.m_optionCells:GetItem(index)
        if optionCell then
            optionCell:RefreshDialogOptionSelectedState(index == self.m_currSelectedOptionIndex)
        end
    end
end
DialogCtrl._SwitchControllerAutoPlayHint = HL.Method() << function(self)
    local onAutoPlay = GameInstance.world.dialogManager.autoMode
    self.view.controllerHint.skipHint.gameObject:SetActiveIfNecessary(not onAutoPlay)
    self.view.controllerHint.skipHintLoop.gameObject:SetActiveIfNecessary(onAutoPlay)
end
DialogCtrl._SwitchFriendshipShow = HL.Method(HL.Boolean) << function(self, visible)
    local charId = GameInstance.world.dialogManager.spaceshipCharId
    local realVisible = visible and not string.isEmpty(charId)
    local cellGO = self.view.friendshipRight.reliabilityCell.gameObject
    local lastVisible = cellGO.activeSelf
    if realVisible then
        self.view.friendshipRight.gameObject:SetActive(realVisible)
        cellGO:SetActive(realVisible)
        if not lastVisible then
            AudioAdapter.PostEvent("Au_UI_Popup_ReliabilithCell_Open")
        end
        self.view.friendshipRight.reliabilityCell:InitReliabilityCell(charId)
    else
        self.view.friendshipRight.animationWrapper:PlayOutAnimation(function()
            cellGO:SetActive(realVisible)
            if lastVisible then
                AudioAdapter.PostEvent("Au_UI_Popup_ReliabilithCell_Close")
            end
        end)
    end
end
DialogCtrl.ShowPresentSuccess = HL.Method(HL.Boolean, HL.Number, HL.Table) << function(self, levelChanged, deltaFav, selectedItems)
    self.view.friendshipRight.reliabilityCell:ShowPresentSuccessTips(levelChanged, deltaFav, selectedItems)
    local workFriendship = GameInstance.world.dialogManager.showSpaceshipCharFriendship
    self:_SwitchFriendshipShow(workFriendship)
end
DialogCtrl._RefreshRestCell = HL.Method(HL.String) << function(self, charId)
    local restCell = self.view.friendshipRight.restCell
    local roomId, isWorking = CSPlayerDataUtil.GetCharRoomId(charId)
    local maxStamina = Tables.spaceshipConst.maxPhysicalStrength
    local curStamina = CSPlayerDataUtil.GetCharCharCurStamina(charId)
    local percent = curStamina / maxStamina
    if isWorking then
        restCell.textRest.text = Language.LUA_SPACESHIP_CHAR_WORKING
    elseif string.isEmpty(roomId) then
        if percent >= 1 then
            restCell.textRest.text = Language.LUA_SPACESHIP_CHAR_HANGING
        else
            restCell.textRest.text = Language.LUA_SPACESHIP_CHAR_RESTING
        end
    else
        restCell.textRest.text = Language.LUA_SPACESHIP_CHAR_RESTING
    end
    restCell.slider.value = percent
    restCell.textStamina.text = tostring(lume.round(percent * 100)) .. "%"
    if string.isEmpty(roomId) then
        restCell.textRoom.text = Language.LUA_SPACESHIP_HALL_NAME
    else
        local res, data = Tables.spaceshipRoomInsTable:TryGetValue(roomId)
        restCell.textRoom.text = data.name
    end
end
HL.Commit(DialogCtrl)