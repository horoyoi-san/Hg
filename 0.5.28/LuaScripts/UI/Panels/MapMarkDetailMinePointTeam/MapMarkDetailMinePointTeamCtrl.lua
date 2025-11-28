local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MapMarkDetailMinePointTeam
MapMarkDetailMinePointTeamCtrl = HL.Class('MapMarkDetailMinePointTeamCtrl', uiCtrl.UICtrl)
MapMarkDetailMinePointTeamCtrl.s_messages = HL.StaticField(HL.Table) << {}
MapMarkDetailMinePointTeamCtrl.m_minePointList = HL.Field(HL.Forward("UIListCache"))
MapMarkDetailMinePointTeamCtrl.HIGH_PURITY = HL.Field(HL.Number) << 2
MapMarkDetailMinePointTeamCtrl.LOW_PURITY = HL.Field(HL.Number) << 1
MapMarkDetailMinePointTeamCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_minePointList = UIUtils.genCellCache(self.view.singleMinePoint)
    local markInstId = args.markInstId
    local commonArgs = {}
    commonArgs.markInstId = markInstId
    commonArgs.descText = ""
    commonArgs.bigBtnActive = true
    self.view.detailCommon:InitMapMarkDetailCommon(commonArgs)
    local getRuntimeDataSuccess, markRuntimeData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
    if getRuntimeDataSuccess == false then
        logger.error("地图详情页获取实例数据失败" .. markInstId)
        return
    end
    local detail = markRuntimeData.detail
    if detail == nil then
        logger.error("集中矿点详情页没有detail" .. markInstId)
        return
    end
    local itemId = detail.displayItemId
    local _, itemData = Tables.itemTable:TryGetValue(itemId)
    self.view.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
    self.view.itemDetailBtn.onClick:AddListener(function()
        Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = itemId, transform = self.view.itemIcon.gameObject.transform, posType = UIConst.UI_TIPS_POS_TYPE.LeftTop, notPenetrate = true, })
    end)
    self:_ProcessMinepoint(markRuntimeData, detail)
end
MapMarkDetailMinePointTeamCtrl._ProcessMinepoint = HL.Method(HL.Any, HL.Any) << function(self, markRuntimeData, detail)
    local minePointCount = detail.count
    local levelId = markRuntimeData.levelId
    local sceneGrade = GameInstance.player.mapManager:GetSceneGrade(levelId)
    local infoTable = {}
    for i = 1, minePointCount do
        local index = CSIndex(i)
        local lowLevel = detail.lowPurityLevel[index]
        local highLevel = detail.highPurityLevel[index]
        local logicIdGlobal = detail.coreLogicId[index]
        local state
        if sceneGrade < lowLevel then
            state = -lowLevel
        end
        if sceneGrade >= lowLevel then
            state = self.LOW_PURITY
        end
        if sceneGrade >= highLevel then
            state = self.HIGH_PURITY
        end
        table.insert(infoTable, { id = logicIdGlobal, state = state, })
    end
    table.sort(infoTable, Utils.genSortFunction({ "state" }, false))
    local idList = {}
    for i = 1, minePointCount do
        table.insert(idList, infoTable[i].id)
    end
    local haveMinerList = GameInstance.player.mapManager:GetMinerInfo(idList, levelId)
    self.m_minePointList:Refresh(minePointCount, function(minePoint, index)
        local state = infoTable[index].state
        local minerDeployed = haveMinerList[CSIndex(index)]
        self:_FillSingleMinePoint(minePoint, state, minerDeployed, index)
    end)
end
MapMarkDetailMinePointTeamCtrl._FillSingleMinePoint = HL.Method(HL.Any, HL.Number, HL.Boolean, HL.Number) << function(self, minePoint, state, haveMiner, indexNumber)
    minePoint.indexNumberText.text = indexNumber
    minePoint.lockedRoot.gameObject:SetActive(state < 0)
    minePoint.unlockedRoot.gameObject:SetActive(state > 0)
    if state < 0 then
        minePoint.lockText.text = string.format(Language.LUA_MINE_TEAM_DETAIL_SCENE_GRADE_UNLOCK, UIConst.SCENE_GRADE_TEXT[-state])
    else
        minePoint.purityLow.gameObject:SetActive(state == self.LOW_PURITY)
        minePoint.purityHigh.gameObject:SetActive(state == self.HIGH_PURITY)
        minePoint.minerDeployed.gameObject:SetActive(haveMiner)
    end
end
HL.Commit(MapMarkDetailMinePointTeamCtrl)