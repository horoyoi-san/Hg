local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RepairInteractive
RepairInteractiveCtrl = HL.Class('RepairInteractiveCtrl', uiCtrl.UICtrl)
RepairInteractiveCtrl.s_messages = HL.StaticField(HL.Table) << {}
RepairInteractiveCtrl.m_submitItems = HL.Field(HL.Table)
RepairInteractiveCtrl.m_info = HL.Field(HL.Table)
RepairInteractiveCtrl.m_unlockType = HL.Field(HL.Any)
RepairInteractiveCtrl.m_onComplete = HL.Field(HL.Function)
RepairInteractiveCtrl.m_costItemCache = HL.Field(HL.Forward("UIListCache"))
RepairInteractiveCtrl.m_isClosing = HL.Field(HL.Boolean) << false
RepairInteractiveCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_isClosing = false
    self.m_unlockType = args.unlockType
    self:_SwitchPanelDisplay()
    if self.m_unlockType == GEnums.InteractiveUnlockType.Submit then
        self:_OnCreateSubmit(args)
    elseif self.m_unlockType == GEnums.InteractiveUnlockType.MiniGame then
        self:_OnCreateMinigame(args)
    end
end
RepairInteractiveCtrl.OnShow = HL.Override() << function(self)
    if not GameInstance.world.gameMechManager.mainCharFixBrain.isPanelExpectedShowing then
        RepairInteractiveCtrl.ForceCloseRepairInteractive()
        self:PlayAnimationOutAndClose()
    end
end
RepairInteractiveCtrl._SwitchPanelDisplay = HL.Method() << function(self)
    self.view.costContent.gameObject:SetActive(true)
    self.view.emptyCost.gameObject:SetActive(false)
    self.view.nonDescRepairNode.gameObject:SetActive(false)
    self.view.machineTitle.gameObject:SetActive(true)
    self.view.machineDescNode.gameObject:SetActive(true)
    self.view.repairBtn.gameObject:SetActive(true)
    self.view.notEnoughHint.gameObject:SetActive(false)
    local isSubmit = self.m_unlockType == GEnums.InteractiveUnlockType.Submit
    local isMiniGame = self.m_unlockType == GEnums.InteractiveUnlockType.MiniGame
    self.view.repairDecos.gameObject:SetActive(isSubmit)
    self.view.puzzleDecos.gameObject:SetActive(isMiniGame)
    self.view.costTitle.gameObject:SetActive(isSubmit)
    self.view.costItemList.gameObject:SetActive(isSubmit)
    self.view.blockInfoNode.gameObject:SetActive(isMiniGame)
end
RepairInteractiveCtrl._OnCreateMinigame = HL.Method(HL.Table) << function(self, args)
    self.view.closeButton.onClick:AddListener(function()
        self:_CloseRepairInteractive()
    end)
    self.view.repairBtn.onClick:AddListener(function()
        self:_OnClickRepair()
    end)
    self.m_info = args
    local desc = args.desc
    local hasDesc = desc and not desc.isEmpty
    if hasDesc then
        self.view.descText.text = desc:GetText()
    end
    self.view.machineTitle.gameObject:SetActive(hasDesc)
    self.view.machineDescNode.gameObject:SetActive(hasDesc)
    self.view.costContent.gameObject:SetActive(hasDesc)
    self.view.blockLine.gameObject:SetActive(hasDesc)
    self.view.repairBlockLine.gameObject:SetActive(not hasDesc)
    self.view.nonDescRepairNode.gameObject:SetActive(not hasDesc)
    local title = args.title
    local hasTitle = title and not title.isEmpty
    self.view.machineNameText.text = hasTitle and title:GetText() or Language.LUA_UNLOCK_MINIGAME_TITLE
end
RepairInteractiveCtrl._OnCreateSubmit = HL.Method(HL.Table) << function(self, args)
    self.view.closeButton.onClick:AddListener(function()
        self:_CloseRepairInteractive()
    end)
    self.view.repairBtn.onClick:AddListener(function()
        self:_OnClickRepair()
    end)
    local submitId = args.submitId
    self.m_info = args
    local data = Tables.submitItem[submitId]
    self.view.machineNameText.text = data.name
    self.view.descText.text = data.desc
    self.view.machineIconImage.sprite = self:LoadSprite(data.icon)
    self.m_submitItems = {}
    for _, v in pairs(data.paramData) do
        if v.type == GEnums.SubmitTermType.Common then
            table.insert(self.m_submitItems, { id = v.paramList[0].valueStringList[0], count = v.paramList[1].valueIntList[0], })
        end
    end
    self:UpdateCount(true)
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_LARGER_UPDATE_INTERVAL)
            self:UpdateCount(false)
        end
    end)
