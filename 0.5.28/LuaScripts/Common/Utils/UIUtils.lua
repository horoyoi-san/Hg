function initLuaCustomConfig(self)
    self.luaCustomConfig = self.luaCustomConfig or self.transform:GetComponent("LuaCustomConfig")
    if not self.luaCustomConfig then
        return
    end
    self.config = {}
    self.config.HasValue = function(_, key)
        local flag = self.luaCustomConfig.itemDict:TryGetValue(key)
        local defaultValue = self.defaultConfig and self.defaultConfig[key]
        local hotfixValue = self.hotfixConfig and self.hotfixConfig[key]
        if (not flag) and (not defaultValue) and (not hotfixValue) then
            return false
        end
        return true
    end
    if UNITY_EDITOR and CS.Beyond.DebugDefines.realTimeLuaCustomConfig then
        setmetatable(self.config, {
            __index = function(_, key)
                local hotfixValue = self.hotfixConfig and self.hotfixConfig[key]
                if hotfixValue ~= nil then
                    return hotfixValue
                end
                local flag, item = self.luaCustomConfig.itemDict:TryGetValue(key)
                if flag then
                    local valueType = CS.Beyond.Lua.LuaCustomConfig.ValueType
                    if item.valueType == valueType.Bool then
                        return item.boolValue
                    elseif item.valueType == valueType.Int then
                        return item.intValue
                    elseif item.valueType == valueType.Float then
                        return item.floatValue
                    elseif item.valueType == valueType.String then
                        return item.stringValue
                    elseif item.valueType == valueType.Vector2 then
                        return item.vector2Value
                    elseif item.valueType == valueType.Vector3 then
                        return item.vector3Value
                    elseif item.valueType == valueType.Color then
                        return item.colorValue
                    elseif item.valueType == valueType.Lua then
                        return lume.dostring("return " .. item.luaValue)
                    elseif item.valueType == valueType.FMODEvent then
                        return item.fmodEventValue
                    elseif item.valueType == valueType.GameObject then
                        return item.gameObjectValue
                    elseif item.valueType == valueType.RectTransform then
                        return item.rectTransformValue
                    elseif item.valueType == valueType.AnimationCurve then
                        return item.curveValue
                    elseif item.valueType == valueType.LayerMask then
                        return item.layerMaskValue
                    elseif item.valueType == valueType.Material then
                        return item.material
                    end
                end
                local defaultValue = self.defaultConfig and self.defaultConfig[key]
                if defaultValue ~= nil then
                    return defaultValue
                end
                logger.error("无法获取 LuaCustomConfig 配置项", key)
            end
        })
    else
        local componentConfig = {}
        self.luaCustomConfig:InitConfigTable(componentConfig)
        setmetatable(self.config, {
            __index = function(_, key)
                local hotfixValue = self.hotfixConfig and self.hotfixConfig[key]
                if hotfixValue ~= nil then
                    return hotfixValue
                end
                local componentValue = componentConfig[key]
                if componentValue ~= nil then
                    return componentValue
                end
                local defaultValue = self.defaultConfig and self.defaultConfig[key]
                if defaultValue ~= nil then
                    return defaultValue
                end
                logger.error("无法获取 LuaCustomConfig 配置项", key)
            end
        })
    end
    getmetatable(self.config).__newindex = function()
        logger.error("请在面板上配置 LuaCustomConfig，勿在代码中修改 view.config 中的值！" & "默认值请添加到 view.defaultConfig, 热更新值请添加到 view.hotfixConfig")
    end
end
function genCachedCellFunction(list, onMiss)
    onMiss = onMiss or function(obj)
        return Utils.wrapLuaNode(obj)
    end
    local cache = {}
    local getCell = function(object)
        local cell = cache[object]
        if not cell then
            cell = onMiss(object)
            cache[object] = cell
        end
        return cell
    end
    return function(object)
        if not object then
            return
        end
        if type(object) == "number" then
            if not list then
                logger.error("genCachedCellFunction fail", list)
                return
            end
            local luaIndex = object
            object = list:Get(CSIndex(luaIndex))
        end
        if object then
            return getCell(object)
        end
    end
end
function addChild(parent, prefab, keepScale)
    local item = {}
    item.gameObject = CSUtils.CreateObject(prefab.gameObject, parent.gameObject)
    item.transform = item.gameObject.transform:GetComponent("RectTransform")
    if not keepScale then
        item.transform.localScale = Vector3.one
    end
    return item
end
local UIListCacheClass = require_ex("Common/Utils/UI/UIListCache").UIListCache
function genCellCache(itemTemplate, wrapFunction, parent)
    return UIListCacheClass(itemTemplate, wrapFunction, parent)
end
function getStandardScreenX(x)
    return x / Screen.width * UIConst.CANVAS_DEFAULT_WIDTH
end
function getStandardScreenY(y)
    return y / Screen.height * UIConst.CANVAS_DEFAULT_HEIGHT
end
function getNormalizedScreenX(x)
    return x / Screen.width
end
function getNormalizedScreenY(y)
    return y / Screen.height
end
function isInputEventScopeValid(scope)
    scope = scope or Types.EInputBindingScope.IncludeStandalone
    local isValid
    if scope == Types.EInputBindingScope.EditorOnly then
        isValid = UNITY_EDITOR
    elseif scope == Types.EInputBindingScope.IncludeDev then
        isValid = UNITY_EDITOR or DEVELOPMENT_BUILD
    elseif scope == Types.EInputBindingScope.IncludeStandalone then
        isValid = UNITY_EDITOR or DEVELOPMENT_BUILD or UNITY_STANDALONE
    end
    return isValid
end
function bindInputPlayerAction(actionId, callback, groupId)
    return InputManagerInst:CreateBinding(actionId, callback, groupId)
end
function bindInputEvent(key, action, modifyKeys, timing, groupId)
    return InputManagerInst:CreateBinding(key, modifyKeys or "", timing or InputTimingType.OnClick, action, groupId or UIManager.persistentInputBindingKey)
end
function initUIDragHelper(uiDragItem, info)
    if uiDragItem.luaTable then
        local dragHelper = uiDragItem.luaTable[1]
        dragHelper:RefreshInfo(info)
        return dragHelper
    else
        local DragHelperClass = require_ex("Common/Utils/UI/UIDragHelper")
        return DragHelperClass(uiDragItem, info)
    end
end
function initUIDropHelper(uiDropItem, info)
    if uiDropItem.luaTable then
        local dropHelper = uiDropItem.luaTable[1]
        if BEYOND_DEBUG_COMMAND then
            if not dropHelper or type(dropHelper) ~= "userdata" then
                logger.error("InValid dropHelper", uiDropItem.luaTable, uiDropItem.transform:PathFromRoot())
            end
        end
        dropHelper:RefreshInfo(info)
        return dropHelper
    else
        local DropHelperClass = require_ex("Common/Utils/UI/UIDropHelper")
        return DropHelperClass(uiDropItem, info)
    end
