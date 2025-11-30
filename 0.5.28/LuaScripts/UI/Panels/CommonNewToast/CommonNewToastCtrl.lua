local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonNewToast
CommonNewToastCtrl = HL.Class('CommonNewToastCtrl', uiCtrl.UICtrl)
CommonNewToastCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_FIRST_GOT_ITEM] = 'OnFirstGotItem', [MessageConst.ON_UNLOCK_PRTS] = 'OnFirstGotPRTSItem', }
CommonNewToastCtrl.m_curNewItemDatas = HL.Field(HL.Forward("Queue"))
CommonNewToastCtrl.m_curPlayingNewItemData = HL.Field(HL.Table)
CommonNewToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_curNewItemDatas = require_ex("Common/Utils/DataStructure/Queue")()
    self.view.newItemNode.button.onClick:AddListener(function()
        self:_OnClickNewItem()
    end)
    self.view.newItemNode.storyNode.button.onClick:AddListener(function()
        self:_OnClickStoryItem()
    end)
    self.view.newItemNode.investNode.gotoBtn.onClick:AddListener(function()
        self:_OnClickInvestItem()
    end)
    self.view.newItemNode.gameObject:SetActive(false)
    self.view.newItemNode.canvasGroup.blocksRaycasts = true
end
CommonNewToastCtrl.OnShow = HL.Override() << function(self)
    self:_OnPlayNewItemFinished()
    self.view.newItemNode.canvasGroup.blocksRaycasts = true
end
CommonNewToastCtrl.OnHide = HL.Override() << function(self)
end
CommonNewToastCtrl.OnClose = HL.Override() << function(self)
end
CommonNewToastCtrl.OnFirstGotItem = HL.Method(HL.Table) << function(self, args)
    local itemId = unpack(args)
    local data = { itemId = itemId, }
    LuaSystemManager.mainHudToastSystem:AddRequest("FirstGotItem", function()
        if self:IsShow() and not self.m_curPlayingNewItemData then
            self:_StartPlayNewItem(data)
        else
            self.m_curNewItemDatas:Push(data)
        end
    end)
end
CommonNewToastCtrl.OnFirstGotPRTSItem = HL.Method(HL.Table) << function(self, args)
    if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.PRTS) then
        return
    end
    local prtsId = unpack(args)
    local data = { prtsId = prtsId, }
    local investInfos = {}
    local investIds = GameInstance.player.prts:GetBelongsInvestIds(prtsId)
    if investIds ~= nil then
        for _, id in pairs(investIds) do
            table.insert(investInfos, { investId = id })
        end
    end
    LuaSystemManager.mainHudToastSystem:AddRequest("UnlockPRTS", function()
        if self:IsShow() and not self.m_curPlayingNewItemData then
            self:_StartPlayNewItem(data)
        else
            self.m_curNewItemDatas:Push(data)
        end
        for _, investData in pairs(investInfos) do
            self.m_curNewItemDatas:Push(investData)
        end
    end)
end
CommonNewToastCtrl._StartPlayNewItem = HL.Method(HL.Table) << function(self, data)
    self.m_curPlayingNewItemData = data
    local itemId = data.itemId
    local prtsId = data.prtsId
    local investId = data.investId
    local node = self.view.newItemNode
    node.gameObject:SetActive(true)
    if itemId then
        AudioAdapter.PostEvent("au_ui_popup_reward")
        self.view.toastState:SetState("Normal")
        local itemData = Tables.itemTable[itemId]
        node.nameTxt.text = itemData.name
        node.decTxt.text = itemData.desc
        node.itemIcon:InitItemIcon(itemId)
        UIUtils.setItemRarityImage(node.rarity, itemData.rarity)
        node.animationWrapper:PlayInAnimation(function()
            if self:IsShow() then
                self:_OnPlayNewItemFinished()
            end
        end)
    elseif prtsId then
        AudioManager.PostEvent("au_ui_prts_get")
        self.view.toastState:SetState("StoryItem")
        local prtsData = Tables.prtsAllItem:GetValue(prtsId)
        local _, firstLvInfo = Tables.prtsFirstLv:TryGetValue(prtsData.firstLvId)
        node.storyNode.nameTxt.text = prtsData.name
        local iconPath = Utils.getImgGenderDiffPath(firstLvInfo.icon)
        node.storyNode.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_PRTS_ICON, iconPath)
        node.storyNode.typeIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_PRTS, "icon_tab_" .. prtsData.type .. "_nml")
        node.storyNode.animationWrapper:PlayInAnimation(function()
            if self:IsShow() then
                self:_OnPlayNewItemFinished()
            end
        end)
    elseif investId then
        AudioManager.PostEvent("au_ui_prts_get")
        self.view.toastState:SetState("PRTSInvest")
        local investCfg = Utils.tryGetTableCfg(Tables.prtsInvestigate, investId)
        if investCfg then
            node.investNode.investNameTxt.text = investCfg.name
            local curCount = GameInstance.player.prts:GetStoryCollUnlockCount(investId)
            local targetCount = #investCfg.collectionIdList
            if curCount <= 1 then
                node.investNode.investState:SetState("New")
            elseif curCount < targetCount then
                node.investNode.investState:SetState("Update")
            else
                node.investNode.investState:SetState("CanFinish")
            end
        end
        node.investNode.animationWrapper:PlayInAnimation(function()
            if self:IsShow() then
                self:_OnPlayNewItemFinished()
            end
        end)
    end
end
CommonNewToastCtrl._OnPlayNewItemFinished = HL.Method() << function(self)
    local node = self.view.newItemNode
    if self.m_curNewItemDatas:Empty() then
        self.m_curPlayingNewItemData = nil
        node.animationWrapper:ClearTween()
        node.gameObject:SetActive(false)
    else
        local data = self.m_curNewItemDatas:Pop()
        self:_StartPlayNewItem(data)
    end
end
CommonNewToastCtrl._OnClickNewItem = HL.Method() << function(self)
    local itemId = self.m_curPlayingNewItemData.itemId
    self:_OnPlayNewItemFinished()
    Notify(MessageConst.SHOW_WIKI_ENTRY, { itemId = itemId })
end
CommonNewToastCtrl._OnClickStoryItem = HL.Method() << function(self)
    local prtsId = self.m_curPlayingNewItemData.prtsId
    self:_OnPlayNewItemFinished()
    local prtsCfg = Utils.tryGetTableCfg(Tables.prtsAllItem, prtsId)
    if prtsCfg then
        local firstLvCfg = Utils.tryGetTableCfg(Tables.prtsFirstLv, prtsCfg.firstLvId)
        local ids = {}
        local showIndex = 1
        if firstLvCfg then
            local index = 1
            for _, id in pairs(firstLvCfg.itemIds) do
                if GameInstance.player.prts:IsPrtsUnlocked(id) then
                    table.insert(ids, id)
                    if id == prtsId then
                        showIndex = index
                    end
                    index = index + 1
                end
            end
        else
            table.insert(ids, prtsId)
        end
        PhaseManager:OpenPhase(PhaseId.PRTSStoryCollDetail, { isFirstLvId = false, idList = ids, initShowIndex = showIndex, })
    end
end
CommonNewToastCtrl._OnClickInvestItem = HL.Method() << function(self)
    local investId = self.m_curPlayingNewItemData.investId
    self:_OnPlayNewItemFinished()
    local investCfg = Utils.tryGetTableCfg(Tables.prtsInvestigate, investId)
    if investCfg then
        PhaseManager:OpenPhase(PhaseId.PRTSInvestigateDetail, { id = investId })
    end
end
HL.Commit(CommonNewToastCtrl)