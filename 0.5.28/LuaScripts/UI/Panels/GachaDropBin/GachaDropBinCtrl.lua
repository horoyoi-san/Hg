local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaDropBin
GachaDropBinCtrl = HL.Class('GachaDropBinCtrl', uiCtrl.UICtrl)
GachaDropBinCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaDropBinCtrl.m_sortedRarityList = HL.Field(HL.Table)
GachaDropBinCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.skipBtn.onClick:AddListener(function()
        self:_OnClickSkip()
    end)
end
local Cut2DropBinIndexList = { 0, 9, 8, 7 }
local Cut3DropBinIndexList = { 0, 6, 7, 3 }
GachaDropBinCtrl.Start = HL.Method() << function(self)
    self.m_sortedRarityList = {}
    local chars = self.m_phase.arg.chars
    for _, v in ipairs(chars) do
        table.insert(self.m_sortedRarityList, v.rarity)
    end
    table.sort(self.m_sortedRarityList, function(a, b)
        return a > b
    end)
    logger.info("sortedRarityList", self.m_sortedRarityList)
    local timelineRoot = self.m_phase.m_outsideObjItem.view.timelineRoot.transform
    local count = #self.m_sortedRarityList
    for k = 1, 10 do
        local dropBin = timelineRoot:Find("Actor/DropBin" .. CSIndex(k))
        local active = k <= count
        dropBin.gameObject:SetActive(active)
    end
    for k, index in ipairs(Cut2DropBinIndexList) do
        if k <= count then
            local rarity = self.m_sortedRarityList[k]
            local effectRoot = timelineRoot:Find(string.format("Effect/P_gacha_01/Cut2/DropBin%d/RarityEffect", index))
            effectRoot:Find("Rarity5Effect").gameObject:SetActive(rarity >= 5)
            effectRoot:Find("Rarity4Effect").gameObject:SetActive(rarity == 4)
        end
    end
    for k, index in ipairs(Cut3DropBinIndexList) do
        if k <= count then
            local rarity = self.m_sortedRarityList[k]
            local effectRoot = timelineRoot:Find(string.format("Effect/P_gacha_01/Cut2/DropBin%d/RarityEffect2", index))
            effectRoot:Find("Rarity5Effect").gameObject:SetActive(rarity >= 5)
            effectRoot:Find("Rarity4Effect").gameObject:SetActive(rarity == 4)
        end
    end
    for k, index in ipairs(Cut3DropBinIndexList) do
        if k <= count then
            local rarity = self.m_sortedRarityList[k]
            local effectRoot = timelineRoot:Find(string.format("Effect/P_gacha_01/Cut3/light/DropBin%d", index))
            effectRoot:Find("Rarity4Effect").gameObject:SetActive(rarity == 4)
            effectRoot:Find("Rarity5Effect").gameObject:SetActive(rarity == 5)
            effectRoot:Find("Rarity6Effect").gameObject:SetActive(rarity == 6)
        end
    end
    self.m_phase.m_outsideObjItem.go:SetActive(true)
    local dir = self.m_phase.m_outsideDirector
    dir:Stop()
    dir.time = 0
    dir:Evaluate()
    local duration = self.m_phase.m_outsideDirector.duration
    logger.info("Gacha Drop Bin Duration", duration)
    self:_StartCoroutine(function()
        coroutine.step()
        dir:Play()
        while true do
            coroutine.step()
            if self.m_phase.m_outsideDirector.time >= duration then
                self:_OnClickSkip()
            end
        end
    end)
end
GachaDropBinCtrl._OnClickSkip = HL.Method() << function(self)
    local onComplete = self.m_phase.arg.onComplete
    onComplete()
    PhaseManager:ExitPhaseFast(PhaseId.GachaDropBin)
end
HL.Commit(GachaDropBinCtrl)