end
function isTypeDropValid(dragHelper, acceptTypes)
    local isSourceValid = not acceptTypes.sources or lume.find(acceptTypes.sources, dragHelper.source)
    if not isSourceValid then
        return false
    end
    local isTypeValid = not acceptTypes.types or lume.find(acceptTypes.types, dragHelper.type)
    if not isTypeValid then
        return false
    end
    return true
end
function playItemDragAudio(itemId)
    local res, audioData = Tables.audioItemDragAndDrop:TryGetValue(itemId)
    if res and not string.isEmpty(audioData.audioDrag) then
        AudioAdapter.PostEvent(audioData.audioDrag)
        return
    end
    local itemData = Tables.itemTable[itemId]
    local audioTypeData = Tables.audioItemTypeDragAndDrop[itemData.showingType]
    if audioTypeData ~= nil and not string.isEmpty(audioTypeData.audioDrag) then
        AudioAdapter.PostEvent(audioTypeData.audioDrag)
    end
end
function playItemDropAudio(itemId)
    local res, audioData = Tables.audioItemDragAndDrop:TryGetValue(itemId)
    if res and not string.isEmpty(audioData.audioDrop) then
        AudioAdapter.PostEvent(audioData.audioDrop)
        return
    end
    local itemData = Tables.itemTable[itemId]
    local audioTypeData = Tables.audioItemTypeDragAndDrop[itemData.showingType]
    if audioTypeData ~= nil and not string.isEmpty(audioTypeData.audioDrop) then
        AudioAdapter.PostEvent(audioTypeData.audioDrop)
    end
end
function screenPointToUI(screenPos, uiCamera, canvasRect)
    canvasRect = canvasRect or UIManager.uiCanvasRect
    local isInside, uiPos = Unity.RectTransformUtility.ScreenPointToLocalPointInRectangle(canvasRect, screenPos, uiCamera)
    return uiPos, isInside
end
function objectPosToUI(pos, uiCamera, canvasRect)
    local screenPos = CameraManager.mainCamera:WorldToScreenPoint(pos)
    if screenPos.z < 0 then
        screenPos.x = -screenPos.x
        screenPos.y = -screenPos.y
    end
    return screenPointToUI(Vector2(screenPos.x, screenPos.y), uiCamera, canvasRect)
end
function getUIRectOfRectTransform(rectTransform, uiCamera)
    local rect = CSUtils.RectTransformToScreenRect(rectTransform, uiCamera)
    rect.y = Screen.height - rect.yMax
    local canvasRect = UIManager.uiCanvasRect.rect
    local scaleX = canvasRect.width / Screen.width
    local scaleY = canvasRect.height / Screen.height
    return Unity.Rect(rect.x * scaleX, rect.y * scaleY, rect.size.x * scaleX, rect.size.y * scaleY)
end
function getSpritePath(path, name)
    if name then
        path = path .. "/" .. name
    end
    return UIConst.UI_SPRITE_PATH:format(path)
end
function isScreenPosInRectTransform(pos, rectTransform, uiCamera)
    return CS.Beyond.UI.UIUtils.IsScreenPosInRectTransform(pos, rectTransform, uiCamera)
end
function getTransformScreenRect(transform, uiCamera)
    local bounds = CSUtils.GetRectTransformBounds(transform)
    local min = bounds.min
    local size = bounds.size
    if uiCamera then
        min = uiCamera:WorldToScreenPoint(min)
        local max = uiCamera:WorldToScreenPoint(bounds.max)
        size = max - min
    end
    return Unity.Rect(min.x, Screen.height - (min.y + size.y), size.x, size.y)
end
function updateTipsPosition(contentRectTrans, targetTransform, canvasRectTrans, uiCamera, posType, padding, xOffset)
    if IsNull(targetTransform) then
        contentRectTrans.anchoredPosition = Vector2.zero
        return
    end
    local targetScreenRect = getTransformScreenRect(targetTransform, uiCamera)
    updateTipsPositionWithScreenRect(contentRectTrans, targetScreenRect, canvasRectTrans, uiCamera, posType, padding, xOffset)
