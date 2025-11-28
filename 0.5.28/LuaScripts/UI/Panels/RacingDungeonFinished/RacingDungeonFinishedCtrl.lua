local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonFinished
RacingDungeonFinishedCtrl = HL.Class('RacingDungeonFinishedCtrl', uiCtrl.UICtrl)
RacingDungeonFinishedCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonFinishedCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.exitBtn.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self:_UpdateView(arg)
end
RacingDungeonFinishedCtrl._UpdateView = HL.Method(HL.Any) << function(self, arg)
    self:_UpdateChar()
    arg = unpack(arg)
    self.view.successedTimeTxt.text = UIUtils.getLeftTimeToSecondMS(GameInstance.player.racingDungeonSystem.racingDungeonTime)
    self.view.failedTimeTxt.text = UIUtils.getLeftTimeToSecondMS(GameInstance.player.racingDungeonSystem.racingDungeonTime)
    self.view.score.text = math.floor(arg.Score)
    self.view.failedTitleNode.gameObject:SetActive(not arg.IsPassed)
    self.view.successedTitleNode.gameObject:SetActive(arg.IsPassed)
    self.view.levelText.text = arg.Level
    self.view.sucessNumberText.text = arg.CompletedRoomList.Count
    self.view.failedNode.gameObject:SetActive(not arg.IsPassed)
    self.view.successedNode.gameObject:SetActive(arg.IsPassed)
    local id = GameInstance.player.racingDungeonSystem.racingDungeonData.tacticsId
    local data = nil
    local t = Tables.racingTacticsTable
    for k, v in pairs(t) do
        if v.tacticsId == id then
            data = v
            break
        end
    end
    self.view.iconImg.sprite = self:LoadSprite("RacingDungeon", data.icon)
    self.view.racedgTxt.text = data.name
end
RacingDungeonFinishedCtrl._UpdateChar = HL.Method() << function(self)
    local childCount = self.view.charContent.childCount
    for i = 1, childCount do
        local cell = self.view.charContent:GetChild(i - 1).gameObject
        self:_UpdateCharCell(cell, i)
    end
end
RacingDungeonFinishedCtrl._UpdateCharCell = HL.Method(GameObject, HL.Number) << function(self, cell, index)
    local t = {}
    cell:GetComponent(typeof(CS.Beyond.Lua.LuaReference)):BindToLua(t)
    local slotList = GameInstance.player.squadManager.curSquad.slots
    if index > slotList.Count then
        t.racingEmptyState.gameObject:SetActive(true)
        t.charHeadCell.gameObject:SetActive(false)
        return
    else
        local info = {}
        info.templateId = slotList[index - 1].charId
        info.instId = slotList[index - 1].charInstId
        t.racingEmptyState.gameObject:SetActive(false)
        t.charHeadCell.gameObject:SetActive(true)
        t.charHeadCell:InitCharFormationHeadCell(info)
    end
end
RacingDungeonFinishedCtrl.OnFinish = HL.StaticMethod(HL.Any) << function(arg)
    UIManager:Open(PANEL_ID, arg)
end
RacingDungeonFinishedCtrl.OnClose = HL.Override() << function(self)
    GameInstance.player.racingDungeonSystem:ReqEndDungeon()
end
HL.Commit(RacingDungeonFinishedCtrl)