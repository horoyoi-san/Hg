local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MouseIconHint
MouseIconHintCtrl = HL.Class('MouseIconHintCtrl', uiCtrl.UICtrl)
MouseIconHintCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.CHANGE_MOUSE_ICON_HINT] = 'ChangeMouseIconHint', }
MouseIconHintCtrl.m_iconInfos = HL.Field(HL.Table)
MouseIconHintCtrl.m_nextPriority = HL.Field(HL.Number) << 0
MouseIconHintCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_iconInfos = {}
    self:_UpdateIcon()
end
MouseIconHintCtrl.OnClose = HL.Override() << function(self)
end
MouseIconHintCtrl.ChangeMouseIconHint = HL.Method(HL.Table) << function(self, args)
    local name = args.name
    local type = args.type
    if type == UIConst.MOUSE_ICON_HINT.Default then
        self.m_iconInfos[name] = nil
    else
        self.m_iconInfos[name] = { name = name, type = type, priority = self.m_nextPriority, }
        self.m_nextPriority = self.m_nextPriority + 1
    end
    self:_UpdateIcon()
end
MouseIconHintCtrl._UpdateIcon = HL.Method() << function(self)
    local maxPriority = -1
    local maxPriorityInfo
    for _, v in pairs(self.m_iconInfos) do
        if v.priority > maxPriority then
            maxPriority = v.priority
            maxPriorityInfo = v
        end
    end
    local texName
    if maxPriorityInfo then
        texName = maxPriorityInfo.type
    else
        texName = UIConst.MOUSE_ICON_HINT.Default
    end
    local tex = self.loader:LoadTexture(string.format("Assets/Beyond/DynamicAssets/Gameplay/UI/Textures/Mouse/%s.png", texName))
    Unity.Cursor.SetCursor(tex, Vector2.zero, Unity.CursorMode.Auto)
end
HL.Commit(MouseIconHintCtrl)