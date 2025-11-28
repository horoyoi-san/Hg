local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaCharResultTop
GachaCharResultTopCtrl = HL.Class('GachaCharResultTopCtrl', uiCtrl.UICtrl)
GachaCharResultTopCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaCharResultTopCtrl.m_args = HL.Field(HL.Table)
GachaCharResultTopCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.view.closeBtn.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self.m_args = args
    for k = 1, 10 do
        self:_UpdateChar(k)
    end
    self:PlayAnimationIn()
end
GachaCharResultTopCtrl._UpdateChar = HL.Method(HL.Number) << function(self, index)
    local cell = self.view["charCell" .. index]
    local char = self.m_args.chars[index]
    if DeviceInfo.isPCorConsole then
        local scale = Vector3.one / CS.Beyond.UI.UIConst.PC_REFERENCE_RESOLUTION_SCALE
        cell.weaponTicket.transform.localScale = scale
        cell.newNode.transform.localScale = scale
        cell.itemNode.transform.localScale = scale
    end
    local wpnBundle = char.items[1]
    local wpnData = Tables.itemTable[wpnBundle.id]
    cell.weaponTicket.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, wpnData.iconId)
    cell.weaponTicket.countTxt.text = wpnBundle.count
    if char.isNew then
        cell.newNode.gameObject:SetActive(true)
        cell.itemNode.gameObject:SetActive(false)
    else
        cell.newNode.gameObject:SetActive(false)
        cell.itemNode.gameObject:SetActive(true)
        if not cell.m_items then
            cell.m_items = UIUtils.genCellCache(cell.itemCell)
        end
        cell.m_items:Refresh(#char.items - 1, function(itemCell, itemIndex)
            local bundle = char.items[itemIndex + 1]
            local itemData = Tables.itemTable[bundle.id]
            if itemData.type == GEnums.ItemType.CharPotentialUp then
                itemCell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_WALLET, "item_charpotentialup_0" .. itemData.rarity)
            else
                itemCell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_WALLET, itemData.iconId)
            end
            itemCell.countTxt.text = bundle.count
        end)
    end
    local stateName = char.rarity >= UIConst.CHAR_MAX_RARITY and "SixStar" or "Normal"
    cell.simpleStateController:SetState(stateName)
end
GachaCharResultTopCtrl._OnClickClose = HL.Method() << function(self)
    if PhaseManager.m_curState ~= Const.PhaseState.Idle then
        return
    end
    local onComplete = self.m_args.onComplete
    self:Close()
    onComplete()
end
HL.Commit(GachaCharResultTopCtrl)