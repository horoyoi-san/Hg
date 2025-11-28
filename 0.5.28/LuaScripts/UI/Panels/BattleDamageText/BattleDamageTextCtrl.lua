local queueClass = require_ex("Common/Utils/DataStructure/Queue")
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.BattleDamageText
BattleDamageTextCtrl = HL.Class('BattleDamageTextCtrl', uiCtrl.UICtrl)
BattleDamageTextCtrl.s_messages = HL.StaticField(HL.Table) << {}
local DamageTextType = { Level0Normal = 1, Level0Critical = 2, Level1Normal = 4, Level1Critical = 5, EnemyDamage = 6, Heal = 7, IgniteBuff = 8, Airborne = 9, Crush = 10, KnockDown = 11, ImmuneStunned = 14, ImmuneFrozen = 15, ImmuneAirborne = 16, ImmuneKnockDown = 17, ImmuneDamage = 18, ImmuneArmor = 19, Usp = 20, CommonFlowText = 21, LevelUpText = 22, }
BattleDamageTextCtrl.m_textCache = HL.Field(HL.Table)
BattleDamageTextCtrl.m_textPrefabMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_physicalInflictionTypeToDamageTypeMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_immuneTagToDamageTypeMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_damageTypeColorMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_igniteBuffTypeColorMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_showingTextPos = HL.Field(HL.Table)
BattleDamageTextCtrl.m_showingTextTimer = HL.Field(HL.Table)
BattleDamageTextCtrl.m_entityTextTimeMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_entityCoalitionGroupMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_charLevelUpTextMap = HL.Field(HL.Table)
BattleDamageTextCtrl.m_charLevelUpTextToShow = HL.Field(HL.Table)
BattleDamageTextCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.damageTextCtrl:OnCreate()
end
BattleDamageTextCtrl.OnShow = HL.Override() << function(self)
    self.view.damageTextCtrl:OnShow()
end
BattleDamageTextCtrl.OnHide = HL.Override() << function(self)
    self.view.damageTextCtrl:OnHide()
end
BattleDamageTextCtrl.OnClose = HL.Override() << function(self)
    self.view.damageTextCtrl:OnClose()
