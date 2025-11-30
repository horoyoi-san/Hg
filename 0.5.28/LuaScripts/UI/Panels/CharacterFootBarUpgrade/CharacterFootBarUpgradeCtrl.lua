local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharacterFootBarUpgrade
CharacterFootBarUpgradeCtrl = HL.Class('CharacterFootBarUpgradeCtrl', uiCtrl.UICtrl)
CharacterFootBarUpgradeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.INTERRUPT_MAIN_HUD_TOAST] = 'InterruptMainHudToast', }
CharacterFootBarUpgradeCtrl.m_cells = HL.Field(HL.Table)
CharacterFootBarUpgradeCtrl.m_coroutine = HL.Field(HL.Thread)
local MAX_DASH_COUNT_IN_RING = 6
local ANGLE_PER_CELL = 360 / MAX_DASH_COUNT_IN_RING
local ANGLE_PER_HALF_CELL = ANGLE_PER_CELL / 2
local ANGLE_PER_QUARTER_CELL = ANGLE_PER_CELL / 4
CharacterFootBarUpgradeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local old, current = unpack(arg)
    self.m_cells = {}
    local oldCount = math.ceil(old)
    local hasHalfCell = oldCount - old > 0.1
    for i = 1, oldCount do
        local cellModel
        local isHalfCell = hasHalfCell and i == oldCount
        if isHalfCell then
            cellModel = self.view.halfCellNode
        else
            cellModel = self.view.fullCellNode
        end
        local obj = CSUtils.CreateObject(cellModel.gameObject, cellModel.gameObject.transform.parent)
        local cell = Utils.wrapLuaNode(obj)
        cell.glow.gameObject:SetActive(false)
        local angle
        if isHalfCell then
            angle = -((i - 1) * ANGLE_PER_CELL + ANGLE_PER_QUARTER_CELL)
        else
            angle = -((i - 1) * ANGLE_PER_CELL + ANGLE_PER_HALF_CELL);
        end
        obj.transform.localEulerAngles = Vector3(0, 0, angle)
    end
    if hasHalfCell then
        local cellModel = self.view.halfCellNode
        local obj = CSUtils.CreateObject(cellModel.gameObject, cellModel.gameObject.transform.parent)
        local cell = Utils.wrapLuaNode(obj)
        cell.gameObject:SetActive(false)
        cell.glow.gameObject:SetActive(false)
        local angle = -((oldCount - 1) * ANGLE_PER_CELL + ANGLE_PER_QUARTER_CELL + ANGLE_PER_HALF_CELL)
        obj.transform.localEulerAngles = Vector3(0, 0, angle)
        table.insert(self.m_cells, cell)
    end
    local new = current - oldCount
    local newCount = math.ceil(current - oldCount)
    hasHalfCell = newCount - new > 0.1
    for i = 1, newCount do
        local cellModel
        local isHalfCell = hasHalfCell and i == newCount
        if isHalfCell then
            cellModel = self.view.halfCellNode
        else
            cellModel = self.view.fullCellNode
        end
        local obj = CSUtils.CreateObject(cellModel.gameObject, cellModel.gameObject.transform.parent)
        local cell = Utils.wrapLuaNode(obj)
        cell.gameObject:SetActive(false)
        cell.glow.gameObject:SetActive(false)
        local angle
        if isHalfCell then
            angle = -((i - 1 + oldCount) * ANGLE_PER_CELL + ANGLE_PER_QUARTER_CELL)
        else
            angle = -((i - 1 + oldCount) * ANGLE_PER_CELL + ANGLE_PER_HALF_CELL);
        end
        obj.transform.localEulerAngles = Vector3(0, 0, angle)
        table.insert(self.m_cells, cell)
    end
    self.view.halfCellNode.gameObject:SetActive(false)
    self.view.fullCellNode.gameObject:SetActive(false)
end
CharacterFootBarUpgradeCtrl.OnShow = HL.Override() << function(self)
    GameInstance.playerController.dashCountChangeAnimShowing = true
end
CharacterFootBarUpgradeCtrl.OnAnimationInFinished = HL.Override() << function(self)
    self.m_coroutine = coroutine.create(function()
        if #self.m_cells > 0 then
            for i, cell in ipairs(self.m_cells) do
                cell.gameObject:SetActive(true)
                AudioAdapter.PostEvent("au_ui_sprinting_upperlimit_improve")
                cell.anim:PlayInAnimation(function()
                    self:_ResumeCoroutine()
                end)
                coroutine.yield()
                if self.m_coroutine == nil then
                    return
                end
            end
            AudioAdapter.PostEvent("au_ui_sprinting_upperlimit_improve_shiny")
            for i, cell in ipairs(self.m_cells) do
                cell.glow.gameObject:SetActive(true)
                if i == 1 then
                    cell.anim:PlayOutAnimation(function()
                        self:_ResumeCoroutine()
                    end)
                else
                    cell.anim:PlayOutAnimation()
                end
            end
            coroutine.yield()
            if self.m_coroutine == nil then
                return
            end
        end
        self:PlayAnimationOutAndClose()
        Notify(MessageConst.ON_ONE_MAIN_HUD_TOAST_FINISH, "DashBarUpgrade")
    end)
    coroutine.resume(self.m_coroutine)
end
CharacterFootBarUpgradeCtrl._ResumeCoroutine = HL.Method() << function(self)
    if self.m_coroutine ~= nil then
        coroutine.resume(self.m_coroutine)
    end
end
CharacterFootBarUpgradeCtrl.OnDashCountMaxChanged = HL.StaticMethod() << function()
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    if isOpen then
        return
    end
    local old = GameInstance.playerController.lastShownMaxDashCount
    local current = GameInstance.playerController.maxDashCount
    if old >= current then
        return
    end
    LuaSystemManager.mainHudToastSystem:AddRequest("DashBarUpgrade", function()
        local old = GameInstance.playerController.lastShownMaxDashCount
        local current = GameInstance.playerController.maxDashCount
        GameInstance.playerController.lastShownMaxDashCount = current
        if old >= current then
            Notify(MessageConst.ON_ONE_MAIN_HUD_TOAST_FINISH, "DashBarUpgrade")
            return
        end
        UIManager:Open(PANEL_ID, { old, current })
    end)
end
CharacterFootBarUpgradeCtrl.InterruptMainHudToast = HL.Method() << function(self)
    self:Close()
end
CharacterFootBarUpgradeCtrl.OnClose = HL.Override() << function(self)
    self.m_coroutine = nil
    GameInstance.playerController.dashCountChangeAnimShowing = false
end
HL.Commit(CharacterFootBarUpgradeCtrl)