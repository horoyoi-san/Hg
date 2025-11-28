local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharInfoAttributeHint
CharInfoAttributeHintCtrl = HL.Class('CharInfoAttributeHintCtrl', uiCtrl.UICtrl)
CharInfoAttributeHintCtrl.s_messages = HL.StaticField(HL.Table) << {}
CharInfoAttributeHintCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.fcAttributeHintNode.gameObject:SetActive(false)
    self.view.scAttributeHintNode.gameObject:SetActive(false)
    self.view.fcAttributeHintNode.autoCloseArea.onTriggerAutoClose:AddListener(function()
        if self.m_args and self.m_isFC then
            self.m_args = nil
        end
        self:_OnCloseSkillTips()
    end)
    self.view.scAttributeHintNode.autoCloseArea.onTriggerAutoClose:AddListener(function()
        if self.m_args and not self.m_isFC then
            self.m_args = nil
        end
        self:_OnCloseSkillTips()
    end)
end
CharInfoAttributeHintCtrl.m_args = HL.Field(HL.Table)
CharInfoAttributeHintCtrl.m_isFC = HL.Field(HL.Boolean) << false
CharInfoAttributeHintCtrl.CharInfoShowFCAttrHint = HL.StaticMethod(HL.Table) << function(args)
    CharInfoAttributeHintCtrl._TryShowHint(args, true)
end
CharInfoAttributeHintCtrl.CharInfoShowSCAttrHint = HL.StaticMethod(HL.Table) << function(args)
    CharInfoAttributeHintCtrl._TryShowHint(args, false)
end
CharInfoAttributeHintCtrl._TryShowHint = HL.StaticMethod(HL.Table, HL.Boolean) << function(args, isFirstClass)
    if args.key == nil then
        args.key = args.transform
    end
    local self = UIManager:AutoOpen(PANEL_ID)
    local hintNode = isFirstClass and self.view.fcAttributeHintNode or self.view.scAttributeHintNode
    if self.m_args and self.m_args.key == args.key then
        hintNode.autoCloseArea:CloseSelf()
        return
    end
    UIManager:SetTopOrder(PANEL_ID)
    hintNode.gameObject:SetActive(false)
    hintNode.gameObject:SetActive(true)
    self.m_args = args
    self.m_isFC = isFirstClass
    if isFirstClass then
        self:_ShowFCAttrHintNode()
    else
        self:_ShowSCMainAttrHintNode()
    end
    local targetScreenRect = UIUtils.getTransformScreenRect(args.transform, self.uiCamera)
    local scale = self.view.transform.rect.width / Screen.width
    hintNode.transform.anchoredPosition = Vector2(targetScreenRect.xMax, -targetScreenRect.yMin) * scale
    hintNode.autoCloseArea.tmpSafeArea = args.transform
end
CharInfoAttributeHintCtrl._ShowFCAttrHintNode = HL.Method() << function(self)
    local hintNode = self.view.fcAttributeHintNode
    local hintInfo = AttributeUtils.getAttributeHint(self.m_args.attributeInfo, { charTemplateId = self.m_args.charTemplateId, charInstId = self.m_args.charInstId })
    self:_RefreshAttributeHint(hintNode, self.m_args.attributeInfo, hintInfo, true)
end
CharInfoAttributeHintCtrl._ShowSCMainAttrHintNode = HL.Method() << function(self)
    local hintNode = self.view.scAttributeHintNode
    local charInfo = self.m_args.charInfo
    local attributeInfo = self.m_args.attributeInfo
    if hintNode.defExtra ~= nil then
        local isDef = attributeInfo.attributeType == GEnums.AttributeType.Def
        hintNode.defExtra.gameObject:SetActive(isDef)
        hintNode.defExtraTxt.text = CharInfoUtils.getDefExtraHint(charInfo.instId)
    end
    hintNode.attributeText.text = attributeInfo.showName
    hintNode.valueText.text = attributeInfo.showValue
    hintNode.attributeIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ATTRIBUTE_ICON, attributeInfo.iconName)
    if hintNode.detailGroupCache == nil then
        hintNode.detailGroupCache = UIUtils.genCellCache(hintNode.detailGroup)
    end
    local detailCfgList = UIConst.CHAR_INFO_ATTR_TYPE_2_DETAIL_GROUP[attributeInfo.attributeType]
    hintNode.detailGroupCache:Refresh(#detailCfgList, function(group, index)
        local detailCfg = detailCfgList[index]
        local showValue, value = CharInfoUtils[detailCfg.valueFuncName](charInfo, attributeInfo)
        local isShowValue = true
        if detailCfg.notZero then
            if not value then
                isShowValue = false
            end
            if value and math.abs(value) < 0.001 then
                isShowValue = false
            end
        end
        group.gameObject:SetActive(isShowValue)
        group.groupText.text = detailCfg.showName
        group.groupValue.text = showValue
        local detailList = {}
        if detailCfg.detailListFuncName then
            detailList = CharInfoUtils[detailCfg.detailListFuncName](charInfo, value)
        end
        if group.detailCellCache == nil then
            group.detailCellCache = UIUtils.genCellCache(group.detailCell)
        end
        group.detailCellCache:Refresh(#detailList, function(detailCell, detailIndex)
            local detailInfo = detailList[detailIndex]
            detailCell.detailName.text = detailInfo.showName
            detailCell.valueText.text = detailInfo.showValue
        end)
    end)
end
CharInfoAttributeHintCtrl._RefreshAttributeHint = HL.Method(HL.Any, HL.Table, HL.Table, HL.Boolean) << function(self, cell, attributeInfo, hintInfo, isFCAttr)
    cell.attributeText.text = attributeInfo.showName
    cell.hintText.text = hintInfo.mainHint
    if isFCAttr then
        if not cell.m_fcSubHintCellCache then
            cell.m_fcSubHintCellCache = UIUtils.genCellCache(cell.attributesCell)
        end
        local subHintCount = hintInfo.subHintList and #hintInfo.subHintList or 0
        cell.m_fcSubHintCellCache:Refresh(subHintCount, function(subCell, index)
            subCell.text.text = hintInfo.subHintList[index]
        end)
        local extraHintCount = hintInfo.extraHintList and #hintInfo.extraHintList or 0
        cell.boundary.gameObject:SetActive(extraHintCount > 0)
        if not cell.m_fcExtraHintCellCache then
            cell.m_fcExtraHintCellCache = UIUtils.genCellCache(cell.extraHint)
        end
        cell.m_fcExtraHintCellCache:Refresh(extraHintCount, function(extraCell, index)
            extraCell.text.text = hintInfo.extraHintList[index]
        end)
    end
end
CharInfoAttributeHintCtrl._OnCloseSkillTips = HL.Method() << function(self)
    Notify(MessageConst.CHAR_INFO_CLOSE_ATTR_TIP)
end
HL.Commit(CharInfoAttributeHintCtrl)