end
BattleDamageTextCtrl._OnHpChanged = HL.Method(HL.Any) << function(self, args)
    local modifier = unpack(args)
    if not modifier.showText then
        return
    end
    local textType
    if modifier.isDamage then
        local antiFaction = CS.Beyond.Gameplay.Core.FactionCategories.GetAntiFaction(CS.Beyond.Gameplay.Core.FactionIndex.Good)
        local isEnemy = modifier.source and CS.Beyond.Misc.IndexBelongToBinaryMask(modifier.source.factionIndex:GetHashCode(), antiFaction:GetHashCode())
        if isEnemy then
            textType = DamageTextType.EnemyDamage
        elseif modifier:CheckSharedFlag(CS.Beyond.Gameplay.Core.AbilitySystem.Modifier.SharedFlagIndex.IsCritical) then
            if modifier.damageVisualImportance == CS.Beyond.Gameplay.Core.AbilitySystem.Modifier.DamageVisualImportance.Level1 then
                textType = DamageTextType.Level1Critical
            else
                textType = DamageTextType.Level0Critical
            end
        else
            if modifier.damageVisualImportance == CS.Beyond.Gameplay.Core.AbilitySystem.Modifier.DamageVisualImportance.Level1 then
                textType = DamageTextType.Level1Normal
            else
                textType = DamageTextType.Level0Normal
            end
        end
    elseif modifier.isHeal then
        textType = DamageTextType.Heal
    end
    local item = self:_GetTextItem(textType)
    local isCoalesce = false
    local currentTime = CS.Beyond.TimeManager.time
    local previousItem, previousTime, previousValue, previousType
    if modifier.damageVisualCoalition.enableCoalition then
        local coalitionGroupKey = modifier.damageVisualCoalition.coalitionGroupKey
        local enemyCoalitionGroups = self.m_entityCoalitionGroupMap[modifier.target] or {}
        local coalitionGroups = enemyCoalitionGroups[modifier.source] or {}
        local coalitionValue = 0
        if not modifier.damageVisualCoalition.alwaysStartNewCoalition and coalitionGroups[coalitionGroupKey] ~= nil then
            previousItem, previousTime, previousValue, previousType = unpack(coalitionGroups[coalitionGroupKey])
            if (textType == DamageTextType.Level1Normal or textType == DamageTextType.Level1Critical) and currentTime - previousTime <= self.view.config.MAIN_CHR_DMG_TXT_COALITION_MAX_TIME then
                coalitionValue = previousValue
                isCoalesce = true
            end
            if (textType == DamageTextType.Level0Normal or textType == DamageTextType.Level0Critical) and currentTime - previousTime <= self.view.config.GUARD_DMG_TXT_COALITION_MAX_TIME then
                coalitionValue = previousValue
                isCoalesce = true
            end
        end
        if modifier.damageVisualCoalition.alwaysEndCoalition then
            coalitionGroups[coalitionGroupKey] = nil
        else
            coalitionGroups[coalitionGroupKey] = { item, currentTime, coalitionValue + modifier.value, textType }
        end
        enemyCoalitionGroups[modifier.source] = coalitionGroups
        self.m_entityCoalitionGroupMap[modifier.target] = enemyCoalitionGroups
    end
    local value = isCoalesce and previousValue + modifier.value or modifier.value
    local showNumber = lume.round(math.abs(value))
    if textType == DamageTextType.Heal then
        item.text.text = string.format("+%d", showNumber)
    elseif textType == DamageTextType.Level1Critical then
        item.text.text = string.format("%d", showNumber)
    else
        item.text.text = string.format("%d", showNumber)
    end
    if textType ~= DamageTextType.Heal then
        local textColor = self.m_damageTypeColorMap[modifier.damageType] or Color(1, 1, 1, 1)
        textColor = Color(textColor.r, textColor.g, textColor.b, item.text.color.a)
        item.text.color = textColor
        if textType == DamageTextType.Level1Critical then
            item.criticalIcon.color = textColor
            item.criticalIconShadow.color = textColor
            item.bg01.color = textColor
            item.bg02.color = textColor
        elseif textType == DamageTextType.Level0Critical then
            item.criticalIcon.color = textColor
        end
    end
    local targetTrans
    local targetPos
    if item.dmgTxtMountPointGetter ~= nil then
        targetTrans = item.dmgTxtMountPointGetter:GetSpawnTransform(modifier)
        targetPos = item.dmgTxtMountPointGetter:GetSpawnPosition(modifier)
    else
        targetTrans = modifier.target.entity.rootCom:GetNodeTransform(CS.Beyond.Gameplay.MountPoint.DmgTxtSpawnPoint)
        targetPos = targetTrans.position
    end
    if isCoalesce then
        if Vector3.Dot(modifier.target.entity.rootCom.transform.position - modifier.source.entity.rootCom.transform.position, CameraManager.mainCamera.transform.right) < 0 then
            if textType == DamageTextType.Level1Normal then
                item.anim:PlayWithTween("battletext_normal_left")
            elseif textType == DamageTextType.Level1Critical then
                item.anim:PlayWithTween("battletext_critical_left")
            end
        else
            if textType == DamageTextType.Level1Normal then
                item.anim:PlayWithTween("battletext_normal_right")
            elseif textType == DamageTextType.Level1Critical then
                item.anim:PlayWithTween("battletext_critical_right")
            end
        end
        item.elementFollower.targetTransform = targetTrans
        item.elementFollower.followPosition = targetPos
        item.elementFollower.displayUIOffset = previousItem.elementFollower.displayUIOffset
        if self.m_showingTextTimer[previousItem] then
            self:_ClearTimer(self.m_showingTextTimer[previousItem])
        end
        self:_CacheTextItem(previousItem, previousType)
        if (self.m_entityTextTimeMap[modifier.target] ~= nil) then
            for move, time in pairs(self.m_entityTextTimeMap[modifier.target]) do
                if time == previousTime then
                    self.m_entityTextTimeMap[modifier.target][move] = currentTime
                    break
                end
            end
        end
    else
        local targetScreenPos = CameraManager.mainCamera:WorldToScreenPoint(targetPos)
        local offset
        if textType == DamageTextType.Level1Normal or textType == DamageTextType.Level1Critical then
            local cameraTransform = CameraManager.mainCamera.transform
            if targetTrans == nil then
                for _ = 1, self.view.config.TEXT_POS_MAX_RANDOM_TIMES do
                    offset = self:_GetRandomTextOffset(self.view.config.TEXT_RANDOM_AREA_SIZE.x, self.view.config.TEXT_RANDOM_AREA_SIZE.y)
                    if self:_IsTextPosValid(targetScreenPos + offset) then
                        self.m_showingTextPos[item] = targetScreenPos + offset
                        break
                    end
                end
                if Vector3.Dot(modifier.target.entity.rootCom.transform.position - modifier.source.entity.rootCom.transform.position, cameraTransform.right) < 0 then
                    if textType == DamageTextType.Level1Normal then
                        item.anim:PlayWithTween("battletext_normal_left")
                    elseif textType == DamageTextType.Level1Critical then
                        item.anim:PlayWithTween("battletext_critical_left")
                    end
                else
                    if textType == DamageTextType.Level1Normal then
                        item.anim:PlayWithTween("battletext_normal_right")
                    elseif textType == DamageTextType.Level1Critical then
                        item.anim:PlayWithTween("battletext_critical_right")
                    end
                end
            else
                local mainChrDmgTxtSpawnOffset = self.view.config.MAIN_CHR_DMG_TXT_SPAWN_OFFSET
                local mainChrDmgTxtMoveSpawnOffset = self.view.config.MAIN_CHR_DMG_TXT_MOVE_SPAWN_OFFSET
                local mainChrDmgTxtMaxMoveNum = self.view.config.MAIN_CHR_DMG_TXT_MOVE_NUM
                local mainChrDmgTxtMoveSpawnWaitTime = self.view.config.MAIN_CHR_DMG_TXT_MOVE_SPAWN_WAIT_TIME
                if modifier.target.data.uiData.useSpecificDamageTextParam then
                    mainChrDmgTxtSpawnOffset = modifier.target.data.uiData.damageTextRelated.mainChrDmgTxtSpawnOffset
                    mainChrDmgTxtMoveSpawnOffset = modifier.target.data.uiData.damageTextRelated.mainChrDmgTxtMoveSpawnOffset
                    mainChrDmgTxtMaxMoveNum = modifier.target.data.uiData.damageTextRelated.mainChrDmgTxtMaxMoveNum
                    mainChrDmgTxtMoveSpawnWaitTime = modifier.target.data.uiData.damageTextRelated.mainChrDmgTxtMoveSpawnWaitTime
                end
                if self.m_entityTextTimeMap[modifier.target] == nil then
                    self.m_entityTextTimeMap[modifier.target] = {}
                end
                local currentMove = 0
                local minSpawnTime = math.huge
                local minIndex = nil
                while currentMove <= mainChrDmgTxtMaxMoveNum and self.m_entityTextTimeMap[modifier.target][currentMove] ~= nil and currentTime - self.m_entityTextTimeMap[modifier.target][currentMove] < mainChrDmgTxtMoveSpawnWaitTime do
                    if self.m_entityTextTimeMap[modifier.target][currentMove] < minSpawnTime then
                        minSpawnTime = self.m_entityTextTimeMap[modifier.target][currentMove]
                        minIndex = currentMove
                    end
                    currentMove = currentMove + 1
                end
                if currentMove > mainChrDmgTxtMaxMoveNum then
                    currentMove = minIndex
                end
                self.m_entityTextTimeMap[modifier.target][currentMove] = currentTime
                local offset2D = mainChrDmgTxtSpawnOffset + currentMove * mainChrDmgTxtMoveSpawnOffset
                if Vector3.Dot(modifier.target.entity.rootCom.transform.position - modifier.source.entity.rootCom.transform.position, cameraTransform.right) < 0 then
                    offset = Vector3(-offset2D.x, offset2D.y, 0)
                    if textType == DamageTextType.Level1Normal then
                        item.anim:PlayWithTween("battletext_normal_left")
                    elseif textType == DamageTextType.Level1Critical then
                        item.anim:PlayWithTween("battletext_critical_left")
                    end
                else
                    offset = Vector3(offset2D.x, offset2D.y, 0)
                    if textType == DamageTextType.Level1Normal then
                        item.anim:PlayWithTween("battletext_normal_right")
                    elseif textType == DamageTextType.Level1Critical then
                        item.anim:PlayWithTween("battletext_critical_right")
                    end
                end
            end
        elseif textType == DamageTextType.Level0Normal or textType == DamageTextType.Level0Critical then
            local guardDmgTxtSpawnOffset = self.view.config.GUARD_DMG_TXT_SPAWN_OFFSET
            local guardDmgTxtSpawnAreaSize = self.view.config.GUARD_DMG_TXT_SPAWN_AREA_SIZE
            if modifier.target.data.uiData.useSpecificDamageTextParam then
                guardDmgTxtSpawnOffset = modifier.target.data.uiData.damageTextRelated.guardDmgTxtSpawnOffset
                guardDmgTxtSpawnAreaSize = modifier.target.data.uiData.damageTextRelated.guardDmgTxtSpawnAreaSize
            end
            for _ = 1, self.view.config.TEXT_POS_MAX_RANDOM_TIMES do
                offset = Vector3(guardDmgTxtSpawnOffset.x, guardDmgTxtSpawnOffset.y, 0) + self:_GetRandomTextOffset(guardDmgTxtSpawnAreaSize.x, guardDmgTxtSpawnAreaSize.y)
                if self:_IsTextPosValid(targetScreenPos + offset) then
                    self.m_showingTextPos[item] = targetScreenPos + offset
                    break
                end
            end
        else
            for _ = 1, self.view.config.TEXT_POS_MAX_RANDOM_TIMES do
                offset = self:_GetRandomTextOffset(self.view.config.TEXT_RANDOM_AREA_SIZE.x, self.view.config.TEXT_RANDOM_AREA_SIZE.y)
                if self:_IsTextPosValid(targetScreenPos + offset) then
                    self.m_showingTextPos[item] = targetScreenPos + offset
                    break
                end
            end
        end
        item.elementFollower.targetTransform = targetTrans
        item.elementFollower.followPosition = targetPos
        item.elementFollower.displayUIOffset = offset
    end
    if modifier.target.hp <= 0 then
        self.m_entityTextTimeMap[modifier.target] = nil
        self.m_entityCoalitionGroupMap[modifier.target] = nil
    end
    self.m_showingTextTimer[item] = self:_StartTimer(item.config.SHOW_DURATION, function()
        self:_CacheTextItem(item, textType)
    end)
