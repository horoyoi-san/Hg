local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ImportantRewardPopup
ImportantRewardPopupCtrl = HL.Class('ImportantRewardPopupCtrl', uiCtrl.UICtrl)
ImportantRewardPopupCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.INTERRUPT_MAIN_HUD_TOAST] = 'InterruptMainHudToast', }
ImportantRewardPopupCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.maskBtn.onClick:AddListener(function()
        self:_Exit()
    end)
end
ImportantRewardPopupCtrl.OnGetImportantRewardItem = HL.StaticMethod(HL.Table) << function(args)
    local itemId, count = unpack(args)
    LuaSystemManager.mainHudToastSystem:AddRequest("ImportantReward", function()
        local self = UIManager:AutoOpen(PANEL_ID)
        self:_UpdateContent(itemId)
    end)
end
ImportantRewardPopupCtrl._Exit = HL.Method() << function(self)
    self:PlayAnimationOutWithCallback(function()
        Notify(MessageConst.ON_ONE_MAIN_HUD_TOAST_FINISH, "ImportantReward")
        if LuaSystemManager.mainHudToastSystem:GetCurShowingRequestType() ~= "ImportantReward" then
            self:Close()
        else
            self:PlayAnimationIn()
        end
    end)
end
ImportantRewardPopupCtrl.InterruptMainHudToast = HL.Method() << function(self)
    Notify(MessageConst.HIDE_ITEM_TIPS)
    self:Close()
end
ImportantRewardPopupCtrl._UpdateContent = HL.Method(HL.String) << function(self, itemId)
    self.view.itemIcon:InitItemIcon(itemId, true)
    local itemData = Tables.itemTable[itemId]
    self.view.itemNameTxt.text = itemData.name
    local importantItemData = Tables.importantRewardItemTable[itemId]
    self.view.descTxt.text = UIUtils.resolveTextStyle(importantItemData.desc)
    self.view.tipsBtn.onClick:RemoveAllListeners()
    self.view.tipsBtn.onClick:AddListener(function()
        Notify(MessageConst.SHOW_ITEM_TIPS, { transform = self.view.tipsBtn.transform, itemId = itemId, })
    end)
end
HL.Commit(ImportantRewardPopupCtrl)