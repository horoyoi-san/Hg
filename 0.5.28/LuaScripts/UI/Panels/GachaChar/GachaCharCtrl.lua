local GachaCharTLHelper = require_ex("UI/Panels/GachaChar/GachaCharTLHelper")
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaChar
local GachaState = { UIStar = 1, CharEnter = 2, CharLoop = 3, ShowResult = 4, }
local StarAnimations = { [4] = "gacha_char_start_4", [5] = "gacha_char_start_5", [6] = "gacha_char_start_6", }
local StarAudios = { [4] = "Au_UI_Gacha_Star4", [5] = "Au_UI_Gacha_Star5", [6] = "Au_UI_Gacha_Star6", }
local LoopAudios = { [4] = "Au_UI_Gacha_Charshow4", [5] = "Au_UI_Gacha_Charshow5", [6] = "Au_UI_Gacha_Charshow6", }
GachaCharCtrl = HL.Class('GachaCharCtrl', uiCtrl.UICtrl)
GachaCharCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaCharCtrl.m_args = HL.Field(HL.Table)
GachaCharCtrl.m_charCount = HL.Field(HL.Number) << -1
GachaCharCtrl.m_curInfo = HL.Field(HL.Table)
GachaCharCtrl.m_curIndex = HL.Field(HL.Number) << -1
GachaCharCtrl.m_state = HL.Field(HL.Number) << -1
GachaCharCtrl.m_startTimelineCor = HL.Field(HL.Thread)
GachaCharCtrl.m_curCharObj = HL.Field(CS.UnityEngine.GameObject)
GachaCharCtrl.m_curCharTLHelper = HL.Field(HL.Forward('GachaCharTLHelper'))
GachaCharCtrl.m_isSkipped = HL.Field(HL.Boolean) << false
GachaCharCtrl.m_startTimerId = HL.Field(HL.Number) << -1
GachaCharCtrl.m_introduceVoiceTimerId = HL.Field(HL.Number) << -1
GachaCharCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.view.fullScreenBtn.onClick:AddListener(function()
        self:_OnClickScreen()
    end)
    self.view.skipBtn.onClick:AddListener(function()
        self:_Skip()
    end)
    self.m_args = args
    self.m_charCount = #self.m_args.chars
    self.view.transitions.gameObject:SetActive(true)
end
GachaCharCtrl.OnClose = HL.Override() << function(self)
    if self.m_curCharTLHelper then
        self.m_curCharTLHelper:OnDispose()
    end
end
GachaCharCtrl._PlayCharacterAt = HL.Method(HL.Number) << function(self, index)
    self.m_curIndex = index
    self.m_curInfo = self.m_args.chars[index]
    self.m_lastSkipTime = 0
    self.m_startTimerId = self:_ClearTimer(self.m_startTimerId)
    logger.info("GachaCharCtrl._PlayCharacterAt", index, self.m_curInfo)
    self:_PlayStarAnimation()
end
GachaCharCtrl._PlayStarAnimation = HL.Method() << function(self)
    logger.info("GachaCharCtrl._PlayStarAnimation")
    self.m_state = GachaState.UIStar
    self.view.contentNode.gameObject:SetActive(false)
    self.view.starNode.gameObject:SetActive(true)
    self.m_phase.m_roomObjItem.view.charInfo3DUI.gameObject:SetActive(false)
    local rarity = self.m_curInfo.rarity
    local ani = StarAnimations[rarity]
    self.view.transitions:ResetVideo()
    self.view.starNode:Play(ani)
    self.view.bottomMaskBeforePlayTL.gameObject:SetActive(true)
    AudioManager.PostEvent(StarAudios[rarity])
    local charId = self.m_curInfo.charId
    local gachaCharData = Tables.gachaCharInfoTable[charId]
    local path = string.format(UIConst.GACHA_CHAR_TIMELINE_PATH, gachaCharData.timelineAssetName, gachaCharData.timelineAssetName)
    local time = Time.unscaledTime
    self.loader:LoadGameObjectAsync(path, function()
        logger.info("抽卡角色预载完成", Time.unscaledTime - time, charId)
    end)
    self.m_startTimelineCor = self:_ClearCoroutine(self.m_startTimelineCor)
    self.m_startTimelineCor = self:_StartCoroutine(function()
        local delayTime = self.view.config["TIMELINE_DELAY_TIME_" .. rarity]
        local tween = self.view.starNode.curTween
        local clipLength = self.view.starNode:GetClipLength(ani)
        while true do
            coroutine.step()
            if tween:GetValue() * clipLength >= delayTime then
                self:_PlayTimeline(false)
                return
            end
        end
    end)
