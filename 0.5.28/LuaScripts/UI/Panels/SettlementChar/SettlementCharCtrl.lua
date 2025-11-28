local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementChar
local settlementSystem = GameInstance.player.settlementSystem
SettlementCharCtrl = HL.Class('SettlementCharCtrl', uiCtrl.UICtrl)
SettlementCharCtrl.m_settlementId = HL.Field(HL.String) << ""
SettlementCharCtrl.m_curOfficerId = HL.Field(HL.Any) << nil
SettlementCharCtrl.m_charInfoList = HL.Field(HL.Table)
SettlementCharCtrl.m_curSelectedCharIndex = HL.Field(HL.Number) << 1
SettlementCharCtrl.m_getFeatureCellFunc = HL.Field(HL.Function)
SettlementCharCtrl.m_getCharCellFunc = HL.Field(HL.Function)
SettlementCharCtrl.m_waitMsgToClose = HL.Field(HL.Boolean) << false
SettlementCharCtrl.m_filterSetting = HL.Field(HL.Table)
SettlementCharCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SETTLEMENT_OFFICER_CHANGE] = '_OnSettlementOfficerChange', }
SettlementCharCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnBack.onClick:AddListener(function()
        Notify(MessageConst.ON_SETTLEMENT_CHAR_CLOSE)
        PhaseManager:PopPhase(PhaseId.SettlementChar)
    end)
    if arg == nil or type(arg) ~= "string" then
        logger.error(ELogChannel.UI, "打开联络干员界面参数错误")
        return
    end
    self.m_filterSetting = { { name = Language.LUA_SPACESHIP_CHAR_WORKING, isOn = false, type = "working", }, { name = Language.LUA_SETTLEMENT_HAVE_CHAR_ENHANCE, isOn = false, type = "enhance", } }
    self.view.mask.onClick:AddListener(function()
    end)
    local selectedFilter = {}
    local luaWidget = self.view.transform:Find("Main/SettlementDetails/Down/FilterBtn"):GetComponent("LuaUIWidget")
    local filterBtn = UIWidgetManager:Wrap(luaWidget)
    filterBtn:InitFilterBtn({
        tagGroups = { { tags = self.m_filterSetting } },
        selectedTags = selectedFilter,
        onConfirm = function(tags)
            for i = 1, #self.m_filterSetting do
                self.m_filterSetting[i].isOn = false
            end
            if tags ~= nil then
                for i = 1, #tags do
                    for j = 1, #self.m_filterSetting do
                        if self.m_filterSetting[j].type == tags[i].type then
                            self.m_filterSetting[j].isOn = true
                        end
                    end
                end
            end
            self:_RefreshCharList()
        end,
    })
    self.m_settlementId = arg
    self.m_curOfficerId = settlementSystem:GetSettlementOfficerId(self.m_settlementId)
    self.m_getCharCellFunc = UIUtils.genCachedCellFunction(self.view.charScrollList)
    self.view.charScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_RefreshCharCell(self.m_getCharCellFunc(obj), LuaIndex(csIndex))
    end)
    self:_RefreshCharList()
    self.view.btnRemove.onClick:AddListener(function()
        settlementSystem:SetOfficer(self.m_settlementId, nil)
        self.m_waitMsgToClose = true
    end)
    self.view.btnConfirm.onClick:AddListener(function()
        local charId = self.m_charInfoList[self.m_curSelectedCharIndex].templateId
        local charData = Tables.characterTable[charId]
        local charSettledId = settlementSystem:GetCharSettledId(charId)
        if charSettledId == self.m_settlementId then
            Notify(MessageConst.ON_SETTLEMENT_CHAR_CLOSE)
            PhaseManager:PopPhase(PhaseId.SettlementChar)
        elseif charSettledId ~= nil then
            local settlementData = Tables.settlementBasicDataTable[charSettledId]
            Notify(MessageConst.SHOW_POP_UP, {
                content = string.format(Language.LUA_SETTLEMENT_CHARACTER_SWITCH_CONFIRM, charData.name, settlementData.settlementName),
                charIcons = { charId },
                hideBlur = true,
                onConfirm = function()
                    settlementSystem:SetOfficer(self.m_settlementId, charId)
                    self.m_waitMsgToClose = true
                end
            })
        else
            settlementSystem:SetOfficer(self.m_settlementId, charId)
            self.m_waitMsgToClose = true
        end
    end)
    self.m_getFeatureCellFunc = UIUtils.genCachedCellFunction(self.view.featureScrollList)
    self.view.featureScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_RefreshFeatureCell(self.m_getFeatureCellFunc(obj), csIndex)
    end)
    self:_OnSelectCharChange(1)
