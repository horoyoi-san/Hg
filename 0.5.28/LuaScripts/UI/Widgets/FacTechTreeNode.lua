local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local State = { None = 0, Locked = 1, CanUnlock = 2, Unlocked = 3, }
FacTechTreeNode = HL.Class('FacTechTreeNode', UIWidgetBase)
FacTechTreeNode.techId = HL.Field(HL.String) << ""
FacTechTreeNode.m_x = HL.Field(HL.Number) << 0
FacTechTreeNode.m_y = HL.Field(HL.Number) << 0
FacTechTreeNode.m_state = HL.Field(HL.Number) << State.None
FacTechTreeNode._OnFirstTimeInit = HL.Override() << function(self)
end
FacTechTreeNode.InitFacTechTreeNode = HL.Method(HL.String, HL.Number, HL.Number, HL.Boolean, HL.Function) << function(self, techId, x, y, recommend, onClickFun)
    self:_FirstTimeInit()
    self.techId = techId
    self.m_x = x
    self.m_y = y
    self.gameObject.name = "Node-" .. techId
    self.view.itemBtn.onClick:RemoveAllListeners()
    self.view.itemBtn.onClick:AddListener(function()
        onClickFun(self)
    end)
    self:OnShowNameStateChange(false)
    self:Refresh(recommend)
    self.view.redDot:InitRedDot("TechTreeNode", techId)
end
FacTechTreeNode.Refresh = HL.Method(HL.Boolean) << function(self, recommend)
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    local techId = self.techId
    local nodeData = Tables.facSTTNodeTable:GetValue(techId)
    self.view.nameTxt.text = nodeData.name
    local layerIsLocked = techTreeSystem:LayerIsLocked(nodeData.layer)
    local isLocked = techTreeSystem:NodeIsLocked(nodeData.techId)
    self.view.lockNode.gameObject:SetActiveIfNecessary(layerIsLocked)
    self.view.completeNode.gameObject:SetActiveIfNecessary(not isLocked)
    self.view.normalNode.gameObject:SetActiveIfNecessary(not layerIsLocked and isLocked)
    local hasCornerIcon = not string.isEmpty(nodeData.cornerIcon)
    self.view.cornerIconNodeN.gameObject:SetActiveIfNecessary(hasCornerIcon)
    self.view.cornerIconNodeL.gameObject:SetActiveIfNecessary(hasCornerIcon)
    if hasCornerIcon then
        local cornerIconSprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_HUB_ICON, nodeData.cornerIcon)
        self.view.cornerIconN.sprite = cornerIconSprite
        self.view.cornerIconL.sprite = cornerIconSprite
    end
    local sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_TECH_ICON, nodeData.icon)
    self.view.iconN.sprite = sprite
    self.view.iconC.sprite = sprite
    self.view.iconL.sprite = sprite
    self.transform.localPosition = Vector3(self.m_x, self.m_y)
    self.view.recommend.gameObject:SetActiveIfNecessary(recommend)
    local preState = self.m_state
    if not isLocked then
        self.m_state = State.Unlocked
    elseif not layerIsLocked then
        self.m_state = State.CanUnlock
    else
        self.m_state = State.Locked
    end
    if preState == State.CanUnlock and self.m_state == State.Unlocked then
        self.view.animationWrapper:Play("factechtree_treenode_unlock")
    elseif preState == State.Locked and self.m_state == State.CanUnlock then
        self.view.animationWrapper:Play("factechtree_treenodenormal_unlock")
    end
end
FacTechTreeNode.OnSelect = HL.Method(HL.Boolean) << function(self, isSelect)
    self.view.selected.gameObject:SetActiveIfNecessary(isSelect)
end
FacTechTreeNode.OnShowNameStateChange = HL.Method(HL.Boolean) << function(self, show)
    self.view.nameNode.gameObject:SetActiveIfNecessary(show)
end
HL.Commit(FacTechTreeNode)
return FacTechTreeNode