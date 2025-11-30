local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonProtal
RacingDungeonProtalCtrl = HL.Class('RacingDungeonProtalCtrl', uiCtrl.UICtrl)
RacingDungeonProtalCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonProtalCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self:_InitView(arg.roomId, arg.position, arg.rotation, arg.sceneId)
end
RacingDungeonProtalCtrl._InitView = HL.Method(HL.String, HL.Table, HL.Table, HL.String) << function(self, roomId, position, rotation, sceneId)
    roomId = tonumber(roomId)
    local config = Tables.racingDungeonRoomTable:GetValue(roomId)
    if config == nil then
        return
    end
    self.view.titleTxt.text = config.roomName
    self.view.descText.text = UIUtils.resolveTextStyle(config.roomDesc)
    self.view.ruleText.text = UIUtils.resolveTextStyle(config.roomFeaturesDesc)
    local effectBuff = config.compeleteBuffDescId
    for i = 0, effectBuff.Count - 1 do
        local item = effectBuff[i]
        local go = CS.Beyond.Lua.UtilsForLua.CreateObject(self.view.effectCell.gameObject, self.view.effectNode)
        go:SetActive(true)
        go.transform:Find("EffectText"):GetComponent(typeof(CS.Beyond.UI.UIText)).text = Tables.racingDungeonCompeleBuffDescTextTable:GetValue(item).text
    end
    if effectBuff.Count == 0 then
        self.view.effectNode.gameObject:SetActive(false)
    end
    self.view.btnCommon.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
        local quaternion = CS.UnityEngine.Quaternion.Euler(rotation.x, rotation.y, rotation.z)
        GameAction.TeleportToPosition(sceneId, GEnums.TeleportReason.Map, CS.UnityEngine.Vector3(position.x, position.y, position.z), quaternion)
    end)
    for i = 0, config.enemyIds.Count - 1 do
        local enemyId = config.enemyIds[i]
        local go = CS.Beyond.Lua.UtilsForLua.CreateObject(self.view.enemyCell.gameObject, self.view.enemyNode)
        go:SetActive(true)
        go.transform:Find("EnemyName"):GetComponent(typeof(CS.Beyond.UI.UIText)).text = Tables.enemyTemplateDisplayInfoTable:GetValue(enemyId).name
        go.transform:Find("EnemyName/Text/EnemyLevel"):GetComponent(typeof(CS.Beyond.UI.UIText)).text = config.enemyLevels[i]
        go.transform:Find("BG/Texture1"):GetComponent(typeof(CS.Beyond.UI.UIImage)).sprite = UIUtils.loadSprite(self.loader, UIConst.UI_SPRITE_MONSTER_ICON, enemyId)
    end
end
RacingDungeonProtalCtrl.OnClose = HL.Override() << function(self)
end
HL.Commit(RacingDungeonProtalCtrl)