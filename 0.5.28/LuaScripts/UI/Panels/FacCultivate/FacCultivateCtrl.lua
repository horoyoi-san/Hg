local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacCultivate
FacCultivateCtrl = HL.Class('FacCultivateCtrl', uiCtrl.UICtrl)
FacCultivateCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CROP_STEP_CHANGE] = '_OnStepChange', [MessageConst.ON_CROP_OPERATION_FAILED] = '_OnOperationFailed', [MessageConst.ON_CROP_OPERATION_FAILED_FORCE_CLOSE] = '_OnOperationFailedForce', }
FacCultivateCtrl.m_nodeId = HL.Field(HL.Any)
FacCultivateCtrl.m_soilNode = HL.Field(CS.Beyond.Gameplay.FacSoilSystem.SoilNode)
FacCultivateCtrl.m_soilShow = HL.Field(CS.Beyond.Gameplay.SoilShow)
FacCultivateCtrl.m_soilComp = HL.Field(CS.Beyond.Gameplay.Core.IntFacSoilComponent)
FacCultivateCtrl.m_soilCfg = HL.Field(CS.Beyond.Cfg.PlantingStepData)
FacCultivateCtrl.m_uiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_Soil)
FacCultivateCtrl.m_enumMap = HL.Field(HL.Table)
FacCultivateCtrl.m_enumList = HL.Field(HL.Table)
FacCultivateCtrl.m_progressImgMap = HL.Field(HL.Table)
FacCultivateCtrl.m_partNodeList = HL.Field(HL.Table)
FacCultivateCtrl.m_getCell = HL.Field(HL.Function)
FacCultivateCtrl.m_showInfo = HL.Field(HL.Boolean) << false
FacCultivateCtrl.m_currentStep = HL.Field(HL.Number) << -1
FacCultivateCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    self.m_enumMap = { [GEnums.PlantingStepType.Reclaim] = { icon = "icon_fac_plant_1" }, [GEnums.PlantingStepType.Water] = { icon = "icon_fac_plant_2" }, [GEnums.PlantingStepType.Grow] = { icon = "icon_fac_plant_3" }, [GEnums.PlantingStepType.Harvest] = { icon = "icon_fac_plant_4" }, }
    self.m_progressImgMap = { [GEnums.PlantingStepType.Reclaim] = { icon = "deco_bg_fac_cultivate_1" }, [GEnums.PlantingStepType.Water] = { icon = "deco_bg_fac_cultivate_2" }, [GEnums.PlantingStepType.Grow] = { icon = "deco_bg_fac_cultivate_3" }, [GEnums.PlantingStepType.Harvest] = { icon = "deco_bg_fac_cultivate_4" }, }
    self.m_partNodeList = { [1] = "part1", [2] = "part2", [3] = "part3", [4] = "part4", [5] = "part5", [6] = "part6", [7] = "part7", [8] = "part8", }
    self.m_enumList = { [1] = GEnums.PlantingStepType.Reclaim, [2] = GEnums.PlantingStepType.Water, [3] = GEnums.PlantingStepType.Grow, [4] = GEnums.PlantingStepType.Harvest }
    self.m_soilNode = GameInstance.player.facSoilSystem:GetSoilNodeInCurrentRegion(nodeId)
    self.m_soilShow = GameInstance.player.facSoilSystem:GetSoilShow(nodeId)
    self.m_soilCfg = self.m_soilShow:GetCurPlantConfig()
    self.m_soilComp = self.m_soilShow.facSoilComponent
    self.view.buildingCommon:InitBuildingCommon(self.m_uiInfo, {
        onStateChanged = function(state)
        end
    })
    self:_SetInfoVisible(false)
    self.view.showStepInfoBtn.onClick:AddListener(function()
        self:_SetInfoVisible(true)
    end)
    local t = self.view.nodeContainer
    local childCount = t.childCount
    local curStep = self.m_soilNode.soilStage
    local maxCnt = self.m_soilCfg.plantingSteps.Count
    for index, key in ipairs(self.m_partNodeList) do
        local i = index - 1
        local curChild = t[key]
        local visible = (i < maxCnt)
        local currentActive = (i == curStep)
        local currentHasDone = (i < curStep)
        local currentNotStart = (i > curStep)
        if curChild ~= nil then
            if i < maxCnt then
                local cfg = self.m_enumMap[self.m_soilCfg.plantingSteps[i].plantingStepType]
                if cfg ~= nil then
                    curChild.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CROP, cfg.icon)
                end
            end
            curChild.gameObject:SetActiveIfNecessary(visible)
        end
    end
    local curStepCfg = self.m_soilCfg.plantingSteps[curStep]
    local hasFound, curStepConstCfg = Tables.plantingStepConstTable:TryGetValue(self.m_soilCfg.id)
    local rewardValid, rewardCfg = Tables.rewardSoilTable:TryGetValue(self.m_soilCfg.rewardId)
    self.view.mainPanel.gameObject:SetActiveIfNecessary(not self.m_soilComp.isNatureResourceBusy)
    self:_SetCancelBtn(self.m_soilComp.isNatureResourceBusy)
    self.view.bottomNode.gameObject:SetActiveIfNecessary(self.m_soilComp.isNatureResourceBusy)
    self.view.btnCommonYellow.onClick:AddListener(function()
        self:_DoOperation()
    end)
    self.view.btnCommonYellow.gameObject:SetActiveIfNecessary(curStepCfg.plantingStepType ~= GEnums.PlantingStepType.Grow)
    self.view.closeInfoBtn.onClick:AddListener(function()
        self.view.closeInfoBtn.gameObject:SetActiveIfNecessary(false)
        self.view.stepContainer.gameObject:SetActiveIfNecessary(true)
        self.view.stepInfoContainer.gameObject:SetActiveIfNecessary(false)
    end)
    self.view.bottomNodeBtn.onClick:AddListener(function()
    end)
    self.view.itemContent.onClick:AddListener(function()
        self.m_soilShow:DoInterrupt()
    end)
    local showItemId = rewardCfg.itemBundles[0].id
    local showItemNum = rewardCfg.itemBundles[0].count
    self.view.item:InitItem({ id = showItemId, count = showItemNum }, true)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateStepCell(self.m_getCell(obj), LuaIndex(csIndex))
    end)
    self.view.scrollList:UpdateCount(#self.m_enumList)
    self:_UpdateShow()
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_LARGER_UPDATE_INTERVAL)
            self:_UpdateShow()
        end
    end)
