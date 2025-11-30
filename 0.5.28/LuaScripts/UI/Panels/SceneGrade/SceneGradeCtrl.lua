local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SceneGrade
SceneGradeCtrl = HL.Class('SceneGradeCtrl', uiCtrl.UICtrl)
local GRADE_STATE_NAME = { CURRENT = "current", NORMAL = "normal", LOCKED = "locked", CD = "cd", }
SceneGradeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SCENE_GRADE_CHANGE_NOTIFY] = '_OnSceneGradeChangeNotify' }
SceneGradeCtrl.m_levelId = HL.Field(HL.String) << ""
SceneGradeCtrl.m_mapManager = HL.Field(HL.Userdata)
SceneGradeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local args = arg
    self.m_levelId = (args and args.levelId) and args.levelId or GameInstance.world.curLevelId
    self.m_mapManager = GameInstance.player.mapManager
    self.view.commonTopTitlePanel.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SceneGrade)
    end)
    self.view.commonTopTitlePanel.btnTips.onClick:AddListener(function()
        UIManager:Open(PanelId.InstructionBook, "scene_grade")
    end)
    self:_RefreshAll()
end
SceneGradeCtrl._RefreshAll = HL.Method() << function(self)
    self:_RefreshLevelInfo()
    self:_RefreshAllGrades()
    self:_RefreshCD()
end
SceneGradeCtrl._OnSceneGradeChangeNotify = HL.Method(HL.Table) << function(self, args)
    self:_RefreshAll()
end
SceneGradeCtrl.m_currentGrade = HL.Field(HL.Number) << 0
SceneGradeCtrl.m_domainId = HL.Field(HL.String) << ""
SceneGradeCtrl.m_currentProsperity = HL.Field(HL.Number) << 0
SceneGradeCtrl._RefreshLevelInfo = HL.Method() << function(self)
    self.m_currentGrade = self.m_mapManager:GetSceneGrade(self.m_levelId)
    self.view.leftNode.txtGrade.text = UIConst.SCENE_GRADE_TEXT[self.m_currentGrade]
    local hasValue
    local levelDescData
    hasValue, levelDescData = Tables.levelDescTable:TryGetValue(self.m_levelId)
    local sceneName = hasValue and levelDescData.showName or ""
    self.view.leftNode.txtSceneName.text = sceneName
    local levelBasicInfo
    local domainData
    hasValue, levelBasicInfo = DataManager.levelBasicInfoTable:TryGetValue(self.m_levelId)
    if hasValue then
        self.m_domainId = levelBasicInfo.domainName
        hasValue, domainData = Tables.domainDataTable:TryGetValue(levelBasicInfo.domainName)
    end
    local domainName = hasValue and domainData.domainName or ""
    self.view.leftNode.txtDomainName.text = domainName
    local _
    self.m_currentProsperity, _ = GameInstance.player.settlementSystem:GetProsperityByDomainId(self.m_domainId)
end
SceneGradeCtrl.m_gradesCachedCellFunction = HL.Field(HL.Function)
SceneGradeCtrl.m_allGrades = HL.Field(HL.Userdata)
SceneGradeCtrl.m_currentGradeIndex = HL.Field(HL.Number) << 0
SceneGradeCtrl.m_lastUnlockedGradeIndex = HL.Field(HL.Number) << 0
SceneGradeCtrl._RefreshAllGrades = HL.Method() << function(self)
    if not self.m_gradesCachedCellFunction then
        self.m_gradesCachedCellFunction = UIUtils.genCachedCellFunction(self.view.listNode)
        self.view.listNode.onUpdateCell:AddListener(function(object, csIndex)
            self:_OnUpdateGradeCell(self.m_gradesCachedCellFunction(object), LuaIndex(csIndex))
        end)
        self.view.listNode.onGraduallyShowFinish:AddListener(function()
            if self.m_mapManager:IsNewSceneGradeUnlocked(self.m_levelId) then
                local cell = self.m_gradesCachedCellFunction(self.view.listNode:Get(CSIndex(self.m_lastUnlockedGradeIndex)))
                cell.redDot.gameObject:SetActive(true)
                self.m_mapManager:SendMsgRemoveNewSceneGradeUnlocked(self.m_levelId)
            end
        end)
    end
    local hasValue
    local levelGradeData
    hasValue, levelGradeData = Tables.levelGradeTable:TryGetValue(self.m_levelId)
    if hasValue then
        self.m_allGrades = levelGradeData.grades
    end
    local gradeCount = hasValue and #levelGradeData.grades or 0
    self.view.listNode:UpdateCount(gradeCount)
