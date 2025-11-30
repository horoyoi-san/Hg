local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaCharResult
GachaCharResultCtrl = HL.Class('GachaCharResultCtrl', uiCtrl.UICtrl)
GachaCharResultCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaCharResultCtrl.m_args = HL.Field(HL.Table)
GachaCharResultCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_args = args
    local isSix
    for k = 1, 10 do
        self:_UpdateChar(k)
        local char = self.m_args.chars[k]
        if char.rarity >= UIConst.CHAR_MAX_RARITY then
            isSix = true
        end
    end
    self.view.main:SetState(isSix and "SixStar" or "Normal")
    AudioManager.PostEvent(isSix and "Au_UI_Gacha_Sum6" or "Au_UI_Gacha_Sum")
    self:PlayAnimationIn()
    UIManager:ToggleBlockObtainWaysJump("IN_GACHA", true)
end
GachaCharResultCtrl._UpdateChar = HL.Method(HL.Number) << function(self, index)
    local name = "charCell" .. index
    local backCell = self.view.charBackNode[name]
    local frontCell = self.view.charFrontNode[name]
    local char = self.m_args.chars[index]
    backCell.button.onClick:RemoveAllListeners()
    backCell.button.onClick:AddListener(function()
        self:_ShowCharInfo(char.charId)
    end)
    backCell.bgMain1:LoadSprite(UIConst.UI_SPRITE_GACHA, string.format("bg_gacha_color_%d", char.rarity))
    backCell.bgMain2:LoadSprite(UIConst.UI_SPRITE_GACHA, string.format("bg_gacha_color_%d_2", char.rarity))
    backCell.bgReflection:LoadSprite(UIConst.UI_SPRITE_GACHA, string.format("bg_gacha_color_%d_3", char.rarity))
    backCell.charImg:LoadSprite(UIConst.UI_SPRITE_GACHA_CHAR, char.charId)
    backCell.charShadowImgReflection:LoadSprite(UIConst.UI_SPRITE_GACHA_CHAR_SHADOW, string.format("%s_s", char.charId))
    frontCell.charShadowImg:LoadSprite(UIConst.UI_SPRITE_GACHA_CHAR_SHADOW, char.charId)
    if not frontCell.m_starCells then
        frontCell.m_starCells = UIUtils.genCellCache(frontCell.starCell)
    end
    frontCell.m_starCells:Refresh(char.rarity)
    local stateName
    if char.rarity >= UIConst.CHAR_MAX_RARITY then
        stateName = "SixStar"
    elseif char.rarity >= UIConst.CHAR_MAX_RARITY - 1 then
        stateName = "FiveStar"
    else
        stateName = "Normal"
    end
    backCell.simpleStateController:SetState(stateName)
    frontCell.simpleStateController:SetState(stateName)
end
GachaCharResultCtrl.OnClose = HL.Override() << function(self)
    GameInstance.player.charBag:ClearAllClientCharInfo()
    UIManager:ToggleBlockObtainWaysJump("IN_GACHA", false)
end
GachaCharResultCtrl._ShowCharInfo = HL.Method(HL.String) << function(self, charId)
    if not UIManager:IsOpen(PANEL_ID) then
        return
    end
    if PhaseManager:IsOpen(PhaseId.CharInfo) then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_GACHA_RESULT_OPEN_CHAR_INFO_FAIL)
        return
    end
    local curCharInfo = CharInfoUtils.getPlayerCharInfoByTemplateId(charId, GEnums.CharType.Default)
    PhaseManager:OpenPhase(PhaseId.CharInfo, { initCharInfo = { instId = curCharInfo.instId, templateId = charId, charInstIdList = { curCharInfo.instId }, } })
end
HL.Commit(GachaCharResultCtrl)