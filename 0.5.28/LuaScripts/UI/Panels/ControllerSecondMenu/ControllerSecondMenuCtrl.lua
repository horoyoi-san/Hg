local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ControllerSecondMenu
ControllerSecondMenuCtrl = HL.Class('ControllerSecondMenuCtrl', uiCtrl.UICtrl)
ControllerSecondMenuCtrl.s_messages = HL.StaticField(HL.Table) << {}
ControllerSecondMenuCtrl.m_btnCells = HL.Field(HL.Forward('UIListCache'))
ControllerSecondMenuCtrl.m_btnMenuListCpt = HL.Field(CS.Beyond.UI.ControllerSecondMenuBtnList)
ControllerSecondMenuCtrl.m_btnInfos = HL.Field(HL.Table)
ControllerSecondMenuCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeMask.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self:BindInputPlayerAction("common_close_second_menu", function()
        self:PlayAnimationOutAndClose()
    end)
    self.m_btnCells = UIUtils.genCellCache(self.view.btnCell)
    self.view.titleText.text = arg.title
    self.m_btnMenuListCpt = arg.menuBtnList
    self.m_btnInfos = arg.btnInfos
    self.m_btnCells:Refresh(#self.m_btnInfos, function(cell, index)
        cell.button.onClick:AddListener(function()
            self:_OnClickBtn(index)
        end)
        local info = self.m_btnInfos[index]
        if type(info) == "table" then
            cell.icon.sprite = info.sprite
            cell.text.text = Language[info.textId]
        else
            cell.icon.sprite = info.sprite
            cell.text.text = info:GetText()
        end
        cell.gameObject.name = "BtnCell" .. index
        if index == 1 then
            InputManagerInst.controllerNaviManager:SetTarget(cell.button)
        end
    end)
    local targetScreenRect = UIUtils.getTransformScreenRect(self.m_btnMenuListCpt.contentPosTrans, self.uiCamera)
    local pos = UIUtils.screenPointToUI(targetScreenRect.center, self.uiCamera, self.view.transform)
    pos.y = -pos.y
    self.view.listContent.anchoredPosition = pos
    self.view.listContent.sizeDelta = self.m_btnMenuListCpt.contentPosTrans.rect.size
    self:_ShowFacBonusNode(arg.buildingNodeId)
    self:_ShowControllerHint(arg.hintPlaceholder)
end
ControllerSecondMenuCtrl.OnClose = HL.Override() << function(self)
    Notify(MessageConst.HIDE_CONTROLLER_HINT, { panelId = PANEL_ID, })
end
ControllerSecondMenuCtrl._ShowControllerHint = HL.Method(HL.Forward('ControllerHintPlaceholder')) << function(self, hintPlaceholder)
    local hintArgs = hintPlaceholder:GetArgs()
    hintArgs.panelId = PANEL_ID
    hintArgs.groupIds = { self.view.inputGroup.groupId }
    hintArgs.optionalActionIds = nil
    hintArgs.offset = 1
    Notify(MessageConst.SHOW_CONTROLLER_HINT, hintArgs)
end
ControllerSecondMenuCtrl._ShowFacBonusNode = HL.Method(HL.Opt(HL.Number)) << function(self, buildingNodeId)
    if buildingNodeId then
        self.view.facCharacterBonusNode:InitFacCharacterBonusNode(buildingNodeId)
        self.view.facCharacterBonusNode:ToggleContent(true)
        self.view.facCharacterBonusNode.view.titleNode.childAlignment = self.m_btnMenuListCpt.bonusNodeTitleOnRight and CS.UnityEngine.TextAnchor.MiddleRight or CS.UnityEngine.TextAnchor.MiddleLeft
        local targetScreenRect = UIUtils.getTransformScreenRect(self.m_btnMenuListCpt.bonusNodePosTrans, self.uiCamera)
        local pos = UIUtils.screenPointToUI(targetScreenRect.center, self.uiCamera, self.view.transform)
        pos.y = -pos.y
        self.view.facCharacterBonusNode.view.transform.anchoredPosition = pos
    else
        self.view.facCharacterBonusNode.gameObject:SetActive(false)
    end
end
ControllerSecondMenuCtrl._OnClickBtn = HL.Method(HL.Number) << function(self, index)
    local info = self.m_btnInfos[index]
    self:Close()
    if info.button then
        info.button.onClick:Invoke(nil)
    else
        info.action()
    end
end
HL.Commit(ControllerSecondMenuCtrl)