local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharFormation
local BTN_ANIM_NAME = { BTN_FORMATION_MIXCONFIRM_IN = "btn_formation_mixconfirm_in", BTN_FORMATION_MIXCONFIRM_OUT = "btn_formation_mixconfirm_out", BTN_FORMATION_REMOV_IN = "btn_formation_remov_in", BTN_FORMATION_REMOV_OUT = "btn_formation_remov_out", BTN_EMPTY_IN = "btn_empty_in", BTN_EMPTY_OUT = "btn_empty_out", }
CharFormationCtrl = HL.Class('CharFormationCtrl', uiCtrl.UICtrl)
CharFormationCtrl.s_messages = HL.StaticField(HL.Table) << {}
CharFormationCtrl.m_teamCells = HL.Field(HL.Forward("UIListCache"))
CharFormationCtrl.m_curTeamIndex = HL.Field(HL.Number) << -1
CharFormationCtrl.m_teamSet = HL.Field(HL.Number) << -1
CharFormationCtrl.preState = HL.Field(HL.Number) << -1
CharFormationCtrl.state = HL.Field(HL.Number) << -1
CharFormationCtrl.singleState = HL.Field(HL.Number) << -1
CharFormationCtrl.m_index2Char = HL.Field(HL.Table)
CharFormationCtrl.m_singleCharIndex = HL.Field(HL.Number) << -1
CharFormationCtrl.m_singleCharInfo = HL.Field(HL.Table)
CharFormationCtrl.m_genStars = HL.Field(HL.Forward('UIListCache'))
CharFormationCtrl.m_empty = HL.Field(HL.Boolean) << false
CharFormationCtrl.m_dungeonId = HL.Field(HL.Any)
CharFormationCtrl.m_racingDungeonArg = HL.Field(HL.Table)
CharFormationCtrl.m_curHoverIndex = HL.Field(HL.Number) << 1
CharFormationCtrl.m_navigationGroupId = HL.Field(HL.Number) << -1
CharFormationCtrl.m_exGroupId = HL.Field(HL.Number) << -1
CharFormationCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self:_ProcessArgs(args)
end
CharFormationCtrl.OnPhaseRefresh = HL.Override(HL.Any) << function(self, args)
    self:_ProcessArgs(args)
end
CharFormationCtrl.OnShow = HL.Override() << function(self)
    AudioAdapter.PostEvent("au_ui_menu_formation_open")
    if self.m_singleCharInfo then
        self:RefreshCharInformation(self.m_singleCharInfo)
    end
end
CharFormationCtrl.OnHide = HL.Override() << function(self)
    AudioAdapter.PostEvent("au_ui_menu_formation_close")
end
CharFormationCtrl.OnClose = HL.Override() << function(self)
    AudioAdapter.PostEvent("au_ui_menu_formation_close")
end
CharFormationCtrl._OnChangeTeamNameClicked = HL.Method() << function(self)
    local team = GameInstance.player.charBag.teamList[CSIndex(self.m_curTeamIndex)]
    local name = team.name
    if string.isEmpty(name) then
        name = Language[string.format("LUA_TEAM_NUM_%d", self.m_curTeamIndex)]
    end
    Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_CHANGE_TEAM_NAME,
        input = true,
        inputName = name,
        onConfirm = function(changedName)
            GameInstance.player.squadManager:SendChangeSquadName(CSIndex(self.m_curTeamIndex), changedName)
        end
    })
end
CharFormationCtrl._OnCharInfoClicked = HL.Method(HL.Table) << function(self, charInfo)
    local isShowFixed, isShowTrail = CharInfoUtils.getLockedFormationCharTipsShow(charInfo)
    CharInfoUtils.openCharInfoBestWay({ initCharInfo = { instId = charInfo.charInstId, templateId = charInfo.charId, isSingleChar = true, isTrail = true, isShowFixed = isShowFixed, isShowTrail = isShowTrail, }, forceSkipIn = true, })
end
CharFormationCtrl.InitSelectTeam = HL.Method() << function(self)
    local curSquadIndex = GameInstance.player.squadManager.curSquadIndex
    self.m_teamSet = LuaIndex(curSquadIndex)
    self:_SetTeamSelect(self.m_teamSet)
    self.view.infoNoe.gameObject:SetActive(not self.m_isFormationLocked)