end
function updateTipsPositionWithScreenRect(contentRectTrans, targetScreenRect, canvasRectTrans, uiCamera, posType, padding, xOffset)
    posType = posType or UIConst.UI_TIPS_POS_TYPE.RightDown
    LayoutRebuilder.ForceRebuildLayoutImmediate(contentRectTrans)
    local width = contentRectTrans.rect.width
    local height = contentRectTrans.rect.height
    local canvasSize = canvasRectTrans.rect.size
    local oriScreenSize = Vector2(Screen.width, Screen.height)
    local xRation = oriScreenSize.x / canvasSize.x
    local yRation = oriScreenSize.y / canvasSize.y
    local widthInScreen = width * xRation
    local heightInScreen = height * yRation
    local halfHeightInScreen = heightInScreen / 2
    local halfWidthInScreen = widthInScreen / 2
    padding = padding or {}
    local paddingTop = (padding.top or 0) * yRation
    local paddingLeft = (padding.left or 0) * xRation
    local paddingRight = (padding.right or 0) * xRation
    local paddingBottom = (padding.bottom or 0) * yRation
    local screenSize = Vector2(oriScreenSize.x - (paddingLeft + paddingRight), oriScreenSize.y - (paddingTop + paddingBottom))
    targetScreenRect.x = targetScreenRect.x - paddingLeft
    targetScreenRect.y = targetScreenRect.y - paddingTop
    local screenPos = Vector2(0, 0)
    if posType == UIConst.UI_TIPS_POS_TYPE.MidBottom then
        local verticalSpaceEnough = true
        local downHeight = screenSize.y - targetScreenRect.yMax
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.yMax + halfHeightInScreen
        else
            local upHeightEnough = targetScreenRect.yMin >= heightInScreen
            if upHeightEnough then
                screenPos.y = targetScreenRect.yMin - halfHeightInScreen
            else
                screenPos.y = targetScreenRect.center.y
                verticalSpaceEnough = false
            end
        end
        local rightWidth = screenSize.x - targetScreenRect.xMax
        local leftWidth = targetScreenRect.xMin
        if verticalSpaceEnough then
            if rightWidth >= halfWidthInScreen and leftWidth >= halfWidthInScreen then
                screenPos.x = targetScreenRect.center.x
            else
                if leftWidth < halfWidthInScreen then
                    screenPos.x = targetScreenRect.center.x + halfWidthInScreen - leftWidth
                else
                    screenPos.x = targetScreenRect.center.x - (halfWidthInScreen - rightWidth)
                end
            end
        else
            if leftWidth >= widthInScreen then
                screenPos.x = targetScreenRect.xMin - halfWidthInScreen
            else
                screenPos.x = targetScreenRect.xMax + halfWidthInScreen
            end
        end
    elseif posType == UIConst.UI_TIPS_POS_TYPE.LeftTop then
        local downHeight = screenSize.y - targetScreenRect.yMin
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.yMin + halfHeightInScreen
        else
            screenPos.y = screenSize.y - halfHeightInScreen
        end
        local leftWidth = targetScreenRect.xMin
        if leftWidth >= widthInScreen then
            screenPos.x = targetScreenRect.xMin - halfWidthInScreen
        else
            screenPos.x = 0
        end
    elseif posType == UIConst.UI_TIPS_POS_TYPE.RightTop then
        local downHeight = screenSize.y - targetScreenRect.yMin
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.yMin + halfHeightInScreen
        else
            screenPos.y = screenSize.y - halfHeightInScreen
        end
        local rightWidth = screenSize.x - targetScreenRect.xMax
        if rightWidth >= widthInScreen then
            screenPos.x = targetScreenRect.xMax + halfWidthInScreen
        else
            screenPos.x = screenSize.x - halfWidthInScreen
        end
    elseif posType == UIConst.UI_TIPS_POS_TYPE.RightDown then
        local downHeight = screenSize.y - targetScreenRect.yMax
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.yMax + halfHeightInScreen
        else
            local upHeight = targetScreenRect.yMin
            if upHeight >= downHeight then
                screenPos.y = targetScreenRect.yMin - halfHeightInScreen
            else
                screenPos.y = screenSize.y - halfHeightInScreen
            end
        end
        local rightWidth = screenSize.x - targetScreenRect.xMax
        if rightWidth >= widthInScreen then
            screenPos.x = targetScreenRect.xMax + halfWidthInScreen
        else
            local leftWidth = targetScreenRect.xMin
            if leftWidth >= widthInScreen then
                screenPos.x = targetScreenRect.xMin - halfWidthInScreen
            else
                screenPos.x = screenSize.x - halfWidthInScreen
            end
        end
    elseif posType == UIConst.UI_TIPS_POS_TYPE.LeftDown then
        local downHeight = screenSize.y - targetScreenRect.yMax
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.yMax + halfHeightInScreen
        else
            local upHeight = targetScreenRect.yMin
            if upHeight >= downHeight then
                screenPos.y = targetScreenRect.yMin - halfHeightInScreen
            else
                screenPos.y = screenSize.y - halfHeightInScreen
            end
        end
        local leftWidth = targetScreenRect.xMin
        if leftWidth >= widthInScreen then
            screenPos.x = targetScreenRect.xMin - halfWidthInScreen
        else
            screenPos.x = 0
        end
    elseif posType == UIConst.UI_TIPS_POS_TYPE.MidTop then
        logger.error("当前tips停靠类型MidTop还未支持，请联系@wenjiahao")
    elseif posType == UIConst.UI_TIPS_POS_TYPE.LeftMid then
        local downHeight = screenSize.y - targetScreenRect.center.y
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.center.y
        else
            screenPos.y = screenSize.y - halfHeightInScreen
        end
        local leftWidth = targetScreenRect.xMin
        if leftWidth >= widthInScreen then
            screenPos.x = targetScreenRect.xMin - halfWidthInScreen
        else
            screenPos.x = 0
        end
    elseif posType == UIConst.UI_TIPS_POS_TYPE.RightMid then
        local downHeight = screenSize.y - targetScreenRect.center.y
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.center.y
        else
            screenPos.y = screenSize.y - halfHeightInScreen
        end
        local rightWidth = screenSize.x - targetScreenRect.xMax
        if rightWidth >= widthInScreen then
            screenPos.x = targetScreenRect.xMax + halfWidthInScreen
        else
            screenPos.x = screenSize.x - halfWidthInScreen
        end
    elseif posType == UIConst.UI_TIPS_POS_TYPE.GuideTips then
        local downHeight = screenSize.y - targetScreenRect.yMin
        if downHeight >= heightInScreen then
            screenPos.y = targetScreenRect.yMin + halfHeightInScreen
        else
            screenPos.y = screenSize.y - halfHeightInScreen
        end
        local leftWidth = targetScreenRect.xMin
        if leftWidth >= widthInScreen then
            screenPos.x = targetScreenRect.xMin - halfWidthInScreen - xOffset
        else
            local rightWidth = screenSize.x - targetScreenRect.xMax
            if rightWidth >= widthInScreen then
                screenPos.x = targetScreenRect.xMax + halfWidthInScreen + xOffset
            else
                screenPos.x = targetScreenRect.center.x
                if targetScreenRect.yMin >= (screenSize.y - targetScreenRect.yMax) then
                    screenPos.y = targetScreenRect.yMin - halfHeightInScreen
                else
                    screenPos.y = targetScreenRect.yMax + halfHeightInScreen
                end
            end
        end
    end
    screenPos.x = lume.clamp(screenPos.x, halfWidthInScreen, screenSize.x - halfWidthInScreen) + paddingLeft
    screenPos.y = lume.clamp(screenPos.y, halfHeightInScreen, screenSize.y - halfHeightInScreen) + paddingTop
    screenPos = screenPos - oriScreenSize / 2
    screenPos.y = -screenPos.y
    local canvasPos = Vector2(screenPos.x / xRation, screenPos.y / yRation)
    contentRectTrans.anchoredPosition = canvasPos
end
function screenPosToWorldPos(x, y, yPlane)
    local ray = CameraManager.mainCamera:ScreenPointToRay(Vector3(x, y, 0))
    local length = (yPlane - ray.origin.y) / ray.direction.y
    local worldPos = ray.origin + ray.direction * length
    return worldPos
end
function changeAlpha(target, a)
    local color = target.color
    color.a = a
    target.color = color
end
function isPosInScreen(worldPos, camera, xFrame, yFrame)
    xFrame = xFrame or 0
    yFrame = yFrame or 0
    local xMin = xFrame
    local xMax = Screen.width - xFrame
    local yMin = yFrame
    local yMax = Screen.height - yFrame
    camera = camera or CameraManager.mainCamera
    local pos = camera:WorldToScreenPoint(worldPos)
    return pos.x >= xMin and pos.y >= yMin and pos.z >= 0 and pos.x <= xMax and pos.y <= yMax, pos
end
function getRemainingText(t)
    local hour = math.floor(t / 3600)
    t = t % 3600
    local min = math.floor(t / 60)
    t = math.floor(t % 60)
    return string.format("%02d:%02d:%02d", hour, min, t)
