local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.LevelToast
LevelToastCtrl = HL.Class('LevelToastCtrl', uiCtrl.UICtrl)
LevelToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
LevelToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
LevelToastCtrl.OnHide = HL.Override() << function(self)
    self.view.levelCollection.gameObject:SetActive(false)
end
LevelToastCtrl.OnShowLevelCollectionToast = HL.StaticMethod(HL.Any) << function(arg)
    local ctrl = LevelToastCtrl.AutoOpen(PANEL_ID, nil, false)
    ctrl:_ShowLevelCollectionToast(arg)
end
LevelToastCtrl.OnShowLevelCollectionToastSimple = HL.StaticMethod(HL.Any) << function(arg)
    local ctrl = LevelToastCtrl.AutoOpen(PANEL_ID, nil, false)
    ctrl:_ShowLevelCollectionToastSimple(arg)
end
LevelToastCtrl._ShowLevelCollectionToastSimple = HL.Method(HL.Any) << function(self, arg)
    local data = unpack(arg)
    if data == nil then
        self.view.levelCollection.gameObject:SetActive(false)
        return
    end
    local itemData = self:_GetLevelCollectionToastItemData(data.itemId)
    if itemData == nil then
        self.view.levelCollection.gameObject:SetActive(false)
        return
    end
    self.view.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_LEVEL_COLLECTION, itemData.imagePath)
    self.view.textItemName.text = itemData.infoLabel
    self.view.labelTotal.text = string.format("%d/%d", data.itemCnt, data.itemMaxCnt)
    local sceneMsg = FactoryUtils.getCurSceneHandler()
    if sceneMsg then
        self:_ShowLevelCollectionToastInfo({ infoNode = self.view.bandwidthNode, infoTotalVal = sceneMsg.bandwidth.max })
        self:_ShowLevelCollectionToastInfo({ infoNode = self.view.buildingNumLimitNode, infoTotalVal = sceneMsg.bandwidth.spMax })
    end
    self.view.levelCollection.gameObject:SetActive(true)
    self.view.levelCollection:Stop()
    self.view.levelCollection:Play("level_toast_collection_show")
end
LevelToastCtrl._GetLevelCollectionToastItemData = HL.Method(HL.String).Return(HL.Any) << function(self, itemId)
    local success, itemTable = Tables.sceneCollectableItemTable:TryGetValue(GameInstance.world.curLevelId)
    if not success then
        logger.error("请配置关卡" .. GameInstance.world.curLevelId .. "的关卡收集物信息")
        return nil
    end
    local itemList = itemTable.itemList
    if itemList == nil then
        return nil
    end
    for i = 0, #itemList - 1, 1 do
        if itemList[i].itemId == itemId then
            return itemList[i]
        end
    end
    return nil
end
LevelToastCtrl._ShowLevelCollectionToastInfo = HL.Method(HL.Table) << function(self, arg)
    local infoNode, infoVal, infoTotalVal = arg.infoNode, arg.infoVal, arg.infoTotalVal
    if infoNode == nil then
        return
    end
    if infoVal == 0 or infoVal == nil then
        infoNode.gameObject:SetActive(false)
        return
    end
    infoNode.afterTxt.text = infoTotalVal + infoVal
    infoNode.beforeTxt.text = infoTotalVal
    infoNode.gameObject:SetActive(true)
end
LevelToastCtrl._ShowLevelCollectionToast = HL.Method(HL.Any) << function(self, arg)
    self.view.levelCollection.gameObject:SetActive(true)
    self.view.levelCollection:Stop()
    local data = unpack(arg)
    logger.info("baseItemName: ", data.baseItemName)
    logger.info("baseItemCount: ", data.baseItemCount)
    logger.info("baseItemConvertRequiredCount: ", data.baseItemConvertRequiredCount)
    logger.info("isConvert: ", data.isConvert)
    logger.info("convertedItemName: ", data.convertedItemName)
    logger.info("convertedItemCount: ", data.convertedItemCount)
    logger.info("convertedItemMaxCount: ", data.convertedItemMaxCount)
    if data.isConvert then
        self.view.levelCollection:Play("level_toast_collection_show_convert")
        self.view.textItemName.text = data.baseItemName
        self.view.textItemName2.text = data.convertedItemName
        self.view.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_LEVEL_COLLECTION, data.baseItemSpritePath)
        self.view.icon2.sprite = self:LoadSprite(UIConst.UI_SPRITE_LEVEL_COLLECTION, data.convertedItemSpritePath)
    else
        self.view.levelCollection:Play("level_toast_collection_show")
        if not string.isEmpty(data.baseItemName) then
            self.view.textItemName.text = data.baseItemName
            self.view.labelTotal.gameObject:SetActive(false)
            self.view.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_LEVEL_COLLECTION, data.baseItemSpritePath)
        elseif not string.isEmpty(data.convertedItemName) then
            self.view.textItemName.text = data.convertedItemName
            self.view.textTotalNumber.text = string.format("%d/%d", data.convertedItemCount, data.convertedItemMaxCount)
            self.view.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_LEVEL_COLLECTION, data.convertedItemSpritePath)
        end
    end
end
HL.Commit(LevelToastCtrl)