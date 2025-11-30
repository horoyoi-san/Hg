local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.GachaPool
PhaseGachaPool = HL.Class('PhaseGachaPool', phaseBase.PhaseBase)
PhaseGachaPool.s_messages = HL.StaticField(HL.Table) << {}
PhaseGachaPool._OnInit = HL.Override() << function(self)
    PhaseGachaPool.Super._OnInit(self)
end
PhaseGachaPool.PrepareTransition = HL.Override(HL.Number, HL.Boolean, HL.Opt(HL.Number)) << function(self, transitionType, fastMode, anotherPhaseId)
    AudioAdapter.LoadAndPinEventsAsync({ UIConst.GACHA_MUSIC_UI, UIConst.GACHA_MUSIC_DROP_BIN })
end
PhaseGachaPool._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseGachaPool._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    AudioAdapter.UnpinEvent(UIConst.GACHA_MUSIC_UI)
    AudioAdapter.UnpinEvent(UIConst.GACHA_MUSIC_DROP_BIN)
end
PhaseGachaPool._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseGachaPool._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseGachaPool._OnActivated = HL.Override() << function(self)
    LuaSystemManager.gachaSystem:UpdateGachaSettingState()
end
PhaseGachaPool._OnDeActivated = HL.Override() << function(self)
    LuaSystemManager.gachaSystem:UpdateGachaSettingState()
end
PhaseGachaPool._OnDestroy = HL.Override() << function(self)
    PhaseGachaPool.Super._OnDestroy(self)
end
HL.Commit(PhaseGachaPool)