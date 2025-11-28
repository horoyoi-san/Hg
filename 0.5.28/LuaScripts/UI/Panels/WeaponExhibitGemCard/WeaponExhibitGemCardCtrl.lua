local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WeaponExhibitGemCard
WeaponExhibitGemCardCtrl = HL.Class('WeaponExhibitGemCardCtrl', uiCtrl.UICtrl)
WeaponExhibitGemCardCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.WEAPON_EXHIBIT_REFRESH_GEM_CARD] = "RefreshGemCard", [MessageConst.CLOSE_WEAPON_EXHIBIT_GEM_CARD] = "PlayAnimationOut", }
WeaponExhibitGemCardCtrl.m_gemInstIdLeft = HL.Field(HL.Number) << -1
WeaponExhibitGemCardCtrl.m_gemInstIdRight = HL.Field(HL.Number) << -1
WeaponExhibitGemCardCtrl.m_weaponInfo = HL.Field(HL.Table)
WeaponExhibitGemCardCtrl.m_effectCor = HL.Field(HL.Thread)
WeaponExhibitGemCardCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local weaponInfo = arg.weaponInfo
    self.m_weaponInfo = weaponInfo
    self.view.gemCardLeft.gameObject:SetActive(false)
    self.view.gemCardRight.gameObject:SetActive(false)
end
WeaponExhibitGemCardCtrl.RefreshGemCard = HL.Method(HL.Any) << function(self, arg)
    local hasGem = arg.hasGem
    local equippedGemInstId = arg.equippedGemInstId
    local selectGemInstId = arg.selectGemInstId
    local tryWeaponInstId = self.m_weaponInfo.weaponInstId
    local hasSelectedGem = selectGemInstId and selectGemInstId > 0
    local hasEquippedGem = equippedGemInstId and equippedGemInstId > 0
    local gemInstIdLeft = hasEquippedGem and equippedGemInstId or selectGemInstId
    local hasLeftGem = gemInstIdLeft and gemInstIdLeft > 0
    self.view.gemCardNode.gameObject:SetActive(hasGem)
    self.view.gemCardLeft.gameObject:SetActive(hasLeftGem)
    local isDifferentGem = hasSelectedGem and hasEquippedGem and selectGemInstId ~= equippedGemInstId
    if self.view.gemCardRight.gameObject.activeSelf ~= isDifferentGem then
        UIUtils.PlayAnimationAndToggleActive(self.view.gemCardRight.view.animationWrapper, isDifferentGem)
    end
    self.view.gemCardLeft.view.weaponInlayNode.gameObject:SetActive(hasEquippedGem)
    if isDifferentGem then
        if self.m_gemInstIdRight ~= selectGemInstId then
            self.m_gemInstIdRight = selectGemInstId
            self.view.gemCardRight:InitGemCard(selectGemInstId, tryWeaponInstId)
            self.view.gemCardRight.view.animationWrapper:ClearTween()
            self.view.gemCardRight.view.animationWrapper:PlayInAnimation()
        end
        self.view.gemCardRight.view.lockToggle.gameObject:SetActive(true)
        self.view.gemCardLeft.view.lockToggle.gameObject:SetActive(false)
    else
        if self.m_gemInstIdLeft ~= gemInstIdLeft then
            if self.m_gemInstIdLeft > 0 then
                self.m_effectCor = self:_ClearCoroutine(self.m_effectCor)
                self.m_effectCor = self:_StartCoroutine(function()
                    self.view.gemCardLeft.view.animationWrapper:ClearTween()
                    self.view.gemCardLeft.view.animationWrapper:PlayOutAnimation()
                    coroutine.wait(0.1)
                    self.view.gemCardLeft:InitGemCard(gemInstIdLeft, tryWeaponInstId)
                    self.view.gemCardLeft.view.animationWrapper:PlayInAnimation()
                end)
                self.view.gemCardRight.view.lockToggle.gameObject:SetActive(true)
                self.view.gemCardLeft.view.lockToggle.gameObject:SetActive(false)
            else
                self.view.gemCardLeft.view.animationWrapper:ClearTween()
                self.view.gemCardLeft.view.animationWrapper:PlayInAnimation()
                self.view.gemCardLeft:InitGemCard(gemInstIdLeft, tryWeaponInstId)
            end
            self.m_gemInstIdLeft = gemInstIdLeft
        else
            self.view.gemCardRight.view.lockToggle.gameObject:SetActive(false)
            self.view.gemCardLeft.view.lockToggle.gameObject:SetActive(true)
        end
    end
end
HL.Commit(WeaponExhibitGemCardCtrl)