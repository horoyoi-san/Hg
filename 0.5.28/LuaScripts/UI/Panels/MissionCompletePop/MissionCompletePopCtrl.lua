local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MissionCompletePop
local ChapterType = CS.Beyond.Gameplay.ChapterType
local MissionState = CS.Beyond.Gameplay.MissionSystem.MissionState
local CHAPTER_ICON_PATH = "Mission/ChapterIcon"
local CHAPTER_BG_ICON_PATH = "Mission/ChapterBgIcon"
local ChapterConfig = { [ChapterType.Main] = { icon = "chapter_main_icon_01", bgIcon = "chapter_main_bg_icon_01", deco = "main_mission_icon_gray", }, [ChapterType.Other] = { icon = "", bgIcon = "", deco = "", }, }
MissionCompletePopCtrl = HL.Class('MissionCompletePopCtrl', uiCtrl.UICtrl)
MissionCompletePopCtrl.s_messages = HL.StaticField(HL.Table) << {}
MissionCompletePopCtrl.m_chapterEffectList = HL.Field(HL.Table)
MissionCompletePopCtrl.m_itemCells = HL.Field(HL.Forward("UIListCache"))
MissionCompletePopCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    Notify(MessageConst.COMMON_START_BLOCK_MAIN_HUD_TOAST)
    self.m_chapterEffectList = {}
    local chapterId, state = unpack(arg)
    self:PushChapter(chapterId, state)
    self.view.main.gameObject:SetActive(false)
    self:_StartCoroutine(function()
        while #self.m_chapterEffectList > 0 do
            coroutine.step()
            while UIManager:IsOpen(PanelId.CommonTaskTrackToast) do
                coroutine.step()
            end
            local chapterEffect = table.remove(self.m_chapterEffectList, 1)
            self.view.main.gameObject:SetActive(true)
            local length = self:_Refresh(chapterEffect.chapterId, chapterEffect.state)
            coroutine.wait(length)
            self.view.main.gameObject:SetActive(false)
        end
        self:Close()
    end)
end
MissionCompletePopCtrl._Refresh = HL.Method(HL.String, HL.Number).Return(HL.Number) << function(self, chapterId, state)
    local missionSystem = GameInstance.player.mission
    local chapterInfo = missionSystem:GetChapterInfo(chapterId)
    if chapterInfo then
        local length = 0
        if chapterInfo.type == ChapterType.Main or chapterInfo.type == ChapterType.Other then
            length = self:_RefreshMainChapter(chapterInfo, state)
        elseif chapterInfo.type == ChapterType.Character then
            length = self:_RefreshCharacterChapter(chapterInfo, state)
        end
        return length
    end
    return 0
end
MissionCompletePopCtrl._RefreshMainChapter = HL.Method(HL.Any, HL.Number).Return(HL.Number) << function(self, chapterInfo, state)
    if state == 0 then
        AudioManager.PostEvent("Au_UI_Banner_Chapter_Main_Start")
    else
        AudioManager.PostEvent("Au_UI_Banner_Chapter_Main_Finish")
    end
    local chapterMain = self.view.chapterMain
    local chapterCharacter = self.view.chapterCharacter
    chapterMain.gameObject:SetActive(true)
    chapterCharacter.gameObject:SetActive(false)
    chapterMain.episodeName.text = UIUtils.resolveTextStyle(chapterInfo.episodeName:GetText())
    local chapterNumTxt = UIUtils.resolveTextStyle(chapterInfo.chapterNum:GetText())
    local episodeNumTxt = UIUtils.resolveTextStyle(chapterInfo.episodeNum:GetText())
    local separator = ""
    if not string.isEmpty(chapterNumTxt) and not string.isEmpty(episodeNumTxt) then
        separator = " — "
    end
    chapterMain.chapterNumAndEpisodeNum.text = chapterNumTxt .. separator .. episodeNumTxt
    local chapterConfig = ChapterConfig[chapterInfo.type]
    if not string.isEmpty(chapterInfo.icon) then
        chapterMain.icon.gameObject:SetActive(true)
        chapterMain.icon.sprite = self:LoadSprite(CHAPTER_ICON_PATH, chapterInfo.icon)
    elseif not string.isEmpty(chapterConfig.icon) then
        chapterMain.icon.gameObject:SetActive(true)
        chapterMain.icon.sprite = self:LoadSprite(CHAPTER_ICON_PATH, chapterConfig.icon)
    else
        chapterMain.icon.gameObject:SetActive(false)
        chapterMain.icon.sprite = nil
    end
    if not string.isEmpty(chapterInfo.bgIcon) then
        chapterMain.bgIcon.gameObject:SetActive(true)
        chapterMain.bgIcon.sprite = self:LoadSprite(CHAPTER_BG_ICON_PATH, chapterInfo.bgIcon .. "_long")
    elseif not string.isEmpty(chapterConfig.icon) then
        chapterMain.bgIcon.gameObject:SetActive(true)
        chapterMain.bgIcon.sprite = self:LoadSprite(CHAPTER_BG_ICON_PATH, chapterConfig.bgIcon .. "_long")
    else
        chapterMain.bgIcon.gameObject:SetActive(false)
        chapterMain.bgIcon.sprite = nil
    end
    if not string.isEmpty(chapterConfig.deco) then
        chapterMain.deco.gameObject:SetActive(true)
        chapterMain.deco.sprite = self:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, chapterConfig.deco)
    else
        chapterMain.deco.gameObject:SetActive(false)
        chapterMain.deco.sprite = nil
    end
    chapterMain.chapterStartLabel.gameObject:SetActive(state == 0)
    chapterMain.chapterCompleteLabel.gameObject:SetActive(state ~= 0)
    chapterMain.finishTitle.gameObject:SetActive(state ~= 0)
    local animWrapper = self:GetAnimationWrapper()
    if state == 0 then
        animWrapper:PlayWithTween(self.view.config.CHAPTER_MAIN_START_ANIM)
        local length = animWrapper:GetClipLength(self.view.config.CHAPTER_MAIN_START_ANIM)
        return length
    else
        animWrapper:PlayWithTween(self.view.config.CHAPTER_MAIN_FINISH_ANIM)
        local length = animWrapper:GetClipLength(self.view.config.CHAPTER_MAIN_FINISH_ANIM)
        return length
    end