end
CharFormationCtrl.UpdateTeamSet = HL.Method() << function(self)
    self.m_teamSet = LuaIndex(GameInstance.player.squadManager.curSquadIndex)
    if self.m_curTeamIndex == self.m_teamSet then
        self:SetState(UIConst.UI_CHAR_FORMATION_STATE.TeamHasSet)
    else
        self:SetState(UIConst.UI_CHAR_FORMATION_STATE.TeamWaitSet)
    end
end
CharFormationCtrl.SetSingleCharIndex = HL.Method(HL.Number) << function(self, index)
    self.m_singleCharIndex = index
    local charInfo = self.m_index2Char[index]
    self:RefreshCharInformation(charInfo)
end
CharFormationCtrl.RefreshTeamCharInfo = HL.Method(HL.Table) << function(self, team)
    local index = 1
    if team ~= nil then
        for _, teamChar in pairs(team.slots) do
            self:UpdateChar(index, teamChar)
            index = index + 1
        end
    end
    for i = index, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
        self:UpdateChar(i, nil)
    end
end
CharFormationCtrl.UpdateChar = HL.Method(HL.Number, HL.Table) << function(self, index, charInfo)
    self:Notify(MessageConst.P_ON_CHAR_FORMATION_REFRESH_SLOT, { index, charInfo })
    self.m_index2Char[index] = charInfo
end
CharFormationCtrl.SetState = HL.Method(HL.Number) << function(self, state)
    local needRefresh = self.state ~= state
    local isTeamFullLocked = self.m_lockedTeamData and not self.m_lockedTeamData.hasReplaceable and self.m_lockedTeamData.lockedTeamMemberCount == self.m_lockedTeamData.maxTeamMemberCount
    local showFormation = state == UIConst.UI_CHAR_FORMATION_STATE.TeamWaitSet or state == UIConst.UI_CHAR_FORMATION_STATE.TeamHasSet
    self.view.btnFormation.gameObject:SetActive(showFormation and not isTeamFullLocked)
    local showMixConfirm = state == UIConst.UI_CHAR_FORMATION_STATE.CharChange
    self.view.btnMixConfirm.gameObject:SetActive(showMixConfirm)
    if self.m_dungeonId then
        self.view.btnConfirm.text = Language.LUA_CHAR_FORMATION_ENTER_DUNGEON
        self.view.btnConfirm.interactable = true
    elseif self.m_racingDungeonArg then
        self.view.btnConfirm.text = Language.LUA_CHAR_FORMATION_ENTER_DUNGEON
        self.view.btnConfirm.interactable = true
    else
        if self.m_curTeamIndex ~= self.m_teamSet then
            self.view.btnConfirm.text = Language.LUA_CHAR_FORMATION_TEAM_CONFIRM
            self.view.btnConfirm.interactable = true
        else
            self.view.btnConfirm.text = Language.LUA_CHAR_FORMATION_TEAM_CONFIRMED
            self.view.btnConfirm.interactable = false
        end
        self:RefreshControllerHint()
    end
    self.view.btnConfirm.gameObject:SetActive(showFormation)
    local showSingle = state == UIConst.UI_CHAR_FORMATION_STATE.SingleChar
    self.view.btnSoloConfirm.gameObject:SetActive(showSingle)
    local singleState = UIConst.UI_CHAR_FORMATION_SINGLE_STATE.None
    if needRefresh then
        if showSingle then
            singleState = UIConst.UI_CHAR_FORMATION_SINGLE_STATE.Current
            if self.m_isFormationLocked and self.m_singleCharIndex <= self.m_lockedTeamData.lockedTeamMemberCount then
                singleState = UIConst.UI_CHAR_FORMATION_SINGLE_STATE.CurrentLocked
            end
        else
            singleState = UIConst.UI_CHAR_FORMATION_SINGLE_STATE.None
        end
    end
    self:_PlayBtnMultiAnim(state)
    self:RefreshSingleBtns(singleState, self.m_singleCharInfo)
    local leftRightVisible = state == UIConst.UI_CHAR_FORMATION_STATE.TeamWaitSet or state == UIConst.UI_CHAR_FORMATION_STATE.TeamHasSet
    self:_RefreshLeftRightBtns(leftRightVisible and not self.m_lockedTeamData)
    local back = state == UIConst.UI_CHAR_FORMATION_STATE.CharChange or state == UIConst.UI_CHAR_FORMATION_STATE.SingleChar
    self.view.btnClose.gameObject:SetActive(not back)
    self.view.btnBack.gameObject:SetActive(back)
    self.view.btnBackTouch.gameObject:SetActive(showMixConfirm)
    if back then
        self:_ClearNavigation()
    else
        self:_InitNavigation()
    end
    self.preState = self.state
    self.state = state
