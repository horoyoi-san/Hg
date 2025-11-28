local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaWeapon
local GachaState = { UIStar = 1, Show = 2, }
local StarAnimations = { [4] = "gacha_char_start_4", [5] = "gacha_char_start_5", [6] = "gacha_char_start_6", }
local StarAudios = { [4] = "Au_UI_Gacha_Star4_weapon", [5] = "Au_UI_Gacha_Star5_weapon", [6] = "Au_UI_Gacha_Star6_weapon", }
local UIRarityColorConfigName = { [4] = "RARITY_COLOR_4", [5] = "RARITY_COLOR_5", [6] = "RARITY_COLOR_6", }
local LoopAudios = { [4] = "Au_UI_Gacha_Weaponshow4", [5] = "Au_UI_Gacha_Weaponshow5", [6] = "Au_UI_Gacha_Weaponshow6", }
local WeaponRootName = { [GEnums.WeaponType.Sword] = "swordRoot", [GEnums.WeaponType.Wand] = "wandRoot", [GEnums.WeaponType.Claymores] = "claymoresRoot", [GEnums.WeaponType.Gun] = "gunRoot", [GEnums.WeaponType.Lance] = "lanceRoot", [GEnums.WeaponType.Pistol] = "pistolRoot", }
GachaWeaponCtrl = HL.Class('GachaWeaponCtrl', uiCtrl.UICtrl)
GachaWeaponCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaWeaponCtrl.m_args = HL.Field(HL.Table)
GachaWeaponCtrl.m_curInfo = HL.Field(HL.Table)
GachaWeaponCtrl.m_weaponCount = HL.Field(HL.Number) << -1
GachaWeaponCtrl.m_curIndex = HL.Field(HL.Number) << -1
GachaWeaponCtrl.m_isSkipped = HL.Field(HL.Boolean) << false
GachaWeaponCtrl.m_lastSkipTime = HL.Field(HL.Number) << 0
GachaWeaponCtrl.m_state = HL.Field(HL.Number) << -1
GachaWeaponCtrl.m_curWeaponObjList = HL.Field(HL.Table)
GachaWeaponCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.view.fullScreenBtn.onClick:AddListener(function()
        self:_OnClickScreen()
    end)
    self.view.skipBtn.onClick:AddListener(function()
        self:_Skip()
    end)
    self.view.transitions.gameObject:SetActive(true)
    self.m_args = args
    self.m_weaponCount = #self.m_args.weapons
    self.m_modelRequestList = {}
    self.m_curWeaponObjList = {}
end
GachaWeaponCtrl._PlayWeaponAt = HL.Method(HL.Number) << function(self, index)
    self.m_curIndex = index
    self.m_curInfo = self.m_args.weapons[index]
    self.m_lastSkipTime = 0
    logger.info("GachaWeaponCtrl._PlayWeaponAt", index, self.m_curInfo)
    self:_PlayStarAnimation()
end
GachaWeaponCtrl._PlayStarAnimation = HL.Method() << function(self)
    logger.info("GachaWeaponCtrl._PlayStarAnimation")
    self.m_state = GachaState.UIStar
    self.view.contentNode.gameObject:SetActive(false)
    self.view.starNode.gameObject:SetActive(true)
    self.m_phase.m_displayObjItem.view.charInfo3DUI.gameObject:SetActive(false)
    self:_HideAllRarityEffect()
    local ani = StarAnimations[self.m_curInfo.rarity]
    self.view.transitions:ResetVideo()
    self.view.starNode:Play(ani, function()
        if PhaseManager:IsOpen(PhaseId.GachaWeapon) then
            self:_ShowContent()
        end
    end)
    local info = self.m_curInfo
    local weaponId = info.weaponId
    local weaponCfg = Utils.tryGetTableCfg(Tables.weaponBasicTable, weaponId)
    local weaponType = weaponCfg.weaponType
    self:_ShowModelAsset(weaponId, weaponType)
    AudioManager.PostEvent(StarAudios[info.rarity])