end
SettlementCharCtrl._RefreshCharList = HL.Method() << function(self)
    self.m_charInfoList = {}
    local index = 1
    for _, charInfo in pairs(GameInstance.player.charBag.charList) do
        if charInfo.templateId ~= self.m_curOfficerId and charInfo.templateId ~= Tables.globalConst.maleCharID and charInfo.templateId ~= Tables.globalConst.femaleCharID then
            for j = 1, #self.m_filterSetting do
                if self.m_filterSetting[j].isOn then
                    if self.m_filterSetting[j].type == "working" then
                        if settlementSystem:GetCharSettledId(charInfo.templateId) == nil then
                            goto continue
                        end
                    elseif self.m_filterSetting[j].type == "enhance" then
                        local enhanceRate = settlementSystem:GetSettlementTotalEnhanceRate(self.m_settlementId, charInfo.templateId)
                        if enhanceRate.Item1 == 0 and enhanceRate.Item2 == 0 then
                            goto continue
                        end
                    end
                end
            end
            self.m_charInfoList[index] = { templateId = charInfo.templateId, rate = settlementSystem:GetSettlementTotalEnhanceRate(self.m_settlementId, charInfo.templateId) }
            index = index + 1
            ::continue::
        end
    end
    table.sort(self.m_charInfoList, function(a, b)
        if a == nil then
            return false
        end
        if b == nil then
            return true
        end
        local aCount = settlementSystem:GetCharTagPreferredCount(a.templateId, self.m_settlementId)
        local bCount = settlementSystem:GetCharTagPreferredCount(b.templateId, self.m_settlementId)
        if aCount ~= bCount then
            return aCount > bCount
        end
        return (a.rate.Item1 + a.rate.Item2) > (a.rate.Item1 + b.rate.Item2)
    end)
    if self.m_curOfficerId ~= nil then
        table.insert(self.m_charInfoList, 1, { templateId = self.m_curOfficerId, })
    end
    self.view.charScrollList:UpdateCount(#self.m_charInfoList)
end
SettlementCharCtrl._RefreshCharCell = HL.Method(HL.Table, HL.Number) << function(self, cell, luaIndex)
    local charId = self.m_charInfoList[luaIndex].templateId
    local charData = Tables.characterTable[charId]
    if not Tables.characterTagTable:ContainsKey(charId) then
        return
    end
    local charTagData = Tables.characterTagTable[charId]
    local hobbyName1
    local hobbyName2
    local hobbyTags = charTagData.hobbyTagIds
    if #hobbyTags == 1 then
        hobbyName1 = Tables.tagDataTable[hobbyTags[0]].tagName
        hobbyName2 = nil
    end
    if #hobbyTags == 2 then
        hobbyName1 = Tables.tagDataTable[hobbyTags[0]].tagName
        hobbyName2 = Tables.tagDataTable[hobbyTags[1]].tagName
    end
    local blocName = Tables.tagDataTable[charTagData.blocTagId].tagName
    local expertName1, expertName2
    local expertTagIds = charTagData.expertTagIds
    if #expertTagIds == 1 then
        expertName1 = Tables.tagDataTable[expertTagIds[0]].tagName
        expertName2 = nil
    elseif #expertTagIds == 2 then
        expertName1 = Tables.tagDataTable[expertTagIds[0]].tagName
        expertName2 = Tables.tagDataTable[expertTagIds[1]].tagName
    end
    if charTagData.blocId == "" then
        return
    end
    local blocPre = false
    if settlementSystem:IsCharTagPreferred(charTagData.blocTagId, self.m_settlementId) then
        blocPre = true
    end
    local blocIconName = Tables.blocDataTable[charTagData.blocId].icon
    if self.m_curSelectedCharIndex ~= luaIndex then
        cell.normalNode.gameObject:SetActiveIfNecessary(true)
        cell.selectNode.gameObject:SetActiveIfNecessary(false)
        cell.charIconNormal.spriteName = "icon_" .. charId
        cell.charNameNormal.text = charData.name
        cell.charHobbyNormal1.text = hobbyName1
        if hobbyName2 ~= nil then
            cell.charHobbyNormal2.gameObject:SetActiveIfNecessary(true)
            cell.charHobbyNormal2.text = hobbyName2
            if settlementSystem:IsCharTagPreferred(charTagData.hobbyTagIds[1], self.m_settlementId) then
                cell.charHobbyNormal2.color = self.view.config.charNormalTxtHighlightColor
            else
                cell.charHobbyNormal2.color = self.view.config.charNormalTxtColor
            end
        else
            cell.charHobbyNormal2.gameObject:SetActiveIfNecessary(false)
        end
        if settlementSystem:IsCharTagPreferred(charTagData.hobbyTagIds[0], self.m_settlementId) then
            cell.charHobbyNormal1.color = self.view.config.charNormalTxtHighlightColor
        else
            cell.charHobbyNormal1.color = self.view.config.charNormalTxtColor
        end
        cell.charBlocNormal.text = blocName
        if blocPre then
            cell.charBlocNormal.color = self.view.config.charNormalTxtHighlightColor
        else
            cell.charBlocNormal.color = self.view.config.charNormalTxtColor
        end
        cell.charExpertNormal1.text = expertName1
        if expertName2 ~= nil then
            cell.charExpertNormal2.gameObject:SetActiveIfNecessary(true)
            cell.charExpertNormal2.text = expertName2
            if settlementSystem:IsCharTagPreferred(charTagData.expertTagIds[1], self.m_settlementId) then
                cell.charExpertNormal2.color = self.view.config.charNormalTxtHighlightColor
            else
                cell.charExpertNormal2.color = self.view.config.charNormalTxtColor
            end
        else
            cell.charExpertNormal2.gameObject:SetActiveIfNecessary(false)
        end
        if settlementSystem:IsCharTagPreferred(charTagData.expertTagIds[0], self.m_settlementId) then
            cell.charExpertNormal1.color = self.view.config.charNormalTxtHighlightColor
        else
            cell.charExpertNormal1.color = self.view.config.charNormalTxtColor
        end
    else
        cell.normalNode.gameObject:SetActiveIfNecessary(false)
        cell.selectNode.gameObject:SetActiveIfNecessary(true)
        cell.selectNode:Play("settlementchar_select")
        cell.charIconSelected.spriteName = "icon_" .. charId
        cell.charNameSelected.text = charData.name
        cell.charHobbySelected1.text = hobbyName1
        if hobbyName2 ~= nil then
            cell.charHobbySelected2.gameObject:SetActiveIfNecessary(true)
            cell.charHobbySelected2.text = hobbyName2
            if settlementSystem:IsCharTagPreferred(charTagData.hobbyTagIds[1], self.m_settlementId) then
                cell.charHobbySelected2.color = self.view.config.charSelectedTxtHighlightColor
            else
                cell.charHobbySelected2.color = self.view.config.charSelectedTxtColor
            end
        else
            cell.charHobbySelected2.gameObject:SetActiveIfNecessary(false)
        end
        if settlementSystem:IsCharTagPreferred(charTagData.hobbyTagIds[0], self.m_settlementId) then
            cell.charHobbySelected1.color = self.view.config.charSelectedTxtHighlightColor
        else
            cell.charHobbySelected1.color = self.view.config.charSelectedTxtColor
        end
        cell.charBlocSelected.text = blocName
        if blocPre then
            cell.charBlocSelected.color = self.view.config.charSelectedTxtHighlightColor
        else
            cell.charBlocSelected.color = self.view.config.charSelectedTxtColor
        end
        cell.charExpertSelected1.text = expertName1
        if expertName2 ~= nil then
            cell.charExpertSelected2.gameObject:SetActiveIfNecessary(true)
            cell.charExpertSelected2.text = expertName2
            if settlementSystem:IsCharTagPreferred(charTagData.expertTagIds[1], self.m_settlementId) then
                cell.charExpertSelected2.color = self.view.config.charSelectedTxtHighlightColor
            else
                cell.charExpertSelected2.color = self.view.config.charSelectedTxtColor
            end
        else
            cell.charExpertSelected2.gameObject:SetActiveIfNecessary(false)
        end
        if settlementSystem:IsCharTagPreferred(charTagData.expertTagIds[0], self.m_settlementId) then
            cell.charExpertSelected1.color = self.view.config.charSelectedTxtHighlightColor
        else
            cell.charExpertSelected1.color = self.view.config.charSelectedTxtColor
        end
    end
    local insideSettlementId = settlementSystem:GetCharSettledId(charId)
    cell.currentNode.gameObject:SetActiveIfNecessary(insideSettlementId == self.m_settlementId)
    cell.otherNode.gameObject:SetActiveIfNecessary(insideSettlementId ~= self.m_settlementId and insideSettlementId ~= nil)
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        if luaIndex ~= self.m_curSelectedCharIndex then
            self:_OnSelectCharChange(luaIndex)
        end
    end)
