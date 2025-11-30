local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.BigLogo
BigLogoCtrl = HL.Class('BigLogoCtrl', uiCtrl.UICtrl)
BigLogoCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SHOW_BIG_LOGO] = '_OnShowBigLogo', [MessageConst.ON_LOAD_NEW_CUTSCENE] = '_OnLoadNewCutscene', }
BigLogoCtrl.m_timelineHandle = HL.Field(HL.Userdata)
BigLogoCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_timelineHandle = unpack(args)
end
BigLogoCtrl.OnShow = HL.Override() << function(self)
    self:_BindBigLogo()
end
BigLogoCtrl._OnShowBigLogo = HL.Method(HL.Table) << function(self, args)
    local sprite, useStretchImage = unpack(args)
    if useStretchImage then
        self.view.stretchImage.sprite = sprite
    else
        self.view.nameImg.sprite = sprite
    end
end
BigLogoCtrl._OnLoadNewCutscene = HL.Method(HL.Any) << function(self, args)
    self:_BindBigLogo()
end
BigLogoCtrl._BindBigLogo = HL.Method() << function(self)
    self.view.bigLogoMain.gameObject:SetActive(false)
    self.view.stretchImageMain.gameObject:SetActive(false)
    local cinematicMgr = GameInstance.world.cutsceneManager
    cinematicMgr:BindBigLogo(self.m_timelineHandle, self.view.bigLogoPanel)
end
HL.Commit(BigLogoCtrl)