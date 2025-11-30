local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SSCharSkillNode = HL.Class('SSCharSkillNode', UIWidgetBase)
SSCharSkillNode.m_charId = HL.Field(HL.String) << ''
SSCharSkillNode.m_skillCells = HL.Field(HL.Forward('UIListCache'))
SSCharSkillNode._OnFirstTimeInit = HL.Override() << function(self)
    self.m_skillCells = UIUtils.genCellCache(self.view.skillCell)
end
SSCharSkillNode.InitSSCharSkillNode = HL.Method(HL.String, HL.Opt(HL.String)) << function(self, charId, targetRoomId)
    self:_FirstTimeInit()
    self.m_charId = charId
    local spaceship = GameInstance.player.spaceship
    local char = spaceship.characters:get_Item(charId)
    local roomType
    if targetRoomId then
        local roomData = Tables.spaceshipRoomInsTable[targetRoomId]
        roomType = roomData.roomType
    end
    local ssCharSkillInfoList = Tables.spaceshipCharSkillTable[charId]
    local skillIndexList = {}
    for skIndex = 0, ssCharSkillInfoList.maxSkillCount - 1 do
        local isValid = true
        if self.view.config.HIDE_NON_VALID_SKILL then
            local unlocked, skillId = char.skills:TryGetValue(skIndex)
            if unlocked then
                local skillData = Tables.spaceshipSkillTable[skillId]
                isValid = skillData.roomType == roomType
            else
                isValid = false
            end
        end
        if isValid then
            table.insert(skillIndexList, skIndex)
        end
    end
    local skillCount = #skillIndexList
    self.m_skillCells:Refresh(skillCount, function(cell, index)
        local skIndex = skillIndexList[index]
        local unlocked, skillId = char.skills:TryGetValue(skIndex)
        local nextSkillId, unlockHint = char:GetNextSkillId(skIndex)
        if unlocked then
            cell.gameObject.name = "SkillCell-" .. skillId
            local canLevelUp = not string.isEmpty(nextSkillId)
            cell.upgradeBtn.gameObject:SetActive(canLevelUp)
            cell.upgradeHint.gameObject:SetActive(false)
            cell.upgradeBtn.onClick:RemoveAllListeners()
            if canLevelUp then
                cell.upgradeBtn.onClick:AddListener(function()
                    cell.upgradeHint.gameObject:SetActive(not cell.upgradeHint.gameObject.activeSelf)
                end)
                cell.upgradeHintTxt.text = unlockHint
            end
            local skillData = Tables.spaceshipSkillTable[skillId]
            cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_SS_SKILL_ICON, skillData.icon)
            cell.nameTxt.text = skillData.name
            cell.desc.text = skillData.desc
            local isActive = true
            if roomType then
                isActive = skillData.roomType == roomType
            end
            cell.animationWrapper:PlayWithTween(isActive and "ss_char_skill_cell_normal" or "ss_char_skill_cell_inactive")
        else
            cell.gameObject.name = "SkillCell-" .. nextSkillId
            local skillData = Tables.spaceshipSkillTable[nextSkillId]
            cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_SS_SKILL_ICON, skillData.icon)
            cell.nameTxt.text = skillData.name
            cell.desc.text = unlockHint
            cell.upgradeHint.gameObject:SetActive(false)
            cell.upgradeBtn.gameObject:SetActive(false)
            cell.animationWrapper:PlayWithTween("ss_char_skill_cell_locked")
        end
    end)
end
HL.Commit(SSCharSkillNode)
return SSCharSkillNode