end
CharFormationCtrl.RefreshSingleBtns = HL.Method(HL.Number, HL.Table) << function(self, singleState, charInfo)
    self:_PlayBtnSingleAnim(singleState)
    self.singleState = singleState
    if singleState == UIConst.UI_CHAR_FORMATION_SINGLE_STATE.None then
        self.view.btnSoloConfirm.gameObject:SetActive(false)
        self.view.btnRemove.gameObject:SetActive(false)
        self.view.btnCannotReplace.gameObject:SetActive(false)
        return
    end
    local showRemove = singleState == UIConst.UI_CHAR_FORMATION_SINGLE_STATE.Current
    local otherDead = singleState == UIConst.UI_CHAR_FORMATION_SINGLE_STATE.OtherDead
    local currentLocked = singleState == UIConst.UI_CHAR_FORMATION_SINGLE_STATE.CurrentLocked
    local interactable = singleState ~= UIConst.UI_CHAR_FORMATION_SINGLE_STATE.OtherInTeam and singleState ~= UIConst.UI_CHAR_FORMATION_SINGLE_STATE.OtherInTeamLocked and singleState ~= UIConst.UI_CHAR_FORMATION_SINGLE_STATE.OtherUnavailable and not otherDead
    local text
    if otherDead then
        text = Language.ui_bat_action_exit
    elseif interactable then
        text = Language.LUA_CHAR_FORMATION_SINGLE_CONFIRM
    else
        text = Language.LUA_CHAR_FORMATION_SINGLE_CONFIRMED
    end
    self.view.btnSoloConfirm.interactable = interactable
    self.view.btnSoloConfirm.text = text
    self.view.btnSoloConfirm.gameObject:SetActive(not showRemove and not currentLocked)
    self.view.btnRemove.gameObject:SetActive(showRemove)
    self.view.btnCannotReplace.gameObject:SetActive(currentLocked)
    if currentLocked then
        local isFixed = charInfo and charInfo.isLocked and not charInfo.isReplaceable
        self.view.txtCannotReplace.text = isFixed and Language.LUA_TEAM_FORMATION_CHAR_CANNOT_CHANGE or Language.LUA_TEAM_FORMATION_CHAR_CANNOT_LEAVE
    end
end
CharFormationCtrl.RefreshEmpty = HL.Method(HL.Boolean) << function(self, empty)
    if self.m_empty == empty then
        return
    end
    self.view.btnFomationNode.gameObject:SetActive(not empty)
    self.view.btnMixConfirmNode.gameObject:SetActive(not empty)
    self.view.btnRemovNode.gameObject:SetActive(not empty)
    self.view.btnNode:ClearTween()
    if empty then
        self.view.emptyNode.gameObject:SetActive(empty)
        self.view.btnNode:PlayWithTween(BTN_ANIM_NAME.BTN_EMPTY_IN)
    else
        self.view.btnNode:PlayWithTween(BTN_ANIM_NAME.BTN_EMPTY_OUT, function()
            self.view.emptyNode.gameObject:SetActive(empty)
        end)
    end
    self.m_empty = empty
end
CharFormationCtrl.RefreshTeamName = HL.Method(HL.Opt(HL.String)) << function(self, name)
    if string.isEmpty(name) and not self.m_isFormationLocked then
        local team = GameInstance.player.charBag.teamList[CSIndex(self.m_curTeamIndex)]
        name = team.name
    end
    if string.isEmpty(name) or self.m_isFormationLocked then
        name = Language[string.format("LUA_TEAM_NUM_%d", self.m_curTeamIndex)]
    end
    self.view.textName.text = name
end
CharFormationCtrl.SetExGroupId = HL.Method(HL.Number) << function(self, groupId)
    self.m_exGroupId = groupId