end
GachaWeaponCtrl._ShowContent = HL.Method() << function(self)
    logger.info("GachaWeaponCtrl._ShowContent")
    self.m_state = GachaState.Show
    local info = self.m_curInfo
    local weaponId = info.weaponId
    local weaponCfg = Utils.tryGetTableCfg(Tables.weaponBasicTable, weaponId)
    local weaponName = UIUtils.getItemName(weaponId)
    local weaponTypeName = UIUtils.getItemTypeName(weaponId)
    local weaponEngName = weaponCfg.engName
    local weaponType = weaponCfg.weaponType
    self.view.nameTxt.text = weaponName
    self.view.nameShadowTxt.text = weaponName
    self.view.professionIcon:LoadSprite(UIConst.UI_SPRITE_WEAPON_EXHIBIT, UIConst.WEAPON_EXHIBIT_WEAPON_TYPE_ICON_PREFIX .. weaponType:ToInt())
    self.view.elementTxt.text = weaponTypeName
    self.view.newHintNode.gameObject:SetActive(info.isNew)
    self.view.starGroup:InitStarGroup(info.rarity)
    local extraRewardNode = self.view.extraRewardNode
    if info.items and next(info.items) then
        local extraCount = #info.items
        extraRewardNode.gameObject:SetActive(true)
        if not extraRewardNode.m_extraItemCells then
            extraRewardNode.m_extraItemCells = UIUtils.genCellCache(extraRewardNode.extraItemCell)
        end
        extraRewardNode.m_extraItemCells:Refresh(extraCount, function(cell, index)
            local bundle = info.items[index]
            self:_UpdateItemCell(cell, bundle.id, bundle.count)
        end)
    else
        extraRewardNode.gameObject:SetActive(false)
    end
    self.view.contentNode.gameObject:SetActive(true)
    local ui3d = self.m_phase.m_displayObjItem.view.charInfo3DUI
    if ui3d then
        ui3d.nameTxt.text = weaponEngName
        ui3d.gameObject:SetActive(true)
    end
    AudioManager.PostEvent(LoopAudios[info.rarity])
    local colorName = UIRarityColorConfigName[info.rarity]
    self.view.lightImg.color = self.view.config[colorName]
    self:_ShowRarityEffect(info.rarity)
    if not self.m_isSkipped then
        self.view.skipBtn.gameObject:SetActive(self.m_curIndex < self.m_weaponCount)
    end
end
GachaWeaponCtrl._UpdateItemCell = HL.Method(HL.Table, HL.String, HL.Number) << function(self, cell, itemId, count)
    local itemData = Tables.itemTable[itemId]
    cell.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
    cell.countTxt.text = string.format("×%d", count)
    cell.rarityImg.color = UIUtils.getItemRarityColor(itemData.rarity)
end
GachaWeaponCtrl._Exit = HL.Method() << function(self)
    logger.info("GachaWeaponCtrl._Exit")
    local onComplete = self.m_args.onComplete
    PhaseManager:ExitPhaseFast(PhaseId.GachaWeapon)
    if onComplete then
        onComplete()
    end
end
GachaWeaponCtrl.m_weaponRootCache = HL.Field(HL.Table)
GachaWeaponCtrl._InitAllWeaponRoot = HL.Method() << function(self)
    self.m_weaponRootCache = {}
    for weaponType, rootName in pairs(WeaponRootName) do
        local root = self.m_phase.m_displayObjItem.view.weaponRoot[rootName]
        if root then
            local rootList = self.m_weaponRootCache[weaponType]
            if not rootList then
                rootList = {}
                self.m_weaponRootCache[weaponType] = rootList
            end
            local subRootCount = root.childCount
            if subRootCount <= 0 then
                subRootCount = 1
                table.insert(rootList, root)
            else
                for i = 0, subRootCount - 1 do
                    local child = root:GetChild(i)
                    table.insert(rootList, child)
                end
            end
        else
            logger.error("Not found weapon root, name：" .. rootName)
        end
    end
end
GachaWeaponCtrl._ShowModelAsset = HL.Method(HL.String, GEnums.WeaponType) << function(self, weaponId, weaponType)
    logger.info("GachaWeaponCtrl._ShowModelAsset")
    local hasValue, modelPath = CS.Beyond.Gameplay.WeaponUtil.TryGetWeaponModelByTemplateId(weaponId, false)
    if not hasValue then
        logger.error("Not found weapon model path, id：" .. weaponId)
        return
    end
    if self.m_weaponRootCache == nil then
        self:_InitAllWeaponRoot()
    end
    local subRootList = self.m_weaponRootCache[weaponType]
    if subRootList == nil then
        logger.error("[GachaWeaponCtrl._ShowModelAsset] subRootList == nil, weaponType:" .. weaponType)
        return
    end
    local subRootCount = #subRootList
    for i = 1, subRootCount do
        local subRoot = subRootList[i]
        self:_LoadModelAsync(i, modelPath, function(modelGo)
            table.insert(self.m_curWeaponObjList, modelGo)
            modelGo:SetLayerRecursive(UIConst.GACHA_LAYER)
            local success, animator = modelGo:TryGetComponent(typeof(CS.UnityEngine.Animator))
            if success then
                animator.enabled = false
            end
            local transform = modelGo.transform
            transform:SetParent(subRoot)
            transform.localPosition = Vector3.zero
            transform.localEulerAngles = Vector3.zero
            transform.localScale = Vector3.one
        end)
    end
