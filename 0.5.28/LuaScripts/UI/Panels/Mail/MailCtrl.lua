local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Mail
MailCtrl = HL.Class('MailCtrl', uiCtrl.UICtrl)
MailCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ALL_MAIL_INITED] = 'OnAllMailInited', [MessageConst.ON_READ_MAIL] = 'OnReadMail', [MessageConst.ON_GET_MAIL_ATTACHMENT] = 'OnGetMailAttachment', [MessageConst.ON_DEL_MAILS] = 'OnDelMails', [MessageConst.ON_GET_NEW_MAILS] = 'OnGetNewMails', [MessageConst.ON_MARK_STAR_MAIL] = 'OnStarMail', [MessageConst.ON_GET_LOST_AND_FOUND] = 'OnGetLostAndFound', [MessageConst.ON_ADD_LOST_AND_FOUND] = 'OnAddLostAndFound' }
MailCtrl.m_inLoading = HL.Field(HL.Boolean) << false
MailCtrl.m_getMailCell = HL.Field(HL.Function)
MailCtrl.m_curMails = HL.Field(HL.Table)
MailCtrl.m_curMailIndex = HL.Field(HL.Number) << 1
MailCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self:BindInputPlayerAction("common_open_mail", function()
        self:_OnClickClose()
    end)
    self.view.helpBtn.onClick:AddListener(function()
        UIManager:Open(PanelId.InstructionBook, "mail")
    end)
    self.view.getBtn.onClick:AddListener(function()
        self:_OnClickGet()
    end)
    self.view.delBtn.onClick:AddListener(function()
        self:_OnClickDel()
    end)
    self.view.getAllBtn.onClick:AddListener(function()
        self:_OnClickGetAll()
    end)
    self.view.delReadBtn.onClick:AddListener(function()
        self:_OnClickDelAll()
    end)
    self.view.lostAndFoundBtn.onClick:AddListener(function()
        self:_OnClickLostAndFound()
    end)
    self.view.contentTxt.onClickLink:AddListener(function(value)
        self:_OnClickLink(value)
    end)
    self.m_getMailCell = UIUtils.genCachedCellFunction(self.view.mailList)
    self.view.mailList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getMailCell(obj), LuaIndex(csIndex))
    end)
    self.view.filterBtn.view.normalBtn.onClick:AddListener(function()
        self:_OnClickStar()
    end)
    self.view.filterBtn.view.selectedBtn.onClick:AddListener(function()
        self:_OnClickStar()
    end)
    self.view.lostAndFoundRedDot:InitRedDot("LostAndFoundBtn")
    self.view.getAllBtnRedDot:InitRedDot("MailTabGetAllBtn")
    local mailSys = GameInstance.player.mail
    if mailSys:IsAllMailInited() then
        self:_OnLoadingFinished()
    else
        self:_ToggleLoading(true)
        mailSys:GetAllMails()
    end
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_CheckExpiredMail()
        end
    end)
    InputManagerInst:CreateBindingByActionId("common_navigation_up", function()
        self:_ChangeSelectedMail(-1)
    end, self.view.mailListNodeInputBindingGroupMonoTarget.groupId)
    InputManagerInst:CreateBindingByActionId("common_navigation_down", function()
        self:_ChangeSelectedMail(1)
    end, self.view.mailListNodeInputBindingGroupMonoTarget.groupId)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
MailCtrl.OnShow = HL.Override() << function(self)
    self:RefreshLostAndFoundBtn()
end
MailCtrl.OnGetLostAndFound = HL.Method(HL.Table) << function(self, args)
    self:RefreshLostAndFoundBtn()
end
MailCtrl.OnAddLostAndFound = HL.Method() << function(self)
    self:RefreshLostAndFoundBtn()
end
MailCtrl.RefreshLostAndFoundBtn = HL.Method() << function(self)
    local lostAndFound = GameInstance.player.inventory.lostAndFound
    local isEmpty = lostAndFound:IsEmpty()
    if isEmpty then
        self.view.lostAndFoundBtn.gameObject:SetActive(false)
    else
        self.view.lostAndFoundBtn.gameObject:SetActive(true)
        self.view.lostAndFoundNum.text = tostring(lostAndFound:GetUsedGridCount())
        self.view.lostAndFoundMax.text = tostring(Const.MAX_LOST_AND_FOUND_COUNT)
    end
