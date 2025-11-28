local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local BannerWidget = require_ex('UI/Panels/Watch/BannerWidget')
local PANEL_ID = PanelId.Watch
WatchCtrl = HL.Class('WatchCtrl', uiCtrl.UICtrl)
WatchCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_GOLD_CHANGE] = 'RefreshCurrency', [MessageConst.ON_BLOC_TOKEN_CHANGE] = 'RefreshCurrency', [MessageConst.ON_WALLET_CHANGED] = 'OnWalletChanged', [MessageConst.ON_SYSTEM_UNLOCK] = '_OnSystemUnlock', }
local BTN_CONST = { LEFT = { CHAR_FORMATION = 0, CHAR_INFO = 1, GACHA = 2, SHOP = 18, }, RIGHT = { MISSION = 3, NARRATE = 4, INVENTORY = 5, VALUABLE_INVENTORY = 6, MAP = 7, WIKI = 8, SNS = 16, SETTLEMENT = 15, EQUIP_PRODUCER = 17, CHECK_IN = 19, ADVENTURE_BOOK = 20, }, CENTER = { MAIL = 9, ANNOUNCEMENT = 10, SETTING = 11, FAC_TECH_TREE = 12, FAC_HUB_DATA = 13, FAC_CHAR_SET = 14, } }
WatchCtrl.m_btnData = HL.Field(HL.Table)
WatchCtrl.m_inited = HL.Field(HL.Boolean) << false
WatchCtrl.m_banner = HL.Field(HL.Forward("BannerWidget"))
WatchCtrl.BuildData = HL.Method() << function(self)
    if self.m_btnData == nil then
        self.m_btnData = {}
    end
    self.m_btnData = { [BTN_CONST.LEFT.CHAR_FORMATION] = { view = self.view.buttonCharFormation, phaseId = PhaseId.CharFormation, needRefreshUnlock = true, }, [BTN_CONST.LEFT.CHAR_INFO] = { view = self.view.buttonCharInfo, phaseId = PhaseId.CharInfo, needRefreshUnlock = true, needShowRedDot = true, }, [BTN_CONST.LEFT.GACHA] = { view = self.view.gachaBtnShadow, phaseId = PhaseId.GachaPool, openPhaseArg = "", needRefreshUnlock = true, }, [BTN_CONST.LEFT.SHOP] = { view = self.view.purchaseBtnNode, phaseId = PhaseId.ShopEntry, openPhaseArg = "", needRefreshUnlock = true, }, [BTN_CONST.RIGHT.ADVENTURE_BOOK] = { view = self.view.adventureBookNode, phaseId = PhaseId.AdventureBook, needRefreshUnlock = true, needShowRedDot = true, }, [BTN_CONST.RIGHT.MISSION] = { view = self.view.buttonMission, phaseId = PhaseId.Mission, needRefreshUnlock = true, }, [BTN_CONST.RIGHT.NARRATE] = { view = self.view.narrateNode, phaseId = PhaseId.PRTS, needShowRedDot = true, needRefreshUnlock = true, }, [BTN_CONST.RIGHT.INVENTORY] = { view = self.view.buttonInventory, phaseId = PhaseId.Inventory, needCloseWatch = true, needRefreshUnlock = true, }, [BTN_CONST.RIGHT.VALUABLE_INVENTORY] = { view = self.view.valuableButtonInvntory, phaseId = PhaseId.ValuableDepot, needRefreshUnlock = true, }, [BTN_CONST.RIGHT.MAP] = { view = self.view.buttonMap, phaseId = PhaseId.Map, needRefreshUnlock = true, needShowRedDot = true, }, [BTN_CONST.RIGHT.WIKI] = { view = self.view.wikiBtnShadow, phaseId = PhaseId.Wiki, needRefreshUnlock = true, needShowRedDot = true, }, [BTN_CONST.RIGHT.SNS] = { view = self.view.snsBtn, phaseId = PhaseId.SNS, needRefreshUnlock = true, needShowRedDot = true, }, [BTN_CONST.RIGHT.SETTLEMENT] = { view = self.view.settlementBtn, phaseId = PhaseId.SettlementMain, needRefreshUnlock = true, }, [BTN_CONST.RIGHT.EQUIP_PRODUCER] = { view = self.view.equipBtn, phaseId = PhaseId.EquipProducer, needRefreshUnlock = true, needShowRedDot = true, }, [BTN_CONST.RIGHT.CHECK_IN] = { view = self.view.checkInBtnShadow, phaseId = PhaseId.CheckIn, needRefreshUnlock = true, needShowRedDot = true, }, [BTN_CONST.CENTER.MAIL] = { view = self.view.mailNode, phaseId = PhaseId.Mail, needShowRedDot = true, }, [BTN_CONST.CENTER.SETTING] = { view = self.view.settingNode, phaseId = PhaseId.GameSetting, }, [BTN_CONST.CENTER.FAC_TECH_TREE] = { view = self.view.techtreeNode, phaseId = PhaseId.FacTechTree, needRefreshUnlock = true, needRefreshForbidden = true, needShowRedDot = true, }, [BTN_CONST.CENTER.FAC_HUB_DATA] = { view = self.view.reportNode, phaseId = PhaseId.FacHUBData, needRefreshUnlock = true, needRefreshForbidden = true, }, }
