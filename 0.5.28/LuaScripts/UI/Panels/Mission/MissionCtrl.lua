local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Mission
local CHAPTER_ICON_PATH = "Mission/ChapterIcon"
local CHAPTER_BG_ICON_PATH = "Mission/ChapterBgIcon"
local OPTIONAL_TEXT_COLOR = "C7EC59"
local QuestState = CS.Beyond.Gameplay.MissionSystem.QuestState
local MissionState = CS.Beyond.Gameplay.MissionSystem.MissionState
local MissionListCellType_Chapter = 0
local MissionListCellType_Mission = 1
local MissionType = CS.Beyond.Gameplay.MissionSystem.MissionType
local ChapterType = CS.Beyond.Gameplay.ChapterType
local MissionFilterType_All = -1
local MISSION_TYPE_ORDER = { [MissionType.Main] = 0, [MissionType.Char] = 1, [MissionType.Factory] = 2, [MissionType.Bloc] = 3, [MissionType.Hide] = 4, [MissionType.World] = 5, [MissionType.Dungeon] = 6, [MissionType.Misc] = 7, }
local MissionFilterCellConfig = { [1] = { missionFilterType = MissionFilterType_All, icon = "all_mission_icon_gray", typeText = Language.ui_mis_panel_tab_all, }, [2] = { missionFilterType = MissionType.Main, icon = "main_mission_icon_gray", typeText = Language.ui_mis_panel_tab_main, }, [3] = { missionFilterType = MissionType.Char, icon = "char_mission_icon_gray", typeText = Language.ui_mis_panel_tab_char, }, [4] = { missionFilterType = MissionType.Factory, icon = "fac_mission_icon_gray", typeText = Language.ui_mis_panel_tab_factory, }, [5] = { missionFilterType = MissionType.World, icon = "world_mission_icon_gray", typeText = Language.ui_mis_panel_tab_world, }, [6] = { missionFilterType = MissionType.Misc, icon = "misc_mission_icon_gray", typeText = Language.ui_mis_panel_tab_misc, }, }
MissionCtrl = HL.Class('MissionCtrl', uiCtrl.UICtrl)
MissionCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_TRACK_MISSION_CHANGE] = 'OnTrackMissionChange', [MessageConst.ON_QUEST_OBJECTIVE_UPDATE] = 'OnObjectiveUpdate', [MessageConst.ON_SYNC_ALL_MISSION] = 'OnSyncAllMission', [MessageConst.ON_MISSION_STATE_CHANGE] = 'OnMissionStateChange', [MessageConst.ON_QUEST_STATE_CHANGE] = 'OnQuestStateChange', }
MissionCtrl.m_missionSystem = HL.Field(HL.Any)
MissionCtrl.m_selectedMissionId = HL.Field(HL.Any) << nil
MissionCtrl.m_missionViewInfo = HL.Field(HL.Table)
MissionCtrl.m_getMissionCellsFunc = HL.Field(HL.Function)
MissionCtrl.m_questCellCache = HL.Field(HL.Forward("UIListCache"))
MissionCtrl.m_missionTypeCells = HL.Field(HL.Forward("UIListCache"))
MissionCtrl.m_missionFilterType = HL.Field(HL.Any)
MissionCtrl.m_getRewardItemCellsFunc = HL.Field(HL.Function)
MissionCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_missionSystem = GameInstance.player.mission
    self.m_questCellCache = UIUtils.genCellCache(self.view.missionInfoNode.questCell)
    self.view.btnClose.onClick:RemoveAllListeners()
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.Mission)
    end)
    self:_InitMissionFilter()
    if DeviceInfo.isMobile then
    end
    self.m_getMissionCellsFunc = UIUtils.genCachedCellFunction(self.view.missionScrollView)
    if arg and arg.autoSelect then
        self.m_selectedMissionId = arg.autoSelect
    else
        self.m_selectedMissionId = self.m_missionSystem.trackMissionId
    end
    self.view.blackMask.gameObject:SetActive(arg and arg.useBlackMask == true)
    self:_RefreshMissionList()
    self:_AutoSelectMission()
    self:_RefreshMissionInfo()
    self:BindInputPlayerAction("common_navigation_up", function()
        self:_ChangeSelectedMission(-1)
    end)
    self:BindInputPlayerAction("common_navigation_down", function()
        self:_ChangeSelectedMission(1)
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
MissionCtrl._InitMissionFilter = HL.Method() << function(self)
    self.view.m_missionTypeCells = UIUtils.genCellCache(self.view.missionTypeTab.tabCell)
    self.m_missionFilterType = MissionFilterType_All
    self.view.titleTxt.text = Language.ui_mis_panel_tab_all
    local firstTab
    self.view.m_missionTypeCells:Refresh(#MissionFilterCellConfig, function(cell, index)
        if index == 1 then
            firstTab = cell
        end
        local config = MissionFilterCellConfig[index]
        if config then
            cell.toggle.onValueChanged:AddListener(function(isOn)
                if isOn then
                    self:_SetMissionFilterType(config.missionFilterType)
                end
            end)
            cell.selectedIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, config.icon)
            cell.defaultIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, config.icon)
        end
    end)
    if firstTab then
        firstTab.toggle.isOn = true
    end
