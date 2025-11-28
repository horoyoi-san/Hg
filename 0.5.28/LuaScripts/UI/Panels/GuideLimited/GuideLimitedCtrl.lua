local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local mainHudCtrl = require_ex('UI/Panels/MainHud/MainHudCtrl')
local PANEL_ID = PanelId.GuideLimited
GuideLimitedCtrl = HL.Class('GuideLimitedCtrl', uiCtrl.UICtrl)
local INITIAL_GUIDE_ID = 1
local NEXT_GUIDE_SHOW_DELAY = 1.0
local DEFAULT_ICON = "guide_limited_icon_default"
local LimitedGuideType = CS.Beyond.Gameplay.LimitedGuideType
GuideLimitedCtrl.m_showQueue = HL.Field(HL.Forward("Queue"))
GuideLimitedCtrl.m_guideInfoMap = HL.Field(HL.Table)
GuideLimitedCtrl.m_nextGuideId = HL.Field(HL.Number) << 1
GuideLimitedCtrl.m_showUpdate = HL.Field(HL.Number) << -1
GuideLimitedCtrl.m_updateValid = HL.Field(HL.Boolean) << true
GuideLimitedCtrl.m_delayShowTimer = HL.Field(HL.Number) << -1
GuideLimitedCtrl.m_progressWidth = HL.Field(HL.Number) << -1
GuideLimitedCtrl.m_isShowing = HL.Field(HL.Boolean) << false
GuideLimitedCtrl.m_isMainVisible = HL.Field(HL.Boolean) << false
GuideLimitedCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.CLEAR_LIMITED_GUIDE] = '_OnClearLimitedGuide', [MessageConst.ON_GUIDE_PREPARE_NARRATIVE] = '_RefreshMainVisibleState', [MessageConst.ON_GUIDE_LEAVE_NARRATIVE] = '_RefreshMainVisibleState', [MessageConst.ON_CLEAR_SCREEN_STATE_CHANGED] = '_RefreshMainVisibleState', }
GuideLimitedCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_showQueue = require_ex("Common/Utils/DataStructure/Queue")()
    self.m_nextGuideId = INITIAL_GUIDE_ID
    self.m_guideInfoMap = {}
    self.m_progressWidth = self.view.progressLine.rect.width
    self.view.button.onClick:AddListener(function()
        self:_OnClickButton()
    end)
end
GuideLimitedCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, isActive)
    self.m_updateValid = isActive
end
GuideLimitedCtrl.OnShowLimitedGuide = HL.StaticMethod(HL.Any) << function(args)
    local guideInfo = unpack(args)
    if guideInfo == nil then
        return
    end
    local ctrl = UIManager:AutoOpen(PANEL_ID)
    ctrl:TryShowLimitedGuide(guideInfo)
end
GuideLimitedCtrl.TryShowLimitedGuide = HL.Method(HL.Any) << function(self, guideInfo)
    if self.m_isShowing and guideInfo.needIgnoreWhenConflict then
        return
    end
    local guideId = self.m_nextGuideId
    self.m_nextGuideId = self.m_nextGuideId + 1
    self.m_guideInfoMap[guideId] = guideInfo
    if self.m_showQueue:Empty() then
        self:_StartShowLimitedGuide(guideId)
    end
    self.m_showQueue:Push(guideId)
end
GuideLimitedCtrl._StartShowLimitedGuide = HL.Method(HL.Number) << function(self, guideId)
    local guideInfo = self.m_guideInfoMap[guideId]
    if guideInfo == nil then
        return
    end
    self:_RefreshDisplayState(guideId)
    local duration = guideInfo.duration
    local time = 0.0
    self:_RefreshProgressFillState(0)
    self.m_showUpdate = LuaUpdate:Add("Tick", function(deltaTime)
        if not self:IsShow() or not self.m_updateValid or not self.m_isMainVisible then
            return
        end
        if time >= duration then
            self:_StopShowLimitedGuide(guideId)
        end
        self:_RefreshProgressFillState(time / duration)
        time = time + deltaTime
    end)
    self.m_isShowing = true
    GameInstance.player.guide.isLimitedGuideShowing = true
    self:_RefreshMainVisibleState()
end
GuideLimitedCtrl._StopShowLimitedGuide = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, guideId, forceStop)
    self:_RefreshProgressFillState(0)
    self.m_showUpdate = LuaUpdate:Remove(self.m_showUpdate)
    if self.m_showQueue:Front() ~= guideId then
        logger.error("Wrong sequence in limited guide show queue!")
        return
    end
    self.m_showQueue:Pop()
    self.m_guideInfoMap[guideId] = nil
    if forceStop then
        self.m_showQueue:Clear()
        self.m_guideInfoMap = {}
    end
    if not self.m_showQueue:Empty() then
        self.m_delayShowTimer = self:_StartTimer(NEXT_GUIDE_SHOW_DELAY, function()
            self.m_delayShowTimer = self:_ClearTimer(self.m_delayShowTimer)
            self:_StartShowLimitedGuide(self.m_showQueue:Front())
        end)
    else
        self.m_isShowing = false
        GameInstance.player.guide.isLimitedGuideShowing = false
        self:_RefreshMainVisibleState()
    end