end
CharFormationCtrl.RefreshControllerHint = HL.Method() << function(self)
    local groupIds = { self.view.inputGroup.groupId }
    if self.m_exGroupId and self.m_exGroupId > 0 then
        table.insert(groupIds, self.m_exGroupId)
    end
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder(groupIds, nil, function(infoList)
        if self.view.btnConfirm.interactable or not self.view.btnConfirm.gameObject.activeInHierarchy then
            return
        end
        table.insert(infoList, #infoList, { actionId = self.view.btnConfirm.bindingViewActionId, hintView = self.view.btnConfirm, })
    end)
end
CharFormationCtrl.RefreshCharInformation = HL.Method(HL.Table, HL.Opt(HL.Table)) << function(self, charInfo, selectTable)
    local needRefresh = false
    if self.m_singleCharInfo and charInfo and self.m_singleCharInfo.charInstId ~= charInfo.charInstId then
        needRefresh = true
    end
    self.m_singleCharInfo = charInfo
    if charInfo then
        self:_SetSlotCharInfo(self.view.charInformation, charInfo)
        self.view.charInformation.charSkillNode:InitCharSkillNodeNew(charInfo.charInstId, true, true, self.view.charInformation.skillTipsNode, UIConst.UI_TIPS_POS_TYPE.LeftTop)
        self.view.charInformation.charPassiveSkillNode:InitCharPassiveSkillNode(charInfo.charInstId, true, true, self.view.charInformation.passiveSkillTipsNode, UIConst.UI_TIPS_POS_TYPE.LeftTop)
        local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInfo.charInstId)
        local dungeonId = self.m_dungeonId
        if string.isEmpty(dungeonId) and self.m_racingDungeonArg then
            dungeonId = self.m_racingDungeonArg.dungeonId
        end
        local tacticalItemArgs = { itemId = charInst.tacticalItemId, isLocked = charInfo.isTrail, isForbidden = not string.isEmpty(dungeonId) and UIUtils.isItemTypeForbidden(dungeonId, GEnums.ItemType.TacticalItem), isClickable = true, charTemplateId = charInfo.charId, charInstId = charInfo.charInstId, tipNode = self.view.charInformation.tacticalItemTipsNode, tipPosType = UIConst.UI_TIPS_POS_TYPE.LeftTop, }
        self.view.charInformation.charFormationTacticalItem:InitCharFormationTacticalItem(tacticalItemArgs)
        self.view.charInformation.gameObject:SetActive(true)
        if needRefresh then
            self.view.charInformation.animationWrapper:PlayInAnimation()
        end
    else
        if self.view.charInformation.gameObject.activeSelf then
            self.view.charInformation.animationWrapper:PlayOutAnimation(function()
                self.view.charInformation.gameObject:SetActive(false)
            end)
        end
    end
    local starNum = 0
    if charInfo then
        local characterTable = Tables.characterTable
        local data = characterTable:GetValue(charInfo.charId)
        starNum = data.rarity
    end
    self.m_genStars:Refresh(starNum)
end
CharFormationCtrl._ProcessArgs = HL.Method(HL.Table) << function(self, args)
    self.m_dungeonId = args.dungeonId
    self.m_racingDungeonArg = args.racingDungeonArg
    self.m_index2Char = {}
    self.m_teamSet = LuaIndex(GameInstance.player.squadManager.curSquadIndex)
    self.m_isFormationLocked = args.lockedTeamData ~= nil
    self.m_lockedTeamData = args.lockedTeamData
    self:_Init()