end
MissionCtrl._SetMissionFilterType = HL.Method(HL.Any) << function(self, filterType)
    if self.m_missionFilterType == filterType then
        return
    end
    self.m_missionFilterType = filterType
    for _, missionTypeConfig in pairs(MissionFilterCellConfig) do
        if filterType == missionTypeConfig.missionFilterType then
            self.view.titleTxt.text = missionTypeConfig.typeText
            break
        end
    end
    self:_RefreshMissionList()
    if not string.isEmpty(self.m_selectedMissionId) then
        local missionInfo = self.m_missionSystem:GetMissionInfo(self.m_selectedMissionId)
        if self.m_missionFilterType == MissionFilterType_All or self.m_missionFilterType == missionInfo.missionType then
            self.view.missionInfoNode.gameObject:SetActive(true)
        else
            self.view.missionInfoNode.gameObject:SetActive(false)
        end
    end
    self:_AutoSelectMission()
    self:_ChangeSelectedMission(0)
end
MissionCtrl._AutoSelectMission = HL.Method() << function(self)
    local trackMissionId = self.m_missionSystem.trackMissionId
    local priority = 0
    local toBeSelectedMissionId = ""
    for _, viewInfo in pairs(self.m_missionViewInfo) do
        if viewInfo.type == MissionListCellType_Chapter then
            for _, missionViewInfo in pairs(viewInfo.missionList) do
                local missionId = missionViewInfo.id
                if missionId == self.m_selectedMissionId and priority < 3 then
                    toBeSelectedMissionId = missionId
                    priority = 3
                elseif missionId == trackMissionId and priority < 2 then
                    toBeSelectedMissionId = missionId
                    priority = 2
                elseif string.isEmpty(toBeSelectedMissionId) and priority < 1 then
                    toBeSelectedMissionId = missionId
                    priority = 1
                end
            end
        else
            local missionId = viewInfo.id
            if missionId == self.m_selectedMissionId and priority < 3 then
                toBeSelectedMissionId = missionId
                priority = 3
            elseif missionId == trackMissionId and priority < 2 then
                toBeSelectedMissionId = missionId
                priority = 2
            elseif string.isEmpty(toBeSelectedMissionId) and priority < 1 then
                toBeSelectedMissionId = missionId
                priority = 1
            end
        end
    end
    if self.m_selectedMissionId ~= toBeSelectedMissionId then
        self.m_selectedMissionId = toBeSelectedMissionId
        self:_RefreshSelectedMission()
        self:_RefreshMissionInfo()
    end
end
MissionCtrl._TraverseAllMissionCell = HL.Method(HL.Any) << function(self, callback)
    for i, viewInfo in ipairs(self.m_missionViewInfo) do
        local t = viewInfo.type
        if t == MissionListCellType_Mission then
            local missionId = viewInfo.id
            local csIdx = CSIndex(i)
            local gameObject = self.view.missionScrollView:Get(csIdx)
            if gameObject then
                local contentCell = self.m_getMissionCellsFunc(gameObject)
                callback(missionId, contentCell.missionCell)
            end
        elseif t == MissionListCellType_Chapter then
            local csIdx = CSIndex(i)
            local gameObject = self.view.missionScrollView:Get(csIdx)
            if gameObject then
                local contentCell = self.m_getMissionCellsFunc(gameObject)
                local missionList = viewInfo.missionList
                for missionIdx = 1, #missionList do
                    local missionId = missionList[missionIdx].id
                    local missionCell = contentCell.missionCellCache:GetItem(missionIdx)
                    callback(missionId, missionCell)
                end
            end
        end
    end