end
WatchCtrl.GenClickCallBack = HL.Method(HL.Int).Return(HL.Function) << function(self, key)
    if self.m_btnData == nil then
        return nil
    end
    local data = self.m_btnData[key]
    if data == nil then
        return nil
    end
    return function()
        if data.needCloseWatch then
            PhaseManager:ExitPhaseFast(PhaseId.Watch)
        end
        if not string.isEmpty(data.phaseId) then
            PhaseManager:OpenPhase(data.phaseId, data.openPhaseArg)
        end
    end
end
WatchCtrl.InitWatchNodes = HL.Method() << function(self)
    self:BuildData()
    local inSafeZone = Utils.isInSafeZone()
    for key, data in pairs(self.m_btnData or {}) do
        local view, phaseId = data.view, data.phaseId
        if view ~= nil and phaseId ~= nil then
            local needRefreshUnlock = data.needRefreshUnlock == true
            local unlocked = (not needRefreshUnlock) or self:_CheckUnlock(phaseId, true)
            local needCheckSafeZone = data.view.safeZoneIcon ~= nil
            local showSafeIcon = needCheckSafeZone and inSafeZone
            if needRefreshUnlock then
                if view.icon ~= nil then
                    view.icon.gameObject:SetActiveIfNecessary(unlocked and (not showSafeIcon))
                end
                if view.lockIcon ~= nil then
                    view.lockIcon.gameObject:SetActiveIfNecessary(not unlocked)
                end
                if view.text ~= nil then
                    view.text.gameObject:SetActiveIfNecessary(unlocked)
                end
            end
            if needCheckSafeZone and view.safeZoneIcon ~= nil then
                view.safeZoneIcon.gameObject:SetActiveIfNecessary(unlocked and showSafeIcon)
            end
            local needShowRedDot = data.needShowRedDot
            if view.redDot ~= nil then
                if needShowRedDot and unlocked then
                    local redDotName = PhaseManager:GetPhaseRedDotName(phaseId)
                    local showRedDot = not string.isEmpty(redDotName)
                    view.redDot.gameObject:SetActiveIfNecessary(showRedDot)
                    if showRedDot then
                        view.redDot:InitRedDot(redDotName)
                    end
                else
                    view.redDot:InitRedDot("")
                end
            end
            local callback = self:GenClickCallBack(key)
            if view.btn ~= nil then
                view.btn.onClick:AddListener(callback)
            end
        end
    end
    self.view.mapBtn.onClick:AddListener(function()
        if Utils.isInSpaceShip() then
            MapUtils.openMap(nil, Tables.spaceshipConst.baseSceneName)
            return
        end
        PhaseManager:OpenPhase(PhaseId.RegionMap)
    end)
