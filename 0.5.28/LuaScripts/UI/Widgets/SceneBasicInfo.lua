local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SceneBasicInfo = HL.Class('SceneBasicInfo', UIWidgetBase)
SceneBasicInfo._OnFirstTimeInit = HL.Override() << function(self)
end
SceneBasicInfo.InitSceneBasicInfo = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    local hasValue
    local levelDescData
    hasValue, levelDescData = Tables.levelDescTable:TryGetValue(args.levelId)
    if hasValue then
        self.view.txtName.text = levelDescData.showName
    end
    local sceneGrade = GameInstance.player.mapManager:GetSceneGrade(args.levelId)
    self.view.iconImg.sprite = self:LoadSprite(string.format(UIConst.UI_SPRITE_SCENE_GRADE_PATH, sceneGrade))
    self.view.txtGrade.text = '.' .. UIConst.SCENE_GRADE_TEXT[sceneGrade]
    self.view.btn.targetGraphic.raycastTarget = false
    self.view.btn.onClick:RemoveAllListeners()
    if args.onClick then
        self.view.btn.targetGraphic.raycastTarget = true
        self.view.btn.onClick:AddListener(function()
            args.onClick(args.levelId)
        end)
    end
    self.view.btn.onHoverChange:RemoveAllListeners()
    if args.onHoverChanged then
        self.view.btn.targetGraphic.raycastTarget = true
        self.view.btn.onHoverChange:AddListener(function(isHover)
            args.onHoverChanged(args.levelId, isHover)
        end)
    end
end
HL.Commit(SceneBasicInfo)
return SceneBasicInfo