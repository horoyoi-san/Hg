local phaseStateBehaviour = require_ex('Phase/Core/PhaseStateBehaviour')
PhaseItemBase = HL.Class("PhaseItemBase", phaseStateBehaviour.PhaseStateBehaviour)
PhaseItemBase.phase = HL.Field(HL.Forward("PhaseBase"))
PhaseItemBase.phaseMsgMgr = HL.Field(HL.Forward("MessageManager"))
PhaseItemBase.phaseId = HL.Field(HL.Number) << -1
PhaseItemBase._OnInit = HL.Override() << function(self)
    self.phaseMsgMgr = nil
end
PhaseItemBase.OnPhaseRefresh = HL.Virtual(HL.Opt(HL.Any)) << function(self, arg)
end
PhaseItemBase.BindBasicInfos = HL.Method(HL.Forward('PhaseBase'), HL.Forward("MessageManager"), HL.Number) << function(self, phase, mgr, phaseId)
    self.phaseMsgMgr = mgr
    self.phaseId = phaseId
    self.phase = phase
end
PhaseItemBase._DoTransitionInCoroutine = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseItemBase._OnActivated = HL.Override() << function(self)
end
PhaseItemBase._OnDeActivated = HL.Override() << function(self)
end
PhaseItemBase._DoTransitionBehindCoroutine = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseItemBase._DoTransitionOutCoroutine = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseItemBase._CheckAllTransitionDone = HL.Override().Return(HL.Boolean) << function(self)
    return true
end
PhaseItemBase._OnDestroy = HL.Override() << function(self)
    self.phaseMsgMgr:UnregisterAll(self)
end
PhaseItemBase.Register = HL.Method(HL.Number, HL.Function) << function(self, msg, action)
    self.phaseMsgMgr:Register(msg, action, self)
end
PhaseItemBase.Notify = HL.Method(HL.Number, HL.Opt(HL.Any)) << function(self, msg, arg)
    self.phaseMsgMgr:Send(msg, arg)
end
HL.Commit(PhaseItemBase)