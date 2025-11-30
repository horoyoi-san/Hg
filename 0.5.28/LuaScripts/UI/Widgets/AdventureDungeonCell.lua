local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
AdventureDungeonCell = HL.Class('AdventureDungeonCell', UIWidgetBase)
AdventureDungeonCell.m_genRewardCells = HL.Field(HL.Forward("UIListCache"))
AdventureDungeonCell.m_rewardInfos = HL.Field(HL.Table)
AdventureDungeonCell.m_info = HL.Field(HL.Table)
AdventureDungeonCell.m_subGameIds = HL.Field(HL.Table)
AdventureDungeonCell._OnFirstTimeInit = HL.Override() << function(self)
    self.view.goToBtn.onClick:RemoveAllListeners()
    self.view.goToBtn.onClick:AddListener(function()
        self:_OnClickGoToBtn()
    end)
    self.view.tracerBtn.onClick:RemoveAllListeners()
    self.view.tracerBtn.onClick:AddListener(function()
        self:_OnClickTracerBtn()
    end)
    self.m_genRewardCells = UIUtils.genCellCache(self.view.rewardCell)
end
AdventureDungeonCell.InitAdventureDungeonCell = HL.Method(HL.Any) << function(self, info)
    self:_FirstTimeInit()
    self.m_info = info
    self.m_subGameIds = info.subGameIds
    local hasRoleImg = not string.isEmpty(info.dungeonRoleImg)
    local hasDungeonImg = not string.isEmpty(info.dungeonImg)
    if hasRoleImg then
        self.view.imgState:SetState("ShowRoleIcon")
        self.view.roleImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_MONSTER_ICON, info.dungeonRoleImg)
        if hasDungeonImg then
            self.view.dungeonBgImg.gameObject:SetActiveIfNecessary(true)
            self.view.dungeonBgImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ADVENTURE, info.dungeonImg)
        else
            self.view.dungeonBgImg.gameObject:SetActiveIfNecessary(false)
        end
    elseif hasDungeonImg then
        self.view.imgState:SetState("ShowDungeonIcon")
        self.view.dungeonBgImg.gameObject:SetActiveIfNecessary(true)
        self.view.dungeonBgImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ADVENTURE, info.dungeonImg)
        self.view.dungeonImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ADVENTURE, info.dungeonImg)
    end
    self.view.dungeonNameTxt.text = info.dungeonName
    if string.isEmpty(info.staminaTxt) then
        self.view.staminaState:SetState("HideStamina")
    else
        self.view.staminaState:SetState("ShowStamina")
        self.view.staminaCostTxt.text = info.staminaTxt
    end
    self.m_rewardInfos = info.rewardInfos
    self.m_genRewardCells:Refresh(#self.m_rewardInfos, function(cell, luaIndex)
        local rewardInfo = self.m_rewardInfos[luaIndex]
        cell:InitItemAdventureReward(rewardInfo)
    end)
    if info.isActive then
        self.view.btnNodeState:SetState("ShowGoToBtn")
    else
        self.view.btnNodeState:SetState("ShowTracerBtn")
    end
    self.view.redDot:InitRedDot("AdventureDungeonCell", self.m_subGameIds)
end
AdventureDungeonCell._OnClickGoToBtn = HL.Method() << function(self)
    local id = self.m_info.seriesId
    if string.isEmpty(id) then
        return
    end
    if self.m_info.onGotoDungeon then
        self.m_info.onGotoDungeon()
    end
    Notify(MessageConst.ON_OPEN_DUNGEON_ENTRY_PANEL, { id })
    GameInstance.player.subGameSys:SendSubGameListRead(self.m_subGameIds)
end
AdventureDungeonCell._OnClickTracerBtn = HL.Method() << function(self)
    local hasData, instId = GameInstance.player.mapManager:GetMapMarkInstId(self.m_info.mapMarkType, self.m_info.seriesId)
    if not hasData then
        logger.error("[MapManager.GetMapMarkInstId] missing, id = " .. self.m_info.seriesId .. " type = " .. self.m_info.mapMarkType:ToString())
        return
    end
    if self.m_info.onGotoDungeon then
        self.m_info.onGotoDungeon()
    end
    MapUtils.openMap(instId)
    GameInstance.player.subGameSys:SendSubGameListRead(self.m_subGameIds)
end
HL.Commit(AdventureDungeonCell)
return AdventureDungeonCell