end
function getRemainingTextToMinute(t)
    local min = math.floor(t / 60)
    t = math.floor(t % 60)
    return string.format("%02d:%02d", min, t)
end
function getItemRarity(itemId)
    local data = Tables.itemTable:GetValue(itemId)
    return data.rarity
end
function getItemUseDesc(itemId)
    return UIUtils.resolveTextStyle(CS.Beyond.Gameplay.TacticalItemUtil.GetUseItemDesc(itemId))
end
function getItemEquippedDesc(itemId)
    return UIUtils.resolveTextStyle(CS.Beyond.Gameplay.TacticalItemUtil.GetEquipItemDesc(itemId))
end
function getItemRarityColor(rarity)
    local rarityColorStr = Tables.rarityColorTable[rarity]
    return getColorByString(rarityColorStr.color)
end
function getCharRarityColor(rarity)
    return getItemRarityColor(rarity)
end
function getColorByString(strColor, a)
    local r = 0
    local g = 0
    local b = 0
    a = a or 255
    if string.len(strColor) == 6 then
        local strR = string.sub(strColor, 1, 2)
        local strG = string.sub(strColor, 3, 4)
        local strB = string.sub(strColor, 5, 6)
        r = tonumber(strR, 16)
        g = tonumber(strG, 16)
        b = tonumber(strB, 16)
    end
    if string.len(strColor) == 8 then
        local strR = string.sub(strColor, 1, 2)
        local strG = string.sub(strColor, 3, 4)
        local strB = string.sub(strColor, 5, 6)
        local strA = string.sub(strColor, 7, 8)
        r = tonumber(strR, 16)
        g = tonumber(strG, 16)
        b = tonumber(strB, 16)
        a = tonumber(strA, 16)
    end
    local color = CS.UnityEngine.Color(r / 255, g / 255, b / 255, a / 255)
    return color
end
function setSpecialFillAmount(img, percent, minMaxVector2)
    img.fillAmount = percent * (minMaxVector2.y - minMaxVector2.x) + minMaxVector2.x
end
function checkInputValid(value)
    return CS.Beyond.I18n.I18nUtils.CheckInputValid(value)
end
function getStringLength(str)
    return CS.Beyond.I18n.I18nUtils.GetStringLength(str)
end
function getNumString(num)
    local curLang = CS.Beyond.I18n.I18nUtils.curEnvLang
    local isChineseStyleLang = curLang == CS.Beyond.I18n.EnvLang.CN
    if isChineseStyleLang then
        local wan = num / 10000
        if wan < 1 then
            return string.format("%d", num)
        end
        if wan < 10000 then
            return _getNumAbbrStr(wan, Language.LUA_NUM_UNIT_WAN)
        end
        local yi = wan / 10000
        return _getNumAbbrStr(yi, Language.LUA_NUM_UNIT_YI)
    else
        local m = num / 1000 / 1000
        local k = num / 1000
        if m >= 1 then
            return _getNumAbbrStr(m, Language.LUA_NUM_UNIT_MILLION)
        elseif k >= 1 then
            return _getNumAbbrStr(k, Language.LUA_NUM_UNIT_THOUSAND)
        else
            return string.format("%d", num)
        end
    end
end
function _getNumAbbrStr(num, text)
    if num < 1000 then
        if num < 100 and math.floor(num * 100) % 10 > 0 then
            return string.format("%.2f%s", num, text)
        elseif math.floor(num * 10) % 10 > 0 then
            return string.format("%.1f%s", num, text)
        end
    end
    return string.format("%d%s", math.floor(num), text)
end
local ROMAN_VAL = { 1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1 }
local ROMAN_SYM = { "M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I" }
function intToRoman(num)
    local roman = ""
    for i = 1, #ROMAN_VAL do
        while num >= ROMAN_VAL[i] do
            num = num - ROMAN_VAL[i]
            roman = roman .. ROMAN_SYM[i]
        end
    end
    return roman
end
function setSizeDeltaX(rect, value)
    local size = rect.sizeDelta
    size.x = value
    rect.sizeDelta = size
end
function setSizeDeltaY(rect, value)
    local size = rect.sizeDelta
    size.y = value
    rect.sizeDelta = size
end
function mapScreenPosToEllipseEdge(screenPos, ellipseXRadius, ellipseYRadius)
    local x = screenPos.x
    local y = screenPos.y
    local angle = math.atan(y, x)
    local k = y / x
    local uiPos = Vector2.zero
    local a = ellipseXRadius
    local b = ellipseYRadius
    uiPos.x = a * b / math.sqrt(b * b + a * a * k * k)
    if x < 0 then
        uiPos.x = -uiPos.x
    end
    uiPos.y = uiPos.x * k
    if uiPos.magnitude < screenPos.magnitude then
        return uiPos, math.deg(angle), true
    end
    return screenPos, math.deg(angle), false
end
function resolveTextPlayerName(text)
    local playerName = Utils.getPlayerName()
    local targetText = string.gsub(text, UIConst.PLAYER_NAME_FORMATTER, playerName)
    return targetText
end
function resolveTextGender(text)
    return CS.Beyond.Gameplay.GameplayUIUtils.ResolveTextGender(text)
end
function resolveTextCinematic(text)
    local cfg = { richText = true, playerName = true, gender = true, }
    return resolveText(text, cfg)
end
function resolveText(text, cfg)
    local resolvedText = text
    if cfg then
        if cfg.richText then
            resolvedText = resolveTextStyle(resolvedText)
        end
        if cfg.playerName then
            resolvedText = resolveTextPlayerName(resolvedText)
        end
        if cfg.gender then
            resolvedText = resolveTextGender(resolvedText)
        end
    end
    return resolvedText
end
function resolveTextStyle(text)
    return string.gsub(text, "<@(.-)>(.-)</>", function(tag, body)
        local textStyleTable = Tables.richTextStyleTable
        local _, data = textStyleTable:TryGetValue(tag)
        if not data then
            logger.error("No tag", tag, body)
            return body
        end
        return data.preDef .. body .. data.postDef
    end)
end
function genDynamicBlackScreenMaskData(systemName, fadeInTime, fadeOutTime, fadeInCallback)
    local maskData = CS.Beyond.Gameplay.UICommonMaskData()
    maskData.fadeInTime = fadeInTime
    maskData.fadeBeforeTime = 0
    maskData.fadeOutTime = fadeOutTime
    if fadeInCallback ~= nil then
        maskData.fadeInCallback = function()
            fadeInCallback()
        end
    end
    if BEYOND_DEBUG or BEYOND_DEBUG_COMMAND then
        maskData.extraData = CS.Beyond.Gameplay.CommonMaskExtraData()
        maskData.extraData.desc = systemName
    end
    return maskData