end
CharFormationCtrl._Init = HL.Method() << function(self)
    if self.m_dungeonId then
        local succ, dungeonCfg = Tables.dungeonTable:TryGetValue(self.m_dungeonId)
        if succ then
            self.view.titleTxt.text = dungeonCfg.dungeonName
            local featureInfos = DungeonUtils.getListByStr(dungeonCfg.featureDesc)
            local hasFeature = #featureInfos > 0
            self.view.dungeonInfoBtn.onClick:RemoveAllListeners()
            self.view.dungeonInfoBtn.onClick:AddListener(function()
                UIManager:AutoOpen(PanelId.DungeonInfoPopup, { dungeonId = self.m_dungeonId })
            end)
            self.view.dungeonInfoBtn.gameObject:SetActive(hasFeature)
        else
            self.view.dungeonInfoBtn.gameObject:SetActive(false)
            self.view.titleTxt.gameObject:SetActive(false)
        end
    elseif self.m_racingDungeonArg then
        self.view.dungeonInfoBtn.gameObject:SetActive(false)
    else
        self.view.dungeonInfoBtn.gameObject:SetActive(false)
    end
    self.view.btnClose.onClick:RemoveAllListeners()
    self.view.btnClose.onClick:AddListener(function()
        self:Notify(MessageConst.P_ON_COMMON_BACK_CLICKED)
    end)
    self:BindInputPlayerAction("common_close_team_panel", function()
        PhaseManager:PopPhase(PhaseId.CharFormation)
    end)
    self.view.btnBack.onClick:RemoveAllListeners()
    self.view.btnBack.onClick:AddListener(function()
        self:Notify(MessageConst.P_ON_COMMON_BACK_CLICKED)
    end)
    self.view.btnRename.onClick:RemoveAllListeners()
    self.view.btnRename.onClick:AddListener(function()
        self:_OnChangeTeamNameClicked()
    end)
    self.view.btnFormation.onClick:RemoveAllListeners()
    self.view.btnFormation.onClick:AddListener(function()
        self:_OnEnterMultiSelect()
    end)
    self.view.btnMixConfirm.onClick:RemoveAllListeners()
    self.view.btnMixConfirm.onClick:AddListener(function()
        self:Notify(MessageConst.P_ON_CHAR_FORMATION_LIST_CONFIRM, self.m_curTeamIndex)
    end)
    self.view.btnConfirm.onClick:RemoveAllListeners()
    self.view.btnConfirm.onClick:AddListener(function()
        if Utils.isCurSquadAllDead() then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH)
            return
        end
        if self.state == UIConst.UI_CHAR_FORMATION_STATE.TeamWaitSet then
            self:Notify(MessageConst.P_ON_CHAR_FORMATION_TEAM_SET, { self.m_curTeamIndex, self.m_dungeonId })
        else
            if self.m_dungeonId then
                if self.m_isFormationLocked then
                    local charInfos = {}
                    for _, charInfo in ipairs(self.m_lockedTeamData.chars) do
                        table.insert(charInfos, CharInfoUtils.getPlayerCharInfoByInstId(charInfo.charInstId))
                    end
                    local selectedCharCount = #charInfos
                    if selectedCharCount == 0 then
                        Notify(MessageConst.SHOW_TOAST, Language.LUA_TEAM_FORMATION_EMPTY_TIPS)
                        return
                    end
                    local showConfirmTips = false
                    if selectedCharCount < self.m_lockedTeamData.maxTeamMemberCount then
                        local _, selectableCharCount = CharInfoUtils.getCharInfoListWithLockedTeamData(self.m_lockedTeamData)
                        if selectableCharCount > selectedCharCount then
                            showConfirmTips = true
                        end
                    end
                    if showConfirmTips then
                        self:Notify(MessageConst.SHOW_POP_UP, {
                            content = Language.LUA_TEAM_FORMATION_CHAR_NOT_FULL_TIPS,
                            onConfirm = function()
                                self:_EnterDungeon(self.m_dungeonId, charInfos)
                            end
                        })
                    else
                        self:_EnterDungeon(self.m_dungeonId, charInfos)
                    end
                else
                    self:_EnterDungeon(self.m_dungeonId)
                end
            end
            if self.m_racingDungeonArg then
                GameInstance.player.racingDungeonSystem:ReqStartDungeon(self.m_racingDungeonArg.dungeonId, self.m_racingDungeonArg.level, self.m_racingDungeonArg.tacticsId)
            end
        end
        if self.m_dungeonId then
            AudioAdapter.PostEvent("au_ui_btn_start_dungeon")
        elseif self.m_racingDungeonArg then
            AudioAdapter.PostEvent("au_ui_btn_start_dungeon")
        else
            AudioAdapter.PostEvent("au_ui_g_confirm_button")
        end
    end)
    self.view.btnSoloConfirm.onClick:RemoveAllListeners()
    self.view.btnSoloConfirm.onClick:AddListener(function()
        self:Notify(MessageConst.P_ON_CHAR_FORMATION_CONFIRM_SINGLE_CHAR, self.m_curTeamIndex)
    end)
    self.view.btnRemove.onClick:RemoveAllListeners()
    self.view.btnRemove.onClick:AddListener(function()
        self:Notify(MessageConst.P_ON_CHAR_FORMATION_UNEQUIP_INDEX)
    end)
    self.view.buttonRight.onClick:RemoveAllListeners()
    self.view.buttonRight.onClick:AddListener(function()
        self:_SetTeamSelect(self.m_curTeamIndex + 1)
    end)
    self.view.buttonLeft.onClick:RemoveAllListeners()
    self.view.buttonLeft.onClick:AddListener(function()
        self:_SetTeamSelect(self.m_curTeamIndex - 1)
    end)
    self.view.charInformation.btnCultivation.onClick:RemoveAllListeners()
    self.view.charInformation.btnCultivation.onClick:AddListener(function()
        self:_OnCharInfoClicked(self.m_singleCharInfo)
    end)
    self.m_teamCells = self.m_teamCells or UIUtils.genCellCache(self.view.team)
    local totalSquadNum = Tables.globalConst.totalSquadNum
    self.m_teamCells:Refresh(totalSquadNum, function(cell, luaIndex)
        local data = { index = luaIndex }
        cell:InitTeamCell(data, function()
            self:OnTeamClick(luaIndex)
        end)
        cell.gameObject:SetActive(true)
    end)
    self.m_genStars = self.m_genStars or UIUtils.genCellCache(self.view.charInformation.starIcon)
    self:_InitNavigation()
    self:RefreshControllerHint()
    self.view.charInformation.gameObject:SetActive(false)
    self.view.emptyNode.gameObject:SetActive(false)
    self.view.btnCannotReplace.gameObject:SetActive(false)
    self.view.trialOperators.gameObject:SetActive(self.m_lockedTeamData and self.m_lockedTeamData.shouldShowTrailTips)