end
MissionCtrl._RefreshEmptyNode = HL.Method() << function(self)
    local noMission = #self.m_missionViewInfo <= 0
    self.view.emptyNode.gameObject:SetActive(noMission)
    self.view.missionScrollList.gameObject:SetActive(not noMission)
    self.view.missionInfoNode.gameObject:SetActive(not noMission)
    local filterCellConfig = nil
    for _, c in pairs(MissionFilterCellConfig) do
        if self.m_missionFilterType == c.missionFilterType then
            filterCellConfig = c
            break
        end
    end
    if filterCellConfig then
        self.view.emptyIcon.gameObject:SetActive(true)
        self.view.emptyIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, filterCellConfig.icon)
    else
        self.view.emptyIcon.gameObject:SetActive(false)
    end
end
MissionCtrl._RefreshMissionList = HL.Method() << function(self)
    local missionFilterType = self.m_missionFilterType
    if missionFilterType ~= MissionFilterType_All then
        missionFilterType = missionFilterType:ToInt()
    end
    local trackMissionId = self.m_missionSystem.trackMissionId
    self.m_missionViewInfo = {}
    local missionLayout = self.m_missionSystem:GetMissionListLayout(missionFilterType)
    for _, chapter in pairs(missionLayout.chapters) do
        local missionList = {}
        table.insert(self.m_missionViewInfo, { type = MissionListCellType_Chapter, id = chapter.chapterId, missionList = missionList })
        for _, missionId in pairs(chapter.missionList) do
            table.insert(missionList, { type = MissionListCellType_Mission, id = missionId })
        end
        table.sort(missionList, function(a, b)
            local missionA = self.m_missionSystem:GetMissionInfo(a.id)
            local missionB = self.m_missionSystem:GetMissionInfo(b.id)
            if missionA.significant and not missionB.significant then
                return true
            elseif not missionA.significant and missionB.significant then
                return false
            end
            return missionA.missionId < missionB.missionId
        end)
    end
    for _, missionId in pairs(missionLayout.standaloneMissions) do
        table.insert(self.m_missionViewInfo, { type = MissionListCellType_Mission, id = missionId })
    end
    table.sort(self.m_missionViewInfo, function(a, b)
        if a.type < b.type then
            return true
        elseif a.type == b.type then
            local viewType = a.type
            if viewType == MissionListCellType_Chapter then
                local chapterA = self.m_missionSystem:GetChapterInfo(a.id)
                local chapterB = self.m_missionSystem:GetChapterInfo(b.id)
                if chapterA.type:ToInt() < chapterB.type:ToInt() then
                    return true
                elseif chapterA.type:ToInt() == chapterB.type:ToInt() then
                    if chapterA.priority < chapterB.priority then
                        return true
                    elseif chapterA.priority == chapterB.priority then
                        return chapterA.chapterId < chapterB.chapterId
                    else
                        return false
                    end
                else
                    return false
                end
            else
                local missionA = self.m_missionSystem:GetMissionInfo(a.id)
                local missionB = self.m_missionSystem:GetMissionInfo(b.id)
                local missionTypeOrderA = MISSION_TYPE_ORDER[missionA.missionType]
                local missionTypeOrderB = MISSION_TYPE_ORDER[missionB.missionType]
                if missionTypeOrderA < missionTypeOrderB then
                    return true
                elseif missionA.missionType:ToInt() == missionB.missionType:ToInt() then
                    if missionA.significant and not missionB.significant then
                        return true
                    elseif not missionA.significant and missionB.significant then
                        return false
                    end
                    return missionA.missionId < missionB.missionId
                else
                    return false
                end
            end
        else
            return false
        end
    end)
    self:_RefreshEmptyNode()
    self.view.missionScrollView.getCellSize = function(index)
        local luaIdx = LuaIndex(index)
        local viewInfo = self.m_missionViewInfo[luaIdx]
        if viewInfo.type == MissionListCellType_Chapter then
            return 210 + 112 * #viewInfo.missionList
        elseif viewInfo.type == MissionListCellType_Mission then
            return 112
        end
    end
    self.view.missionScrollView.onUpdateCell:RemoveAllListeners();
    self.view.missionScrollView.onUpdateCell:AddListener(function(gameObject, index)
        local luaIndex = LuaIndex(index)
        local content = self.m_getMissionCellsFunc(gameObject)
        local viewInfo = self.m_missionViewInfo[luaIndex]
        if viewInfo.type == MissionListCellType_Chapter then
            content.chapterCell.gameObject:SetActive(true)
            content.missionCell.gameObject:SetActive(false)
            local chapterCell = content.chapterCell
            local chapterId = self.m_missionViewInfo[luaIndex].id
            local chapterInfo = self.m_missionSystem:GetChapterInfo(chapterId)
            if chapterInfo then
                chapterCell.episodeName.text = UIUtils.resolveTextStyle(chapterInfo.episodeName:GetText())
                local chapterNumTxt = UIUtils.resolveTextStyle(chapterInfo.chapterNum:GetText())
                local episodeNumTxt = UIUtils.resolveTextStyle(chapterInfo.episodeNum:GetText())
                local separator = ""
                if not string.isEmpty(chapterNumTxt) and not string.isEmpty(episodeNumTxt) then
                    separator = " — "
                end
                chapterCell.chapterNumAndEpisodeNum.text = chapterNumTxt .. separator .. episodeNumTxt
                chapterCell.chapterMainDecoNode.gameObject:SetActive(chapterInfo.type == ChapterType.Main)
                chapterCell.chapterCharacterDecoNode.gameObject:SetActive(chapterInfo.type == ChapterType.Character)
                local chapterConfig = UIConst.CHAPTER_ICON_CONFIGS[chapterInfo.type]
                if not string.isEmpty(chapterInfo.icon) then
                    chapterCell.icon.gameObject:SetActive(true)
                    chapterCell.icon.sprite = self:LoadSprite(CHAPTER_ICON_PATH, chapterInfo.icon)
                elseif not string.isEmpty(chapterConfig.icon) then
                    chapterCell.icon.gameObject:SetActive(true)
                    chapterCell.icon.sprite = self:LoadSprite(CHAPTER_ICON_PATH, chapterConfig.icon)
                else
                    chapterCell.icon.gameObject:SetActive(false)
                    chapterCell.icon.sprite = nil
                end
                if not string.isEmpty(chapterInfo.bgIcon) then
                    chapterCell.bgIcon.gameObject:SetActive(true)
                    chapterCell.bgIcon.sprite = self:LoadSprite(CHAPTER_BG_ICON_PATH, chapterInfo.bgIcon)
                elseif not string.isEmpty(chapterConfig.bgIcon) then
                    chapterCell.bgIcon.gameObject:SetActive(true)
                    chapterCell.bgIcon.sprite = self:LoadSprite(CHAPTER_BG_ICON_PATH, chapterConfig.bgIcon)
                else
                    chapterCell.bgIcon.gameObject:SetActive(false)
                    chapterCell.bgIcon.sprite = nil
                end
                local missionList = self.m_missionViewInfo[luaIndex].missionList
                content.missionCellCache = content.missionCellCache or UIUtils.genCellCache(chapterCell.missionCell)
                content.missionCellCache:Refresh(#missionList, function(missionCell, luaIndex)
                    local missionId = missionList[luaIndex].id
                    local missionInfo = self.m_missionSystem:GetMissionInfo(missionId)
                    if missionInfo then
                        self:_SetMissionCellContent(missionCell, missionInfo)
                    end
                end)
            end
        else
            content.chapterCell.gameObject:SetActive(false)
            content.missionCell.gameObject:SetActive(true)
            local missionCell = content.missionCell
            local missionId = self.m_missionViewInfo[luaIndex].id
            local missionInfo = self.m_missionSystem:GetMissionInfo(missionId)
            if missionInfo then
                self:_SetMissionCellContent(missionCell, missionInfo)
            end
        end
        LayoutRebuilder.ForceRebuildLayoutImmediate(content.transform)
    end)
    self.view.missionScrollView:UpdateCount(#self.m_missionViewInfo)
end
MissionCtrl._RefreshSelectedMission = HL.Method() << function(self)
    self:_TraverseAllMissionCell(function(missionId, missionCell)
        self:_SetMissionCellSelected(missionCell, missionId == self.m_selectedMissionId)
    end)
end
MissionCtrl._SetMissionCellSelected = HL.Method(HL.Any, HL.Boolean) << function(self, missionCell, selected)
    missionCell.selectedBG.gameObject:SetActive(selected)
    missionCell.unSelectedBG.gameObject:SetActive(not selected)
    missionCell.selectedDeco.gameObject:SetActive(selected)
    if selected then
        missionCell.missionNameTxt.color = self.view.config.SELECTED_MISSION_NAME_COLOR
        missionCell.missionLevelName.color = self.view.config.SELECTED_MISSION_LEVEL_NAME_COLOR
    else
        missionCell.missionNameTxt.color = self.view.config.MISSION_NAME_COLOR
        missionCell.missionLevelName.color = self.view.config.MISSION_LEVEL_NAME_COLOR
    end
end
MissionCtrl._SetMissionCellTrack = HL.Method(HL.Any, HL.Any) << function(self, missionCell, missionInfo)
    local missionId = missionInfo.missionId
    local track = (missionInfo.missionId == self.m_missionSystem.trackMissionId)
    if track then
        missionCell.missionTrackTip.gameObject:SetActive(true)
        missionCell.missionTrackTip.gameObject:GetComponent("CanvasGroup").color = self.m_missionSystem:GetMissionColor(missionId)
        local distance = self.m_missionSystem:GetMissionTrackDistance(missionId)
        if distance > 0 then
            missionCell.missionLevelName.text = tostring(math.floor(distance + 0.5)) .. "M"
        else
            local levelId = missionInfo.levelId or ""
            local _, levelInfo = Tables.levelDescTable:TryGetValue(levelId)
            if levelInfo then
                missionCell.missionLevelName.text = UIUtils.resolveTextStyle(levelInfo.showName)
            else
                missionCell.missionLevelName.text = UIUtils.resolveTextStyle(Language[levelId])
            end
        end
    else
        missionCell.missionTrackTip.gameObject:SetActive(false)
        local levelId = missionInfo.levelId or ""
        local _, levelInfo = Tables.levelDescTable:TryGetValue(levelId)
        if levelInfo then
            missionCell.missionLevelName.text = UIUtils.resolveTextStyle(levelInfo.showName)
        else
            missionCell.missionLevelName.text = UIUtils.resolveTextStyle(Language[levelId])
        end
    end
end
MissionCtrl._SetMissionCellContent = HL.Method(HL.Any, HL.Any) << function(self, missionCell, missionInfo)
    local missionId = missionInfo.missionId
    missionCell.missionNameTxt.text = UIUtils.resolveTextStyle(missionInfo.missionName:GetText())
    missionCell.selectBtn.onClick:RemoveAllListeners()
    missionCell.selectBtn.onClick:AddListener(function()
        if self.m_selectedMissionId ~= missionId then
            self.m_selectedMissionId = missionId
            self:_RefreshSelectedMission()
            self.view.missionInfoNode.animation:SkipInAnimation()
            self.view.missionInfoNode.animation:PlayInAnimation()
            self:_RefreshMissionInfo()
        end
    end)
    local missionType = missionInfo.missionType
    local icon = UIConst.MISSION_TYPE_CONFIG[missionType].missionIcon
    missionCell.missionIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, icon)
    missionCell.redDot.gameObject:SetActive(missionInfo.significant)
    self:_SetMissionCellTrack(missionCell, missionInfo)
    self:_SetMissionCellSelected(missionCell, self.m_selectedMissionId == missionId)