end
local rewardItemRarityEffectNames = { [1] = "normaGlow", [2] = "greenGlow", [3] = "blueGlow", [4] = "purpleGlow", [5] = "goldGlow", [6] = "goldGlow", }
function setRewardItemRarityGlow(cell, rarity)
    for k = 6, 1, -1 do
        local name = rewardItemRarityEffectNames[k]
        cell.view[name].gameObject:SetActiveIfNecessary(k == rarity)
    end
end
function getItemTypeName(itemId)
    local itemCfg = Tables.itemTable:GetValue(itemId)
    local itemTypeCfg = Tables.itemTypeTable:GetValue(itemCfg.type:GetHashCode())
    local defaultTypeName = itemTypeCfg.name
    if itemCfg.type == GEnums.ItemType.Weapon then
        local weaponCfg = Tables.weaponBasicTable:GetValue(itemId)
        if not weaponCfg then
            return defaultTypeName
        end
        local weaponTypeInt = weaponCfg.weaponType:ToInt()
        local weaponTypeName = Language[string.format("LUA_WEAPON_TYPE_%d", weaponTypeInt)]
        return weaponTypeName
    end
    if itemCfg.type == GEnums.ItemType.Equip then
        local _, equipBasicCfg = Tables.equipTable:TryGetValue(itemId)
        if not equipBasicCfg then
            return defaultTypeName
        end
        local equipTemplateId = itemId
        local _, equipTemplate = Tables.equipTable:TryGetValue(equipTemplateId)
        if not equipTemplate then
            return defaultTypeName
        end
        local equipType = equipTemplate.partType
        local equipTypeName = Language[UIConst.CHAR_INFO_EQUIP_TYPE_TILE_PREFIX .. LuaIndex(equipType:ToInt())]
        return equipTypeName
    end
    return defaultTypeName
end
function displayItemBasicInfos(view, loader, itemId, instId)
    local data = Tables.itemTable:GetValue(itemId)
    local itemType = data.type
    if view.itemNameTxt then
        view.itemNameTxt.text = getItemName(itemId, instId)
    end
    if view.itemIcon then
        view.itemIcon:InitItemIcon(itemId, true, instId)
    end
    if view.itemTypeTxt then
        local itemTypeName = getItemTypeName(itemId)
        view.itemTypeTxt.text = itemTypeName
    end
    if view.rarityLine then
        setItemRarityImage(view.rarityLine, data.rarity)
    end
end
function getItemName(itemId, instId)
    local data = Tables.itemTable:GetValue(itemId)
    if not instId then
        return data.name
    end
    if data.type == GEnums.ItemType.WeaponGem then
        local leadTermId = CharInfoUtils.getGemLeadSkillTermId(instId)
        if not leadTermId then
            return data.name
        end
        local leadTermCfg = Tables.gemTable:GetValue(leadTermId)
        return string.format(Language.LUA_ITEM_COMPOSITE_NAME, data.name, leadTermCfg.tagName)
    end
    return data.name
end
function checkIfReachAdventureLv(needLv)
    local adventureLevelData = GameInstance.player.adventure.adventureLevelData
    return adventureLevelData.lv >= needLv
end
function displayWeaponInfo(view, loader, itemId, instId)
    local itemData = Tables.itemTable[itemId]
    local weaponInstData = instId and CharInfoUtils.getWeaponByInstId(instId)
    view.starGroup:InitStarGroup(itemData.rarity)
    view.potentialStar:InitWeaponPotentialStar(weaponInstData and weaponInstData.refineLv or 0)
    view.weaponGemSlimNode:InitWeaponGemSlimNode(weaponInstData and weaponInstData.attachedGemInstId or 0)
    if weaponInstData then
        view.tipWeaponLevelNode:InitTipWeaponLevelNode(itemId, instId)
        view.weaponAttributeNode:InitWeaponAttributeNode(instId, weaponInstData.attachedGemInstId)
        view.weaponSkillNode:InitWeaponSkillNode(instId)
    else
        local hasValue
        local weaponBasicData
        local weaponBreakThroughDetailList
        local initMaxLevel, breakThroughCount, maxBreakthroughLevel = 0, 0, 0
        hasValue, weaponBasicData = Tables.weaponBasicTable:TryGetValue(itemId)
        if hasValue then
            hasValue, weaponBreakThroughDetailList = Tables.weaponBreakThroughTemplateTable:TryGetValue(weaponBasicData.breakthroughTemplateId)
            if hasValue then
                breakThroughCount = #weaponBreakThroughDetailList.list
                if breakThroughCount > 1 then
                    initMaxLevel = weaponBreakThroughDetailList.list[1].breakthroughLv
                    maxBreakthroughLevel = breakThroughCount - 1
                end
            end
        end
        view.tipWeaponLevelNode:InitTipWeaponLevelNodeNoInst(1, initMaxLevel, 0, maxBreakthroughLevel)
        view.weaponAttributeNode:InitWeaponAttributeNodeByTemplateId(itemId)
        view.weaponSkillNode:InitWeaponSkillNodeByTemplateId(itemId, 0, 0, false)
    end
    if view.equippedNode then
        if instId and instId > 0 then
            view.equippedNode:InitEquipNodeByWeaponInstId(instId)
        else
            view.equippedNode.gameObject:SetActive(false)
        end
    end
end
function displayEquipInfo(view, loader, itemId, instId)
    local equipCfg = Tables.equipTable[itemId]
    view.equipLvTxt.text = equipCfg.minWearLv
    view.equipSuitNode:InitEquipSuitNode(itemId)
    local hasInst = CharInfoUtils.getEquipByInstId(instId) ~= nil
    if hasInst then
        view.weaponAttributeNode:InitEquipAttributeNode(instId)
    else
        view.weaponAttributeNode:InitEquipAttributeNodeByTemplateId(itemId)
    end
    if view.equippedNode then
        if hasInst then
            view.equippedNode:InitEquippedNodeByEquipInstId(instId)
        else
            view.equippedNode.gameObject:SetActive(false)
        end
    end
end
function displayWeaponGemInfo(view, loader, itemId, instId)
    view.gemSkillNode:InitGemSkillNode(instId)
    if view.equippedNode then
        if instId and instId > 0 then
            view.equippedNode:InitEquippedNodeByGemInstId(instId)
        else
            view.equippedNode.gameObject:SetActive(false)
        end
    end
end
function checkText(text, errHint)
    if string.isEmpty(text) then
        return errHint
    end
    return text
