local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementProsperity
SettlementProsperityCtrl = HL.Class('SettlementProsperityCtrl', uiCtrl.UICtrl)
SettlementProsperityCtrl.s_messages = HL.StaticField(HL.Table) << {}
SettlementProsperityCtrl.m_progressCache = HL.Field(HL.Any)
SettlementProsperityCtrl.m_featureCache = HL.Field(HL.Any)
SettlementProsperityCtrl.m_domainId = HL.Field(HL.String) << ""
SettlementProsperityCtrl.m_prosperity = HL.Field(HL.Number) << 0
SettlementProsperityCtrl.m_maxProsperity = HL.Field(HL.Number) << 0
SettlementProsperityCtrl.m_data = HL.Field(HL.Table)
SettlementProsperityCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnBack.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.mask.onClick:AddListener(function()
    end)
    self.m_progressCache = UIUtils.genCellCache(self.view.progressNode)
    self.m_featureCache = UIUtils.genCellCache(self.view.featureNode)
    self.m_domainId = arg[1]
    local system = GameInstance.player.settlementSystem
    self.m_prosperity, self.m_maxProsperity = system:GetProsperityByDomainId(self.m_domainId)
    self.view.level.text = self.m_prosperity
    self.m_data = {}
    local curDomainData = Tables.domainDataTable[self.m_domainId]
    for k, v in pairs(Tables.levelGradeTable) do
        local array = v.grades
        for i = 0, array.Count - 1 do
            local grade = array[i]
            local isInDomain = false
            for j = 0, curDomainData.levelGroup.Count - 1 do
                if v.name == curDomainData.levelGroup[j] then
                    isInDomain = true
                    break
                end
            end
            if grade.prosperity > 0 and isInDomain and grade.prosperity <= self.m_maxProsperity then
                if not self.m_data[grade.prosperity] then
                    self.m_data[grade.prosperity] = {}
                end
                table.insert(self.m_data[grade.prosperity], { info = grade, level = k })
            end
        end
    end
    self:_UpdateProgress()
    self:_UpdateFeature()
end
SettlementProsperityCtrl._UpdateProgress = HL.Method() << function(self)
    self.m_progressCache:Refresh(self.m_maxProsperity, function(obj, index)
        self:_UpdateProgressNode(obj, index)
    end)
end
SettlementProsperityCtrl._UpdateProgressNode = HL.Method(HL.Any, HL.Number) << function(self, obj, index)
    obj.gameObject:SetActive(true)
    obj.activateText.text = index
    obj.lockText.text = index
    obj.lockText.gameObject:SetActive(index > self.m_prosperity)
    obj.activateText.gameObject:SetActive(index <= self.m_prosperity)
    obj.decoActivate.gameObject:SetActive(index <= self.m_prosperity)
    obj.decoLock.gameObject:SetActive(index > self.m_prosperity)
    obj.lightBg.gameObject:SetActive(index <= self.m_prosperity)
    obj.dimBg.gameObject:SetActive(index > self.m_prosperity)
    if obj.arrow then
        obj.arrow.gameObject:SetActive(index == self.m_prosperity)
    end
    if obj.light then
        obj.light.gameObject:SetActive(self.m_data[index] ~= nil)
    end
end
SettlementProsperityCtrl._UpdateFeature = HL.Method() << function(self)
    local realData = {}
    for k, v in pairs(self.m_data) do
        table.insert(realData, v)
    end
    table.sort(realData, function(a, b)
        return a[1].info.prosperity < b[1].info.prosperity
    end)
    self.m_featureCache:Refresh(#realData, function(obj, index)
        obj.gameObject:SetActive(true)
        obj.info.gameObject:SetActive(false)
        self:_UpdateProgressNode(obj.levelNode, realData[index][1].info.prosperity)
        local haveLock = false
        for i = 1, #realData[index] do
            local grade = realData[index][i]
            local levelUnlock = GameInstance.player.mapManager:IsLevelUnlocked(grade.level)
            if haveLock then
                goto continue
            end
            local info = CS.Beyond.Lua.UtilsForLua.CreateObject(obj.info.gameObject, obj.infoList)
            info.gameObject:SetActive(true)
            info = Utils.wrapLuaNode(info)
            info.lockIcon.gameObject:SetActive(not levelUnlock)
            local found, i18nText = CS.Beyond.I18n.I18nUtils.TryGetText("ui_maplevel_level" .. grade.info.grade)
            local _, desc = Tables.levelDescTable:TryGetValue(grade.level)
            info.lightText.text = UIUtils.resolveTextStyle(string.format(Language.LUA_SETTLEMENT_PROSPERITY_FEATURE, desc.showName, i18nText))
            if levelUnlock then
                info.dimText.text = info.lightText.text
            else
                info.dimText.text = Language.LUA_SETTLEMENT_PROSPERITY_FEATURE_LOCK
            end
            info.lightText.gameObject:SetActive(levelUnlock and self.m_prosperity >= grade.info.prosperity)
            info.dimText.gameObject:SetActive(self.m_prosperity < grade.info.prosperity or not levelUnlock)
            info.lightBg.gameObject:SetActive(levelUnlock and self.m_prosperity >= grade.info.prosperity and i % 2 == 1)
            info.dimBg.gameObject:SetActive(levelUnlock and self.m_prosperity >= grade.info.prosperity and i % 2 == 0)
            if not levelUnlock then
                haveLock = true
            end
            info.blackBg.gameObject:SetActive(not levelUnlock or self.m_prosperity < grade.info.prosperity)
            ::continue::
        end
    end)
end
HL.Commit(SettlementProsperityCtrl)