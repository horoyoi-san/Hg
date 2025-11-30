local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
MapMarkDetailCommon = HL.Class('MapMarkDetailCommon', UIWidgetBase)
MapMarkDetailCommon.m_onLeftBtnClickFromOuterSide = HL.Field(HL.Function)
MapMarkDetailCommon.m_onRightBtnClickFromOuterSide = HL.Field(HL.Function)
MapMarkDetailCommon.m_onBigBtnClickFromOuterSide = HL.Field(HL.Function)
MapMarkDetailCommon.m_markDetailData = HL.Field(HL.Any)
MapMarkDetailCommon.m_template = HL.Field(HL.Any)
MapMarkDetailCommon.m_instId = HL.Field(HL.String) << ""
MapMarkDetailCommon._OnFirstTimeInit = HL.Override() << function(self)
    self.view.fullScreenBtn.onClick:AddListener(function()
        self:_Close()
    end)
    self.view.closeBtn.onClick:AddListener(function()
        self:_Close()
    end)
    self.view.leftBtn.onClick:AddListener(function()
        self:_OnLeftBtnClick()
    end)
    self.view.rightBtn.onClick:AddListener(function()
        self:_OnRightBtnClick()
    end)
    self.view.bigBtn.onClick:AddListener(function()
        self:_OnBigBtnClick()
    end)
end
MapMarkDetailCommon.InitMapMarkDetailCommon = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    self.m_instId = args.markInstId
    local getRuntimeDataSuccess
    getRuntimeDataSuccess, self.m_markDetailData = GameInstance.player.mapManager:GetMarkInstRuntimeData(self.m_instId)
    if getRuntimeDataSuccess == false then
        logger.error("地图详情页获取实例数据失败" .. self.m_instId)
        return
    end
    local getTemplateSuccess, template = Tables.mapMarkTempTable:TryGetValue(self.m_markDetailData.templateId)
    if getTemplateSuccess == false then
        logger.error("地图详情页模板失败" .. self.m_instId)
        return
    end
    if args.descText ~= nil then
        self.view.desc.text = UIUtils.resolveTextStyle(args.descText)
    else
        self.view.desc.text = UIUtils.resolveTextStyle(template.desc)
    end
    if args.titleText ~= nil then
        self.view.common.title.text.text = args.titleText
    else
        self.view.common.title.text.text = template.name
    end
    local levelId = self.m_markDetailData.levelId
    local getLevelNameSuccess, levelDescInfo = Tables.levelDescTable:TryGetValue(levelId)
    if getLevelNameSuccess == false then
        logger.error("关卡名称获取失败" .. self.m_instId)
        return
    end
    self.view.common.subTitle.text.text = levelDescInfo.showName
    self.m_template = template
    local leftBtnActive = (args.leftBtnActive == true)
    self.view.leftBtn.gameObject:SetActive(leftBtnActive)
    if leftBtnActive == true then
        local leftBtnCallback = args.leftBtnCallback
        if leftBtnCallback ~= nil then
            self.m_onLeftBtnClickFromOuterSide = leftBtnCallback
        end
        local leftBtnText = args.leftBtnText
        self.view.leftBtnText.text = leftBtnText
        self.view.leftBtnIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_DETAIL_BTN_ICON, args.leftBtnIconName)
    end
    local rightBtnActive = (args.rightBtnActive == true)
    self.view.rightBtn.gameObject:SetActive(rightBtnActive)
    if rightBtnActive == true then
        local rightBtnCallback = args.rightBtnCallback
        if rightBtnCallback ~= nil then
            self.m_onRightBtnClickFromOuterSide = rightBtnCallback
            local rightBtnText = args.rightBtnText
            self.view.rightBtnText.text = rightBtnText
            self.view.rightBtnIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_DETAIL_BTN_ICON, args.rightBtnIconName)
        else
            self:_SetTracerBtn()
        end
    end
    local bigBtnActive = (args.bigBtnActive == true)
    self.view.bigBtn.gameObject:SetActive(bigBtnActive)
    if bigBtnActive == true then
        local bigBtnCallback = args.bigBtnCallback
        if bigBtnCallback ~= nil then
            self.m_onBigBtnClickFromOuterSide = bigBtnCallback
            local bigBtnText = args.bigBtnText
            self.view.bigBtnText.text = bigBtnText
            self.view.bigBtnIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_DETAIL_BTN_ICON, args.bigBtnIconName)
        else
            self:_SetTracerBtn()
        end
    end
    self:_RefreshHeadIconSprite()
end
MapMarkDetailCommon._SetTracerBtn = HL.Method() << function(self)
    local tracking = self.m_instId == GameInstance.player.mapManager.trackingMarkInstId
    if tracking == false then
        self.view.rightBtnIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_DETAIL_BTN_ICON, UIConst.MAP_DETAIL_BTN_ICON_NAME.TRACE)
        self.view.rightBtnText.text = Language["ui_map_common_tracer"]
        self.view.bigBtnIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_DETAIL_BTN_ICON, UIConst.MAP_DETAIL_BTN_ICON_NAME.TRACE)
        self.view.bigBtnText.text = Language["ui_map_common_tracer"]
    else
        self.view.rightBtnIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_DETAIL_BTN_ICON, UIConst.MAP_DETAIL_BTN_ICON_NAME.REMOVE_TRACE)
        self.view.rightBtnText.text = Language["ui_map_common_tracer_cancel"]
        self.view.bigBtnIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_DETAIL_BTN_ICON, UIConst.MAP_DETAIL_BTN_ICON_NAME.REMOVE_TRACE)
        self.view.bigBtnText.text = Language["ui_map_common_tracer_cancel"]
    end
end
MapMarkDetailCommon._RefreshHeadIconSprite = HL.Method() << function(self)
    local active = self.m_markDetailData.isActive
    local sprite
    if active == true then
        sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_ICON, self.m_template.detailActiveIcon)
    else
        sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_ICON, self.m_template.detailInactiveIcon)
    end
    self.view.common.title.icon.sprite = sprite
end
MapMarkDetailCommon._SwitchTracerState = HL.Method() << function(self)
    local tracking = self.m_instId == GameInstance.player.mapManager.trackingMarkInstId
    GameInstance.player.mapManager:TrackMark(self.m_instId, not tracking)
end
MapMarkDetailCommon._Close = HL.Method() << function(self)
    Notify(MessageConst.HIDE_LEVEL_MAP_MARK_DETAIL)
end
MapMarkDetailCommon._OnLeftBtnClick = HL.Method() << function(self)
    if self.m_onLeftBtnClickFromOuterSide ~= nil then
        self:m_onLeftBtnClickFromOuterSide(self.m_instId)
    end
end
MapMarkDetailCommon._OnRightBtnClick = HL.Method() << function(self)
    if self.m_onRightBtnClickFromOuterSide ~= nil then
        self:m_onRightBtnClickFromOuterSide(self.m_instId)
    else
        self:_SwitchTracerState()
        self:_SetTracerBtn()
        self:_RefreshHeadIconSprite()
    end
end
MapMarkDetailCommon._OnBigBtnClick = HL.Method() << function(self)
    if self.m_onBigBtnClickFromOuterSide ~= nil then
        self:m_onBigBtnClickFromOuterSide(self.m_instId)
    else
        self:_SwitchTracerState()
        self:_SetTracerBtn()
        self:_RefreshHeadIconSprite()
    end
end
HL.Commit(MapMarkDetailCommon)
return MapMarkDetailCommon