LuaUpdateGroup = HL.Class('LuaUpdateGroup')
LuaUpdateGroup.updateName = HL.Field(HL.String) << ''
LuaUpdateGroup.m_bindingActions = HL.Field(HL.Table)
LuaUpdateGroup.m_bindingTimeSliceActions = HL.Field(HL.Table)
LuaUpdateGroup.m_timeSliceTickCount = HL.Field(HL.Number) << 0
LuaUpdateGroup.m_lazyDelActions = HL.Field(HL.Table)
LuaUpdateGroup.LuaUpdateGroup = HL.Constructor(HL.String) << function(self, updateName)
    self.updateName = updateName
    self.m_bindingActions = {}
    self.m_bindingTimeSliceActions = {}
    self.m_timeSliceTickCount = 0
    self.m_lazyDelActions = {}
end
LuaUpdateGroup._ExecActions = HL.Method(HL.Number) << function(self, deltaTime)
    local actions = self.m_bindingActions
    local delActions = self.m_lazyDelActions
    for key, action in pairs(actions) do
        if not delActions[key] then
            local succ, result = xpcall(action, debug.traceback, deltaTime)
            if succ then
                local finished = result
                if finished then
                    self:Remove(key)
                end
            else
                logger.error("LuaUpdateGroup Action Fail\n", self.updateName, result)
                self:Remove(key)
            end
        end
    end
    local slicedActions = self.m_bindingTimeSliceActions
    local curSlicedCount = #slicedActions
    if curSlicedCount > 0 then
        local info, key, foundValidTick
        for i = 1, curSlicedCount do
            local index = (self.m_timeSliceTickCount + i - 1) % curSlicedCount + 1
            info = slicedActions[index]
            key = info[1]
            if not delActions[key] then
                foundValidTick = true
                break
            end
        end
        if foundValidTick then
            local action = info[2]
            local succ, result = xpcall(action, debug.traceback, deltaTime)
            if succ then
                local finished = result
                if finished then
                    self:Remove(key)
                end
            else
                logger.error("LuaUpdateGroup Action Fail\n", self.updateName, result)
                self:Remove(key)
            end
            self.m_timeSliceTickCount = (self.m_timeSliceTickCount + 1) % curSlicedCount
        end
    end
    if next(delActions) then
        for k, _ in pairs(delActions) do
            actions[k] = nil
        end
        local newSlicedActions = {}
        for _, v in ipairs(slicedActions) do
            if not delActions[v[1]] then
                table.insert(newSlicedActions, v)
            end
        end
        self.m_bindingTimeSliceActions = newSlicedActions
        self.m_lazyDelActions = {}
    end
end
LuaUpdateGroup.Add = HL.Method(HL.Number, HL.Function, HL.Opt(HL.Boolean)) << function(self, key, action, useTimeSlice)
    if useTimeSlice then
        table.insert(self.m_bindingTimeSliceActions, { key, action })
    else
        self.m_bindingActions[key] = action
    end
end
LuaUpdateGroup.Remove = HL.Method(HL.Opt(HL.Number)) << function(self, key)
    self.m_lazyDelActions[key] = true
end
HL.Commit(LuaUpdateGroup)
return LuaUpdateGroup