end
BattleDamageTextCtrl._OnUspChanged = HL.Method(HL.Any) << function(self, args)
    local modifier = unpack(args)
    if not modifier.showText then
        return
    end
    local textType = DamageTextType.Usp
    local item = self:_GetTextItem(textType)
    local value = lume.round(math.abs(modifier.value))
    item.text.text = string.format("SP+%d", value)
    local targetTrans = modifier.target.entity.rootCom:GetNodeTransform(CS.Beyond.Gameplay.MountPoint.DmgTxtSpawnPoint)
    local targetPos = targetTrans.position
    item.elementFollower.targetTransform = targetTrans
    item.elementFollower.followPosition = targetPos
    self:_StartTimer(item.config.SHOW_DURATION, function()
        self:_CacheTextItem(item, textType)
    end)
end
BattleDamageTextCtrl._OnIgniteBuffText = HL.Method(HL.Any) << function(self, args)
    local position, offset, text, colorType = unpack(args)
    local item = self:_GetTextItem(DamageTextType.IgniteBuff)
    local color = self.m_igniteBuffTypeColorMap[colorType]
    item.elementFollower.followPosition = position
    item.elementFollower.displayUIOffset = Vector3(self.view.config.SPELL_INFLICTION_TEXT_OFFSET.x + offset.x, self.view.config.SPELL_INFLICTION_TEXT_OFFSET.y + offset.y, 0)
    item.text.text = text
    item.text.color = color
    item.textDuplication.text = text
    item.textDuplication.color = color
    self:_StartTimer(item.config.SHOW_DURATION, function()
        self:_CacheTextItem(item, DamageTextType.IgniteBuff)
    end)
