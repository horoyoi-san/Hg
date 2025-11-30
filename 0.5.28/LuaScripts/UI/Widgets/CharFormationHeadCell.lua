local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
CharFormationHeadCell = HL.Class('CharFormationHeadCell', UIWidgetBase)
CharFormationHeadCell.info = HL.Field(HL.Table)
CharFormationHeadCell.exInfo = HL.Field(HL.Table)
CharFormationHeadCell.charInfo = HL.Field(HL.Userdata)
CharFormationHeadCell.characterData = HL.Field(HL.Userdata)
CharFormationHeadCell.isDead = HL.Field(HL.Boolean) << false
CharFormationHeadCell.isUnavailable = HL.Field(HL.Boolean) << false
CharFormationHeadCell.m_singleModeSelected = HL.Field(HL.Boolean) << false
CharFormationHeadCell._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_CHAR_LEVEL_UP, function(args)
        self:_OnLevelChanged(args)
    end)
end
CharFormationHeadCell.InitCharFormationHeadCell = HL.Method(HL.Table, HL.Opt(HL.Function)) << function(self, info, onClick)
    self:_FirstTimeInit()
    self:_InitData(info)
    self:_InitCharBaseInfo()
    self:RefreshCharInfo()
    self:SetDead(self.charInfo.isDead)
    self:SetUnavailable(false)
    if info.noHpBar then
        self.view.charHeadBar.gameObject:SetActive(false)
    end
    if self.info.singleSelect then
        self:SetSingleSelect(self.info.singleSelect)
    else
        self:SetMultiSelect(self.info.selectIndex, true)
    end
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        if onClick then
            onClick()
        end
    end)
end
CharFormationHeadCell._OnLevelChanged = HL.Method(HL.Table) << function(self, args)
    local charInstId, exp = unpack(args)
    if charInstId == self.info.instId then
        self:RefreshCharInfo()
    end
end
CharFormationHeadCell.RefreshExInfo = HL.Method(HL.Table) << function(self, exInfo)
    self.exInfo = exInfo
end
CharFormationHeadCell._InitData = HL.Method(HL.Table) << function(self, info)
    self.info = info
    self.characterData = Tables.characterTable:GetValue(self.info.templateId)
    local instId = info.instId
    if instId and instId > 0 then
        self.charInfo = CharInfoUtils.getPlayerCharInfoByInstId(instId)
        self.isDead = self.charInfo.isDead
    end
end
CharFormationHeadCell._InitCharBaseInfo = HL.Method() << function(self)
    local spriteName = UIConst.UI_CHAR_HEAD_SQUARE_PREFIX .. self.info.templateId
    self.view.imageChar.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD_RECTANGLE, spriteName)
    self.view.charElementIcon:InitCharTypeIcon(self.characterData.charTypeId)
    local proSpriteName = UIConst.UI_CHAR_PROFESSION_PREFIX .. self.characterData.profession:ToInt() .. UIConst.UI_CHAR_PROFESSION_SMALL_SUFFIX
    self.view.imagePro.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_PROFESSION, proSpriteName)
    local rarityColor = UIUtils.getCharRarityColor(self.characterData.rarity)
    if rarityColor then
        self.view.rarityColor.color = rarityColor
    end
    local isFixed, isTrail = CharInfoUtils.getLockedFormationCharTipsShow(self.info)
    self.view.fixedTips.gameObject:SetActive(isFixed)
    self.view.tryoutTips.gameObject:SetActive(isTrail)
    self.gameObject.name = "CharHeadCell_" .. self.info.templateId
end
CharFormationHeadCell.SetMultiSelect = HL.Method(HL.Any, HL.Opt(HL.Boolean)) << function(self, num, playAnim)
    self.view.selectedBG.gameObject:SetActiveIfNecessary(false)
    if num ~= nil and num > 0 then
        self.view.textNum.text = string.format("%d", num)
        self.view.selectedMarkMulti.gameObject:SetActive(true)
        self.view.selectedMarkSingle.gameObject:SetActive(false)
        self.view.selectedMark.gameObject:SetActive(true)
    else
        self.view.selectedMark.gameObject:SetActive(false)
    end
    self.info.selectIndex = num
    if num and num > 0 then
        self.view.button.clickHintTextId = "virtual_mouse_hint_unselect"
    else
        self.view.button.clickHintTextId = "key_hint_common_confirm"
    end
end
CharFormationHeadCell.SetSingleSelect = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, singleSelect, playAnim)
    self.view.selectedBG.gameObject:SetActive(singleSelect)
    if self.m_singleModeSelected then
        if not singleSelect then
            self.view.button.clickHintTextId = ""
        else
            local instId = self.info.instId
            local curInstId = (self.exInfo and self.exInfo.selectedCharInfo) and self.exInfo.selectedCharInfo.charInstId or nil
            if instId == curInstId then
                self.view.button.clickHintTextId = "ui_char_formation_out_team"
            else
                self.view.button.clickHintTextId = "LUA_CHAR_FORMATION_SINGLE_CONFIRM"
            end
        end
    end
end
CharFormationHeadCell.SetSingleModeSelected = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, selected, playAnim)
    self.view.selectedMarkMulti.gameObject:SetActive(not selected)
    self.view.selectedMarkSingle.gameObject:SetActive(selected)
    self.view.selectedMark.gameObject:SetActive(self.info.slotIndex <= Const.BATTLE_SQUAD_MAX_CHAR_NUM)
    self.view.button.clickHintTextId = ""
    self.m_singleModeSelected = selected
end
CharFormationHeadCell.SetDead = HL.Method(HL.Boolean) << function(self, dead)
    self.view.disableMask.gameObject:SetActive(dead)
end
CharFormationHeadCell.SetUnavailable = HL.Method(HL.Boolean) << function(self, unavailable)
    self.isUnavailable = unavailable
    self.view.unavailableMask.gameObject:SetActive(unavailable)
end
CharFormationHeadCell.RefreshCharInfo = HL.Method() << function(self)
    if self.charInfo then
        self.view.textLv.text = string.format("%02d", self.charInfo.level)
        self.view.textLv.gameObject:SetActive(true)
        if self.charInfo.charType == GEnums.CharType.Trial then
            self.view.curHpFill.fillAmount = 1
        else
            if self.charInfo.battleInfo and self.charInfo.attributes then
                self.view.charHeadBar.gameObject:SetActive(true)
                self.view.addHpFill.gameObject:SetActive(false)
                self.view.curHpFill.gameObject:SetActive(true)
                self.view.curHpFill.fillAmount = self.charInfo.battleInfo.hp / self.charInfo.attributes:GetValue(GEnums.AttributeType.MaxHp)
            else
                self.view.charHeadBar.gameObject:SetActive(false)
            end
        end
    else
        self.view.textLv.gameObject:SetActive(false)
        self.view.charHeadBar.gameObject:SetActive(false)
    end
end
HL.Commit(CharFormationHeadCell)
return CharFormationHeadCell