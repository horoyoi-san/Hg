local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonEffect
local PHASE_ID = PhaseId.RacingDungeonEffect
RacingDungeonEffectCtrl = HL.Class('RacingDungeonEffectCtrl', uiCtrl.UICtrl)
RacingDungeonEffectCtrl.m_getItemCell = HL.Field(HL.Function)
RacingDungeonEffectCtrl.m_orderedBuffList = HL.Field(HL.Table)
RacingDungeonEffectCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonEffectCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.RacingDungeonEffect)
    end)
    self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(object, csIndex)
        self:_RefreshItemCell(object, LuaIndex(csIndex))
    end)
end
local noEffectBuff = { ["race_item_1"] = true, ["race_item_2"] = true }
RacingDungeonEffectCtrl.OnShow = HL.Override() << function(self)
    local buffList = GameInstance.player.racingDungeonSystem.buffList
    if buffList == nil or buffList.Count == 0 then
        self.view.content.gameObject:SetActive(false)
        self.view.emptyNode.gameObject:SetActive(true)
        return
    end
    self.view.content.gameObject:SetActive(true)
    self.view.emptyNode.gameObject:SetActive(false)
    local orderedBuff = {}
    local buffNumList = {}
    local enumerator = buffList:GetEnumerator()
    while enumerator:MoveNext() do
        local buffId = enumerator.Current
        if not noEffectBuff[buffId] then
            if buffNumList[buffId] then
                buffNumList[buffId] = buffNumList[buffId] + 1
            else
                buffNumList[buffId] = 1
                table.insert(orderedBuff, { buffId, 0 })
            end
        end
    end
    for i, buff in ipairs(orderedBuff) do
        buff[2] = buffNumList[buff[1]]
    end
    table.sort(orderedBuff, function(a, b)
        local id1 = a[1]
        local id2 = b[1]
        local item1 = Tables.racingInterTable[id1]
        local item2 = Tables.racingInterTable[id2]
        return item1.sortValue < item2.sortValue
    end)
    self.m_orderedBuffList = orderedBuff
    self.view.scrollList:UpdateCount(#orderedBuff, true, true, false, false)
end
RacingDungeonEffectCtrl._RefreshItemCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local listCell = self.m_getItemCell(object)
    local buffId, num = unpack(self.m_orderedBuffList[index])
    listCell:InitRacingEffectCell(buffId, num)
end
HL.Commit(RacingDungeonEffectCtrl)