local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.BombAim
BombAimCtrl = HL.Class('BombAimCtrl', uiCtrl.UICtrl)
BombAimCtrl.m_isHit = HL.Field(HL.Boolean) << false
BombAimCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SYNC_AIM_POS] = '_OnSyncAimPos', [MessageConst.HIDE_BOMB_AIM] = '_OnHideBombAim', }
BombAimCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:BindInputPlayerAction("common_cancel", function()
        self:_OnCancel()
    end)
end
BombAimCtrl._OnShowBombAim = HL.StaticMethod() << function()
    local bombAimPanel = UIManager:AutoOpen(PANEL_ID)
    bombAimPanel.view.aimImage.gameObject:SetActive(true)
    bombAimPanel.view.aimImageFar.gameObject:SetActive(true)
    bombAimPanel.view.rightNode.gameObject:SetActive(true)
    bombAimPanel.view.animationWrapper:PlayWithTween("bombaimfar_in")
end
BombAimCtrl._OnHideBombAim = HL.Method() << function(self)
    self.view.aimImage.gameObject:SetActive(false)
    self.view.aimImageFar.gameObject:SetActive(false)
    self.view.rightNode.gameObject:SetActive(false)
    m_isHit = false
end
BombAimCtrl._OnSyncAimPos = HL.Method(HL.Any) << function(self, args)
    local pos, isHit = unpack(args)
    if isHit ~= m_isHit then
        m_isHit = isHit
        if m_isHit then
            aimImageObj = self.view.aimImage
            self.view.animationWrapper:PlayWithTween("bombaimfar_change", function()
                self.view.animationWrapper:PlayWithTween("bombaim_loop")
            end)
        else
            self.view.animationWrapper:PlayWithTween("bombaim_change", function()
                self.view.animationWrapper:PlayWithTween("bombaimfar_loop")
            end)
        end
    end
    local uiPos = UIUtils.objectPosToUI(pos, self.uiCamera, self.view.transform)
    self.view.aimImage.anchoredPosition = uiPos
    self.view.aimImageFar.anchoredPosition = uiPos
end
BombAimCtrl._OnCancel = HL.Method() << function(self)
    if GameInstance.playerController.mainCharacter == nil then
        return ;
    end
    GameInstance.playerController.mainCharacter.interactiveInstigatorCtrl:ClearPickupItem()
end
HL.Commit(BombAimCtrl)