end
GuideLimitedCtrl._RefreshMainVisibleState = HL.Method(HL.Opt(HL.Any)) << function(self, args)
    local isVisible = true
    if not self.m_isShowing then
        isVisible = false
    end
    if GameInstance.player.guide.isInterruptByNarrative then
        isVisible = false
    end
    if mainHudCtrl.MainHudCtrl.s_clearScreenId ~= nil and mainHudCtrl.MainHudCtrl.s_clearScreenId > 0 then
        isVisible = false
    end
    if mainHudCtrl.MainHudCtrl.s_clearScreenIdExceptSomePanel ~= nil and mainHudCtrl.MainHudCtrl.s_clearScreenIdExceptSomePanel > 0 then
        isVisible = false
    end
    self.view.main.gameObject:SetActive(isVisible)
    self.m_isMainVisible = isVisible
end
GuideLimitedCtrl._RefreshDisplayState = HL.Method(HL.Number) << function(self, guideId)
    local guideInfo = self.m_guideInfoMap[guideId]
    if guideInfo == nil then
        return
    end
    self.view.text.text = Language[guideInfo.textId]
    local sprite
    if guideInfo.type == LimitedGuideType.MediaGuide then
        sprite = self:LoadSprite(UIConst.UI_SPRITE_GUIDE, DEFAULT_ICON)
    elseif guideInfo.type == LimitedGuideType.Wiki then
        sprite = self:_GetWikiIconSprite(guideInfo.wikiId)
    end
    if sprite ~= nil then
        self.view.icon.sprite = sprite
        self.view.iconShadow.sprite = sprite
    end
end
GuideLimitedCtrl._RefreshProgressFillState = HL.Method(HL.Number) << function(self, percent)
    if IsNull(self.view.progressLine) then
        return
    end
    local currentWidth = (1 - percent) * self.m_progressWidth
    UIUtils.setSizeDeltaX(self.view.progressLine, currentWidth)
end
GuideLimitedCtrl._OnClickButton = HL.Method() << function(self)
    if self.m_showQueue:Empty() then
        return
    end
    local guideId = self.m_showQueue:Front()
    local guideInfo = self.m_guideInfoMap[guideId]
    if guideInfo == nil then
        return
    end
    if guideInfo.type == LimitedGuideType.MediaGuide then
        self:_StartMediaGuide(guideInfo.mediaGuideGroupId)
    elseif guideInfo.type == LimitedGuideType.Wiki then
        self:_ShowWikiEntry(guideInfo.wikiId)
    end
    self:_StopShowLimitedGuide(guideId)
end
GuideLimitedCtrl._OnClearLimitedGuide = HL.Method() << function(self)
    if self.m_showQueue:Empty() then
        return
    end
    if not self.m_isShowing then
        return
    end
    local guideId = self.m_showQueue:Front()
    self:_StopShowLimitedGuide(guideId, true)
end
GuideLimitedCtrl._ShowWikiEntry = HL.Method(HL.String) << function(self, wikiId)
    Notify(MessageConst.SHOW_WIKI_ENTRY, { wikiEntryId = wikiId, })
end
GuideLimitedCtrl._GetWikiIconSprite = HL.Method(HL.String).Return(HL.Userdata) << function(self, wikiId)
    local normalSuccess, entryData = Tables.wikiEntryDataTable:TryGetValue(wikiId)
    if normalSuccess then
        local itemId = entryData.refItemId
        local monsterId = entryData.refMonsterTemplateId
        if not string.isEmpty(itemId) then
            local itemSuccess, itemData = Tables.itemTable:TryGetValue(itemId)
            if itemSuccess then
                return self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
            end
        elseif not string.isEmpty(monsterId) then
            return self:LoadSprite(UIConst.UI_SPRITE_WIKI_MONSTER, monsterId)
        end
    else
        return self:LoadSprite(UIConst.UI_SPRITE_GUIDE, DEFAULT_ICON)
    end
end
GuideLimitedCtrl._StartMediaGuide = HL.Method(HL.String) << function(self, mediaGuideGroupId)
    if string.isEmpty(mediaGuideGroupId) then
        return
    end
    GameInstance.player.guide:ManuallyStartGuideGroup(mediaGuideGroupId)
end
HL.Commit(GuideLimitedCtrl)