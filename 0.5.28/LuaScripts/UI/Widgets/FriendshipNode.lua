local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FriendshipNode = HL.Class('FriendshipNode', UIWidgetBase)
FriendshipNode.m_charInstId = HL.Field(HL.Number) << 0
FriendshipNode._OnFirstTimeInit = HL.Override() << function(self)
    self.view.reliabilityTips.gameObject:SetActive(false)
    self.view.button.onClick:AddListener(function()
        self.view.reliabilityTips.gameObject:SetActive(true)
    end)
    self:RegisterMessage(MessageConst.ON_CHAR_FRIENDSHIP_CHANGED, function()
        self:_RefreshFriendship()
    end)
end
FriendshipNode.InitFriendshipNode = HL.Method(HL.Number) << function(self, charInstId)
    self.m_charInstId = charInstId
    self:_FirstTimeInit()
    self.view.reliabilityTips.gameObject:SetActive(false)
    local isCardInTrail = CharInfoUtils.checkIsCardInTrail(charInstId)
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local isEndmin = CharInfoUtils.isEndmin(charInst.templateId)
    local isShowEmpty = isCardInTrail or isEndmin
    self.view.empty.gameObject:SetActive(isShowEmpty)
    self.view.normal.gameObject:SetActive(not isShowEmpty)
    self.view.button.enabled = not isShowEmpty
    if isShowEmpty then
        return
    end
    self:_RefreshFriendship()
end
FriendshipNode._RefreshFriendship = HL.Method() << function(self)
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInstId)
    local friendshipValue = CSPlayerDataUtil.GetCharFriendshipByInstId(charInst.instId)
    local maxFriendship = CSPlayerDataUtil.maxFriendship
    local rate = friendshipValue / maxFriendship
    self.view.percentText.text = string.format("%.0f%%", CharInfoUtils.getCharRelationShowValue(friendshipValue))
    self.view.fill.fillAmount = rate
end
HL.Commit(FriendshipNode)
return FriendshipNode