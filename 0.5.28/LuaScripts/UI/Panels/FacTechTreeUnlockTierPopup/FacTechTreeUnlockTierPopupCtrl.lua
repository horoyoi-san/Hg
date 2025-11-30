local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacTechTreeUnlockTierPopup
FacTechTreeUnlockTierPopupCtrl = HL.Class('FacTechTreeUnlockTierPopupCtrl', uiCtrl.UICtrl)
FacTechTreeUnlockTierPopupCtrl.m_costItemCells = HL.Field(HL.Forward("UIListCache"))
FacTechTreeUnlockTierPopupCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacTechTreeUnlockTierPopupCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local layerId = unpack(arg)
    self.m_costItemCells = UIUtils.genCellCache(self.view.costItemNode)
    self.view.clickMask.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self.view.confirmBtn.onClick:AddListener(function()
        GameInstance.player.facTechTreeSystem:SendUnlockTierMsg(layerId)
        self:_OnClickClose()
    end)
    self.view.cancelBtn.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self:_Refresh(layerId)
end
FacTechTreeUnlockTierPopupCtrl._Refresh = HL.Method(HL.String) << function(self, layerId)
    local layerData = Tables.facSTTLayerTable[layerId]
    local preLayerUnlocked = not GameInstance.player.facTechTreeSystem:LayerIsLocked(layerData.preLayer)
    local txt = preLayerUnlocked and self.view.layerUnlockLightTxt or self.view.layerUnlockDimTxt
    self.view.dimNode.gameObject:SetActive(not preLayerUnlocked)
    self.view.lightNode.gameObject:SetActive(preLayerUnlocked)
    local unlockTitle = string.format(Language.LUA_FAC_TECH_TREE_UNLOCK_HINT_WITH_PRE, layerData.name)
    self.view.dimTxt.text = unlockTitle
    self.view.lightTxt.text = unlockTitle
    txt.text = UIUtils.resolveTextStyle(string.format(Language.LUA_FAC_TECH_TREE_UNLOCK_HINT_WITH_PRE, Tables.facSTTLayerTable[layerData.preLayer].name))
    local costItemVOs = {}
    local isEnough = true
    for _, costItem in pairs(layerData.costItems) do
        local ownCount = Utils.getItemCount(costItem.costItemId)
        local costCount = costItem.costItemCount
        local costItemVO = {}
        costItemVO.id = costItem.costItemId
        costItemVO.ownCount = ownCount
        costItemVO.costCount = costCount
        costItemVO.isEnough = ownCount >= costCount
        if ownCount < costCount then
            isEnough = false
        end
        table.insert(costItemVOs, costItemVO)
    end
    self.m_costItemCells:Refresh(#costItemVOs, function(cell, index)
        local costItemVO = costItemVOs[index]
        cell.item:InitItem({ id = costItemVO.id, count = costItemVO.costCount }, true)
        cell.lightText.gameObject:SetActive(costItemVO.isEnough)
        cell.dimText.gameObject:SetActive(not costItemVO.isEnough)
        local txt = costItemVO.isEnough and cell.lightText or cell.dimText
        txt.text = costItemVO.ownCount
    end)
    self.view.dimIcon.gameObject:SetActive(not isEnough)
    self.view.lightIcon.gameObject:SetActive(isEnough)
    local canUnlock = isEnough and preLayerUnlocked
    self.view.btnNode.gameObject:SetActive(canUnlock)
    self.view.closeHintTxt.gameObject:SetActive(not canUnlock)
    self.view.clickMask.gameObject:SetActive(not canUnlock)
    local wrapper = self:GetAnimationWrapper()
    if canUnlock then
        wrapper:Play("factechtree_tierpopuplock_in")
    else
        wrapper:Play("factechtree_tierpopup_in")
    end
end
FacTechTreeUnlockTierPopupCtrl._OnClickClose = HL.Method() << function(self)
    self:PlayAnimationOutAndClose()
end
HL.Commit(FacTechTreeUnlockTierPopupCtrl)