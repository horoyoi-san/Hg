CharInfoSkillUIHelper = HL.Class('CharInfoSkillUIHelper')
CharInfoSkillUIHelper.m_panel = HL.Field(HL.Table)
CharInfoSkillUIHelper.m_config = HL.Field(HL.Table)
CharInfoSkillUIHelper.m_skillCells = HL.Field(HL.Forward("UIListCache"))
CharInfoSkillUIHelper.m_charInfo = HL.Field(HL.Table)
CharInfoSkillUIHelper.skillIndex = HL.Field(HL.Number) << -1
CharInfoSkillUIHelper.talentIndex = HL.Field(HL.Number) << -1
CharInfoSkillUIHelper.facSkillIndex = HL.Field(HL.Number) << -1
CharInfoSkillUIHelper.m_controllerBindingKey = HL.Field(HL.Number) << -1
CharInfoSkillUIHelper.m_phaseMessageMgr = HL.Field(HL.Forward("MessageManager"))
CharInfoSkillUIHelper.m_resourceLoader = HL.Field(CS.Beyond.LuaResourceLoader)
CharInfoSkillUIHelper.m_talentList = HL.Field(HL.Forward("UIListCache"))
CharInfoSkillUIHelper.m_facSkillList = HL.Field(HL.Forward("UIListCache"))
CharInfoSkillUIHelper.CharInfoSkillUIHelper = HL.Constructor() << function(self)
end
CharInfoSkillUIHelper.Init = HL.Method(HL.Table, HL.Forward("MessageManager"), CS.Beyond.LuaResourceLoader) << function(self, panel, messageMgr, resourceLoader)
    self.m_panel = panel
    self.m_config = Utils.wrapLuaNode(panel).config
    self.m_phaseMessageMgr = messageMgr
    self.m_resourceLoader = resourceLoader
    self:_InitSkill()
    self:_InitTalent()
    self:_InitFacSkill()
end
CharInfoSkillUIHelper.GetInputGroupId = HL.Method().Return(HL.Opt((HL.Number))) << function(self)
    if not self.m_panel then
        return
    end
    return self.m_panel.inputBindingGroupMonoTarget.groupId
end
CharInfoSkillUIHelper.BindControllerKey = HL.Method(HL.Boolean) << function(self, isOn)
    InputManagerInst:DeleteBinding(self.m_controllerBindingKey)
    if isOn then
        self.m_controllerBindingKey = UIUtils.bindInputPlayerAction("char_change_skill", function()
            self:OnSkillClick(2)
        end, self.m_panel.inputBindingGroupMonoTarget.groupId)
    end
end
CharInfoSkillUIHelper._InitSkill = HL.Method() << function(self)
    self.m_panel.canvas.worldCamera = CameraManager.mainCamera
    local skillNum = Const.CHAR_SKILL_NUM
    self.m_skillCells = UIUtils.genCellCache(self.m_panel.rankCell)
    self.m_skillCells:Refresh(skillNum, function(cell, luaIndex)
        local data = {}
        cell.charInfoSkillCell:InitCharInfoSkillCell(data, function(info)
            self:OnSkillClick(luaIndex)
        end)
        cell.gameObject:SetActive(true)
    end)
end
CharInfoSkillUIHelper._InitTalent = HL.Method() << function(self)
    self.m_talentList = UIUtils.genCellCache(self.m_panel.talentListNode)
end
CharInfoSkillUIHelper._InitFacSkill = HL.Method() << function(self)
    self.m_facSkillList = UIUtils.genCellCache(self.m_panel.facSkillistNode)
end
CharInfoSkillUIHelper._SetSkillSelect = HL.Method(HL.Any) << function(self, luaIndex)
    self.skillIndex = luaIndex
    for i = 1, self.m_skillCells:GetCount() do
        local cell = self.m_skillCells:Get(i)
        cell.charInfoSkillCell:SetSelect(i == luaIndex)
    end
end
CharInfoSkillUIHelper._SetTalentSelect = HL.Method(HL.Number) << function(self, luaIndex)
    self.talentIndex = luaIndex
    for rowIndex = 1, self.m_talentList:GetCount() do
        local cellCache = self.m_talentList:Get(rowIndex).cellCache
        if cellCache then
            for columnIndex = 1, cellCache:GetCount() do
                local cell = cellCache:Get(columnIndex)
                local cellIndex = cell.cellIndex
                cell.select.gameObject:SetActive(cellIndex == self.talentIndex)
            end
        end
    end
