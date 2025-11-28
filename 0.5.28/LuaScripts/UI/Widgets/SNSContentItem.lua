local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentItem = HL.Class('SNSContentItem', UIWidgetBase)
SNSContentItem._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentItem.InitSNSContentItem = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
    end
    local itemId = args.itemId
    local itemTableData = Tables.itemTable[itemId]
    UIUtils.setItemRarityImage(self.view.rarityDeco, itemTableData.rarity)
    UIUtils.setItemRarityImage(self.view.rarityLine, itemTableData.rarity)
    self.view.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemTableData.iconId)
    self.view.nameText.text = itemTableData.name
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = itemId, transform = self.view.button.transform, posType = UIConst.UI_TIPS_POS_TYPE.RightTop })
    end)
end
HL.Commit(SNSContentItem)
return SNSContentItem