end
GachaWeaponCtrl.m_modelRequestList = HL.Field(HL.Table)
GachaWeaponCtrl._LoadModelAsync = HL.Method(HL.Number, HL.String, HL.Function) << function(self, loadKey, modelPath, callback)
    local modelManager = GameInstance.modelManager
    self.m_modelRequestList[loadKey] = modelManager:LoadAsync(modelPath, function(path, activeModelGo)
        self.m_modelRequestList[loadKey] = nil
        if activeModelGo and callback then
            callback(activeModelGo)
        end
    end)
end
GachaWeaponCtrl.m_rarityEffect = HL.Field(HL.Table)
GachaWeaponCtrl._ShowRarityEffect = HL.Method(HL.Number) << function(self, rarity)
    if self.m_rarityEffect == nil then
        self:_LoadRarityEffect()
    end
    for key, obj in pairs(self.m_rarityEffect) do
        if key == rarity then
            obj:SetActive(true)
        else
            obj:SetActive(false)
        end
    end
end
GachaWeaponCtrl._HideAllRarityEffect = HL.Method() << function(self)
    if self.m_rarityEffect == nil then
        self:_LoadRarityEffect()
    end
    for _, obj in pairs(self.m_rarityEffect) do
        obj:SetActive(false)
    end
end
GachaWeaponCtrl._LoadRarityEffect = HL.Method() << function(self)
    local displayView = self.m_phase.m_displayObjItem.view
    self.m_rarityEffect = { [4] = displayView.rarityEffect4.gameObject, [5] = displayView.rarityEffect5.gameObject, [6] = displayView.rarityEffect6.gameObject, }
end
GachaWeaponCtrl._ClearCurAsset = HL.Method() << function(self)
    for key, obj in pairs(self.m_curWeaponObjList) do
        GameObject.Destroy(obj)
        self.m_curWeaponObjList[key] = nil
    end
    local modelManager = GameInstance.modelManager
    for key, requestId in pairs(self.m_modelRequestList) do
        modelManager:Cancel(requestId)
        self.m_modelRequestList[key] = nil
    end
end
GachaWeaponCtrl._GoToNext = HL.Method() << function(self)
    logger.info("GachaWeaponCtrl._GoToNext")
    self:_ClearCurAsset()
    local newIndex
    for k = self.m_curIndex + 1, self.m_weaponCount do
        local info = self.m_args.weapons[k]
        if not self.m_isSkipped or info.isNew or info.rarity == UIConst.WEAPON_MAX_RARITY then
            newIndex = k
            break
        end
    end
    if newIndex then
        self:_PlayWeaponAt(newIndex)
    else
        self:_Exit()
    end
end
GachaWeaponCtrl._Skip = HL.Method() << function(self)
    logger.info("GachaWeaponCtrl._Skip")
    self.m_isSkipped = true
    self.view.skipBtn.gameObject:SetActive(false)
    if self.m_curInfo.isNew or self.m_curInfo.rarity == UIConst.WEAPON_MAX_RARITY then
        self:_OnClickScreen()
    else
        self:_GoToNext()
    end
end
GachaWeaponCtrl._OnClickScreen = HL.Method() << function(self)
    if Time.unscaledTime < self.m_lastSkipTime + self.view.config.SKIP_CD then
        return
    end
    logger.info("GachaWeaponCtrl._OnClickScreen", self.m_state)
    if self.m_state == GachaState.UIStar then
        self.m_lastSkipTime = Time.unscaledTime
        self.view.starNode.gameObject:SetActive(false)
        self:_ShowContent()
    elseif self.m_state == GachaState.Show then
        if self.view.starNode.curState == CS.Beyond.UI.UIConst.AnimationState.Stop then
            self.m_lastSkipTime = Time.unscaledTime
            self:_GoToNext()
        end
    end
end
HL.Commit(GachaWeaponCtrl)