end
CharInfoSkillUIHelper._SetFacSkillSelect = HL.Method(HL.Number) << function(self, luaIndex)
    self.facSkillIndex = luaIndex
    for rowIndex = 1, self.m_facSkillList:GetCount() do
        local cellCache = self.m_facSkillList:Get(rowIndex).cellCache
        if cellCache then
            for columnIndex = 1, cellCache:GetCount() do
                local cell = cellCache:Get(columnIndex)
                local cellIndex = cell.cellIndex
                cell.select.gameObject:SetActive(cellIndex == self.facSkillIndex)
            end
        end
    end
end
CharInfoSkillUIHelper.OnSkillClick = HL.Method(HL.Number) << function(self, luaIndex)
    self:_SetSkillSelect(luaIndex)
    self:_SetTalentSelect(-1)
    self:_SetFacSkillSelect(-1)
    self:_TryOpenSkillUpgrade()
    local instId = self.m_charInfo.instId
    local skillDataDict = CharInfoUtils.getPlayerCharCurSkills(instId)
    self.m_phaseMessageMgr:Send(MessageConst.P_CHAR_INFO_SKILL_UPGRADE_SHOW_SKILL, skillDataDict[luaIndex])
end
CharInfoSkillUIHelper._TryOpenSkillUpgrade = HL.Method() << function(self)
    self.m_phaseMessageMgr:Send(MessageConst.P_CHAR_INFO_SKILL_UPGRADE_OPEN)
end
CharInfoSkillUIHelper._OnTalentClick = HL.Method(HL.Number) << function(self, luaIndex)
    self:_SetTalentSelect(luaIndex)
    self:_SetSkillSelect(-1)
    self:_SetFacSkillSelect(-1)
    self:_TryOpenSkillUpgrade()
    local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
    local breakStage = charInfo.breakStage
    local maxBreakStage = Tables.characterConst.maxBreak
    local talents = CharInfoUtils.getCharBreakStageTalents(self.m_charInfo.templateId, breakStage, maxBreakStage, true)
    local unlockTalents = talents.unlockTalents
    local enhancedTalents = talents.enhancedTalents
    local unlockCount = #unlockTalents
    local enhancedCount = #enhancedTalents
    local unlock = luaIndex <= enhancedCount
    local talent = enhancedTalents[luaIndex] or unlockTalents[luaIndex - enhancedCount]
    self.m_phaseMessageMgr:Send(MessageConst.P_CHAR_INFO_SKILL_UPGRADE_SHOW_TALENT, { talent, unlock })
end
CharInfoSkillUIHelper._OnFacSkillOnClick = HL.Method(HL.Number) << function(self, luaIndex)
    self:_SetTalentSelect(-1)
    self:_SetSkillSelect(-1)
    self:_SetFacSkillSelect(luaIndex)
    self:_TryOpenSkillUpgrade()
    local maxBreakStage = Tables.characterConst.maxBreak
    local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
    local breakStage = charInfo.breakStage
    local facSkills = CharInfoUtils.getCharBreakStageFacSkills(self.m_charInfo.templateId, breakStage, maxBreakStage, true)
    local unlockFacSkills = facSkills.unlockFacSkills
    local upgradeFacSkills = facSkills.upgradeFacSkills
    local unlockCount = #unlockFacSkills
    local upgradeCount = #upgradeFacSkills
    local skillData = upgradeFacSkills[luaIndex] or unlockFacSkills[luaIndex - upgradeCount]
    self.m_phaseMessageMgr:Send(MessageConst.P_CHAR_INFO_SKILL_UPGRADE_SHOW_FAC_SKILL, { skillId = skillData.id, isUnlock = luaIndex > upgradeCount })
end
CharInfoSkillUIHelper.SetActive = HL.Method(HL.Boolean) << function(self, active)
    self.m_panel.gameObject:SetActive(active)
    self:BindControllerKey(active)
end
CharInfoSkillUIHelper.SetSelect = HL.Method(HL.Boolean) << function(self, select)
    self.m_panel.lineSelect.gameObject:SetActive(not select)
    self.m_panel.lineNormal.gameObject:SetActive(select)
end
CharInfoSkillUIHelper.Reset = HL.Method() << function(self)
    self:_SetSkillSelect(-1)
    self:_SetTalentSelect(-1)
    self:_SetFacSkillSelect(-1)
end
CharInfoSkillUIHelper.RefreshCharInfo = HL.Method(HL.Table) << function(self, charInfo)
    self.m_charInfo = charInfo
    self:_RefreshSkills()
    self:_RefreshTalent()
    self:_RefreshFacSkills()
