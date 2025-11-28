local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharInfoPotentialSkillTips
CharInfoPotentialSkillTipsCtrl = HL.Class('CharInfoPotentialSkillTipsCtrl', uiCtrl.UICtrl)
local ANIM_NAME_LEFT_IN = "charinfopotentiaskilltips_left_in"
local ANIM_NAME_RIGHT_IN = "charinfopotentiaskilltips_right_in"
CharInfoPotentialSkillTipsCtrl.s_messages = HL.StaticField(HL.Table) << {}
CharInfoPotentialSkillTipsCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.view.btnMask.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
end
CharInfoPotentialSkillTipsCtrl.ShowTips = HL.StaticMethod(HL.Table) << function(args)
    local isShowing = UIManager:IsShow(PANEL_ID)
    local self = UIManager:AutoOpen(PANEL_ID)
    if isShowing then
        self:PlayAnimationOutWithCallback(function()
            self:_Refresh(args)
        end)
    else
        self:_Refresh(args)
    end
end
CharInfoPotentialSkillTipsCtrl._Refresh = HL.Method(HL.Table) << function(self, args)
    local charPotentialList = Tables.characterPotentialTable[args.charId]
    local charPotentialUnlockData = charPotentialList.potentialUnlockBundle[args.potentialLevel - 1]
    self.view.titleText.text = charPotentialUnlockData.name
    local potentialDesc = CS.Beyond.Gameplay.PotentialUtil.GetPotentialDescription(args.charId, args.potentialLevel)
    self.view.descText.text = UIUtils.resolveTextStyle(potentialDesc)
    self.view.hintText.text = string.format(Language.LUA_POTENTIAL_UNLOCK_FORMAT, args.potentialLevel)
    self.view.lock.gameObject:SetActive(args.isLocked)
    self.view.arrowLeft.gameObject:SetActive(args.isArrowLeft)
    self.view.arrowRight.gameObject:SetActive(not args.isArrowLeft)
    UIUtils.updateTipsPosition(self.view.tips, args.followedTransform, self.view.rectTransform, self.uiCamera, args.isArrowLeft and UIConst.UI_TIPS_POS_TYPE.RightTop or UIConst.UI_TIPS_POS_TYPE.LeftTop)
    self.view.animWrapper:Play(args.isArrowLeft and ANIM_NAME_LEFT_IN or ANIM_NAME_RIGHT_IN)
end
HL.Commit(CharInfoPotentialSkillTipsCtrl)