end
GachaCharCtrl._PlayTimeline = HL.Method(HL.Boolean) << function(self, jumpToLoop)
    logger.info("GachaCharCtrl._PlayTimeline", jumpToLoop)
    self.view.bottomMaskBeforePlayTL.gameObject:SetActive(false)
    self.m_startTimelineCor = self:_ClearCoroutine(self.m_startTimelineCor)
    self.m_state = GachaState.CharEnter
    local charId = self.m_curInfo.charId
    local gachaCharData = Tables.gachaCharInfoTable[charId]
    local path = string.format(UIConst.GACHA_CHAR_TIMELINE_PATH, gachaCharData.timelineAssetName, gachaCharData.timelineAssetName)
    local prefab = self.loader:LoadGameObject(path)
    local charObj = CSUtils.CreateObject(prefab, self.m_phase.m_roomObjItem.view.timelineRoot)
    self.m_curCharObj = charObj
    self.m_curCharTLHelper = GachaCharTLHelper(charObj.transform, {
        onLoopChanged = function(isLoop)
            if isLoop and self.m_state ~= GachaState.CharLoop then
                self:_ShowContent()
            end
        end,
    })
    local lightPrefab = self.loader:LoadGameObject(string.format("Assets/Beyond/DynamicAssets/Gameplay/Prefabs/CharInfo/AdditionalLights/light_%s.prefab", charId))
    local lightObj = CSUtils.CreateObject(lightPrefab, charObj.transform)
    local uiModelMono = charObj.gameObject:GetComponentInChildren(typeof(CS.Beyond.Gameplay.View.CharUIModelMono), true)
    lightObj.gameObject:SetActive(true)
    lightObj.transform:DoActionOnChildren(function(childTrans)
        local isTarget = childTrans.name == "light_overview"
        childTrans.gameObject:SetActive(isTarget)
        if isTarget then
            uiModelMono:InitLightFollower(childTrans)
        end
    end)
    local volumePrefab = self.loader:LoadGameObject(string.format("Assets/Beyond/DynamicAssets/Gameplay/Prefabs/CharInfo/CameraTracks/track_%s.prefab", charId))
    local volumeObj = CSUtils.CreateObject(volumePrefab, charObj.transform)
    volumeObj.gameObject:SetActive(true)
    volumeObj.transform:DoActionOnChildren(function(childTrans)
        local isVolume = childTrans.name == "VolumeModifiers"
        childTrans.gameObject:SetActive(isVolume)
        if isVolume then
            childTrans:DoActionOnChildren(function(volumeTrans)
                local isTargetVolume = volumeTrans.name == "volume_overview"
                volumeTrans.gameObject:SetActive(isTargetVolume)
                if isTargetVolume then
                    local mod = volumeTrans:GetComponent(typeof(CS.Beyond.Gameplay.CharInfoVolumeCameraBiasModifier))
                    if mod then
                        local globalVolume = self.m_phase.m_roomObjItem.view.charOverrideVolume
                        mod:UseDataOnVolume(globalVolume)
                    end
                end
            end)
        end
    end)
    charObj:SetLayerRecursive(UIConst.GACHA_LAYER)
    self.m_startTimerId = self:_ClearTimer(self.m_startTimerId)
    if jumpToLoop then
        self.m_curCharTLHelper:JumpToLoopSection(0.5)
    else
        self.m_curCharTLHelper:SampleToBeginning()
        self.m_startTimerId = self:_StartTimer(0.25, function()
            if self.m_curCharTLHelper then
                self.m_curCharTLHelper:PlayFromStart()
            end
        end)
    end
    if not jumpToLoop then
        Utils.triggerVoice("chrbark_Introduce", self.m_curInfo.charId)
        logger.info("Gacha chrbark_Introduce 1", self.m_curInfo.charId)
    end