end
CharFormationCtrl._InitNavigation = HL.Method() << function(self)
    if self.m_navigationGroupId <= 0 then
        self.m_navigationGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
        UIUtils.bindInputPlayerAction("common_navigation_left", function()
            self:_ChangeHoverTarget(-1)
        end, self.m_navigationGroupId)
        UIUtils.bindInputPlayerAction("common_navigation_right", function()
            self:_ChangeHoverTarget(1)
        end, self.m_navigationGroupId)
        UIUtils.bindInputPlayerAction("char_confirm_single_char", function()
            self:Notify(MessageConst.P_ON_CHAR_FORMATION_CONFIRM_HOVER)
        end, self.m_navigationGroupId)
    end
    InputManagerInst:ToggleGroup(self.m_navigationGroupId, true)
end
CharFormationCtrl._ClearNavigation = HL.Method() << function(self)
    if self.m_navigationGroupId > 0 then
        InputManagerInst:ToggleGroup(self.m_navigationGroupId, false)
    end
end
CharFormationCtrl._ChangeHoverTarget = HL.Method(HL.Number) << function(self, offset)
    local newIndex = (self.m_curHoverIndex - 1 + offset) % Const.BATTLE_SQUAD_MAX_CHAR_NUM + 1
    self.m_curHoverIndex = newIndex
    self:Notify(MessageConst.P_ON_CHAR_FORMATION_CHANGE_HOVER_INDEX, newIndex)
end
CharFormationCtrl._EnterDungeon = HL.Method(HL.String, HL.Opt(HL.Table)) << function(self, dungeonId, charInfos)
    if charInfos then
        GameInstance.dungeonManager:EnterDungeon(dungeonId, charInfos)
    else
        GameInstance.dungeonManager:EnterDungeon(dungeonId)
    end
    self:Notify(MessageConst.DIALOG_CLOSE_UI, { nil, nil, 0 })
end
CharFormationCtrl._SetTeamSelect = HL.Method(HL.Number) << function(self, index)
    local totalSquadNum = Tables.globalConst.totalSquadNum
    if index > totalSquadNum then
        index = index - totalSquadNum
    elseif index <= 0 then
        index = index + totalSquadNum
    end
    if self.m_curTeamIndex ~= index then
        local oldCell = self.m_teamCells:GetItem(self.m_curTeamIndex)
        if oldCell then
            oldCell:SetSelect(false)
        end
        self.m_curTeamIndex = index
        local newCell = self.m_teamCells:GetItem(self.m_curTeamIndex)
        newCell:SetSelect(true)
        self:Notify(MessageConst.P_ON_CHAR_FORMATION_SELECT_TEAM_CHANGE, self.m_curTeamIndex)
        self:RefreshTeamName()
    end
    if self.m_curTeamIndex == self.m_teamSet then
        self:SetState(UIConst.UI_CHAR_FORMATION_STATE.TeamHasSet)
    else
        self:SetState(UIConst.UI_CHAR_FORMATION_STATE.TeamWaitSet)
    end
    self.view.textNum.text = string.format("0%d", self.m_curTeamIndex)
    self:RefreshTeamName()