end
function getLeftTime(leftSec)
    if leftSec <= Const.SEC_PER_MIN then
        if leftSec > 0 then
            return string.format(Language.LUA_TIME_FORMAT_MIN, 1)
        else
            return string.format(Language.LUA_TIME_FORMAT_MIN, 0)
        end
    elseif leftSec <= Const.SEC_PER_HOUR then
        return string.format(Language.LUA_TIME_FORMAT_MIN, math.floor(leftSec / Const.SEC_PER_MIN))
    elseif leftSec <= Const.SEC_PER_DAY then
        local hourTime = math.floor(leftSec / Const.SEC_PER_HOUR)
        local minTime = math.floor((leftSec % Const.SEC_PER_HOUR) / Const.SEC_PER_MIN)
        return string.format(Language.LUA_TIME_FORMAT_HOUR, hourTime, minTime)
    else
        local dayTime = math.floor(leftSec / Const.SEC_PER_DAY)
        local hourTime = math.floor((leftSec % Const.SEC_PER_DAY) / Const.SEC_PER_HOUR)
        return string.format(Language.LUA_TIME_FORMAT_DAY, dayTime, hourTime)
    end
end
function getLeftTimeToSecond(leftSec, useColonFormat)
    leftSec = lume.round(leftSec)
    if leftSec <= Const.SEC_PER_MIN then
        return string.format(Language.LUA_TIME_FORMAT_SEC, leftSec)
    elseif leftSec <= Const.SEC_PER_HOUR then
        local format = useColonFormat and Language.LUA_TIME_FORMAT_ONE_COLON or Language.LUA_TIME_FORMAT_MIN_SEC
        return string.format(format, math.floor(leftSec / Const.SEC_PER_MIN), math.fmod(leftSec, Const.SEC_PER_MIN))
    elseif leftSec <= Const.SEC_PER_DAY then
        local hourTime = math.floor(leftSec / Const.SEC_PER_HOUR)
        local minTime = math.floor((leftSec % Const.SEC_PER_HOUR) / Const.SEC_PER_MIN)
        local secTime = math.fmod((leftSec % Const.SEC_PER_HOUR), Const.SEC_PER_MIN)
        local format = useColonFormat and Language.LUA_TIME_FORMAT_TWO_COLON or Language.LUA_TIME_FORMAT_HMS
        return string.format(format, hourTime, minTime, secTime)
    else
        local tempTime = leftSec
        local dayTime = math.floor(leftSec / Const.SEC_PER_DAY)
        tempTime = tempTime - dayTime * Const.SEC_PER_DAY
        local hourTime = math.floor(tempTime / Const.SEC_PER_HOUR)
        tempTime = tempTime - hourTime * Const.SEC_PER_HOUR
        local minTime = math.floor(tempTime / Const.SEC_PER_MIN)
        local secTime = tempTime - minTime * Const.SEC_PER_MIN
        local format = useColonFormat and Language.LUA_TIME_FORMAT_THREE_COLON or Language.LUA_TIME_FORMAT_DAY
        return string.format(format, dayTime, hourTime, minTime, secTime)
    end
end
function getLeftTimeToSecondFull(leftSec)
    leftSec = lume.round(leftSec)
    local hour = math.floor(leftSec / Const.SEC_PER_HOUR)
    local min = math.floor((leftSec % Const.SEC_PER_HOUR) / Const.SEC_PER_MIN)
    local sec = math.fmod((leftSec % Const.SEC_PER_HOUR), Const.SEC_PER_MIN)
    return string.format(Language.LUA_TIME_FORMAT_TWO_COLON_FULL, hour, min, sec)
end
function getLeftTimeToSecondMS(sec)
    sec = lume.round(sec)
    local minutes = math.floor(sec / 60)
    local remainingSeconds = sec % 60
    return string.format("%02d:%02d", minutes, remainingSeconds)
end
function setItemSprite(img, id, self, isBig)
    local data = Tables.itemTable:GetValue(id)
    local sprite
    if isBig then
        sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, data.iconId)
    end
    if not sprite then
        sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, data.iconId)
    end
    img.sprite = sprite
end
function tryGetTagList(itemId, itemType)
    if not itemType then
        local itemData = Tables.itemTable[itemId]
        itemType = itemData.type
    end
    if itemType == GEnums.ItemType.NormalBuilding then
        local machineId = FactoryUtils.getItemBuildingId(itemId)
        local succ, machineId2TagIdData = Tables.factoryMachineId2tagIdsTable:TryGetValue(machineId)
        if not succ then
            return false
        end
        return true, machineId2TagIdData.tagIds
    end
    local succ, ingredientId2TagIdData = Tables.factoryResourceItemId2TagIdTable:TryGetValue(itemId)
    if not succ then
        return false
    end
    local tagIds = {}
    local count = 0
    local facCore = GameInstance.player.remoteFactory.core
    for craftId, tagId in pairs(ingredientId2TagIdData.craftId2TagId) do
        if facCore:IsFormulaVisible(craftId) then
            if not lume.find(tagIds, tagId) then
                tagIds[count] = tagId
                count = count + 1
            end
        end
    end
    if count == 0 then
        return false
    end
    tagIds.Count = count
    return true, tagIds
end
function getMinHpDamagedCharIndex()
    local curIndex = 1
    local minHp = 10000000
    local minCharRatio = 1.0
    for index, slot in pairs(GameInstance.player.squadManager.curSquad.slots) do
        local character = slot.character:Lock()
        if character and character.abilityCom.alive then
            local curMember = character.abilityCom
            local hp = curMember.hp
            local maxHp = curMember.maxHp
            if hp < maxHp and hp < minHp then
                minHp = hp
                minCharRatio = hp / maxHp
                curIndex = LuaIndex(index)
            end
        end
    end
    return curIndex, minCharRatio
end
function getFirstAliveCharIndex()
    for index, slot in pairs(GameInstance.player.squadManager.curSquad.slots) do
        local character = slot.character:Lock()
        if character and character.abilityCom.alive then
            return LuaIndex(index)
        end
    end
    return 0
end
function getFirstNonAliveCharIndex()
    for index, slot in pairs(GameInstance.player.squadManager.curSquad.slots) do
        local character = slot.character:Lock()
        if not (character and character.abilityCom.alive) then
            return LuaIndex(index)
        end
    end
    return 0
end
function getTrackerColorByMissionType(t)
    return DataManager.worldSetting.missionIconColor[t]
end
function getNumTextByLanguage(num)
    return Language[string.format("LUA_NUM_%d", num)]
end
function setFacBuffColorText(uiText, text, isBuff)
    local colorStr = UIConst.FAC_BUILDING_DEBUFF_COLOR_STR
    if isBuff then
        colorStr = UIConst.FAC_BUILDING_BUFF_COLOR_STR
    end
    uiText.text = string.format(UIConst.COLOR_STRING_FORMAT, colorStr, text)