end
GachaCharCtrl._ShowContent = HL.Method() << function(self)
    logger.info("GachaCharCtrl._ShowContent")
    self.m_startTimerId = self:_ClearTimer(self.m_startTimerId)
    self.m_state = GachaState.CharLoop
    local info = self.m_curInfo
    local charId = info.charId
    local charCfg = Tables.characterTable[charId]
    self.view.nameTxt.text = charCfg.name
    self.view.nameTxtShadow.text = charCfg.name
    self.view.professionIcon:LoadSprite(UIConst.UI_SPRITE_CHAR_PROFESSION, UIConst.UI_CHAR_PROFESSION_PREFIX .. charCfg.profession:ToInt())
    self.view.charElementIcon:InitCharTypeIcon(charCfg.charTypeId)
    self.view.elementTxt.text = Tables.CharTypeTable[charCfg.charTypeId].name
    self.view.newHintNode.gameObject:SetActive(info.isNew)
    self.view.starGroup:InitStarGroup(self.m_curInfo.rarity)
    self.view.dialogTxt.gameObject:SetActive(false)
    AudioManager.PostEvent(LoopAudios[self.m_curInfo.rarity])
    local firstItemBundle = info.items[1]
    if firstItemBundle then
        self:_UpdateItemCell(self.view.wpnRewardNode, firstItemBundle.id, firstItemBundle.count)
        local extraCount = #info.items - 1
        local extraRewardNode = self.view.extraRewardNode
        if extraCount > 0 then
            extraRewardNode.gameObject:SetActive(true)
            if not extraRewardNode.m_extraItemCells then
                extraRewardNode.m_extraItemCells = UIUtils.genCellCache(extraRewardNode.extraItemCell)
            end
            extraRewardNode.m_extraItemCells:Refresh(extraCount, function(cell, index)
                local bundle = info.items[index + 1]
                self:_UpdateItemCell(cell, bundle.id, bundle.count)
            end)
        else
            extraRewardNode.gameObject:SetActive(false)
        end
    else
        self.view.wpnRewardNode.gameObject:SetActive(false)
        self.view.extraRewardNode.gameObject:SetActive(false)
    end
    self.view.contentNode.gameObject:SetActive(true)
    local ui3d = self.m_phase.m_roomObjItem.view.charInfo3DUI
    ui3d.nameTxt.text = charCfg.engName
    ui3d.gameObject:SetActive(true)
    local isPadScreen = Screen.width / Screen.height < CS.Beyond.UI.UIConst.STANDARD_RATIO - 0.1
    local uiPosNode = self.m_curCharObj.transform:Find(isPadScreen and "UIPosNodePad" or "UIPosNode")
    if not uiPosNode and isPadScreen then
        logger.error("抽卡角色展示没有为Pad设置的名字位置", charId)
        uiPosNode = self.m_curCharObj.transform:Find("UIPosNode")
    end
    if uiPosNode then
        ui3d.gameObject.transform.position = uiPosNode.transform.position
    else
        logger.error("No UIPosNode In", self.m_curCharObj.transform:PathFromRoot())
    end
    if not self.m_isSkipped then
        self.view.skipBtn.gameObject:SetActive(self.m_curIndex < self.m_charCount)
    end
end
GachaCharCtrl._UpdateItemCell = HL.Method(HL.Table, HL.String, HL.Number) << function(self, cell, itemId, count)
    local itemData = Tables.itemTable[itemId]
    cell.itemIcon:InitItemIcon(itemId)
    cell.countTxt.text = string.format("×%d", count)
    cell.rarityImg.color = UIUtils.getItemRarityColor(itemData.rarity)
end
GachaCharCtrl.m_lastSkipTime = HL.Field(HL.Number) << 0
GachaCharCtrl._OnClickScreen = HL.Method() << function(self)
    if Time.unscaledTime < self.m_lastSkipTime + self.view.config.SKIP_CD then
        return
    end
    logger.info("GachaCharCtrl._OnClickScreen", self.m_state)
    if self.m_state == GachaState.UIStar then
        self.m_lastSkipTime = Time.unscaledTime
        self.view.starNode.gameObject:SetActive(false)
        self:_PlayTimeline(true)
        local curIndex = self.m_curIndex
        self.m_introduceVoiceTimerId = self:_StartTimer(self.view.config.SKIP_CD + 0.1, function()
            if curIndex == self.m_curIndex then
                Utils.triggerVoice("chrbark_Introduce", self.m_curInfo.charId)
                logger.info("Gacha chrbark_Introduce 2", self.m_curInfo.charId)
            end
        end)
    elseif self.m_state == GachaState.CharEnter then
        self.m_lastSkipTime = Time.unscaledTime
        self.m_curCharTLHelper:JumpToLoopSection(0.5)
    elseif self.m_state == GachaState.CharLoop then
        if self.view.starNode.curState == CS.Beyond.UI.UIConst.AnimationState.Stop then
            self.m_lastSkipTime = Time.unscaledTime
            self:_GoToNext()
        end
    end