end
MailCtrl._ChangeSelectedMail = HL.Method(HL.Number) << function(self, offset)
    local oldIndex = self.m_curMailIndex
    local index = lume.clamp(oldIndex + offset, 1, #self.m_curMails)
    if index == oldIndex then
        return
    end
    self:_OnClickMail(index)
    self:_MoveVirtualMouseToSelected(index)
end
MailCtrl._MoveVirtualMouseToSelected = HL.Method(HL.Number) << function(self, index)
end
MailCtrl._OnClickClose = HL.Method() << function(self)
    self.view.mailContentNode:ClearTween()
    PhaseManager:PopPhase(PhaseId.Mail)
end
MailCtrl.OnAnimationInFinished = HL.Override() << function(self)
end
MailCtrl._OnLoadingFinished = HL.Method() << function(self)
    self:_ToggleLoading(false)
    self:_OnClickTab(nil, nil)
end
MailCtrl._OnClickTab = HL.Method(HL.Opt(HL.Number, HL.Any)) << function(self, mailIndex, mailId)
    self.m_curMails = {}
    local mailSys = GameInstance.player.mail
    for _, mail in pairs(mailSys.mails) do
        if mail.inited and not mail.isExpired then
            local info = { mail = mail, }
            setmetatable(info, { __index = mail })
            info.starOrder = mail.isStar and 0 or 1
            info.readOrder = (mail.isRead and mail.collected) and 1 or 0
            info.sendTimeOrder = -mail.sendTime
            if info.itemList then
                info.items = {}
                for _, v in pairs(info.itemList) do
                    local data = Tables.itemTable[v.id]
                    table.insert(info.items, { id = v.id, count = v.count, sortId1 = data.sortId1, sortId2 = data.sortId2, rarity = data.rarity, })
                end
                table.sort(info.items, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
            end
            table.insert(self.m_curMails, info)
        end
    end
    table.sort(self.m_curMails, Utils.genSortFunction({ "starOrder", "readOrder", "sendTimeOrder", "title" }, true))
    local count = #self.m_curMails
    local isEmpty = count == 0
    local isFull = count >= Const.MAX_MAIL_COUNT
    local countTxt = string.format("<color=%s>%d</color>/%d", isFull and "red" or "white", count, Const.MAX_MAIL_COUNT)
    self.view.listCountText.text = countTxt
    if isEmpty then
        self.view.mailContentNode.gameObject:SetActive(false)
        self.view.mailListNode.gameObject:SetActive(false)
        self.view.emptyNode.gameObject:SetActive(true)
    else
        self.view.mailContentNode.gameObject:SetActive(true)
        self.view.mailListNode.gameObject:SetActive(true)
        self.view.emptyNode.gameObject:SetActive(false)
        self.view.listTitleTxt.text = Language.LUA_MAIL_TAB_TITLE
        self.view.mailList:UpdateCount(count)
        if mailId then
            for k, v in ipairs(self.m_curMails) do
                if v.id == mailId then
                    mailIndex = k
                    break
                end
            end
        else
            if mailIndex then
                mailIndex = lume.clamp(mailIndex, 1, count)
            else
                mailIndex = 1
            end
        end
        self:_OnClickMail(mailIndex)
    end
end
MailCtrl._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local info = self.m_curMails[index]
    cell.title.text = info.mail.title
    local sprite = self:LoadSprite(info.senderIcon)
    cell.iconSelected.sprite = sprite
    cell.iconUnselected.sprite = sprite
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        self:_OnClickMail(index)
    end)
    if info.items then
        cell.item:InitItem(info.items[1])
        cell.item.view.rewardedCover.gameObject:SetActive(info.collected)
        cell.item.gameObject:SetActive(true)
    else
        cell.item.gameObject:SetActive(false)
    end
    if info.expireTime > 0 then
        cell.expireTime.gameObject:SetActive(true)
        cell.expireTime.text = string.format(Language.LUA_MAIL_CELL_EXPIRED_TIME_FORMAT, UIUtils.getLeftTime(info.expireTime - DateTimeUtils.GetCurrentTimestampBySeconds()))
    else
        cell.expireTime.gameObject:SetActive(false)
    end
    if info.isStar then
        cell.starSelected.gameObject:SetActive(true)
        cell.starUnselected.gameObject:SetActive(true)
    else
        cell.starSelected.gameObject:SetActive(false)
        cell.starUnselected.gameObject:SetActive(false)
    end
    cell.animator:SetBool("IsSelected", index == self.m_curMailIndex)
    cell.readMask.gameObject:SetActive(info.isRead and info.collected)
    cell.redDot:InitRedDot("SingleMail", info.id)
    cell.gameObject.name = "MailCell-" .. index
end
MailCtrl._OnClickMail = HL.Method(HL.Number) << function(self, index)
    if self.m_curMailIndex ~= index then
        local oldCell = self.m_getMailCell(self.m_curMailIndex)
        if oldCell then
            oldCell.animator:SetBool("IsSelected", false)
        end
    end
    self.m_curMailIndex = index
    local cell = self.m_getMailCell(index)
    if cell then
        cell.animator:SetBool("IsSelected", true)
    end
    self:_ShowContent(index)
end
MailCtrl._ShowContent = HL.Method(HL.Number) << function(self, index)
    local info = self.m_curMails[index]
    self.view.mailName.text = info.mail.title
    self.view.sendTimeTxt.text = os.date("!" .. Language.LUA_MAIL_SEND_TIME_FORMAT, info.sendTime + Utils.getServerTimeZoneOffsetSeconds())
    self.view.senderNameTxt.text = string.format(Language.LUA_MAIL_SENDER_FORMAT, info.senderName)
    self.view.contentTxt.text = UIUtils.resolveTextStyle(info.mail:GetContent())
    self.view.contentTxt:ShrinkLinkTags()
    if info.expireTime > 0 then
        self.view.expireTxt.gameObject:SetActive(true)
        self.view.expireTxt.text = string.format(Language.LUA_MAIL_CELL_EXPIRED_TIME_FORMAT, UIUtils.getLeftTime(info.expireTime - DateTimeUtils.GetCurrentTimestampByMilliseconds() / 1000))
    else
        self.view.expireTxt.gameObject:SetActive(false)
    end
    if info.items then
        self.view.rewardItems:InitRewardItems(info.items, info.collected)
        self.view.rewardsNode.gameObject:SetActive(true)
        self.view.getBtn.gameObject:SetActive(not info.collected)
        self.view.delBtn.gameObject:SetActive(info.collected)
    else
        self.view.rewardsNode.gameObject:SetActive(false)
        self.view.getBtn.gameObject:SetActive(false)
        self.view.delBtn.gameObject:SetActive(true)
    end
    if info.isStar then
        self.view.filterBtn.view.normalBtn.gameObject:SetActive(false)
        self.view.filterBtn.view.selectedBtn.gameObject:SetActive(true)
    else
        self.view.filterBtn.view.normalBtn.gameObject:SetActive(true)
        self.view.filterBtn.view.selectedBtn.gameObject:SetActive(false)
    end
    if not info.isRead then
        GameInstance.player.mail:ReadMail(info.id)
    end
    self.view.mailContentNode:ClearTween()
    self.view.mailContentNode:PlayInAnimation()
end
MailCtrl._OnClickGet = HL.Method() << function(self)
    local info = self.m_curMails[self.m_curMailIndex]
    GameInstance.player.mail:GetMailAttachment(info.id)
    AudioAdapter.PostEvent("au_ui_g_confirm_button_get_mail")
end
MailCtrl._OnClickGetAll = HL.Method() << function(self)
    for _, v in pairs(self.m_curMails) do
        if not v.collected then
            GameInstance.player.mail:GetAllMailAttachments()
            return
        end
    end
    Notify(MessageConst.SHOW_TOAST, Language.LUA_MAIL_NO_ATTACHMENT)
    AudioAdapter.PostEvent("au_ui_g_confirm_button_get_all_mail")
end
MailCtrl._OnClickDel = HL.Method() << function(self)
    local info = self.m_curMails[self.m_curMailIndex]
    if info.items and not info.collected then
        return
    end
    local hint
    if info.isStar then
        hint = Language.LUA_MAIL_HINT_DEL_STAR
    else
        hint = Language.LUA_MAIL_HINT_DEL_NORMAL
    end
    Notify(MessageConst.SHOW_POP_UP, {
        content = hint,
        onConfirm = function()
            GameInstance.player.mail:DelMail(info.id)
            AudioAdapter.PostEvent("au_ui_mail_delete")
        end
    })
end
MailCtrl._OnClickDelAll = HL.Method() << function(self)
    Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_MAIL_HINT_DEL_ALL,
        onConfirm = function()
            local canDelAll = false
            for i, mail in ipairs(self.m_curMails) do
                if mail.isRead and not mail.isStar and not (mail.items and not mail.collected) then
                    canDelAll = true
                    break
                end
            end
            if not canDelAll then
                return
            end
            GameInstance.player.mail:DelAllMails()
            AudioAdapter.PostEvent("au_ui_mail_delete")
        end
    })