end
function childrenArrayActive(root, activeCount)
    local childrenCount = root.transform.childCount
    for i = 0, childrenCount - 1 do
        local child = root.transform:GetChild(i)
        child.gameObject:SetActive(i < activeCount)
    end
end
function parseAllGemIdsFromWeaponId(weaponId)
    local result, weaponBasicData = Tables.weaponBasicTable:TryGetValue(weaponId)
    if result and weaponBasicData.weaponSkillId and string.isEmpty(weaponBasicData.weaponSkillId) then
        return parseAllGemIdsFromSkillId(weaponBasicData.weaponSkillId)
    end
end
function parseAllGemIdsFromSkillId(skillId)
    local modifierIds = {}
    for k, v in pairs(Tables.gemSkillModifierTable) do
        local found = false
        for i = 0, v.list.Count - 1 do
            local t = v.list[i]
            if t.oldSkillId == skillId then
                modifierIds[k] = true
                found = true
                break
            end
            if found then
                break
            end
        end
    end
    local effectIds = {}
    local termIds = {}
    local weaponGemTermIds = {}
    for k, v in pairs(Tables.gemTable) do
        if termIds[v.termEffect] then
            weaponGemTermIds[k] = true
        end
    end
    local dropIds = {}
    local itemIds = {}
    return itemIds
end
function useItemOnTip(itemId)
    if GameInstance.playerController.mainCharacter == nil or GameInstance.playerController.mainCharacter:HasTag(CS.Beyond.Gameplay.PredefinedTag.ForbiddenUsingItem) then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAR_TAG_FORBIDDEN)
        return false
    end
    if GameInstance.mode:IsItemForbidden(itemId) then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAR_TOAST_GAME_MODE_FORBID)
        return false
    end
    local useItemData = Tables.useItemTable:GetValue(itemId)
    if useItemData.uiType == GEnums.ItemUseUiType.SingleHeal then
        UIManager:Open(PanelId.TacticalItem, { itemId = itemId })
        return true
    elseif useItemData.uiType == GEnums.ItemUseUiType.AllHeal then
        UIManager:Open(PanelId.TacticalItem, { itemId = itemId })
        return true
    elseif useItemData.uiType == GEnums.ItemUseUiType.Revive then
        UIManager:Open(PanelId.TacticalItem, { itemId = itemId })
        return true
    elseif useItemData.uiType == GEnums.ItemUseUiType.Alive then
        UIManager:Open(PanelId.TacticalItem, { itemId = itemId })
        return true
    elseif useItemData.uiType == GEnums.ItemUseUiType.Throw then
        if GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId) then
            return true
        end
    end
    return false
end
function beginLog(title)
    local s = ' ---------- ' .. title .. ' ---------\n'
    return {
        log = function(line)
            if type(line) == "table" then
                local strTable = {}
                for i, v in ipairs(line) do
                    strTable[i] = tostring(v)
                end
                line = table.concat(strTable, ", ")
            end
            s = s .. string.format("%s\n", tostring(line))
        end,
        str = function()
            return s
        end
    }
end
function endLog(log)
    logger.error(log.str())
end
function parseAllRecipedAsInput(itemId)
end
function getCellNums(width, space, cellWidthList)
    local nums = {}
    local count = #cellWidthList
    local curWidth = 0
    local curCellNum = 0
    for i = 1, count do
        local cellWidth = cellWidthList[i]
        if curWidth == 0 then
            curWidth = cellWidth
        else
            curWidth = curWidth + cellWidth + space
        end
        if curWidth > width then
            local num = i - curCellNum - 1
            table.insert(nums, num)
            curCellNum = i - 1
            curWidth = cellWidth
        end
    end
    if count > curCellNum then
        table.insert(nums, count - curCellNum)
    end
    return nums
end
function setItemStorageCountText(storageCountNode, itemId, needCount, ignoreInSafeZone)
    local inventory = GameInstance.player.inventory
    local itemData = Tables.itemTable[itemId]
    local isMoneyType = inventory:IsMoneyType(itemData.type)
    local valuableDepotType = itemData.valuableTabType
    local isValuableItem = valuableDepotType ~= GEnums.ItemValuableDepotType.Factory
    local count, bagCount, _ = Utils.getItemCount(itemId, ignoreInSafeZone, true)
    if ignoreInSafeZone or Utils.isInSafeZone() or isMoneyType or isValuableItem then
        storageCountNode:InitStorageNode(count, needCount, true)
    else
        storageCountNode:InitStorageNode(bagCount, needCount, false)
    end
end
function setNoEnoughCountColor(countStr)
    setCountColor(countStr, true)
end
function setCountColor(countStr, isLack)
    if isLack then
        return string.format(UIConst.COLOR_STRING_FORMAT, UIConst.COUNT_NOT_ENOUGH_COLOR_STR, countStr)
    else
        return countStr
    end
end
function PlayAnimationAndToggleActive(animationWrapper, isOn, callback)
    if animationWrapper.gameObject.activeSelf == isOn then
        if callback then
            callback()
        end
        return
    end
    if isOn then
        animationWrapper.gameObject:SetActive(true)
        animationWrapper:PlayInAnimation(callback)
    else
        animationWrapper:PlayOutAnimation(function()
            if animationWrapper and animationWrapper.gameObject then
                animationWrapper.gameObject:SetActiveIfNecessary(false)
            end
            if callback then
                callback()
            end
        end)
    end
end
function inTimeline()
    local inTimeline = GameInstance.world.cutsceneManager.isMainTimelinePlaying
    return inTimeline
end
function inCG()
    local inCG = VideoManager.isPlayingFMV
    return inCG
end
function inDialog()
    local inDialog = GameInstance.world.dialogManager.isPlaying
    return inDialog
end
function inCinematic()
    return inCG() or inTimeline() or inDialog()
end
function inDungeon()
    return GameInstance.dungeonManager.inDungeon
end
function IsPhaseLevelOnTop()
    return PhaseManager:GetTopPhaseId() == PhaseId.PhaseLevel
end
function usingBlockTransition()
    local BlockGlitchTransition = require_ex("UI/Panels/BlockGlitchTransition/BlockGlitchTransitionCtrl")
    return BlockGlitchTransition.BlockGlitchTransitionCtrl.s_renderTexture ~= nil
end
function getTextShowDuration(text, tSpeed)
    local speed = tSpeed or 1
    local duration = I18nUtils.GetTextShowDuration(text)
    return duration / speed
end
function removePattern(str, pattern)
    local result = ""
    for match in string.gmatch(str, pattern) do
        local cleaned = string.gsub(match, "{.*}", "")
        result = result .. cleaned
    end
    if string.isEmpty(result) then
        result = str
    end
    return result
