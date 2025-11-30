local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local State = { None = 0, Locked = 1, CanUnlock = 2, Unlocked = 3, }
FacTechTreeLayerCell = HL.Class('FacTechTreeLayerCell', UIWidgetBase)
FacTechTreeLayerCell.m_layerId = HL.Field(HL.String) << ""
FacTechTreeLayerCell.m_state = HL.Field(HL.Number) << State.None
FacTechTreeLayerCell._OnFirstTimeInit = HL.Override() << function(self)
end
FacTechTreeLayerCell.InitFacTechTreeLayerCell = HL.Method(HL.String, HL.Number, HL.Number, HL.Function) << function(self, layerId, sizeX, sizeY, onClickFunc)
    self:_FirstTimeInit()
    self.gameObject.name = "Layer-" .. layerId
    self.m_layerId = layerId
    self.view.rectTransform.sizeDelta = Vector2(sizeX, sizeY)
    self:Refresh()
    self.view.craftBtn.onClick:RemoveAllListeners()
    self.view.craftBtn.onClick:AddListener(function()
        onClickFunc()
    end)
    self.view.infoBtn.onClick:AddListener(function()
        onClickFunc()
    end)
    local layerData = Tables.facSTTLayerTable[self.m_layerId]
    local order = layerData.order
    local spriteSrcName = string.format("deco_factechtreenew_shadow0%s", tostring(order))
    local spriteOrder = self:LoadSprite(UIConst.UI_SPRITE_FAC_TECH_ICON, spriteSrcName)
    self.view.decoNumberN.sprite = spriteOrder
    self.view.decoNumberL.sprite = spriteOrder
    local layerName = UIUtils.resolveTextStyle(layerData.name)
    self.view.txtN.text = layerName
    self.view.txtU.text = layerName
    self.view.txtL.text = layerName
    self.view.content.gameObject:SetActive(not layerData.isTBD)
    self.view.empty.gameObject:SetActive(layerData.isTBD)
end
FacTechTreeLayerCell.Refresh = HL.Method() << function(self)
    local layerData = Tables.facSTTLayerTable[self.m_layerId]
    local facTechTreeSystem = GameInstance.player.facTechTreeSystem
    local isLocked = facTechTreeSystem:LayerIsLocked(self.m_layerId)
    self.view.normalBg.gameObject:SetActiveIfNecessary(not isLocked)
    self.view.lockBg.gameObject:SetActiveIfNecessary(isLocked)
    local isEnough = true
    for _, costItem in pairs(layerData.costItems) do
        if Utils.getItemCount(costItem.costItemId) < costItem.costItemCount then
            isEnough = false
            break
        end
    end
    local preLayerData = string.isEmpty(layerData.preLayer) and { layerId = "" } or Tables.facSTTLayerTable[layerData.preLayer]
    local canLock = isLocked and isEnough and not facTechTreeSystem:LayerIsLocked(preLayerData.layerId)
    self.view.lock.gameObject:SetActiveIfNecessary(isLocked and not canLock)
    self.view.unlock.gameObject:SetActiveIfNecessary(isLocked and canLock)
    self.view.normal.gameObject:SetActiveIfNecessary(not isLocked)
    local preState = self.m_state
    if not isLocked then
        self.m_state = State.Unlocked
    elseif canLock then
        self.m_state = State.CanUnlock
    else
        self.m_state = State.Locked
    end
    if preState == State.CanUnlock and self.m_state == State.Unlocked then
        self.view.animationWrapper:Play("factechtreelayer_unlock")
    elseif preState == State.Locked and self.m_state == State.CanUnlock then
        local wrapper = self.view.animationWrapper
        local delay = wrapper:GetClipLength("factechtreelayer_unlock")
        wrapper:Play("factechtreelayer_waitlock")
        self:_StartTimer(delay, function()
        end)
    end
end
HL.Commit(FacTechTreeLayerCell)
return FacTechTreeLayerCell