end
BattleDamageTextCtrl._OnPhysicalInflictionApplied = HL.Method(HL.Any) << function(self, args)
    local targetAbility, type = unpack(args)
    if not targetAbility.alive then
        return
    end
    local textType = self.m_physicalInflictionTypeToDamageTypeMap[type]
    local item = self:_GetTextItem(textType)
    local targetTrans = targetAbility.entity.rootCom:GetNodeTransform(CS.Beyond.Gameplay.MountPoint.DmgTxtSpawnPoint)
    local targetPos = targetTrans.position
    item.elementFollower.followPosition = targetPos
    item.elementFollower.displayUIOffset = Vector3(self.view.config.PHYSICAL_INFLICTION_TEXT_OFFSET.x, self.view.config.PHYSICAL_INFLICTION_TEXT_OFFSET.y, 0)
    self:_StartTimer(item.config.SHOW_DURATION, function()
        self:_CacheTextItem(item, textType)
    end)
end
BattleDamageTextCtrl._OnSquadInFightChanged = HL.Method(HL.Any) << function(self, args)
    local inFight = unpack(args)
    if not inFight then
        self.m_entityTextTimeMap = {}
        self.m_entityCoalitionGroupMap = {}
    end
end
BattleDamageTextCtrl._OnImmune = HL.Method(HL.Any) << function(self, args)
    local entity, immuneTag = unpack(args)
    if immuneTag:ToString() ~= "Immune/Damage" then
        return
    end
    if entity.enemy == nil or not entity.enemy:CheckShouldShowImmuneDamageText() then
        return
    end
    local textType = self.m_immuneTagToDamageTypeMap[immuneTag:ToString()]
    if textType == nil then
        return
    end
    if self.m_entityTextTimeMap[entity.abilityCom] == nil then
        self.m_entityTextTimeMap[entity.abilityCom] = {}
    end
    local immuneTxtCooldown = self.view.config.IMMUNE_TXT_COOLDOWN
    if entity.abilityCom.data.uiData.useSpecificDamageTextParam then
        immuneTxtCooldown = entity.abilityCom.data.uiData.damageTextRelated.immuneTxtCooldown
    end
    local currentTime = CS.Beyond.TimeManager.time
    if self.m_entityTextTimeMap[entity.abilityCom][textType] and currentTime - self.m_entityTextTimeMap[entity.abilityCom][textType] < immuneTxtCooldown then
        return
    end
    self.m_entityTextTimeMap[entity.abilityCom][textType] = currentTime
    local item = self:_GetTextItem(textType)
    local targetTrans = entity.rootCom:GetNodeTransform(CS.Beyond.Gameplay.MountPoint.DmgTxtSpawnPoint)
    local targetPos = targetTrans.position
    local targetScreenPos = CameraManager.mainCamera:WorldToScreenPoint(targetPos)
    item.elementFollower.targetTransform = targetTrans
    item.elementFollower.followPosition = targetPos
    local offset
    local immuneTxtSpawnOffset = self.view.config.IMMUNE_TXT_SPAWN_OFFSET
    local immuneTxtSpawnAreaSize = self.view.config.IMMUNE_TXT_SPAWN_AREA_SIZE
    if entity.abilityCom.data.uiData.useSpecificDamageTextParam then
        immuneTxtSpawnOffset = entity.abilityCom.data.uiData.damageTextRelated.immuneTxtSpawnOffset
        immuneTxtSpawnAreaSize = entity.abilityCom.data.uiData.damageTextRelated.immuneTxtSpawnAreaSize
    end
    for _ = 1, self.view.config.TEXT_POS_MAX_RANDOM_TIMES do
        offset = Vector3(immuneTxtSpawnOffset.x, immuneTxtSpawnOffset.y, 0) + self:_GetRandomTextOffset(immuneTxtSpawnAreaSize.x, immuneTxtSpawnAreaSize.y)
        if self:_IsTextPosValid(targetScreenPos + offset) then
            self.m_showingTextPos[item] = targetScreenPos + offset
            break
        end
    end
    item.elementFollower.displayUIOffset = offset
    self:_StartTimer(item.config.SHOW_DURATION, function()
        self:_CacheTextItem(item, textType)
    end)
