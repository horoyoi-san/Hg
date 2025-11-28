local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ControllerSecondMenuBtn = HL.Class('ControllerSecondMenuBtn', UIWidgetBase)
ControllerSecondMenuBtn.m_extraArgs = HL.Field(HL.Table)
ControllerSecondMenuBtn._OnFirstTimeInit = HL.Override() << function(self)
    self.view.button.onClick:AddListener(function()
        self:_OpenMenu()
    end)
end
ControllerSecondMenuBtn.InitControllerSecondMenuBtn = HL.Method(HL.Opt(HL.Table)) << function(self, extraArgs)
    self:_FirstTimeInit()
    self.m_extraArgs = extraArgs
end
ControllerSecondMenuBtn._OpenMenu = HL.Method() << function(self)
    local args = { title = self.view.text.text, menuBtnList = self.view.menuBtnList, btnInfos = {}, hintPlaceholder = self:GetUICtrl().view.controllerHintPlaceholder, }
    for _, v in pairs(self.view.menuBtnList.btnList) do
        if v.button.gameObject.activeInHierarchy then
            table.insert(args.btnInfos, v)
        end
    end
    if self.m_extraArgs.extraBtnInfos then
        for _, v in ipairs(self.m_extraArgs.extraBtnInfos) do
            table.insert(args.btnInfos, v)
        end
    end
    table.sort(args.btnInfos, Utils.genSortFunction({ "priority" }))
    if self.m_extraArgs then
        setmetatable(args, { __index = self.m_extraArgs })
    end
    UIManager:Open(PanelId.ControllerSecondMenu, args)
end
HL.Commit(ControllerSecondMenuBtn)
return ControllerSecondMenuBtn