end
MissionCtrl._RefreshMissionInfo = HL.Method() << function(self)
    local bSelectedMissionValid = false
    if not string.isEmpty(self.m_selectedMissionId) then
        local missionData = self.m_missionSystem:GetMissionData(self.m_selectedMissionId)
        local missionInfo = self.m_missionSystem:GetMissionInfo(self.m_selectedMissionId)
        if missionData and missionInfo and missionData.missionState == MissionState.Processing then
            local missionInfoNode = self.view.missionInfoNode
            bSelectedMissionValid = true
            missionInfoNode.gameObject:SetActive(true)
            local missionNameText = UIUtils.resolveTextStyle(missionInfo.missionName:GetText())
            missionInfoNode.missionName.text = missionNameText
            local missionDescText = UIUtils.resolveTextStyle(missionInfo:GetMissionDesc():GetText())
            missionInfoNode.missionDesc.text = missionDescText
            local levelId = missionInfo.levelId or ""
            local _, sceneInfo = Tables.levelDescTable:TryGetValue(levelId)
            if sceneInfo then
                missionInfoNode.missionLevelName.text = UIUtils.resolveTextStyle(sceneInfo.showName)
            else
                missionInfoNode.missionLevelName.text = UIUtils.resolveTextStyle(Language[levelId])
            end
            if not string.isEmpty(missionInfo.chapterId) then
                local chapterInfo = self.m_missionSystem:GetChapterInfo(missionInfo.chapterId)
                local chapterConfig = UIConst.CHAPTER_ICON_CONFIGS[chapterInfo.type]
                if not string.isEmpty(chapterInfo.icon) then
                    missionInfoNode.icon.gameObject:SetActive(true)
                    missionInfoNode.icon.sprite = self:LoadSprite(CHAPTER_ICON_PATH, chapterInfo.icon)
                elseif not string.isEmpty(chapterConfig.icon) then
                    missionInfoNode.icon.gameObject:SetActive(true)
                    missionInfoNode.icon.sprite = self:LoadSprite(CHAPTER_ICON_PATH, chapterConfig.icon)
                else
                    missionInfoNode.icon.gameObject:SetActive(false)
                    missionInfoNode.icon.sprite = nil
                end
                if not string.isEmpty(chapterInfo.bgIcon) then
                    missionInfoNode.bgIcon.gameObject:SetActive(true)
                    missionInfoNode.bgIcon.sprite = self:LoadSprite(CHAPTER_BG_ICON_PATH, chapterInfo.bgIcon .. "_inverse")
                elseif not string.isEmpty(chapterConfig.bgIcon) then
                    missionInfoNode.bgIcon.gameObject:SetActive(true)
                    missionInfoNode.bgIcon.sprite = self:LoadSprite(CHAPTER_BG_ICON_PATH, chapterConfig.bgIcon .. "_inverse")
                else
                    missionInfoNode.bgIcon.gameObject:SetActive(false)
                    missionInfoNode.bgIcon.sprite = nil
                end
            else
                missionInfoNode.icon.gameObject:SetActive(false)
                missionInfoNode.bgIcon.gameObject:SetActive(false)
            end
            self:_RefreshTrackBtn()
            local missionId = missionInfo.missionId
            if missionId == self.m_missionSystem.trackMissionId and self.m_missionSystem:HasTrackDataForMap() then
                missionInfoNode.mapBtn.gameObject:SetActive(true)
                missionInfoNode.mapBtn.onClick:RemoveAllListeners()
                missionInfoNode.mapBtn.onClick:AddListener(function()
                    if not string.isEmpty(self.m_missionSystem.trackMissionId) then
                        if self.m_missionSystem:HasShowedTrackDataForMap() then
                            MapUtils.openMapByMissionId(self.m_missionSystem.trackMissionId)
                        else
                            Notify(MessageConst.SHOW_TOAST, Language.ui_mis_toast_map_in_challenge)
                        end
                    end
                end)
            else
                missionInfoNode.mapBtn.gameObject:SetActive(false)
                missionInfoNode.mapBtn.onClick:RemoveAllListeners()
            end
            self:_RefreshObjectiveProgress(self.m_selectedMissionId)
            local rewardItemBundles = {}
            local findReward, rewardData = Tables.rewardTable:TryGetValue(missionInfo.rewardId or "")
            if findReward then
                for _, itemBundle in pairs(rewardData.itemBundles) do
                    local itemData = Tables.itemTable[itemBundle.id]
                    table.insert(rewardItemBundles, { id = itemBundle.id, count = itemBundle.count, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, rarity = itemData.rarity, })
                end
            end
            table.sort(rewardItemBundles, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
            if #rewardItemBundles > 0 then
                self.view.rewardsNode.gameObject:SetActive(true)
                self.m_getRewardItemCellsFunc = self.m_getRewardItemCellsFunc or UIUtils.genCachedCellFunction(self.view.rewardScrollList)
                self.view.rewardScrollList.onUpdateCell:RemoveAllListeners();
                self.view.rewardScrollList.onUpdateCell:AddListener(function(gameObject, index)
                    local itemCell = self.m_getRewardItemCellsFunc(gameObject)
                    local luaIdx = LuaIndex(index)
                    itemCell:InitItem(rewardItemBundles[luaIdx], true)
                end)
                self.view.rewardScrollList:UpdateCount(#rewardItemBundles)
            else
                self.view.rewardsNode.gameObject:SetActive(false)
            end
        end
    end
    if not bSelectedMissionValid then
        self.view.missionInfoNode.gameObject:SetActive(false)
    end
end
MissionCtrl._RefreshObjectiveProgress = HL.Method(HL.String) << function(self, missionId)
    if string.isEmpty(missionId) then
        return
    end
    local displayQuestIds = self.m_missionSystem:GetDisplayQuestIdsByMissionId(missionId)
    if displayQuestIds then
        local displayQuestCount = displayQuestIds.Count
        self.m_questCellCache:Refresh(displayQuestCount, function(questCell, luaIdx)
            local csIdx = CSIndex(luaIdx)
            local questId = displayQuestIds[csIdx]
            local questInfo = self.m_missionSystem:GetQuestInfo(questId)
            local questData = self.m_missionSystem:GetQuestData(questId)
            local objectiveCountInQuest = questInfo.objectiveList.Count
            if objectiveCountInQuest > 0 then
                questCell.gameObject:SetActive(true)
                local allObjectiveComplete = true
                for _, objective in pairs(questInfo.objectiveList) do
                    if not objective.isCompleted then
                        allObjectiveComplete = false
                        break
                    end
                end
                questCell.normalIcon.gameObject:SetActive(not allObjectiveComplete)
                questCell.completeIcon.gameObject:SetActive(allObjectiveComplete)
                questCell.multiObjectiveDeco.gameObject:SetActive(objectiveCountInQuest > 1)
                local optional = questInfo.optional
                questCell.objectiveCache = questCell.objectiveCache or UIUtils.genCellCache(questCell.objectiveCell)
                questCell.objectiveCache:Refresh(objectiveCountInQuest, function(objectiveCell, objectiveLuaIdx)
                    local objectiveCSIdx = CSIndex(objectiveLuaIdx)
                    local objective = questInfo.objectiveList[objectiveCSIdx]
                    if optional then
                        objectiveCell.desc.text = string.format("<color=#%s>%s</color> %s", OPTIONAL_TEXT_COLOR, Language.ui_optional_quest, UIUtils.resolveTextStyle(objective.description:GetText()))
                    else
                        objectiveCell.desc.text = UIUtils.resolveTextStyle(objective.description:GetText())
                    end
                    if objective.isShowProgress then
                        objectiveCell.progress.gameObject:SetActive(true)
                        if objective.isCompleted then
                            objectiveCell.progress.text = string.format("%d/%d", objective.progressToCompareForShow, objective.progressToCompareForShow)
                        else
                            objectiveCell.progress.text = string.format("%d/%d", objective.progressForShow, objective.progressToCompareForShow)
                        end
                    else
                        objectiveCell.progress.gameObject:SetActive(false)
                    end
                    if objective.isCompleted then
                        objectiveCell.desc.color = self.view.config.OBJECTIVE_COMPLETE_FONT_COLOR
                        objectiveCell.progress.color = self.view.config.OBJECTIVE_COMPLETE_FONT_COLOR
                    else
                        objectiveCell.desc.color = self.view.config.OBJECTIVE_NORMAL_FONT_COLOR
                        objectiveCell.progress.color = self.view.config.OBJECTIVE_NORMAL_FONT_COLOR
                    end
                end)
            else
                questCell.gameObject:SetActive(false)
            end
        end)
    end
end
MissionCtrl._RefreshTrackBtn = HL.Method() << function(self)
    local missionInfoNode = self.view.missionInfoNode
    local trackMissionId = self.m_missionSystem:GetTrackMissionId()
    if trackMissionId == self.m_selectedMissionId then
        missionInfoNode.trackBtn.gameObject:SetActive(false)
        missionInfoNode.stopBtn.gameObject:SetActive(true)
    else
        missionInfoNode.trackBtn.gameObject:SetActive(true)
        missionInfoNode.stopBtn.gameObject:SetActive(false)
    end
    missionInfoNode.trackBtn.onClick:RemoveAllListeners();
    missionInfoNode.trackBtn.onClick:AddListener(function()
        local id = self.m_selectedMissionId
        local sys = self.m_missionSystem
        PhaseManager:PopPhase(PhaseId.Mission, function()
            sys:TrackMission(id)
        end)
    end)
    missionInfoNode.stopBtn.onClick:RemoveAllListeners()
    missionInfoNode.stopBtn.onClick:AddListener(function()
        self.m_missionSystem:StopTrackMission()
    end)
end
MissionCtrl._RefreshMissionTrackTip = HL.Method() << function(self)
    self:_TraverseAllMissionCell(function(missionId, missionCell)
        local missionInfo = self.m_missionSystem:GetMissionInfo(missionId)
        self:_SetMissionCellTrack(missionCell, missionInfo)
    end)
end
MissionCtrl.OnObjectiveUpdate = HL.Method(HL.Any) << function(self, arg)
    local questId = unpack(arg)
    local missionId = self.m_missionSystem:GetMissionIdByQuestId(questId)
    if not string.isEmpty(self.m_selectedMissionId) and self.m_selectedMissionId == missionId then
        self:_RefreshObjectiveProgress(missionId)
    end
end
MissionCtrl.OnTrackMissionChange = HL.Method() << function(self)
    self:_RefreshTrackBtn()
    self:_RefreshMissionTrackTip()
end
MissionCtrl.OnMissionStateChange = HL.Method(HL.Any) << function(self, arg)
    local missionId, missionState = unpack(arg)
    self:_RefreshMissionList()
    self:_RefreshSelectedMission()
    self:_RefreshMissionInfo()
    self:_RefreshEmptyNode()
    self:_AutoSelectMission()
end
MissionCtrl.OnQuestStateChange = HL.Method(HL.Any) << function(self, arg)
    local questId, questState = unpack(arg)
    local missionId = self.m_missionSystem:GetMissionIdByQuestId(questId)
    if missionId == self.m_selectedMissionId then
        self:_RefreshMissionInfo()
    end
end
MissionCtrl.OnSyncAllMission = HL.Method(HL.Any) << function(self, arg)
    self:_RefreshMissionList()
    self:_RefreshSelectedMission()
    self:_RefreshMissionInfo()
end
MissionCtrl.OnAnimationInFinished = HL.Override() << function(self)
end
MissionCtrl._ChangeSelectedMission = HL.Method(HL.Number) << function(self, offset)
    local selectedIndex
    local missionIdInfoList = {}
    for k, v in ipairs(self.m_missionViewInfo) do
        if v.type == MissionListCellType_Chapter then
            for kk, missionViewInfo in pairs(v.missionList) do
                table.insert(missionIdInfoList, { cellIndex = k, subIndex = kk, id = missionViewInfo.id, })
                if missionViewInfo.id == self.m_selectedMissionId then
                    selectedIndex = #missionIdInfoList
                end
            end
        else
            table.insert(missionIdInfoList, { cellIndex = k, id = v.id, })
            if v.id == self.m_selectedMissionId then
                selectedIndex = #missionIdInfoList
            end
        end
    end
    if not selectedIndex then
        return
    end
    local newInfo = missionIdInfoList[selectedIndex + offset]
    if not newInfo then
        return
    end
    self.m_selectedMissionId = newInfo.id
    self:_RefreshSelectedMission()
    self:_RefreshMissionInfo()
    self.view.missionScrollView:ScrollToIndex(CSIndex(newInfo.cellIndex), true)
end
HL.Commit(MissionCtrl)