end
CharInfoSkillUIHelper._RefreshSkills = HL.Method() << function(self)
    local instId = self.m_charInfo.instId
    local skillDataDict = CharInfoUtils.getPlayerCharCurSkills(instId)
    for btnIndex, skillDatas in pairs(skillDataDict) do
        if #skillDatas > 0 then
            local cell = self.m_skillCells:Get(btnIndex)
            local data = { charInfo = self.m_charInfo, skills = skillDatas, }
            cell.charInfoSkillCell:InitSkill(data)
            local skillType = UIConst.SKILL_BTN_INDEX_2_TYPE[btnIndex]
            local levelString
            if skillType == Const.SkillTypeEnum.NormalAttack then
                levelString = "MAX"
            else
                local level = skillDatas[1].level
                levelString = string.format("%d", level)
            end
            cell.text.text = "RANK " .. levelString
            cell.textShadow.text = "RANK " .. levelString
        end
    end
end
CharInfoSkillUIHelper._ClearTalent = HL.Method() << function(self)
    self.m_talentList:Refresh(0)
end
CharInfoSkillUIHelper._ClearFacSkill = HL.Method() << function(self)
    self.m_facSkillList:Refresh(0)
end
CharInfoSkillUIHelper._ClearAll = HL.Method() << function(self)
    self:_ClearTalent()
    self:_ClearFacSkill()
    self.m_skillCells:Refresh(0)
end
CharInfoSkillUIHelper._GetTalentNums = HL.Method(HL.Table).Return(HL.Table) << function(self, talents)
    local unlockTalents = talents.unlockTalents
    local enhancedTalents = talents.enhancedTalents
    local unlockCount = #unlockTalents
    local enhancedCount = #enhancedTalents
    local talentListNode = self.m_panel.talentListNode
    local cell = talentListNode.charInfoSkillTalentCell
    talentListNode.gameObject:SetActive(true)
    cell.gameObject:SetActive(true)
    local cellWidthList = {}
    for i = 1, enhancedCount do
        local talentData = enhancedTalents[i].talentData
        cell.text = talentData.talentName
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_panel.cellNode.transform)
        local width = cell.transform.rect.width
        table.insert(cellWidthList, width)
    end
    for i = 1, unlockCount do
        local talentData = unlockTalents[i].talentData
        cell.text = talentData.talentName
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_panel.cellNode.transform)
        local width = cell.transform.rect.width
        table.insert(cellWidthList, width)
    end
    cell.gameObject:SetActive(false)
    talentListNode.gameObject:SetActive(false)
    local space = self.m_config.TALENT_LIST_SPACE
    local width = self.m_config.TALENT_LIST_WIDTH
    local nums = UIUtils.getCellNums(width, space, cellWidthList)
    return nums
end
CharInfoSkillUIHelper._GetFacSkillNums = HL.Method(HL.Table).Return(HL.Table) << function(self, facSkills)
    local unlockFacSkills = facSkills.unlockFacSkills
    local upgradeFacSkills = facSkills.upgradeFacSkills
    local unlockCount = #unlockFacSkills
    local upgradeCount = #upgradeFacSkills
    local facSkillistNode = self.m_panel.facSkillistNode
    local cell = facSkillistNode.charInfoFacSkillCell
    facSkillistNode.gameObject:SetActive(true)
    cell.gameObject:SetActive(true)
    local cellWidthList = {}
    for i = 1, upgradeCount do
        local skillData = upgradeFacSkills[i]
        cell.text.text = skillData.name
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_panel.facSkillCellNode.transform)
        local width = cell.transform.rect.width
        table.insert(cellWidthList, width)
    end
    for i = 1, unlockCount do
        local skillData = unlockFacSkills[i]
        cell.text.text = skillData.name
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_panel.facSkillCellNode.transform)
        local width = cell.transform.rect.width
        table.insert(cellWidthList, width)
    end
    facSkillistNode.gameObject:SetActive(false)
    cell.gameObject:SetActive(false)
    local space = self.m_config.FACSKILL_LIST_SPACE
    local width = self.m_config.FACSKILL_LIST_WIDTH
    local nums = UIUtils.getCellNums(width, space, cellWidthList)
    return nums