end
WatchCtrl._InitDomain = HL.Method() << function(self)
    if Utils.isInSpaceShip() then
        local spaceshipPrefab = self:LoadGameObject(string.format(MapConst.UI_DOMAIN_MAP_PATH, MapConst.UI_SPACESHIP_MAP))
        local spaceshipGo = CSUtils.CreateObject(spaceshipPrefab, self.view.domainRoot[string.lower(MapConst.UI_SPACESHIP_MAP)])
        local spaceship = Utils.wrapLuaNode(spaceshipGo)
        local _, roomInfo = GameInstance.player.spaceship:TryGetRoom(Tables.spaceshipConst.controlCenterRoomId)
        spaceship.spaceshipInfo.lvTxt.text = roomInfo.lv
        return
    end
    local _, domainData = Tables.domainDataTable:TryGetValue(Utils.getCurDomainId())
    if domainData == nil then
        return
    end
    local domainPrefab = self:LoadGameObject(string.format(MapConst.UI_DOMAIN_MAP_PATH, domainData.domainMap))
    local domainGo = CSUtils.CreateObject(domainPrefab, self.view.domainRoot[string.lower(domainData.domainMap)])
    local _, regionMapSetting = domainGo:TryGetComponent(typeof(CS.Beyond.UI.RegionMapSetting))
    if regionMapSetting == nil then
        return
    end
    regionMapSetting:InitData(CS.Beyond.UI.RegionMapShowType.Watch, self.view.center, self.view.domainRoot.transform, self.view.config.RADIUS)
    for levelId, cfg in cs_pairs(regionMapSetting.cfg) do
        if cfg.isLoaded then
            local sceneBasicInfo = Utils.wrapLuaNode(cfg.ui)
            if sceneBasicInfo then
                local sceneBasicInfoArgs = { levelId = levelId, }
                sceneBasicInfo:InitSceneBasicInfo(sceneBasicInfoArgs)
            end
        end
    end
end
WatchCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:InitWatchNodes()
    self.view.buttonBack.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.Watch)
    end)
    self.view.quitBtn.onClick:AddListener(function()
        self:Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_EXIT_GAME_CONFIRM,
            hideBlur = true,
            onConfirm = function()
                logger.info("click quit btn on watch")
                CSUtils.QuitGame(0)
            end,
        })
    end)
    self.view.roleId.text = string.format("UID:%s", CSUtils.GetCurrentUID())
    self.view.modNameBtn.onClick:AddListener(function()
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_MODIFIY_NAME_LOCKED)
    end)
    self.view.adventureRewardEntryBtn.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.AdventureReward)
    end)
    self.view.announcementBtn.onClick:AddListener(function()
        GameInstance.player.announcement:OpenAnnouncement()
    end)
    self.view.announcementRedDot:InitRedDot("Announcement")
    self.view.staminaCell.gameObject:SetActive(Utils.isSystemUnlocked(GEnums.UnlockSystemType.Dungeon))
    self.view.staminaCell:InitMoneyCell(Tables.globalConst.apItemId)
    self.m_banner = BannerWidget(self.view.bannerNode)
    self.m_banner:InitBannerWidget()
    self:_InitShowInfo()
    self:_InitDomain()
    self:RefreshCurrency()
    self:RefreshAdventureInfo()
    self.view.addIconShadow.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.CommonMoneyExchange, { sourceId = Tables.globalConst.originiumItemId, targetId = Tables.globalConst.diamondItemId })
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    self.view.content.gameObject:SetActive(false)
    self.view.blurBG:UpdateRT()
    self.m_inited = false
    self:_StartCoroutine(function()
        coroutine.step()
        self.view.content.gameObject:SetActive(true)
        if self:IsShow() then
            self:_SetCameraCfg()
        end
        self.m_inited = true
    end)
end
WatchCtrl.OnClose = HL.Override() << function(self)
    self:_ClearCameraCfg()
    self.m_banner:OnDestroy()