end
FacCultivateCtrl._RefreshBtn = HL.Method() << function(self)
    local curState = self.m_soilCfg.plantingSteps[self.m_currentStep].plantingStepType
    local visible = false
    if curState == GEnums.PlantingStepType.Reclaim then
        visible = true
    elseif curState == GEnums.PlantingStepType.Water then
        visible = true
    elseif curState == GEnums.PlantingStepType.Harvest then
        visible = true
    else
        visible = false
    end
    self:_SetCancelBtn(self.m_soilComp.isNatureResourceBusy)
    self.view.btnCommonYellow.gameObject:SetActiveIfNecessary(curState ~= GEnums.PlantingStepType.Grow)
end
FacCultivateCtrl._SetInfoVisible = HL.Method(HL.Boolean) << function(self, infoVisible)
    self.view.closeInfoBtn.gameObject:SetActiveIfNecessary(infoVisible)
    self.view.stepContainer.gameObject:SetActiveIfNecessary(not infoVisible)
    self.view.stepInfoContainer.gameObject:SetActiveIfNecessary(infoVisible)
end
FacCultivateCtrl._DoOperation = HL.Method() << function(self)
    if self.m_soilComp.isNatureResourceBusy then
        self:_ExitAnyWay()
        return
    end
    local curStep = self.m_soilNode.soilStage
    local stepType = self.m_soilCfg.plantingSteps[curStep].plantingStepType
    if stepType == GEnums.PlantingStepType.Grow then
        self:_ExitAnyWay()
        return
    end
    self.view.mainPanel.gameObject:SetActiveIfNecessary(false)
    self:_SetCancelBtn(true)
    self.view.bottomNode.gameObject:SetActiveIfNecessary(true)
    self.m_soilShow:DoOperation(false)
end
FacCultivateCtrl._OnStepChange = HL.Method(HL.Table) << function(self, args)
    local nodeId = unpack(args)
    if self.m_soilComp.soilNodeId ~= nodeId then
        return
    end
    local curStep = self.m_soilNode.soilStage
    local curStepCfg = self.m_soilCfg.plantingSteps[curStep]
    if curStepCfg.plantingStepType == GEnums.PlantingStepType.Harvest then
        return
    end
    self.view.mainPanel.gameObject:SetActiveIfNecessary(true)
    self:_SetCancelBtn(false)
    self.view.bottomNode.gameObject:SetActiveIfNecessary(false)
    self:_ExitAnyWay()
end
FacCultivateCtrl._SetCancelBtn = HL.Method(HL.Boolean) << function(self, showBtn)
    self.view.itemContent.gameObject:SetActiveIfNecessary(showBtn)
end
FacCultivateCtrl._OnOperationFailed = HL.Method(HL.Any) << function(self, arg)
    local nodeId = unpack(arg)
    if self.m_nodeId == nodeId then
        self:_ExitAnyWay()
    end
end
FacCultivateCtrl._OnOperationFailedForce = HL.Method(HL.Any) << function(self, arg)
    self:_ExitAnyWay()
end
FacCultivateCtrl._ExitAnyWay = HL.Method() << function(self)
    if PhaseManager:IsOpen(PhaseId.FacMachine) then
        PhaseManager:ExitPhaseFast(PhaseId.FacMachine)
    else
        UIManager:Close(PANEL_ID)
    end