end
BattleDamageTextCtrl._OnCreateFlowText = HL.Method(HL.Any) << function(self, args)
    local position, text, color = unpack(args)
    local item = self:_GetTextItem(DamageTextType.CommonFlowText)
    item.elementFollower.followPosition = position
    item.elementFollower.displayUIOffset = Vector3.zero
    item.text.text = text
    item.text.color = color
    self:_StartTimer(item.config.SHOW_DURATION, function()
        self:_CacheTextItem(item, DamageTextType.CommonFlowText)
    end)
end
BattleDamageTextCtrl._OnCharLevelUp = HL.Method(HL.Any) << function(self, args)
    if self:IsHide() then
        table.insert(self.m_charLevelUpTextToShow, args)
        return
    end
    local instId, _ = unpack(args)
    local entity = GameInstance.world:GetCharacterByInstId(instId):Lock()
    if entity then
        local item
        if self.m_charLevelUpTextMap[instId] ~= nil and CS.Beyond.TimeManager.time - self.m_charLevelUpTextMap[instId].time < 2 then
            item = self.m_charLevelUpTextMap[instId].item
            self:_ClearTimer(self.m_showingTextTimer[item])
        else
            item = self:_GetTextItem(DamageTextType.LevelUpText)
        end
        item.elementFollower.targetTransform = entity.rootCom:GetNodeTransform(CS.Beyond.Gameplay.MountPoint.HeadStatus)
        item.elementFollower.displayUIOffset = Vector3.zero
        item.text.text = entity.abilityCom.lv
        item.anim:PlayInAnimation()
        self.m_charLevelUpTextMap[instId] = {}
        self.m_charLevelUpTextMap[instId].item = item
        self.m_charLevelUpTextMap[instId].time = CS.Beyond.TimeManager.time
        self.m_showingTextTimer[item] = self:_StartTimer(item.config.SHOW_DURATION, function()
            self:_CacheTextItem(item, DamageTextType.LevelUpText)
        end)
    end