end
MailCtrl._OnClickLostAndFound = HL.Method() << function(self)
    PhaseManager:OpenPhase(PhaseId.LostAndFound)
end
MailCtrl._OnClickStar = HL.Method() << function(self)
    local info = self.m_curMails[self.m_curMailIndex]
    GameInstance.player.mail:StarMail(info.id, not info.isStar)
end
MailCtrl.OnAllMailInited = HL.Method() << function(self)
    if self.m_inLoading then
        self:_OnLoadingFinished()
    else
        local curMail = self.m_curMails[self.m_curMailIndex]
        self:_OnClickTab(nil, curMail and curMail.id)
    end
end
MailCtrl.OnReadMail = HL.Method(HL.Table) << function(self, args)
    local id = unpack(args)
    for k, v in ipairs(self.m_curMails) do
        if v.id == id then
            local cell = self.m_getMailCell(k)
            if cell then
                self:_OnUpdateCell(cell, k)
            end
            return
        end
    end
end
MailCtrl.OnGetMailAttachment = HL.Method(HL.Table) << function(self, args)
    local rewardPack = unpack(args)
    local items = rewardPack.itemBundleList
    if items.Count == 0 then
        return
    end
    self:_OnClickTab(self.m_curMailIndex, nil)
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = Language.LUA_MAIL_GET_ITEM_SUCC_TITLE, icon = "icon_mail_obtain", items = items, chars = rewardPack.chars, })
end
MailCtrl.OnStarMail = HL.Method(HL.Table) << function(self, args)
    local id = unpack(args)
    for k, v in ipairs(self.m_curMails) do
        if v.id == id then
            local cell = self.m_getMailCell(k)
            if cell then
                self:_OnUpdateCell(cell, k)
            end
            if k == self.m_curMailIndex then
                if v.isStar then
                    self.view.filterBtn.view.normalBtn.gameObject:SetActive(false)
                    self.view.filterBtn.view.selectedBtn.gameObject:SetActive(true)
                else
                    self.view.filterBtn.view.normalBtn.gameObject:SetActive(true)
                    self.view.filterBtn.view.selectedBtn.gameObject:SetActive(false)
                end
            end
            return
        end
    end
end
MailCtrl.OnDelMails = HL.Method() << function(self)
    self:_OnClickTab(self.m_curMailIndex, nil)
end
MailCtrl.OnGetNewMails = HL.Method() << function(self)
    GameInstance.player.mail:GetAllMails()
end
MailCtrl._ToggleLoading = HL.Method(HL.Boolean) << function(self, active)
    self.m_inLoading = active
    self.view.contentNode.gameObject:SetActive(not active)
    self.view.loadingNode.gameObject:SetActive(active)
end
MailCtrl._OnClickLink = HL.Method(HL.String) << function(self, value)
    logger.info("_OnClickLink", value)
    CS.Beyond.UI.WebApplication.Start(value)
end
MailCtrl._CheckExpiredMail = HL.Method() << function(self)
    if not self.m_curMails then
        return
    end
    for _, v in ipairs(self.m_curMails) do
        if v.isExpired then
            self:_OnClickTab(nil, nil)
            return
        end
    end
end
HL.Commit(MailCtrl)