end
CharFormationCtrl._SetSlotCharInfo = HL.Method(HL.Table, HL.Table) << function(self, slot, info)
    local characterTable = Tables.characterTable
    local data = characterTable:GetValue(info.charId)
    local instId = info.charInstId
    local charInfo = nil
    if instId and instId > 0 then
        charInfo = CharInfoUtils.getPlayerCharInfoByInstId(instId)
    end
    if charInfo then
        slot.textLv.text = string.format("%02d", charInfo.level)
    end
    slot.textName.text = data.name
    slot.charElementIcon:InitCharTypeIcon(data.charTypeId)
    local proSpriteName = UIConst.UI_CHAR_PROFESSION_PREFIX .. data.profession:ToInt() .. UIConst.UI_CHAR_PROFESSION_SMALL_SUFFIX
    slot.imagePro.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_PROFESSION, proSpriteName)
    local isFixed, isTrail = CharInfoUtils.getLockedFormationCharTipsShow(info)
    slot.tryoutTips.gameObject:SetActive(isTrail)
    slot.fixedTips.gameObject:SetActive(isFixed)
end
CharFormationCtrl._PlayBtnSingleAnim = HL.Method(HL.Number) << function(self, singleState)
    if singleState == self.singleState then
        return
    end
    local name
    local charInfo = self.m_index2Char[self.m_singleCharIndex]
    if self.singleState == UIConst.UI_CHAR_FORMATION_SINGLE_STATE.None then
        if singleState == UIConst.UI_CHAR_FORMATION_SINGLE_STATE.Current and charInfo then
            name = BTN_ANIM_NAME.BTN_FORMATION_REMOV_IN
        else
            name = BTN_ANIM_NAME.BTN_EMPTY_IN
        end
    else
        if singleState == UIConst.UI_CHAR_FORMATION_SINGLE_STATE.Current then
            name = BTN_ANIM_NAME.BTN_FORMATION_REMOV_IN
        else
            name = BTN_ANIM_NAME.BTN_EMPTY_OUT
        end
    end
    if not string.isEmpty(name) then
        self.view.btnNode:PlayWithTween(name)
    end
end
CharFormationCtrl._RefreshLeftRightBtns = HL.Method(HL.Boolean) << function(self, visible)
    self.view.buttonLeft.gameObject:SetActive(visible)
    self.view.buttonRight.gameObject:SetActive(visible)
end
CharFormationCtrl._PlayBtnMultiAnim = HL.Method(HL.Number) << function(self, state)
    if state == self.state then
        return
    end
    local name
    if state == UIConst.UI_CHAR_FORMATION_STATE.CharChange then
        name = BTN_ANIM_NAME.BTN_FORMATION_MIXCONFIRM_IN
    elseif self.state == UIConst.UI_CHAR_FORMATION_STATE.CharChange then
        name = BTN_ANIM_NAME.BTN_FORMATION_MIXCONFIRM_OUT
    end
    if not string.isEmpty(name) then
        self.view.btnNode:PlayWithTween(name)
    end
end
CharFormationCtrl.OpenCharList = HL.Method(HL.Number, HL.Opt(HL.Int)) << function(self, mode, charInstId)
    if self.state == UIConst.UI_CHAR_FORMATION_STATE.CharChange then
        return
    end
    self.m_charListSingleCharInstId = charInstId or self.m_charListSingleCharInstId
    self.m_charListMode = mode
    self:SetState(UIConst.UI_CHAR_FORMATION_STATE.CharChange)
    local maxCharTeamMemberCount = self.m_lockedTeamData and self.m_lockedTeamData.maxTeamMemberCount or GameInstance.player.charBag.maxCharTeamMemberCount
    local info = { selectNum = math.min(Const.BATTLE_SQUAD_MAX_CHAR_NUM, maxCharTeamMemberCount), mode = self.m_charListMode, selectedCharInfo = self.m_singleCharInfo, lockedTeamData = self.m_lockedTeamData, }
    self.view.charList.gameObject:SetActive(true)
    self.view.charList:InitCharFormationList(info, function(charList)
        self.m_tmpCharItems = charList
    end)
    self.view.charList:SetUpdateCellFunc(nil, function(select, cellIndex, charItem, charItemList, charInfoList)
        self:_CharListChangeSelectIndex(select, cellIndex, charItem, charItemList, charInfoList)
    end)
    self:_RefreshCharList()
    self.view.charList:ShowSelectChars(self:_GetShowSelectChars())
    self:_ActiveTeamInfo(false)
    self:SetExGroupId(self.view.inputGroup.groupId)
    self:RefreshControllerHint()
