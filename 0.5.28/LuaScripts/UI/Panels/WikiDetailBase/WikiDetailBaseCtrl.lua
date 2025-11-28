local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
WikiDetailBaseCtrl = HL.Class('WikiDetailBaseCtrl', uiCtrl.UICtrl)
WikiDetailBaseCtrl.s_messages = HL.StaticField(HL.Table) << {}
WikiDetailBaseCtrl.m_wikiEntryShowData = HL.Field(HL.Table)
WikiDetailBaseCtrl.m_wikiGroupShowDataList = HL.Field(HL.Table)
WikiDetailBaseCtrl.m_itemTipsPosInfo = HL.Field(HL.Table)
WikiDetailBaseCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local args = arg
    self.m_wikiEntryShowData = args.wikiEntryShowData
    self.m_wikiGroupShowDataList = args.wikiGroupShowDataList
    self.m_itemTipsPosInfo = { tipsPosType = UIConst.UI_TIPS_POS_TYPE.LeftTop }
    if self.view.right and self.view.right.itemTipsNode then
        self.m_itemTipsPosInfo.tipsPosTransform = self.view.right.itemTipsNode
    end
    self.view.wikiVideoBgWidget:InitWikiVideoBg()
    if self.view.prtsBtn then
        self.view.prtsBtn.btn.onClick:AddListener(function()
            PhaseManager:GoToPhase(PhaseId.PRTSStoryCollDetail, { id = self.m_wikiEntryShowData.wikiEntryData.prtsId, isFirstLvId = false, })
        end)
    end
    self:_RefreshLeft()
    self:_RefreshCenter()
    self:_RefreshRight()
end
WikiDetailBaseCtrl.OnClose = HL.Override() << function(self)
    if self.m_phase then
        self.m_phase:DestroyModel()
    end
end
WikiDetailBaseCtrl.OnShow = HL.Override() << function(self)
    if self.m_phase and self.m_phase.m_currentWikiDetailArgs and self.m_phase.m_currentWikiDetailArgs.wikiEntryShowData.wikiEntryData.id ~= self.m_wikiEntryShowData.wikiEntryData.id then
        self:Refresh(self.m_phase.m_currentWikiDetailArgs)
    end
end
WikiDetailBaseCtrl._OnPhaseItemBind = HL.Override() << function(self)
    self:_RefreshTop()
end
WikiDetailBaseCtrl.GetPanelId = HL.Virtual().Return(HL.Number) << function(self)
end
WikiDetailBaseCtrl._RefreshTop = HL.Virtual() << function(self)
    local wikiTopArgs = { phase = self.m_phase, panelId = self:GetPanelId(), categoryType = self.m_wikiEntryShowData.wikiCategoryType, wikiEntryShowData = self.m_wikiEntryShowData }
    self.view.top:InitWikiTop(wikiTopArgs)
end
WikiDetailBaseCtrl._RefreshCenter = HL.Virtual() << function(self)
    local args = {
        wikiEntryShowData = self.m_wikiEntryShowData,
        onDetailBtnClick = function()
            self:PlayAnimationOutWithCallback(function()
                self.m_phase:CreatePhasePanelItem(PanelId.WikiModelShow, self.m_wikiEntryShowData)
            end)
        end
    }
    self.view.wikiItemInfo:InitWikiItemInfo(args)
    if self.view.prtsBtn then
        local prtsId = self.m_wikiEntryShowData.wikiEntryData.prtsId
        if not string.isEmpty(prtsId) then
            local _, prtsData = Tables.prtsAllItem:TryGetValue(prtsId)
            if prtsData then
                self.view.prtsBtn.titleTxt.text = prtsData.name
            end
        end
        self.view.prtsBtn.gameObject:SetActive(Utils.isSystemUnlocked(GEnums.UnlockSystemType.PRTS) and not string.isEmpty(prtsId) and GameInstance.player.prts:IsPrtsUnlocked(prtsId))
    end
end
WikiDetailBaseCtrl._RefreshLeft = HL.Virtual() << function(self)
    local wikiGroupItemListArgs = {
        isInitHidden = true,
        wikiGroupShowDataList = self.m_wikiGroupShowDataList,
        onItemClicked = function(wikiEntryShowData)
            self.m_wikiEntryShowData = wikiEntryShowData
            self:_RefreshTop()
            self:_RefreshCenter()
            self:_RefreshRight()
        end,
        onGetSelectedEntryShowData = function()
            return self.m_wikiEntryShowData
        end,
        btnExpandList = self.view.expandListBtn,
        btnClose = self.view.btnEmpty
    }
    self.view.left:InitWikiGroupItemList(wikiGroupItemListArgs)
end
WikiDetailBaseCtrl._RefreshRight = HL.Virtual() << function(self)
end
WikiDetailBaseCtrl.Refresh = HL.Method(HL.Table) << function(self, args)
    self.m_wikiEntryShowData = args.wikiEntryShowData
    self.m_wikiGroupShowDataList = args.wikiGroupShowDataList
    self:_RefreshTop()
    self:_RefreshCenter()
    self:_RefreshRight()
end
HL.Commit(WikiDetailBaseCtrl)