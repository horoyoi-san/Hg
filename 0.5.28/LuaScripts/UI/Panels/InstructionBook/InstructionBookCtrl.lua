local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.InstructionBook
InstructionBookCtrl = HL.Class('InstructionBookCtrl', uiCtrl.UICtrl)
InstructionBookCtrl.s_messages = HL.StaticField(HL.Table) << {}
InstructionBookCtrl.OnCreate = HL.Override(HL.Any) << function(self, id)
    self.view.closeButton.onClick:AddListener(function()
        self:PlayAnimationOut()
    end)
    self.view.maskBtn.onClick:AddListener(function()
        self:PlayAnimationOut()
    end)
    local succ, data = Tables.instructionBook:TryGetValue(id)
    if succ then
        self.view.titleText.text = data.title
        self.view.contentTxt.text = data.content
    else
        self.view.titleText.text = id
        self.view.contentTxt.text = id
    end
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
HL.Commit(InstructionBookCtrl)