end
GachaCharCtrl._GoToNext = HL.Method() << function(self)
    logger.info("GachaCharCtrl._GoToNext")
    self:_ClearCurAsset()
    AudioManager.PostEvent("chr_extrsour_sys_chrbark_introduce_stop")
    logger.info("Gacha chr_extrsour_sys_chrbark_introduce_stop")
    local newIndex
    for k = self.m_curIndex + 1, self.m_charCount do
        local info = self.m_args.chars[k]
        if not self.m_isSkipped or info.isNew or info.rarity == UIConst.CHAR_MAX_RARITY then
            newIndex = k
            break
        end
    end
    if newIndex then
        self:_PlayCharacterAt(newIndex)
    else
        self:_ShowResult()
    end
end
GachaCharCtrl._ClearCurAsset = HL.Method() << function(self)
    if not self.m_curCharObj then
        return
    end
    self.m_startTimerId = self:_ClearTimer(self.m_startTimerId)
    self.m_curCharTLHelper:OnDispose()
    self.m_curCharTLHelper = nil
    GameObject.Destroy(self.m_curCharObj)
    self.m_curCharObj = nil
end
GachaCharCtrl._Skip = HL.Method() << function(self)
    logger.info("GachaCharCtrl._Skip")
    self.m_isSkipped = true
    self.view.skipBtn.gameObject:SetActive(false)
    if self.m_curInfo.isNew or self.m_curInfo.rarity == UIConst.CHAR_MAX_RARITY then
        self:_OnClickScreen()
    else
        self:_GoToNext()
    end
end
GachaCharCtrl._ShowResult = HL.Method() << function(self)
    logger.info("GachaCharCtrl._ShowResult")
    self.m_introduceVoiceTimerId = self:_ClearTimer(self.m_introduceVoiceTimerId)
    AudioManager.PostEvent("chr_extrsour_sys_chrbark_introduce_stop")
    logger.info("Gacha chr_extrsour_sys_chrbark_introduce_stop")
    self.m_startTimelineCor = self:_ClearCoroutine(self.m_startTimelineCor)
    if #self.m_args.chars == 10 then
        UIManager:Open(PanelId.GachaCharResultBG)
        UIManager:Open(PanelId.GachaCharResult, { chars = self.m_args.chars, })
        UIManager:Open(PanelId.GachaCharResultTop, {
            chars = self.m_args.chars,
            onComplete = function()
                UIManager:Close(PanelId.GachaCharResult)
                UIManager:Close(PanelId.GachaCharResultBG)
                self:_ShowRewardsAndExit()
            end
        })
    else
        self:_ShowRewardsAndExit()
    end
end
GachaCharCtrl._ShowRewardsAndExit = HL.Method() << function(self)
    logger.info("GachaCharCtrl._ShowRewardsAndExit")
    if not self.m_args.fromGacha then
        self:_Exit()
        return
    end
    local itemMap = {}
    for _, v in ipairs(self.m_args.chars) do
        for __, bundle in ipairs(v.items) do
            if itemMap[bundle.id] then
                itemMap[bundle.id] = itemMap[bundle.id] + bundle.count
            else
                itemMap[bundle.id] = bundle.count
            end
        end
    end
    local itemList = {}
    for id, count in pairs(itemMap) do
        local info = { id = id, count = count }
        local itemData = Tables.itemTable[id]
        info.sortId1 = itemData.sortId1
        info.sortId2 = itemData.sortId2
        info.rarity = itemData.rarity
        table.insert(itemList, info)
    end
    table.sort(itemList, Utils.genSortFunction("sortId1", "sortId2", "rarity"))
    self:_Exit()
    if next(itemList) then
        Notify(MessageConst.SHOW_SYSTEM_REWARDS, { items = itemList })
    end
end
GachaCharCtrl._Exit = HL.Method() << function(self)
    logger.info("GachaCharCtrl._Exit")
    local onComplete = self.m_args.onComplete
    PhaseManager:PopPhase(PhaseId.GachaChar)
    if onComplete then
        onComplete()
    end
end
HL.Commit(GachaCharCtrl)