end
SettlementCharCtrl._RefreshOfficerInfo = HL.Method() << function(self)
    local charId = self.m_charInfoList[self.m_curSelectedCharIndex].templateId
    local charData = Tables.characterTable[charId]
    local settlementData = Tables.settlementBasicDataTable[self.m_settlementId]
    self.view.officerContent.gameObject:SetActiveIfNecessary(true)
    self.view.officerEmpty.gameObject:SetActiveIfNecessary(false)
    self.view.officerNameText.text = charData.name
    self.view.headIcon.spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. charId
    local enhanceRate = settlementSystem:GetSettlementTotalEnhanceRate(self.m_settlementId, charId)
    self.view.officerEffectText.text = ""
    if enhanceRate.Item1 > 0 then
        self.view.officerEffectText.text = UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHARACTER_EXP_EFFECT, enhanceRate.Item1)) .. "\n"
    end
    if enhanceRate.Item2 > 0 then
        self.view.officerEffectText.text = self.view.officerEffectText.text .. UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHARACTER_REWARD_EFFECT, enhanceRate.Item2))
    end
    if enhanceRate.Item1 == 0 and enhanceRate.Item2 == 0 then
        self.view.officerEffectText.text = Language.LUA_SETTLEMENT_CHARACTER_NO_EFFECT
    end
    self.view.btnRemove.gameObject:SetActiveIfNecessary(self.m_curOfficerId == charId)
