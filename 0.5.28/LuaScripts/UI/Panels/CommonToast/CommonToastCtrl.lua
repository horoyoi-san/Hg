local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonToast
CommonToastCtrl = HL.Class('CommonToastCtrl', uiCtrl.UICtrl)
CommonToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
CommonToastCtrl.m_showingToasts = HL.Field(HL.Forward("Queue"))
CommonToastCtrl.m_cacheToasts = HL.Field(HL.Forward("Stack"))
CommonToastCtrl.m_maxCount = HL.Field(HL.Number) << 0
CommonToastCtrl.OnShowToast = HL.StaticField(HL.Any) << function(arg)
    local ctrl = CommonToastCtrl.AutoOpen(PANEL_ID, nil, false)
    ctrl:ShowToast(arg)
end
CommonToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_showingToasts = require_ex("Common/Utils/DataStructure/Queue")()
    self.m_cacheToasts = require_ex("Common/Utils/DataStructure/Stack")()
    self.view.toastCell.gameObject:SetActive(false)
    self:_InitMaxCount()
    self.view.systemToast:InitToast()
end
CommonToastCtrl._InitMaxCount = HL.Method() << function(self)
    local spacing = self.view.list.spacing
    local cellHeight = self.view.toastCell.rectTransform.rect.height
    local rect = self.view.list:RectTransform().rect
    local maxCount = math.floor((rect.height + spacing) / cellHeight)
    self.m_maxCount = maxCount
end
CommonToastCtrl._GetCurTextToast = HL.Method(HL.String).Return(HL.Table, HL.Number) << function(self, text)
    if self.m_showingToasts:Empty() then
        return nil, -1
    end
    for i = 1, self.m_showingToasts:Size() do
        local toast = self.m_showingToasts:AtIndex(i)
        if toast.label.text == text then
            return toast, i
        end
    end
    return nil, -1
end
CommonToastCtrl.ShowToast = HL.Method(HL.Any) << function(self, arg)
    local text, duration, soundId = nil, nil, nil
    if type(arg) == "string" then
        text = arg
    elseif type(arg) == "table" then
        text, duration, soundId = unpack(arg)
    end
    if text then
        text = UIUtils.resolveTextStyle(text)
        local showingToasts = self.m_showingToasts
        local oldestToast, index = self:_GetCurTextToast(text)
        if oldestToast then
            self.m_showingToasts:RemoveAt(index)
            self:_ClearTimer(oldestToast.timerId)
            oldestToast.animation:ClearTween(false)
            self:_CacheToast(oldestToast)
        elseif showingToasts:Size() >= self.m_maxCount then
            oldestToast = showingToasts:Pop()
            self:_ClearTimer(oldestToast.timerId)
            oldestToast.animation:ClearTween(false)
            self:_CacheToast(oldestToast)
        end
        local toast = self:_GetToast()
        toast.transform:SetAsLastSibling()
        toast.gameObject:SetActive(true)
        toast.animation:PlayInAnimation()
        toast.label.text = text
        showingToasts:Push(toast)
        if duration == nil or duration == 0 then
            toast.timerId = self:_StartTimer(self.view.config.SHOW_DURATION, function()
                self:_HideToast(toast)
            end)
        else
            toast.timerId = self:_StartTimer(duration, function()
                self:_HideToast(toast)
            end)
        end
        self:_PlayToastSound(soundId)
    end
end
CommonToastCtrl._HideToast = HL.Method(HL.Table) << function(self, toast)
    toast.animation:PlayOutAnimation(function()
        self:_CacheToast(toast)
        self.m_showingToasts:Pop()
    end)
end
CommonToastCtrl._GetToast = HL.Method().Return(HL.Table) << function(self)
    if self.m_cacheToasts:Count() > 0 then
        return self.m_cacheToasts:Pop()
    end
    local obj = CSUtils.CreateObject(self.view.toastCell.gameObject, self.view.list.transform)
    local toast = {}
    local luaRef = obj.transform:GetComponent("LuaReference")
    luaRef:BindToLua(toast)
    return toast
end
CommonToastCtrl._CacheToast = HL.Method(HL.Table) << function(self, toast)
    toast.gameObject:SetActive(false)
    toast.timerId = -1
    self.m_cacheToasts:Push(toast)
end
CommonToastCtrl._PlayToastSound = HL.Method(HL.Any) << function(self, soundId)
    if soundId == CS.Proto.CODE.ErrItemBagBagSpaceNotEnough then
        AudioManager.PostEvent("au_sfx_ui_alarm_bag_full")
    end
end
CommonToastCtrl.OnShowSystemToast = HL.StaticField(HL.Any) << function(arg)
    local ctrl = CommonToastCtrl.AutoOpen(PANEL_ID, nil, false)
    if ctrl == nil then
        return
    end
    ctrl:ShowSystemToast(arg)
end
CommonToastCtrl.ShowSystemToast = HL.Method(HL.Any) << function(self, arg)
    local systemToastText = arg
    local systemToast = self.view.systemToast
    if systemToast == nil then
        return
    end
    systemToast.view.systemToastText.text = systemToastText
    systemToast:ShowToast()
end
HL.Commit(CommonToastCtrl)