end
FacCultivateCtrl._UpdateShow = HL.Method() << function(self)
    if self.m_nodeId == nil then
        self:_ExitAnyWay()
        return
    end
    if CSFactoryUtil.CheckMinaCharOperateNodeBlockByTeammate(self.m_nodeId) then
        self:_ExitAnyWay()
        return
    end
    local t = self.view.nodeContainer
    local childCount = t.childCount
    local curStep = self.m_soilNode.soilStage
    self.view.progressBarMask:SetMaskRatio(self.m_soilShow:GetProgress())
    local curStepCfg = self.m_soilCfg.plantingSteps[curStep]
    if curStepCfg.plantingStepType == GEnums.PlantingStepType.Grow then
        self.view.countTimeText.text = self.m_soilShow:GetRemainTimeString()
    end
    if curStepCfg.plantingStepType == GEnums.PlantingStepType.Reclaim or curStepCfg.plantingStepType == GEnums.PlantingStepType.Water then
        self.view.textNode.gameObject:SetActiveIfNecessary(false)
        self.view.textNodeYellow.gameObject:SetActiveIfNecessary(true)
    else
        self.view.textNode.gameObject:SetActiveIfNecessary(true)
        self.view.textNodeYellow.gameObject:SetActiveIfNecessary(false)
    end
    if curStep == self.m_currentStep then
        return
    end
    self.m_currentStep = curStep
    local maxCnt = self.m_soilCfg.plantingSteps.Count
    for index, key in ipairs(self.m_partNodeList) do
        local i = index - 1;
        local curChild = t[key]
        local visible = (i < maxCnt)
        local currentActive = (i == curStep)
        local currentHasDone = (i < curStep)
        local currentNotStart = (i > curStep)
        if curChild ~= nil then
            if i < maxCnt then
                local cfg = self.m_enumMap[self.m_soilCfg.plantingSteps[i].plantingStepType]
                if cfg ~= nil then
                    curChild.bgLine1.gameObject:SetActiveIfNecessary(currentActive)
                    curChild.bgLine2.gameObject:SetActiveIfNecessary(currentActive)
                    curChild.bgBlock1.gameObject:SetActiveIfNecessary(currentNotStart)
                    curChild.bgBlock2.gameObject:SetActiveIfNecessary(currentHasDone)
                    curChild.line1.gameObject:SetActiveIfNecessary((currentActive) or (currentHasDone))
                    curChild.line2.gameObject:SetActiveIfNecessary(currentHasDone)
                    curChild.dotLine1.gameObject:SetActiveIfNecessary(currentNotStart)
                    curChild.dotLine2.gameObject:SetActiveIfNecessary(currentNotStart or currentActive)
                    if currentNotStart then
                        curChild.icon.color = self.view.config.COLOR_ICON_INACTIVE;
                    end
                end
            end
            curChild.gameObject:SetActiveIfNecessary(visible)
        end
    end
    local hasFound, curStepConstCfg = Tables.plantingStepConstTable:TryGetValue(curStepCfg.plantingStepType)
    local facValid, curFacCfg = Tables.factoryBuildingTable:TryGetValue(self.m_soilCfg.id)
    self.view.bottomProgressText.text = curStepConstCfg.progressText
    self.view.mainBtnText.text = curStepConstCfg.btnText
    self.view.soilItemDescText.text = curFacCfg.desc
    local data = UIUtils.getSoilRewardFirstItem(self.m_soilCfg.rewardId)
    local itemCfg = Tables.itemTable:GetValue(data.id)
    if itemCfg ~= nil then
        self.view.soilItemNameDescText.text = itemCfg.name
    end
    local curSprite = self:LoadSprite(UIConst.UI_SPRITE_CROP, self.m_enumMap[curStepCfg.plantingStepType].icon)
    local progressSprite = self:LoadSprite(UIConst.UI_SPRITE_CROP, self.m_progressImgMap[curStepCfg.plantingStepType].icon)
    self.view.progressImg.sprite = progressSprite
    if curStepCfg.plantingStepType == GEnums.PlantingStepType.Reclaim or curStepCfg.plantingStepType == GEnums.PlantingStepType.Water then
        self.view.curStepIconYellow.sprite = curSprite
        self.view.hintTextYellow.text = curStepConstCfg.hintText
    else
        self.view.curStepIcon.sprite = curSprite
        self.view.hintText.text = curStepConstCfg.hintText
    end
    if curStepCfg.plantingStepType ~= GEnums.PlantingStepType.Grow then
        self.view.countTimeText.text = "--:--:--"
    end
    self:_RefreshBtn()
end
FacCultivateCtrl._OnUpdateStepCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local curEnum = self.m_enumList[index]
    local hasFound, curStepConstCfg = Tables.plantingStepConstTable:TryGetValue(curEnum)
    local showCfg = self.m_enumMap[curEnum]
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CROP, showCfg.icon)
    cell.text.text = curStepConstCfg.stepDescription
    cell.blackBG.gameObject:SetActiveIfNecessary(index % 2 == 0)
end
FacCultivateCtrl._OnOpenCrop = HL.StaticMethod(HL.Any) << function(nodeId)
    local unpackNodeId = unpack(nodeId)
    if CSFactoryUtil.CheckMinaCharOperateNodeBlockByTeammate(unpackNodeId) then
        return
    end
    Notify(MessageConst.FAC_OPEN_BUILDING_PANEL, { nodeId = unpackNodeId, })
end
HL.Commit(FacCultivateCtrl)