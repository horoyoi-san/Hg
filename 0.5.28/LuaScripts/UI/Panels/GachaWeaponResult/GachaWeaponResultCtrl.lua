local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaWeaponResult
local PHASE_ID = PhaseId.GachaWeaponResult
GachaWeaponResultCtrl = HL.Class('GachaWeaponResultCtrl', uiCtrl.UICtrl)
GachaWeaponResultCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaWeaponResultCtrl.m_createdWeaponInsts = HL.Field(HL.Table)
GachaWeaponResultCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_createdWeaponInsts = {}
    self.view.btnClose.onClick:AddListener(function()
        self:_OnClickExit()
    end)
    local weapons = arg.weapons
    local maxRarity = 0
    local spriteDict = {}
    local weaponSpriteDict = {}
    for i, weapon in ipairs(weapons) do
        local cell = self.view['gachaWeaponResultCell' .. i]
        cell.gameObject:SetActive(true)
        local rarity = weapon.rarity
        maxRarity = math.max(maxRarity, rarity)
        for j = 4, 6 do
            if j == rarity then
                cell["starBg" .. j].gameObject:SetActive(true)
                cell["starLight" .. j].gameObject:SetActive(true)
            else
                cell["starBg" .. j].gameObject:SetActive(false)
                cell["starLight" .. j].gameObject:SetActive(false)
            end
        end
        if #weapon.items > 0 then
            cell.itemNumberNode.gameObject:SetActive(true)
            local item = weapon.items[1]
            local itemId = item.id
            local itemData = Tables.itemTable:GetValue(itemId)
            local sprite
            if not spriteDict[itemId] then
                sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
                spriteDict[itemId] = sprite
            else
                sprite = spriteDict[itemId]
            end
            cell.icon.sprite = sprite
            cell.countTxt.text = "×" .. item.count
        else
            cell.itemNumberNode.gameObject:SetActive(false)
        end
        cell.newNode.gameObject:SetActive(weapon.isNew)
        local weaponSprite
        local weaponItemData = Tables.itemTable:GetValue(weapon.weaponId)
        if not weaponSpriteDict[weaponItemData.iconId] then
            weaponSprite = self:LoadSprite(UIConst.UI_SPRITE_GACHA_WEAPON, weaponItemData.iconId)
            weaponSpriteDict[weaponItemData.iconId] = weaponSprite
        else
            weaponSprite = weaponSpriteDict[weaponItemData.iconId]
        end
        cell.weaponImg.sprite = weaponSprite
        cell.weaponShadowImg.sprite = weaponSprite
        cell.bgImageMask.enabled = (i ~= 1)
        cell.button.onClick:AddListener(function()
            self:_ShowInitWeaponPreview(weapon.weaponId)
        end)
    end
    self:PlayAnimationIn()
    if maxRarity >= 6 then
        AudioManager.PostEvent("Au_UI_Gacha_Sum6_weapon")
    else
        AudioManager.PostEvent("Au_UI_Gacha_Sum_weapon")
    end
end
GachaWeaponResultCtrl._OnClickExit = HL.Method() << function(self)
    local arg = self.m_phase.arg
    if arg and arg.onComplete then
        arg.onComplete()
    end
    PhaseManager:ExitPhaseFast(PhaseId.GachaWeaponResult)
end
GachaWeaponResultCtrl._ShowInitWeaponPreview = HL.Method(HL.String) << function(self, weaponId)
    local weaponInst
    if self.m_createdWeaponInsts[weaponId] ~= nil then
        weaponInst = self.m_createdWeaponInsts[weaponId]
    else
        weaponInst = GameInstance.player.inventory:CreateClientInitPoolWeaponInst(weaponId)
        self.m_createdWeaponInsts[weaponId] = weaponInst
        GameInstance.player.charBag.clientItemInstDatas:Add(weaponInst.instId, weaponInst)
    end
    local fadeTimeBoth = UIConst.CHAR_INFO_TRANSITION_BLACK_SCREEN_DURATION
    local dynamicFadeData = UIUtils.genDynamicBlackScreenMaskData("GachaWeaponPool->WeaponInfo", fadeTimeBoth, fadeTimeBoth, function()
        PhaseManager:OpenPhase(PhaseId.WeaponInfo, { weaponTemplateId = weaponId, weaponInstId = weaponInst.instId, isFocusJump = true, })
    end)
    GameAction.ShowBlackScreen(dynamicFadeData)
end
GachaWeaponResultCtrl.OnClose = HL.Override() << function(self)
    for weaponId, weaponInst in pairs(self.m_createdWeaponInsts) do
        GameInstance.player.charBag.clientItemInstDatas:Remove(weaponInst.instId)
    end
    self.m_createdWeaponInsts = {}
end
HL.Commit(GachaWeaponResultCtrl)