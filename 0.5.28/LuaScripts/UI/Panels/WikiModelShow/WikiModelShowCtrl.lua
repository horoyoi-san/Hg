local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WikiModelShow
WikiModelShowCtrl = HL.Class('WikiModelShowCtrl', uiCtrl.UICtrl)
WikiModelShowCtrl.s_messages = HL.StaticField(HL.Table) << {}
WikiModelShowCtrl.m_rotateTickKey = HL.Field(HL.Number) << -1
WikiModelShowCtrl.m_starListCache = HL.Field(HL.Forward("UIListCache"))
WikiModelShowCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.wikiVideoBgWidget:InitWikiVideoBg()
    local wikiEntryShowData = arg
    self.view.backBtn.onClick:AddListener(function()
        self:PlayAnimationOutWithCallback(function()
            self.m_phase:RemovePhasePanelItemById(PANEL_ID)
        end)
    end)
    local hasValue
    local itemData
    hasValue, itemData = Tables.itemTable:TryGetValue(wikiEntryShowData.wikiEntryData.refItemId)
    if hasValue then
        self.view.nameTxt.text = itemData.name
        UIUtils.setItemRarityImage(self.view.circleLightImg, itemData.rarity)
        UIUtils.setItemRarityImage(self.view.circleImg, itemData.rarity)
    end
    local monsterData = nil
    hasValue, monsterData = Tables.enemyTemplateDisplayInfoTable:TryGetValue(wikiEntryShowData.wikiEntryData.refMonsterTemplateId)
    if hasValue then
        self.view.nameTxt.text = monsterData.name
    end
    self.view.circleLightImg.gameObject:SetActive(not hasValue)
    self.view.typeTxt.text = wikiEntryShowData.wikiGroupData.groupName
    local isShowStar = wikiEntryShowData.wikiCategoryType == WikiConst.EWikiCategoryType.Weapon
    self.view.star.gameObject:SetActive(isShowStar)
    if isShowStar then
        self.m_starListCache = UIUtils.genCellCache(self.view.starCell)
        self.m_starListCache:Refresh(itemData.rarity)
    end
    self.view.touchPanel.onDrag:AddListener(function(eventData)
        local delta = eventData.delta
        self.m_phase:RotateModel(delta.x * self.view.config.ROTATE_SENSITIVITY)
    end)
    self:_StartCoroutine(function()
        self.m_rotateTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
            local stickValue = InputManagerInst:GetGamepadStickValue(false)
            if stickValue.x ~= 0 then
                self.m_phase:RotateModel(stickValue.x * self.view.config.ROTATE_SENSITIVITY_CONTROLLER)
            end
        end)
    end)
end
WikiModelShowCtrl._OnPhaseItemBind = HL.Override() << function(self)
    self.m_phase:ActiveShowVirtualCamera(true)
end
WikiModelShowCtrl.OnClose = HL.Override() << function(self)
    LuaUpdate:Remove(self.m_rotateTickKey)
    self.m_phase:ActiveShowVirtualCamera(false)
    self.m_phase:ResetModelRotation()
end
HL.Commit(WikiModelShowCtrl)