end
SceneGradeCtrl._OnUpdateGradeCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local gradeInfo = self.m_allGrades[CSIndex(index)]
    cell.txtGrade.text = UIConst.SCENE_GRADE_TEXT[gradeInfo.grade]
    cell.iconImg.sprite = self:LoadSprite(string.format(UIConst.UI_SPRITE_SCENE_GRADE_BIG_PATH, gradeInfo.grade))
    cell.txtDesc.text = Language[string.format("ui_maplevel_level%d_des", gradeInfo.grade)]
    local stateName
    if self.m_currentGrade == gradeInfo.grade then
        stateName = GRADE_STATE_NAME.CURRENT
        self.m_currentGradeIndex = index
    elseif gradeInfo.prosperity > self.m_currentProsperity then
        stateName = GRADE_STATE_NAME.LOCKED
        cell.txtLocked.text = string.format(Language.LUA_SCENE_GRADE_LOCKED_DESC_FORMAT, gradeInfo.prosperity, self.m_currentProsperity, gradeInfo.prosperity)
    elseif self.m_mapManager:IsSceneGradeModifyOnCoolDown(self.m_levelId) then
        stateName = GRADE_STATE_NAME.CD
    else
        stateName = GRADE_STATE_NAME.NORMAL
        cell.btnChangeGrade.onClick:RemoveAllListeners()
        cell.btnChangeGrade.onClick:AddListener(function()
            self:_OnBtnChangeGradeClicked(gradeInfo.grade)
        end)
    end
    if stateName ~= GRADE_STATE_NAME.LOCKED and index > self.m_lastUnlockedGradeIndex then
        self.m_lastUnlockedGradeIndex = index
    end
    cell.stateCtrl:SetState(stateName)
    cell.gameObject.name = string.format("grade_%d", gradeInfo.grade)
    cell.redDot.gameObject:SetActive(false)
end
SceneGradeCtrl._OnBtnChangeGradeClicked = HL.Method(HL.Number) << function(self, toGrade)
    local args = { levelId = self.m_levelId, fromGrade = self.m_currentGrade, toGrade = toGrade, }
    UIManager:Open(PanelId.SceneGradePopUp, args)
end
SceneGradeCtrl._RefreshCD = HL.Method() << function(self)
    local isOnCD = self.m_mapManager:IsSceneGradeModifyOnCoolDown(self.m_levelId)
    self.view.cdNode.gameObject:SetActive(isOnCD)
    if isOnCD then
        local targetTime = self.m_mapManager:GetSceneGradeDecreaseTimestamp(self.m_levelId) + Tables.globalConst.downgradeSceneIntervalTime
        self.view.cdNode.countDownText:InitCountDownText(targetTime, function()
            self:_RefreshAll()
        end, function(leftSec)
            return string.format(Language.LUA_SCENE_GRADE_CD_FORMAT, UIUtils.getLeftTimeToSecondFull(leftSec))
        end)
    end
end
SceneGradeCtrl.OpenSceneGradePanel = HL.StaticMethod(HL.Table) << function(args)
    local levelId = unpack(args)
    PhaseManager:OpenPhase(PhaseId.SceneGrade, { levelId = levelId })
end
HL.Commit(SceneGradeCtrl)