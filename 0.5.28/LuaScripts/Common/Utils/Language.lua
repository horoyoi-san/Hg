local text = {}
local tmpText = {}
setmetatable(text, {
    __index = function(_, k)
        local succ, data = Tables.textTable:TryGetValue(k)
        if succ then
            return data
        end
        return tmpText[k] or k
    end
})
return text