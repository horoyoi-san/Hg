function replaceVars(str, vars)
    if not vars then
        vars = str
        str = vars[1]
    end
    return (string.gsub(str, "({([^}]+)})", function(whole, i)
        return vars[i] or whole
    end))
end