end
MissionCompletePopCtrl._RefreshCharacterChapter = HL.Method(HL.Any, HL.Number).Return(HL.Number) << function(self, chapterInfo, state)
    if state == 0 then
        AudioManager.PostEvent("Au_UI_Banner_Chapter_Character_Start")
    else
        AudioManager.PostEvent("Au_UI_Banner_Chapter_Character_Finish")
    end
    local chapterMain = self.view.chapterMain
    local chapterCharacter = self.view.chapterCharacter
    chapterMain.gameObject:SetActive(false)
    chapterCharacter.gameObject:SetActive(true)
    chapterCharacter.episodeName.text = UIUtils.resolveTextStyle(chapterInfo.episodeName:GetText())
    local chapterNumTxt = UIUtils.resolveTextStyle(chapterInfo.chapterNum:GetText())
    local episodeNumTxt = UIUtils.resolveTextStyle(chapterInfo.episodeNum:GetText())
    local separator = ""
    if not string.isEmpty(chapterNumTxt) and not string.isEmpty(episodeNumTxt) then
        separator = " — "
    end
    chapterCharacter.chapterNumAndEpisodeNum.text = chapterNumTxt .. separator .. episodeNumTxt
    if not string.isEmpty(chapterInfo.iconInChapterBanner) then
        chapterCharacter.charIcon.gameObject:SetActive(true)
        chapterCharacter.charIcon.sprite = self:LoadSprite("CharInfo", chapterInfo.iconInChapterBanner)
    else
        chapterCharacter.charIcon.gameObject:SetActive(false)
        chapterCharacter.charIcon.sprite = nil
    end
    chapterCharacter.startText.gameObject:SetActive(state == 0)
    chapterCharacter.finishText.gameObject:SetActive(state ~= 0)
    chapterCharacter.finishDeco.gameObject:SetActive(state ~= 0)
    local animWrapper = self:GetAnimationWrapper()
    if state == 0 then
        animWrapper:PlayWithTween(self.view.config.CHAPTER_CHARACTER_START_ANIM)
        local length = animWrapper:GetClipLength(self.view.config.CHAPTER_CHARACTER_START_ANIM)
        return length
    else
        animWrapper:PlayWithTween(self.view.config.CHAPTER_CHARACTER_FINISH_ANIM)
        local length = animWrapper:GetClipLength(self.view.config.CHAPTER_CHARACTER_FINISH_ANIM)
        return length
    end
end
MissionCompletePopCtrl.PushChapter = HL.Method(HL.String, HL.Number) << function(self, chapterId, state)
    table.insert(self.m_chapterEffectList, { state = state, chapterId = chapterId })
end
MissionCompletePopCtrl.IsOpen = HL.StaticMethod().Return(HL.Boolean) << function()
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    return isOpen
end
MissionCompletePopCtrl.OnChapterStart = HL.StaticMethod(HL.Table) << function(arg)
    local chapterId = unpack(arg)
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    if isOpen then
        ctrl:PushChapter(chapterId, 0)
    else
        UIManager:Open(PANEL_ID, { chapterId, 0 })
    end
end
MissionCompletePopCtrl.OnChapterCompleted = HL.StaticMethod(HL.Table) << function(arg)
    local chapterId = unpack(arg)
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    if isOpen then
        ctrl:PushChapter(chapterId, 1)
    else
        UIManager:Open(PANEL_ID, { chapterId, 1 })
    end
end
MissionCompletePopCtrl.OnClose = HL.Override() << function(self)
    Notify(MessageConst.COMMON_END_BLOCK_MAIN_HUD_TOAST)
end
HL.Commit(MissionCompletePopCtrl)