end
CharFormationCtrl.CloseCharList = HL.Method() << function(self)
    self.view.charList.gameObject:SetActive(false)
    self:_ActiveTeamInfo(true)
end
CharFormationCtrl._ActiveTeamInfo = HL.Method(HL.Boolean) << function(self, active)
    self.view.charTittleNode.gameObject:SetActive(active)
    self.view.infoNoe.gameObject:SetActive(active and not self.m_isFormationLocked)
end
CharFormationCtrl.SetCharListMode = HL.Method(HL.Number, HL.Opt(HL.Number)) << function(self, mode, charInstId)
    self.view.charList:SetMode(mode, charInstId)
    self.m_charListMode = mode
end
CharFormationCtrl.GetCharListEmpty = HL.Method().Return(HL.Boolean) << function(self)
    return self.view.charList:GetEmpty()
end
CharFormationCtrl.GetCurCharList = HL.Method().Return(HL.Table) << function(self)
    local charList = {}
    local index2Id = {}
    for cellIndex, index in pairs(self.view.charList.cell2Select) do
        index2Id[index] = self.m_tmpCharItems[cellIndex]
    end
    local realIndex = 1
    for i = 1, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
        if index2Id[i] then
            charList[realIndex] = index2Id[i]
            realIndex = realIndex + 1
        end
    end
    return charList
end
CharFormationCtrl.m_charListMode = HL.Field(HL.Number) << 0
CharFormationCtrl.m_charListSingleCharInstId = HL.Field(HL.Int) << 0
CharFormationCtrl.m_tmpCharItems = HL.Field(HL.Table)
CharFormationCtrl._OnEnterMultiSelect = HL.Method() << function(self)
    self:OpenCharList(UIConst.CharListMode.MultiSelect)
    self:Notify(MessageConst.P_ON_CHAR_FORMATION_ENTER_MULTI_SELECT)
end
CharFormationCtrl._RefreshCharList = HL.Method() << function(self)
    if self.m_lockedTeamData then
        self.m_tmpCharItems = CharInfoUtils.getCharInfoListWithLockedTeamData(self.m_lockedTeamData)
    else
        self.m_tmpCharItems = CharInfoUtils.getCharInfoList(CSIndex(self.m_curTeamIndex))
    end
    self.view.charList:UpdateCharItems(self.m_tmpCharItems)
end
CharFormationCtrl._CharListChangeSelectIndex = HL.Method(HL.Boolean, HL.Number, HL.Table, HL.Table, HL.Table) << function(self, select, cellIndex, charItem, charItemList, charInfoList)
    if self.m_charListMode == UIConst.UIConst.CharListMode.MultiSelect then
        self:Notify(MessageConst.P_ON_CHAR_FORMATION_LIST_MULTI_SELECT, { charItemList, charInfoList })
    else
        self:Notify(MessageConst.P_ON_CHAR_FORMATION_LIST_SINGLE_SELECT, { cellIndex, charItem })
    end
end
CharFormationCtrl._GetShowSelectChars = HL.Method().Return(HL.Table) << function(self)
    local showSelectChars = {}
    for i = 1, #self.m_tmpCharItems do
        local charItem = self.m_tmpCharItems[i]
        if charItem.slotIndex and charItem.slotIndex <= Const.BATTLE_SQUAD_MAX_CHAR_NUM then
            table.insert(showSelectChars, charItem)
        end
    end
    table.sort(showSelectChars, Utils.genSortFunction({ "slotIndex" }, true))
    return showSelectChars
end
CharFormationCtrl.m_isFormationLocked = HL.Field(HL.Boolean) << false
CharFormationCtrl.m_lockedTeamData = HL.Field(HL.Table)
HL.Commit(CharFormationCtrl)