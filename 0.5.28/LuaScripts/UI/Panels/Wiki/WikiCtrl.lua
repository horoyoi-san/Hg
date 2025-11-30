local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Wiki
WikiCtrl = HL.Class('WikiCtrl', uiCtrl.UICtrl)
WikiCtrl.s_messages = HL.StaticField(HL.Table) << {}
local WIKI_CATEGORY_TO_Node_NAME = { [WikiConst.EWikiCategoryType.Weapon] = "btnWeapon", [WikiConst.EWikiCategoryType.Equip] = "btnEquip", [WikiConst.EWikiCategoryType.Item] = "btnItem", [WikiConst.EWikiCategoryType.Monster] = "btnMonster", [WikiConst.EWikiCategoryType.Building] = "btnBuilding", [WikiConst.EWikiCategoryType.Tutorial] = "btnTutorial", }
local VIDEO_KEY = "ui_wiki_main"
WikiCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local success, videoFile = CS.Beyond.Gameplay.View.VideoManager.TryGetVideoPlayFullPath(VIDEO_KEY)
    if success then
        self.view.video.player:SetFile(nil, videoFile)
        self.view.video.player.applyTargetAlpha = true
        self:_StartCoroutine(function()
            while true do
                local status = self.view.video.player.status
                if status == CS.CriWare.CriMana.Player.Status.Stop or status == CS.CriWare.CriMana.Player.Status.Ready then
                    break
                end
                coroutine.step()
            end
            self.view.video:Play()
        end)
    end
    local spriteNumberTable = {}
    for i = 1, 6 do
        spriteNumberTable[i] = self.view["imgNumber0" .. i].sprite
    end
    for categoryId, categoryData in pairs(Tables.wikiCategoryTable) do
        local nodeName = WIKI_CATEGORY_TO_Node_NAME[categoryId]
        if nodeName ~= nil then
            local node = self.view[nodeName]
            if node then
                node.btn.transform:SetSiblingIndex(categoryData.categoryPriority - 1)
                node.imgNumber.sprite = spriteNumberTable[categoryData.categoryPriority]
                node.btn.onClick:AddListener(function()
                    if WikiUtils.isWikiCategoryUnlocked(categoryId) then
                        self.m_phase:OpenCategory(categoryId)
                    else
                        Notify(MessageConst.SHOW_TOAST, Language.LUA_WIKI_CATEGORY_LOCKED)
                    end
                end)
                node.redDot:InitRedDot("WikiCategory", categoryId)
            end
        end
    end
    AudioManager.PostEvent("au_ui_menu_wiki_open")
end
WikiCtrl.OnClose = HL.Override() << function(self)
    AudioManager.PostEvent("au_ui_menu_wiki_close")
end
WikiCtrl._OnPhaseItemBind = HL.Override() << function(self)
    self.view.topNode:InitWikiTop({ phase = self.m_phase, panelId = PANEL_ID, forceShowCloseBtn = true, })
end
HL.Commit(WikiCtrl)