end
WatchCtrl._SetCameraCfg = HL.Method() << function(self)
    CameraManager:SetUICameraPostProcess(true)
    CameraManager:SetUICameraCullingMask(UIConst.LAYERS.UIPP)
    UIManager:TryToggleMainCamera(self.panelCfg, true)
end
WatchCtrl._ClearCameraCfg = HL.Method() << function(self)
    CameraManager:SetUICameraPostProcess(false)
    CameraManager:ResetUICameraCullingMask()
    self.m_phase:_ChangeBlurSetting(false)
end
WatchCtrl._CheckUnlock = HL.Method(HL.Number, HL.Opt(HL.Any)).Return(HL.Boolean) << function(self, phaseId, silent)
    local unlock = PhaseManager:IsPhaseUnlocked(phaseId)
    if (not unlock) and (silent ~= true) then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_SYSTEM_LOCK)
    end
    return unlock
end
WatchCtrl._InitShowInfo = HL.Method() << function(self)
    self.view.infoEditImg.gameObject:SetActiveIfNecessary(false)
    self.view.facMiniPowerContent:InitFacMiniPowerContent()
    local needShowFacMiniPower = Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacSystem) and not Utils.isInSpaceShip()
    self.view.facMiniPower.gameObject:SetActiveIfNecessary(needShowFacMiniPower)
    local isInFacMainRegion = Utils.isInFacMainRegion()
    self.view.techtreeNode.forbidIcon.gameObject:SetActiveIfNecessary(false)
    self.view.employeeNode.forbidIcon.gameObject:SetActiveIfNecessary(not isInFacMainRegion)
    self.view.reportNode.forbidIcon.gameObject:SetActiveIfNecessary(false)
end
WatchCtrl.OnWalletChanged = HL.Method(HL.Table) << function(self, args)
    self:RefreshCurrency()
end
WatchCtrl._OnSystemUnlock = HL.Method(HL.Table) << function(self, arg)
    local systemIndex = unpack(arg)
    if systemIndex == GEnums.UnlockSystemType.Dungeon:GetHashCode() then
        self.view.staminaCell.gameObject:SetActive(true)
    end
end
WatchCtrl.RefreshAdventureInfo = HL.Method() << function(self)
    local adventureData = GameInstance.player.adventure.adventureLevelData
    local fillAmount = adventureData.reachMaxLv and 1 or adventureData.relativeExp / adventureData.relativeLevelUpExp
    local progressTxt = adventureData.reachMaxLv and Language.LUA_ADVENTURE_MAX_LEVEL_DESC or string.format(Language.LUA_ADVENTURE_REWARD_EXP_PROGRESS_FORMAT, adventureData.relativeExp, adventureData.relativeLevelUpExp)
    self.view.managerLevel.text = string.format(Language.LUA_ADVENTURE_LEVEL_FORMAT, adventureData.lv)
    self.view.managerName.text = GameInstance.player.playerInfoSystem.playerName
    self.view.levelSlider.fillAmount = fillAmount
    self.view.progressTxt.text = progressTxt
    local isMale = Utils.getPlayerGender() == CS.Proto.GENDER.GenMale
    if isMale then
        self.view.avatarState:SetState("Male")
    else
        self.view.avatarState:SetState("Female")
    end
end
WatchCtrl.RefreshCurrency = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    local originiumId = Tables.globalConst.originiumItemId
    local diamondId = Tables.globalConst.diamondItemId
    self.view.textMoney1.text = tonumber(GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), originiumId))
    self.view.textMoney2.text = tonumber(GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), diamondId))
end
WatchCtrl.OnHide = HL.Override() << function(self)
    self:_ClearCameraCfg()
    self.m_banner:SetPause(true)
end
WatchCtrl.OnShow = HL.Override() << function(self)
    if self.m_inited then
        self:_SetCameraCfg()
        self.m_banner:SetPause(false)
    end
end
WatchCtrl._OnPlayAnimationOut = HL.Override() << function(self)
end
WatchCtrl.OnAnimationInFinished = HL.Override() << function(self)
end
HL.Commit(WatchCtrl)