end
RepairInteractiveCtrl._OnClickRepair = HL.Method() << function(self)
    if self.m_unlockType == GEnums.InteractiveUnlockType.Submit then
        if self.m_info ~= nil and self.m_info.callback ~= nil then
            self.m_info.callback(false)
            self.m_info = nil
            self:_CloseRepairInteractive()
        end
    elseif self.m_unlockType == GEnums.InteractiveUnlockType.MiniGame then
        local finalArgs = {}
        finalArgs.callback = self.m_info.callback
        local title = self.m_info.title
        local hasTitle = title and not title.isEmpty
        if hasTitle then
            finalArgs.title = title:GetText()
        end
        self.m_info = nil
        PhaseManager:ExitPhaseFast(PhaseId.RepairInteractive)
        PhaseManager:OpenPhaseFast(PhaseId.Puzzle, finalArgs)
    end
end
RepairInteractiveCtrl.UpdateCount = HL.Method(HL.Boolean) << function(self, isInit)
    local items = self.m_submitItems
    if isInit then
        self.m_costItemCache = UIUtils.genCellCache(self.view.costItem)
        self.m_costItemCache:Refresh(#items, function(cell, index)
            cell.item:InitItem(items[index], true)
        end)
    end
    local isEnough = true
    local isEmpty = #items == 0
    self.view.costContent.gameObject:SetActive(not isEmpty)
    self.view.emptyCost.gameObject:SetActive(isEmpty)
    self.m_costItemCache:Update(function(cell, index)
        local bundle = items[index]
        local count = Utils.getItemCount(bundle.id)
        local isLack = count < bundle.count
        cell.item:UpdateCountSimple(bundle.count, isLack)
        UIUtils.setItemStorageCountText(cell.storageNode, bundle.id, bundle.count)
        if isLack then
            isEnough = false
        end
    end)
    self.view.repairBtn.gameObject:SetActive(isEnough)
    self.view.notEnoughHint.gameObject:SetActive(not isEnough)
end
RepairInteractiveCtrl.ShowRepairInteractive = HL.StaticMethod(HL.Table) << function(args)
    local submitId, callback = unpack(args)
    local finalArgs = {}
    finalArgs.unlockType = GEnums.InteractiveUnlockType.Submit
    finalArgs.submitId = submitId
    finalArgs.callback = callback
    PhaseManager:OpenPhase(PhaseId.RepairInteractive, finalArgs)
end
RepairInteractiveCtrl.ShowRepairInteractiveByMinigame = HL.StaticMethod(HL.Table) << function(args)
    local callback, desc, title = unpack(args)
    local finalArgs = {}
    finalArgs.unlockType = GEnums.InteractiveUnlockType.MiniGame
    finalArgs.callback = callback
    finalArgs.desc = desc
    finalArgs.title = title
    PhaseManager:OpenPhase(PhaseId.RepairInteractive, finalArgs)
end
RepairInteractiveCtrl._CloseRepairInteractive = HL.Method() << function(self)
    if self.m_isClosing == true then
        return
    end
    self.m_isClosing = true
    local inTransition = PhaseManager:CheckIsInTransition()
    if inTransition then
        self:PlayAnimationOutWithCallback(function()
            PhaseManager:ExitPhaseFast(PhaseId.RepairInteractive)
        end)
    else
        PhaseManager:PopPhase(PhaseId.RepairInteractive)
    end
end
RepairInteractiveCtrl.ForceCloseRepairInteractive = HL.StaticMethod() << function()
    if PhaseManager:GetTopPhaseId() == PhaseId.RepairInteractive then
        if UIManager:IsShow(PANEL_ID) then
            PhaseManager:ExitPhaseFast(PhaseId.RepairInteractive)
        end
    end
end
RepairInteractiveCtrl.OnClose = HL.Override() << function(self)
    if self.m_unlockType == GEnums.InteractiveUnlockType.Submit then
        if self.m_info ~= nil and self.m_info.callback ~= nil then
            self.m_info.callback(true)
            self.m_info = nil
        end
    elseif self.m_unlockType == GEnums.InteractiveUnlockType.MiniGame then
        if self.m_info ~= nil and self.m_info.callback ~= nil then
            self.m_info.callback(false)
            self.m_info = nil
        end
    end
end
RepairInteractiveCtrl.OnHide = HL.Override() << function(self)
    self:_StartCoroutine(function()
        Notify(MessageConst.EXIT_LEVEL_HALF_SCREEN_PANEL_MODE)
        PhaseManager:ExitPhaseFast(PhaseId.RepairInteractive)
    end)
end
HL.Commit(RepairInteractiveCtrl)