end
BattleDamageTextCtrl._GetRandomTextOffset = HL.Method(HL.Number, HL.Number).Return(HL.Userdata) << function(self, width, height)
    return Vector3(lume.random(-width, width), lume.random(-height, height), 0)
end
BattleDamageTextCtrl._IsTextPosValid = HL.Method(HL.Userdata).Return(HL.Boolean) << function(self, newPos)
    local minDist = self.view.config.TEXT_MIN_DIST
    for _, pos in pairs(self.m_showingTextPos) do
        local dist = pos - newPos
        if math.abs(dist.x) < minDist.x then
            return false
        end
        if math.abs(dist.y) < minDist.y then
            return false
        end
    end
    return true
end
BattleDamageTextCtrl._GetTextItem = HL.Method(HL.Number).Return(HL.Table) << function(self, textType)
    local queue = self.m_textCache[textType]
    local item
    if queue:Empty() then
        local prefab = self.m_textPrefabMap[textType]
        item = UIUtils.addChild(self.view.content, prefab)
        item = Utils.wrapLuaNode(item)
    else
        item = queue:Pop()
    end
    item.gameObject:SetActive(true)
    return item
end
BattleDamageTextCtrl._CacheTextItem = HL.Method(HL.Table, HL.Number) << function(self, item, textType)
    self.m_showingTextTimer[item] = nil
    self.m_showingTextPos[item] = nil
    local queue = self.m_textCache[textType]
    if not queue:Contains(item) then
        queue:Push(item)
    end
    item.gameObject:SetActive(false)
end
HL.Commit(BattleDamageTextCtrl)