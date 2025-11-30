local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GuideMedia
GuideMediaCtrl = HL.Class('GuideMediaCtrl', uiCtrl.UICtrl)
local GUIDE_VIDEO_PATH_FORMAT = "Guide/%s"
GuideMediaCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_GUIDE_MEDIA] = 'HideGuideMedia', }
GuideMediaCtrl.m_mediaInfos = HL.Field(HL.Userdata)
GuideMediaCtrl.m_imageIndexCache = HL.Field(HL.Forward("UIListCache"))
GuideMediaCtrl.m_getMediaCell = HL.Field(HL.Function)
GuideMediaCtrl.m_onComplete = HL.Field(HL.Function)
GuideMediaCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local mediaScrollList = self.view.mediaNode.mediaList
    self.view.mediaNode.closeButton.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self.view.mediaNode.leftButton.onClick:AddListener(function()
        mediaScrollList:ScrollToIndex(mediaScrollList.centerIndex - 1)
    end)
    self.view.mediaNode.rightButton.onClick:AddListener(function()
        mediaScrollList:ScrollToIndex(mediaScrollList.centerIndex + 1)
    end)
    self.m_imageIndexCache = UIUtils.genCellCache(self.view.mediaNode.indexToggle.gameObject)
    mediaScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateImageCell(obj, csIndex)
    end)
    mediaScrollList.onCenterIndexChanged:AddListener(function(oldIndex, newIndex)
        self:_OnUpdateSelectImageIndex(newIndex)
    end)
    self.m_getMediaCell = UIUtils.genCachedCellFunction(mediaScrollList)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
GuideMediaCtrl.ShowGuideMedia = HL.StaticMethod(HL.Table) << function(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    self.m_mediaInfos = args.mediaInfos
    self.m_onComplete = args.onComplete
    self:_RefreshMedia(self.m_mediaInfos)
    self.view.luaPanel:RecoverAllInput()
    VoiceManager:SetPause(true)
end
GuideMediaCtrl.HideGuideMedia = HL.Method() << function(self)
    if not self:IsShow() then
        return
    end
    if self:IsPlayingAnimationOut() then
        return
    end
    self:PlayAnimationOutWithCallback(function()
        self.m_mediaInfos = nil
        self.m_onComplete = nil
        self:Hide()
    end)
    VoiceManager:SetPause(false)
end
GuideMediaCtrl._OnClickClose = HL.Method() << function(self)
    self.m_onComplete()
end
GuideMediaCtrl._RefreshMedia = HL.Method(HL.Userdata) << function(self, mediaInfos)
    local node = self.view.mediaNode
    local count = mediaInfos.Count
    self.m_imageIndexCache:Refresh(count)
    node.mediaList:UpdateCount(count, true)
    node.animationWrapper:PlayInAnimation()
end
GuideMediaCtrl._OnUpdateImageCell = HL.Method(GameObject, HL.Number) << function(self, obj, csIndex)
    local info = self.m_mediaInfos[csIndex]
    local cell = self.m_getMediaCell(obj)
    local isImg = info.type == CS.Beyond.Gameplay.GuideMediaInfo.Type.Image
    cell.image.gameObject:SetActive(isImg)
    cell.video.gameObject:SetActive(not isImg)
    cell.video:Stop()
    cell.coroutine = self:_ClearCoroutine(cell.coroutine)
    if isImg then
        cell.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_GUIDE, info.imgPath)
        cell.video.player:SetFile(nil, "")
    else
        local success, file = CS.Beyond.Gameplay.View.VideoManager.TryGetVideoPlayFullPath(string.format(GUIDE_VIDEO_PATH_FORMAT, info.videoPath))
        if success then
            cell.video.player:SetFile(nil, file)
            cell.video.player.applyTargetAlpha = true
            cell.coroutine = self:_StartCoroutine(function()
                while true do
                    local status = cell.video.player.status
                    if status == CS.CriWare.CriMana.Player.Status.Stop or status == CS.CriWare.CriMana.Player.Status.Ready then
                        break
                    end
                    coroutine.step()
                end
                cell.video:Play()
            end)
        end
    end
end
GuideMediaCtrl._OnUpdateSelectImageIndex = HL.Method(HL.Number) << function(self, newIndex)
    local cell = self.m_imageIndexCache:GetItem(LuaIndex(newIndex))
    cell.toggle.isOn = true
    local node = self.view.mediaNode
    local infos = self.m_mediaInfos
    local info = infos[newIndex]
    node.titleTxt.text = InputManager.ParseTextActionId(UIUtils.resolveTextStyle(Language[info.titleTxtId]))
    node.contentTxt.text = InputManager.ParseTextActionId(UIUtils.resolveTextStyle(Language[info.descTxtId]))
    local isLast = newIndex == infos.Count - 1
    node.leftButton.interactable = newIndex > 0
    node.rightButton.interactable = not isLast and infos.Count > 1
    node.closeButton.gameObject:SetActive(isLast)
end
HL.Commit(GuideMediaCtrl)