end
function loadSprite(loader, path, name)
    if path == UIConst.UI_SPRITE_ITEM or path == UIConst.UI_SPRITE_ITEM_BIG then
        local resPath = string.format("Assets/Beyond/DynamicAssets/Gameplay/UI/Sprites/%s/%s.png", path, name)
        if not ResourceManager.CheckExists(resPath) then
            logger.warn("没有道具 Icon，使用临时图标", path, name)
            name = UIConst.UI_SPRITE_ITEM_DEFAULT_ICON
        end
    end
    local sprite = loader:LoadSprite(getSpritePath(path, name))
    return sprite
end
function getPuzzleColorByColorType(colorType)
    local colorStr = UIConst.MINI_PUZZLE_GAME_ECOLOR_STR[colorType]
    local colorStr = string.isEmpty(colorStr) and "FF00FF" or colorStr
    return getColorByString(colorStr)
end
function calcPivotVecByData(data, puzzleCellSize, puzzleCellPadding)
    local centerCell = data.originBlocks[0]
    local xMax = centerCell.x
    local xMin = centerCell.x
    local yMax = centerCell.y
    local yMin = centerCell.y
    for _, originBlock in pairs(data.originBlocks) do
        xMax = math.max(xMax, originBlock.x)
        xMin = math.min(xMin, originBlock.x)
        yMax = math.max(yMax, originBlock.y)
        yMin = math.min(yMin, originBlock.y)
    end
    local width = (xMax - xMin + 1) * (puzzleCellSize + 2 * puzzleCellPadding)
    local height = (yMax - yMin + 1) * (puzzleCellSize + 2 * puzzleCellPadding)
    local centerX = ((centerCell.x - xMin) * 2 + 1) * (puzzleCellSize / 2 + puzzleCellPadding)
    local centerY = ((centerCell.y - yMin) * 2 + 1) * (puzzleCellSize / 2 + puzzleCellPadding)
    return Vector2(centerX / width, centerY / height)
end
function splitItem(slotIndex)
    local toSlot = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()):GetFirstEmptySlotIndex()
    if toSlot < 0 then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_TIPS_TOAST_1)
        return
    end
    UIManager:Open(PanelId.ItemSplit, { slotIndex = slotIndex, })
end
function getRewardFirstItem(rewardId)
    local rewardTableData = Tables.rewardTable[rewardId]
    return rewardTableData.itemBundles[0]
end
function getSoilRewardFirstItem(rewardId)
    local rewardTableData = Tables.rewardSoilTable[rewardId]
    return rewardTableData.itemBundles[0]
end
function getRewardItems(rewardId, items)
    local rewardTableData = Tables.rewardTable[rewardId]
    items = items or {}
    for _, v in pairs(rewardTableData.itemBundles) do
        table.insert(items, v)
    end
    return items
end
function getMonsterIconByMonsterId(monsterId)
    return string.format("Assets/Beyond/DynamicAssets/Gameplay/UI/Sprites/Wiki/MonsterImage/%s.png", monsterId)
end
function getParentCenterAnchoredPosition(rectTransform)
    local position = Vector2.zero
    if rectTransform == nil then
        return position
    end
    if rectTransform.parent == nil then
        return position
    end
    local parentRectTransform = rectTransform.parent:GetComponent("RectTransform")
    if parentRectTransform == nil then
        return position
    end
    local anChorOffset = Vector2(parentRectTransform.rect.width * (0.5 - rectTransform.anchorMin.x), parentRectTransform.rect.height * (0.5 - rectTransform.anchorMin.y))
    local pivotOffset = Vector2(rectTransform.rect.width * (rectTransform.pivot.x - 0.5), rectTransform.rect.height * (rectTransform.pivot.y - 0.5));
    return anChorOffset + pivotOffset;
end
function getRomanNumberText(number)
    if number < 1 or number > 10 then
        return ""
    end
    return Language[string.format("ui_common_roman_num_%d", number)]
end
function setItemRarityImage(img, rarity)
    local rarityColor = getItemRarityColor(rarity)
    img.color = rarityColor
end
function getEnemyInfoByIdAndLevel(enemyId, enemyLevel)
    local enemyInfo = {}
    local enemyCfg = Tables.enemyDisplayInfoTable[enemyId]
    local templateId = enemyCfg.templateId
    local enemyTemplateCfg = Tables.enemyTemplateDisplayInfoTable[templateId]
    enemyInfo.name = string.isEmpty(enemyCfg.name) and enemyTemplateCfg.name or enemyCfg.name
    enemyInfo.level = enemyLevel
    enemyInfo.desc = enemyTemplateCfg.description
    enemyInfo.templateId = enemyTemplateCfg.templateId
    enemyInfo.ability = {}
    local abilityIds = string.isEmpty(enemyCfg.abilityDescIds) and enemyTemplateCfg.abilityDescIds or enemyCfg.abilityDescIds
    for _, abilityId in pairs(abilityIds) do
        local abilityDescCfg = Tables.enemyAbilityDescTable[abilityId]
        table.insert(enemyInfo.ability, { abilityId = abilityDescCfg.abilityId, name = abilityDescCfg.name, description = abilityDescCfg.description, })
    end
    return enemyInfo
end
function isItemTypeForbidden(dungeonId, itemType)
    local _, subGameInstData = DataManager.subGameInstDataTable:TryGetValue(dungeonId)
    if not subGameInstData then
        return false
    end
    local _, gameModeData = DataManager.gameModeTable:TryGetData(subGameInstData.modeId)
    if not gameModeData then
        return false
    end
    if not gameModeData.functionSettings then
        return false
    end
    for functionSetting in cs_pairs(gameModeData.functionSettings) do
        if functionSetting.modeFuncType == GEnums.GameModeFuncType.ForbidUseItemType then
            local funcParams = functionSetting.funcParams
            if funcParams and funcParams.itemTypes and funcParams.itemTypes:Contains(itemType) then
                return true
            end
        end
    end
    return false
end
function convertRewardItemBundlesToDataList(itemBundles, isIncremental)
    local rewardItemDataList = {}
    if itemBundles == nil or itemBundles.Count == 0 then
        return rewardItemDataList
    end
    for index = 0, itemBundles.Count - 1 do
        local rewardItem = itemBundles[index]
        local itemId = rewardItem.id
        local success, itemData = Tables.itemTable:TryGetValue(itemId)
        if success then
            table.insert(rewardItemDataList, { id = itemId, count = rewardItem.count, rarity = itemData.rarity, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, })
        end
    end
    table.sort(rewardItemDataList, Utils.genSortFunction({ "rarity", "sortId1", "sortId2", "id" }, isIncremental))
    return rewardItemDataList
end