end
CharInfoSkillUIHelper._RefreshTalent = HL.Method() << function(self)
    local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
    local breakStage = charInfo.breakStage
    local maxBreakStage = Tables.characterConst.maxBreak
    local talents = CharInfoUtils.getCharBreakStageTalents(self.m_charInfo.templateId, breakStage, maxBreakStage, true)
    local unlockTalents = talents.unlockTalents
    local enhancedTalents = talents.enhancedTalents
    local unlockCount = #unlockTalents
    local enhancedCount = #enhancedTalents
    local nums = self:_GetTalentNums(talents)
    local row = #nums
    self:_ClearTalent()
    local totalCellNum = 0
    self.m_talentList:Refresh(row, function(talentList, rowIndex)
        local cellNum = nums[rowIndex]
        if not talentList.cellCache then
            talentList.cellCache = UIUtils.genCellCache(talentList.charInfoSkillTalentCell)
        end
        talentList.cellCache:Refresh(cellNum, function(cell, columnIndex)
            local cellIndex = totalCellNum + columnIndex
            local talent = enhancedTalents[cellIndex] or unlockTalents[cellIndex - enhancedCount]
            local lock = cellIndex > enhancedCount
            cell.cellIndex = cellIndex
            local talentData = talent.talentData
            local text = cell.text
            text.text = talentData.talentName
            if lock then
                UIUtils.changeAlpha(text, UIConst.LOCK_ALPHA)
            else
                UIUtils.changeAlpha(text, 1)
            end
            LayoutRebuilder.ForceRebuildLayoutImmediate(cell.transform)
            cell.lockedIcon.gameObject:SetActive(lock)
            cell.button.onClick:RemoveAllListeners()
            cell.button.onClick:AddListener(function()
                self:_OnTalentClick(cellIndex)
            end)
        end)
        totalCellNum = totalCellNum + cellNum
        LayoutRebuilder.ForceRebuildLayoutImmediate(talentList.transform)
    end)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_panel.cellNode.transform)
end
CharInfoSkillUIHelper._RefreshFacSkills = HL.Method() << function(self)
    local maxBreakStage = Tables.characterConst.maxBreak
    local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
    local breakStage = charInfo.breakStage
    local facSkills = CharInfoUtils.getCharBreakStageFacSkills(self.m_charInfo.templateId, breakStage, maxBreakStage, true)
    local unlockFacSkills = facSkills.unlockFacSkills
    local upgradeFacSkills = facSkills.upgradeFacSkills
    local unlockCount = #unlockFacSkills
    local upgradeCount = #upgradeFacSkills
    local count = upgradeCount + unlockCount
    local nums = self:_GetFacSkillNums(facSkills)
    local row = #nums
    self:_ClearFacSkill()
    local totalCellNum = 0
    self.m_facSkillList:Refresh(row, function(facSkillList, rowIndex)
        local cellNum = nums[rowIndex]
        if not facSkillList.cellCache then
            facSkillList.cellCache = UIUtils.genCellCache(facSkillList.charInfoFacSkillCell)
        end
        facSkillList.cellCache:Refresh(cellNum, function(cell, columnIndex)
            local cellIndex = totalCellNum + columnIndex
            local skillData = upgradeFacSkills[cellIndex] or unlockFacSkills[cellIndex - upgradeCount]
            local lock = cellIndex > upgradeCount
            cell.cellIndex = cellIndex
            local text = cell.text
            local textShadow = cell.textShadow
            local icon = cell.icon
            icon.sprite = self.m_resourceLoader:LoadSprite(UIUtils.getSpritePath(UIConst.UI_SPRITE_FAC_SKILL_ICON, skillData.icon))
            text.text = skillData.name
            textShadow.text = skillData.name
            if lock then
                UIUtils.changeAlpha(text, UIConst.LOCK_ALPHA)
                UIUtils.changeAlpha(textShadow, UIConst.LOCK_ALPHA)
                UIUtils.changeAlpha(icon, UIConst.LOCK_ALPHA)
            else
                UIUtils.changeAlpha(text, 1)
                UIUtils.changeAlpha(textShadow, 1)
                UIUtils.changeAlpha(icon, 1)
            end
            cell.iconShadow.sprite = self.m_resourceLoader:LoadSprite(UIUtils.getSpritePath(UIConst.UI_SPRITE_FAC_SKILL_ICON, skillData.icon))
            cell.lockedIcon.gameObject:SetActive(lock)
            cell.button.onClick:RemoveAllListeners()
            cell.button.onClick:AddListener(function()
                self:_OnFacSkillOnClick(cellIndex)
            end)
        end)
        totalCellNum = totalCellNum + cellNum
        LayoutRebuilder.ForceRebuildLayoutImmediate(facSkillList.transform)
    end)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_panel.facSkillCellNode.transform)
end
CharInfoSkillUIHelper.Destroy = HL.Method() << function(self)
    self:_ClearAll()
    self:SetActive(false)
end
HL.Commit(CharInfoSkillUIHelper)
return CharInfoSkillUIHelper