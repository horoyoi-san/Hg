local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SceneGradePopUp
SceneGradePopUpCtrl = HL.Class('SceneGradePopUpCtrl', uiCtrl.UICtrl)
local SCENE_UPGRADE_RICH_TEXT_KEY = "scene_grade.up"
local SCENE_DOWNGRADE_RICH_TEXT_KEY = "scene_grade.down"
SceneGradePopUpCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SCENE_GRADE_CHANGE_NOTIFY] = '_OnSceneGradeChangeNotify' }
SceneGradePopUpCtrl.m_allGrades = HL.Field(HL.Userdata)
SceneGradePopUpCtrl.m_args = HL.Field(HL.Table)
SceneGradePopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_args = arg
    local fromGrade = self.m_args.fromGrade
    local toGrade = self.m_args.toGrade
    local hasValue
    local levelDescData
    hasValue, levelDescData = Tables.levelDescTable:TryGetValue(self.m_args.levelId)
    local levelName = hasValue and levelDescData.showName or ""
    self.view.txtTitle.text = string.format(Language.LUA_SCENE_GRADE_MODIFY_TITLE_FORMAT, levelName, UIConst.SCENE_GRADE_TEXT[fromGrade], UIConst.SCENE_GRADE_TEXT[toGrade])
    local levelGradeData
    hasValue, levelGradeData = Tables.levelGradeTable:TryGetValue(self.m_args.levelId)
    if hasValue then
        self.m_allGrades = levelGradeData.grades
    end
    local isDowngrade = toGrade < fromGrade
    self.view.tipsNode.gameObject:SetActive(isDowngrade)
    if isDowngrade then
        self.view.txtTip.text = string.format(Language.LUA_SCENE_GRADE_DOWNGRADE_CD_WARNING_FORMAT, Tables.globalConst.downgradeSceneIntervalTime / 60 / 60)
    end
    self.view.confirmButton.onClick:AddListener(function()
        self:_OnBtnConfirmClicked()
    end)
    self.view.cancelButton.onClick:AddListener(function()
        self:Close()
    end)
    self:_RefreshContent(fromGrade, toGrade)
end
SceneGradePopUpCtrl._OnBtnConfirmClicked = HL.Method() << function(self)
    GameInstance.player.mapManager:SetSceneGrade(self.m_args.levelId, self.m_args.toGrade)
end
SceneGradePopUpCtrl._OnSceneGradeChangeNotify = HL.Method(HL.Table) << function(self, args)
    self:Close()
end
SceneGradePopUpCtrl.m_contentCachedCellFunction = HL.Field(HL.Function)
SceneGradePopUpCtrl._RefreshContent = HL.Method(HL.Number, HL.Number) << function(self, fromGrade, toGrade)
    local fromGradeInfo = self.m_allGrades[fromGrade - 1]
    local toGradeInfo = self.m_allGrades[toGrade - 1]
    local contentTextTable = {}
    local isUpgrade = toGrade > fromGrade
    local richTextKey
    local changeText1
    local changeText2
    if isUpgrade then
        richTextKey = SCENE_UPGRADE_RICH_TEXT_KEY
        changeText1 = Language.LUA_SCENE_GRADE_INCREASE_DESC
        changeText2 = Language.LUA_SCENE_GRADE_UPGRADE_DESC
    else
        richTextKey = SCENE_DOWNGRADE_RICH_TEXT_KEY
        changeText1 = Language.LUA_SCENE_GRADE_DECREASE_DESC
        changeText2 = Language.LUA_SCENE_GRADE_DOWNGRADE_DESC
    end
    if toGradeInfo.monsterBaseLevel ~= fromGradeInfo.monsterBaseLevel then
        table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_MONSTER_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, fromGradeInfo.monsterBaseLevel)), UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, toGradeInfo.monsterBaseLevel))))
    end
    if toGradeInfo.bandwidth ~= fromGradeInfo.bandwidth then
        table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_BANDWIDTH_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, fromGradeInfo.bandwidth)), UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, toGradeInfo.bandwidth))))
    end
    if toGradeInfo.travelPoleLimit ~= fromGradeInfo.travelPoleLimit then
        table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_TRAVEL_POLE_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, fromGradeInfo.travelPoleLimit)), UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, toGradeInfo.travelPoleLimit))))
    end
    if toGradeInfo.battleBuildingLimit ~= fromGradeInfo.battleBuildingLimit then
        table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_BUILDING_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, fromGradeInfo.battleBuildingLimit)), UIUtils.resolveTextStyle(string.format("<@%s>%d</>", richTextKey, toGradeInfo.battleBuildingLimit))))
    end
    table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_MINER_COUNT_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%s</>", richTextKey, changeText1))))
    table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_MINER_EFFICIENCY_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%s</>", richTextKey, changeText1))))
    table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_OUTPUT_EFFICIENCY_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%s</>", richTextKey, changeText1))))
    table.insert(contentTextTable, string.format(Language.LUA_SCENE_GRADE_RECYCLE_QUALITY_DESC_FORMAT, UIUtils.resolveTextStyle(string.format("<@%s>%s</>", richTextKey, changeText2))))
    if not self.m_contentCachedCellFunction then
        self.m_contentCachedCellFunction = UIUtils.genCachedCellFunction(self.view.scrollList)
        self.view.scrollList.onUpdateCell:AddListener(function(object, csIndex)
            local cell = self.m_contentCachedCellFunction(object)
            local text = contentTextTable[LuaIndex(csIndex)]
            cell.txtDesc.text = text
        end)
    end
    self.view.scrollList:UpdateCount(#contentTextTable)
end
HL.Commit(SceneGradePopUpCtrl)