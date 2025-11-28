local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
DialogOptionCell = HL.Class('DialogOptionCell', UIWidgetBase)
DialogOptionCell.info = HL.Field(HL.Table)
DialogOptionCell.optionOnClickFunc = HL.Field(HL.Function)
DialogOptionCell._OnFirstTimeInit = HL.Override() << function(self)
end
DialogOptionCell.InitDialogOptionCell = HL.Method(HL.Any, HL.Opt(HL.Function)) << function(self, info, onClick)
    self:_FirstTimeInit()
    self.info = info
    self.view.textDes.text = UIUtils.resolveTextCinematic(info.text)
    self.view.imageIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_DIALOG_OPTION_ICON, info.icon)
    local selectedOptions = GameInstance.world.dialogManager.selectedOptions
    local optionId = info.optionId
    local iconTypeLower = self.info.iconType:lower()
    if not string.isEmpty(optionId) and selectedOptions:ContainsKey(optionId) and selectedOptions:get_Item(optionId).selectedFlag then
        self.view.imageIcon.color = self.view.config.SELECTED_COLOR
        self.view.textDes.color = self.view.config.SELECTED_COLOR
    elseif self.info.color then
        self.view.imageIcon.color = self.info.color
        self.view.textDes.color = self.info.color
    elseif iconTypeLower == "main" then
        self.view.imageIcon.color = self.view.config.MAINLINE_COLOR
        self.view.textDes.color = self.view.config.MAINLINE_COLOR
    elseif Utils.isInclude(UIConst.DIALOG_OPTION_ENHANCE_COLOR_ICON_TYPE, iconTypeLower) then
        self.view.imageIcon.color = self.view.config.ENHANCE_COLOR
        self.view.textDes.color = self.view.config.ENHANCE_COLOR
    else
        self.view.imageIcon.color = self.view.config.NORMAL_COLOR
        self.view.textDes.color = self.view.config.NORMAL_COLOR
    end
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        if onClick then
            onClick()
        end
    end)
    self.optionOnClickFunc = onClick
end
DialogOptionCell.RefreshDialogOptionSelectedState = HL.Method(HL.Boolean) << function(self, isSelected)
    self.view.controllerSelectedLight.gameObject:SetActiveIfNecessary(isSelected)
    self.view.controllerKeyHint.gameObject:SetActiveIfNecessary(isSelected)
    if isSelected then
        AudioManager.PostEvent("au_ui_g_select")
    end
end
HL.Commit(DialogOptionCell)
return DialogOptionCell