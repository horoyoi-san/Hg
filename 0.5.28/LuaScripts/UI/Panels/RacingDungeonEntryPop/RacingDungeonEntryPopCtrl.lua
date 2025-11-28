local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonEntryPop
RacingDungeonEntryPopCtrl = HL.Class('RacingDungeonEntryPopCtrl', uiCtrl.UICtrl)
RacingDungeonEntryPopCtrl.m_index = HL.Field(HL.Number) << 0
RacingDungeonEntryPopCtrl.m_itemList = HL.Field(HL.Table)
RacingDungeonEntryPopCtrl.m_cellList = HL.Field(HL.Any)
RacingDungeonEntryPopCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonEntryPopCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_index = 1
    self.m_itemList = {}
    for i = 1, self.view.config.imageNum do
        table.insert(self.m_itemList, string.format(self.view.config.imagePath, i))
    end
    self.view.btnBack.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.commonPageController:InitPageController(#self.m_itemList, function(index)
        self.m_index = index
        self:_OnUpdateUI()
    end)
end
RacingDungeonEntryPopCtrl._OnUpdateUI = HL.Method() << function(self)
    local id = self.m_itemList[self.m_index]
    self.view.panel.sprite = self:LoadSprite(id)
    self.view.gameObject:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("racingdungeonentrypop_switch")
    local found, i18nText = CS.Beyond.I18n.I18nUtils.TryGetText(string.format(self.view.config.titleText, self.m_index))
    self.view.titleTxt1.text = UIUtils.resolveTextStyle(i18nText)
    found, i18nText = CS.Beyond.I18n.I18nUtils.TryGetText(string.format(self.view.config.descText, self.m_index))
    self.view.titleTxt2.text = UIUtils.resolveTextStyle(i18nText)
end
HL.Commit(RacingDungeonEntryPopCtrl)