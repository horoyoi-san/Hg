local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
PRTSInvestigateCategoryCell = HL.Class('PRTSInvestigateCategoryCell', UIWidgetBase)
PRTSInvestigateCategoryCell.m_genCollCell = HL.Field(HL.Forward("UIListCache"))
PRTSInvestigateCategoryCell.m_genNoteCell = HL.Field(HL.Forward("UIListCache"))
PRTSInvestigateCategoryCell.m_infoBundle = HL.Field(HL.Table)
PRTSInvestigateCategoryCell.m_isNoteShown = HL.Field(HL.Boolean) << false
PRTSInvestigateCategoryCell._OnFirstTimeInit = HL.Override() << function(self)
    self.m_genCollCell = UIUtils.genCellCache(self.view.collCell)
    self.m_genNoteCell = UIUtils.genCellCache(self.view.noteCell)
    self.view.noteBtn.onClick:RemoveAllListeners()
    self.view.noteBtn.onClick:AddListener(function()
        Notify(MessageConst.PRTS_CHANGE_INVESTIGATE_GALLERY_NOTE_VISIBLE, true)
    end)
end
PRTSInvestigateCategoryCell.InitPRTSInvestigateCategoryCell = HL.Method(HL.Table) << function(self, infoBundle)
    self:_FirstTimeInit()
    self.m_infoBundle = infoBundle
    local viewRef = self.view
    viewRef.titleTxt.text = infoBundle.title
    local noteCountText = string.format(Language.LUA_PRTS_NOTE_COUNT_FORMAT, #infoBundle.noteInfos)
    viewRef.noteCountTxt1.text = noteCountText
    viewRef.noteCountTxt2.text = noteCountText
    viewRef.noteCountTxt3.text = noteCountText
    self:RefreshUINoteShowState(infoBundle.showNote, infoBundle.isPlayNoteAni)
    self.m_genCollCell:Refresh(#infoBundle.collInfos, function(cell, luaIndex)
        self:_OnRefreshCollCell(cell, luaIndex)
    end)
    self.m_genNoteCell:Refresh(#infoBundle.noteInfos, function(cell, luaIndex)
        self:_OnRefreshNoteCell(cell, luaIndex)
    end)
end
PRTSInvestigateCategoryCell._OnRefreshCollCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local info = self.m_infoBundle.collInfos[luaIndex]
    cell.iconImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_PRTS_ICON, info.imgPath)
    cell.nameTxt.text = info.name
    cell.gotoBtn.onClick:RemoveAllListeners()
    cell.gotoBtn.onClick:AddListener(function()
        local ids = {}
        for _, collInfo in pairs(self.m_infoBundle.collInfos) do
            table.insert(ids, collInfo.collId)
        end
        if PhaseManager:IsOpen(PhaseId.PRTSStoryCollDetail) then
            PhaseManager:ExitPhaseFast(PhaseId.PRTSStoryCollDetail)
        end
        PhaseManager:GoToPhase(PhaseId.PRTSStoryCollDetail, { isFirstLvId = false, idList = ids, initShowIndex = luaIndex, showGotoBtn = false, })
    end)
    info.hasRead = true
    cell.redDot:InitRedDot("PRTSItem", info.collId)
end
PRTSInvestigateCategoryCell._OnRefreshNoteCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local info = self.m_infoBundle.noteInfos[luaIndex]
    cell.indexTxt.text = string.format(Language.LUA_PRTS_NOTE_INDEX_FORMAT, info.index + 1)
    cell.descTxt.text = UIUtils.resolveTextCinematic(info.desc)
    cell.redDot:InitRedDot("PRTSNote", info.noteId)
    info.hasRead = true
end
PRTSInvestigateCategoryCell.RefreshUINoteShowState = HL.Method(HL.Boolean, HL.Boolean) << function(self, isShow, playAni)
    self.m_isNoteShown = isShow
    if isShow then
        if playAni then
            self.view.noteState:SetState("ShowNote")
        else
            self.view.noteState:SetState("ShowNote")
        end
    else
        if playAni then
            self.view.noteState:SetState("HideNote")
        else
            self.view.noteState:SetState("HideNote")
        end
    end
    if isShow then
        self.view.noteBtnState:SetState("NoteShown")
    elseif self:_HasNoteUnread() then
        self.view.noteBtnState:SetState("HasNew")
    else
        self.view.noteBtnState:SetState("Normal")
    end
end
PRTSInvestigateCategoryCell._HasNoteUnread = HL.Method().Return(HL.Boolean) << function(self)
    for _, info in pairs(self.m_infoBundle.noteInfos) do
        if GameInstance.player.prts:IsNoteUnread(info.noteId) then
            return true
        end
    end
    return false
end
HL.Commit(PRTSInvestigateCategoryCell)
return PRTSInvestigateCategoryCell