end
SettlementCharCtrl._RefreshFeatureInfo = HL.Method() << function(self)
    local settlementData = Tables.settlementBasicDataTable[self.m_settlementId]
    self.view.featureScrollList:UpdateCount(#settlementData.wantTagIdGroup)
end
SettlementCharCtrl._RefreshFeatureCell = HL.Method(HL.Table, HL.Number) << function(self, cell, csIndex)
    local tagId = Tables.settlementBasicDataTable[self.m_settlementId].wantTagIdGroup[csIndex]
    local tagData = Tables.settlementTagTable[tagId]
    local officerId = self.m_charInfoList[self.m_curSelectedCharIndex].templateId
    local charEnhance = settlementSystem:GetSettlementTagEnhanceRateByChar(tagId, officerId)
    local enhanceRate = settlementSystem:GetSettlementTagEnhanceRate(tagId)
    local extendText = ""
    if enhanceRate.Item1 > 0 then
        extendText = "\n" .. UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHAR_ENHANCE_EXP, enhanceRate.Item1))
    end
    if enhanceRate.Item2 > 1 then
        extendText = extendText .. "\n" .. UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_CHAR_ENHANCE_REWARD, enhanceRate.Item2))
    end
    cell.activeState.gameObject:SetActiveIfNecessary(charEnhance.Item1 > 0 or charEnhance.Item2 > 0)
    cell.featureNormalText.text = tagData.settlementTagName
    cell.featureLockedText.text = tagData.settlementTagName
    cell.detailNormalText.text = tagData.desc .. extendText
    cell.detailLockText.text = tagData.desc .. extendText
    cell.animationWrapper:Play("settlementchar_listin")
end
SettlementCharCtrl._OnSelectCharChange = HL.Method(HL.Number) << function(self, newIndex)
    local oldItem = self.m_getCharCellFunc(self.m_curSelectedCharIndex)
    local newItem = self.m_getCharCellFunc(newIndex)
    local oldIndex = self.m_curSelectedCharIndex
    self.m_curSelectedCharIndex = newIndex
    if oldItem then
        self:_RefreshCharCell(oldItem, oldIndex)
    end
    self:_RefreshCharCell(newItem, newIndex)
    local charId = self.m_charInfoList[self.m_curSelectedCharIndex].templateId
    self.view.btnConfirm.interactable = charId ~= self.m_curOfficerId
    self.view.btnConfirm.transform:Find("Root/ContentLayout/Text"):GetComponent(typeof(CS.Beyond.UI.UIText)).text = charId ~= self.m_curOfficerId and Language.LUA_SETTLEMENT_APPLY or Language.LUA_SETTLEMENT_HAVE_APPLY
    self:_RefreshOfficerInfo()
    self:_RefreshFeatureInfo()
end
SettlementCharCtrl._OnSettlementOfficerChange = HL.Method() << function(self)
    if self.m_waitMsgToClose then
        self.m_waitMsgToClose = false
        local charId = self.m_charInfoList[self.m_curSelectedCharIndex].templateId
        if charId == self.m_curOfficerId then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SETTLEMENT_REMOVE_CHARACTER_SUCC)
        else
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SETTLEMENT_SWITCH_CHARACTER_SUCC)
        end
        Utils.triggerVoice("sim_assign_comm", charId)
        Notify(MessageConst.ON_SETTLEMENT_CHAR_CLOSE)
        PhaseManager:PopPhase(PhaseId.SettlementChar)
    end
end
SettlementCharCtrl.OnClose = HL.Override() << function(self)
end
HL.Commit(SettlementCharCtrl)