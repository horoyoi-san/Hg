local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MapMarkDetailDoodadGroup
MapMarkDetailDoodadGroupCtrl = HL.Class('MapMarkDetailDoodadGroupCtrl', uiCtrl.UICtrl)
MapMarkDetailDoodadGroupCtrl.s_messages = HL.StaticField(HL.Table) << {}
MapMarkDetailDoodadGroupCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    local markInstId = args.markInstId
    local getRuntimeDataSuccess, markRuntimeData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
    if getRuntimeDataSuccess == false then
        logger.error("地图详情页获取实例数据失败" .. markInstId)
        return
    end
    local detail = markRuntimeData.detail
    if detail == nil then
        logger.error("采集组详情数据中没有detailData   " .. markInstId)
    else
        local itemId = markRuntimeData.detail.displayItemId
        local _, itemData = Tables.itemTable:TryGetValue(itemId)
        self.view.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
        self.view.tipsBtn.onClick:AddListener(function()
            Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = itemId, transform = self.view.itemIcon.gameObject.transform, posType = UIConst.UI_TIPS_POS_TYPE.LeftTop, notPenetrate = true, })
        end)
    end
    local commonArgs = {}
    commonArgs.bigBtnActive = true
    commonArgs.markInstId = markInstId
    self.view.detailCommon:InitMapMarkDetailCommon(commonArgs)
end
HL.Commit(MapMarkDetailDoodadGroupCtrl)