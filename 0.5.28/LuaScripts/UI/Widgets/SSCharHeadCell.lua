local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SSCharHeadCell = HL.Class('SSCharHeadCell', UIWidgetBase)
SSCharHeadCell._OnFirstTimeInit = HL.Override() << function(self)
    self.view.infoButton.onClick:AddListener(function()
        self:ShowTips()
    end)
    self.view.button.onClick:AddListener(function()
        self:_OnClick()
    end)
    if self.view.config.SHOW_TIPS_ON_HOVER_DELAY >= 0 then
        self.view.button.onHoverChange:AddListener(function(isEnter)
            self.m_hoverTipsTimerId = self:_ClearTimer(self.m_hoverTipsTimerId)
            if isEnter then
                self.m_hoverTipsTimerId = self:_StartTimer(self.view.config.SHOW_TIPS_ON_HOVER_DELAY, function()
                    self:ShowTips(nil, nil, true)
                end)
            else
                Notify(MessageConst.HIDE_SPACESHIP_CHAR_TIPS, { key = self.transform, isHover = true, })
            end
        end)
    end
    self.view.chooseNode.gameObject:SetActive(false)
    self.m_skillCells = UIUtils.genCellCache(self.view.skillCell)
end
SSCharHeadCell.m_hoverTipsTimerId = HL.Field(HL.Number) << -1
SSCharHeadCell.ShowTips = HL.Method(HL.Opt(HL.Any, HL.Any, HL.Boolean)) << function(self, posType, padding, isHover)
    Notify(MessageConst.SHOW_SPACESHIP_CHAR_TIPS, { key = self.transform, isHover = isHover, charId = self.m_charId, tmpSafeArea = self.transform, transform = self.m_tipsPositionTrans or self.transform, posType = posType or self.m_args.posType, padding = padding or self.m_args.padding, })
end
SSCharHeadCell.m_charId = HL.Field(HL.String) << ''
SSCharHeadCell.m_args = HL.Field(HL.Table)
SSCharHeadCell.m_tipsPositionTrans = HL.Field(CS.UnityEngine.Transform)
SSCharHeadCell.m_skillCells = HL.Field(HL.Forward('UIListCache'))
SSCharHeadCell.InitSSCharHeadCell = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    self.m_args = args
    local charId = args.charId
    self.m_charId = charId
    self.m_tipsPositionTrans = args.tipsPositionTrans
    SpaceshipUtils.updateSSCharInfos(self.view, charId, args.targetRoomId)
    local spaceship = GameInstance.player.spaceship
    local char = spaceship.characters:get_Item(charId)
    local roomData = Tables.spaceshipRoomInsTable[args.targetRoomId]
    local roomType = roomData.roomType
    local skillCount = char.skills.Count
    local indexList = char:GetSkillIndexList()
    self.m_skillCells:Refresh(skillCount, function(cell, index)
        local skillId = char.skills[indexList[CSIndex(index)]]
        local skillData = Tables.spaceshipSkillTable[skillId]
        cell.icon:LoadSprite(UIConst.UI_SPRITE_SS_SKILL_ICON, skillData.icon)
        cell.inactive.gameObject:SetActive(skillData.roomType ~= roomType)
    end)
end
SSCharHeadCell._OnClick = HL.Method() << function(self)
    if self.m_args.onClick then
        self.m_args.onClick()
    end
end
SSCharHeadCell.SetChooseState = HL.Method(HL.Any) << function(self, state)
    if not state then
        self.view.chooseNode.gameObject:SetActive(false)
        return
    end
    self.view.chooseNode.gameObject:SetActive(true)
    if state == true then
        self.view.chooseIcon.gameObject:SetActive(true)
        self.view.chooseIndexTxt.gameObject:SetActive(false)
    else
        self.view.chooseIcon.gameObject:SetActive(false)
        self.view.chooseIndexTxt.gameObject:SetActive(true)
        self.view.chooseIndexTxt.text = state
    end
end
HL.Commit(SSCharHeadCell)
return SSCharHeadCell