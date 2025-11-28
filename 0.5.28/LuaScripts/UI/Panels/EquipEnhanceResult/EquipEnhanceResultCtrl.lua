local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.EquipEnhanceResult
EquipEnhanceResultCtrl = HL.Class('EquipEnhanceResultCtrl', uiCtrl.UICtrl)
EquipEnhanceResultCtrl.s_messages = HL.StaticField(HL.Table) << {}
EquipEnhanceResultCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        self:Close()
    end)
    local args = arg
    self.view.stateCtrl:SetState(args.isSuccessful and "success" or "fail")
    self.view.equipItem:InitEquipItem({ equipInstId = args.equipInstId, })
    local equipInstData = EquipTechUtils.getEquipInstData(args.equipInstId)
    local itemData = Tables.itemTable[equipInstData.templateId]
    self.view.txtEquipName.text = itemData.name
    self.view.equipEnhanceLevelNode:InitEquipEnhanceLevelNode({ equipInstId = args.equipInstId, attrIndex = args.attrShowInfo.enhancedAttrIndex, })
    self.view.txtAttrName.text = args.attrShowInfo.showName
    self.view.txtAttrValueBefore.text = EquipTechUtils.getAttrShowValueText(args.attrShowInfo)
    if args.isSuccessful then
        self.view.txtAttrValueAfter.text = args.nextLevelAttrShowValue
    end
end
HL.Commit(EquipEnhanceResultCtrl)