local EColor = CS.Beyond.Gameplay.EColor
local EPreBlockType = CS.Beyond.Gameplay.EPreBlockType
local HINT_TEXT_POOL = { "ui_msc_puzzle_hint_1", "ui_msc_puzzle_hint_2", "ui_msc_puzzle_hint_3", }
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Puzzle
PuzzleCtrl = HL.Class('PuzzleCtrl', uiCtrl.UICtrl)
PuzzleCtrl.m_cellSize = HL.Field(HL.Number) << -1
PuzzleCtrl.m_info = HL.Field(HL.Table)
PuzzleCtrl.m_spacing = HL.Field(HL.Number) << -1
PuzzleCtrl.m_puzzleGame = HL.Field(HL.Userdata)
PuzzleCtrl.m_chessboardWidthGridNum = HL.Field(HL.Number) << -1
PuzzleCtrl.m_chessboardHeightGridNum = HL.Field(HL.Number) << -1
PuzzleCtrl.m_chessboardGridCells = HL.Field(HL.Forward("UIListCache"))
PuzzleCtrl.m_chessboardRawData = HL.Field(HL.Userdata)
PuzzleCtrl.m_gridsData = HL.Field(HL.Table)
PuzzleCtrl.m_rowConditions = HL.Field(HL.Table)
PuzzleCtrl.m_chessboardRowConditionCells = HL.Field(HL.Forward("UIListCache"))
PuzzleCtrl.m_columnConditions = HL.Field(HL.Table)
PuzzleCtrl.m_chessboardColumnConditionCells = HL.Field(HL.Forward("UIListCache"))
PuzzleCtrl.m_attachPuzzleData = HL.Field(HL.Table)
PuzzleCtrl.m_puzzleRootCells = HL.Field(HL.Forward("UIListCache"))
PuzzleCtrl.m_puzzleBlockShadowCells = HL.Field(HL.Forward("UIListCache"))
PuzzleCtrl.m_id2BlockShadowIndex = HL.Field(HL.Table)
PuzzleCtrl.m_chessboardLock = HL.Field(HL.Boolean) << false
PuzzleCtrl.m_puzzleCanvasGroups = HL.Field(HL.Table)
PuzzleCtrl.m_totalPuzzlesNum = HL.Field(HL.Number) << -1
PuzzleCtrl.m_placeholderCellCache = HL.Field(HL.Forward("UIListCache"))
PuzzleCtrl.m_playerNotHoldBlocks = HL.Field(HL.Table)
PuzzleCtrl.m_curActionBlockId = HL.Field(HL.String) << ""
PuzzleCtrl.m_curActionBlockSlot = HL.Field(HL.Forward("PuzzleSlot"))
PuzzleCtrl.m_cachedGridVec = HL.Field(HL.Table)
PuzzleCtrl.m_cachedGridPos = HL.Field(Vector3)
PuzzleCtrl.m_refAnswerGridCellCache = HL.Field(HL.Forward("UIListCache"))
PuzzleCtrl.m_noActionNoticeThreshold = HL.Field(HL.Number) << -1
PuzzleCtrl.m_noActionNoticeTimerId = HL.Field(HL.Number) << -1
PuzzleCtrl.m_stayNoticeThreshold = HL.Field(HL.Number) << -1
PuzzleCtrl.m_stayNoticeTimerId = HL.Field(HL.Number) << -1
PuzzleCtrl.m_conditionStyleRectangle = HL.Field(HL.Boolean) << true
PuzzleCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.PUZZLE_UNIT_COMPLETE] = 'PuzzleUnitComplete', }
PuzzleCtrl.OpenPuzzlePanel = HL.StaticMethod(HL.Table) << function(args)
    local callback = unpack(args)
    local finalArgs = {}
    finalArgs.callback = callback
    PhaseManager:OpenPhase(PhaseId.Puzzle, finalArgs)
end
PuzzleCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_info = args
    self.view.btnClose.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self.view.resetBtn.onClick:AddListener(function()
        self:_OnClickReset()
    end)
    self.view.noticeBtn.onClick:AddListener(function()
        self:_OnClickNoticeBtn()
    end)
    self.view.btnClick.onClick:AddListener(function()
        self:_OnClickNextBtn()
    end)
    self.view.conditionStyleToggle:InitCommonToggle(function(isOn)
        self:_OnConditionStyleToggleChange(isOn)
    end, true, true)
    local curEndminCharTemplateId = CS.Beyond.Gameplay.CharUtils.curEndminCharTemplateId
    self.view.charIcon:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD_RECTANGLE, UIConst.UI_CHAR_HEAD_SQUARE_PREFIX .. curEndminCharTemplateId)
    self.view.nameTxt.text = string.isEmpty(args.title) and Language["lang_fixable_props_mat_universal"] or args.title
    self.m_chessboardGridCells = UIUtils.genCellCache(self.view.chessboardGrid)
    self.m_chessboardRowConditionCells = UIUtils.genCellCache(self.view.rowConditionItem)
    self.m_chessboardColumnConditionCells = UIUtils.genCellCache(self.view.columnConditionItem)
    self.m_placeholderCellCache = UIUtils.genCellCache(self.view.placeholderItem)
    self.m_puzzleRootCells = UIUtils.genCellCache(self.view.puzzleSlot)
    self.m_puzzleBlockShadowCells = UIUtils.genCellCache(self.view.puzzleBlockShadow)
    self.m_refAnswerGridCellCache = UIUtils.genCellCache(self.view.refAnswerGridCell)
    self.m_puzzleGame = GameInstance.player.miniGame.puzzleGame
    self.m_totalPuzzlesNum = self.m_puzzleGame.levelNum
    self.m_cellSize = self.view.gridLayout.cellSize.x
    self.m_spacing = self.view.gridLayout.spacing.x
    self:_UpdateProgress()
    self.m_puzzleGame.onChessboardStateChange:AddListener(function()
        self:_UpdateRow()
        self:_UpdateColumn()
    end)
    self.m_puzzleGame.onBlockStateChange:AddListener(function()
        self:_UpdateResetBtn()
    end)
    self:BindInputPlayerAction("mini_game_block_rotate", function()
        self:RotateCurActionBlock(false)
    end)
    self:BindInputPlayerAction("mini_game_block_rotate_mouse", function()
        self:RotateCurActionBlock(true)
    end)
end
PuzzleCtrl.OnClose = HL.Override() << function(self)
    GameInstance.player.miniGame.puzzleGame:Clear()
    self.m_puzzleGame.onChessboardStateChange:RemoveAllListeners()
    self.m_puzzleGame.onBlockStateChange:RemoveAllListeners()
end
PuzzleCtrl._Refresh = HL.Method() << function(self)
    self.m_gridsData = self:_ProcessGridsData()
    self.m_chessboardGridCells:Refresh(#self.m_gridsData, function(cell, index)
        self:_UpdateChessboardGrid(cell, index)
    end)
    self.m_refAnswerGridCellCache:Refresh(#self.m_gridsData, function(cell, index)
        self:_UpdateRefAnswerGridCell(cell, index)
    end)
    self.m_rowConditions = self:_ProcessConditions(true)
    self.m_chessboardRowConditionCells:Refresh(#self.m_rowConditions, function(cell, index)
        self:_UpdateChessboardRowCondition(cell, index)
    end)
    self.m_columnConditions = self:_ProcessConditions(false)
    self.m_chessboardColumnConditionCells:Refresh(#self.m_columnConditions, function(cell, index)
        self:_UpdateChessboardColumnCondition(cell, index)
    end)
    self.m_attachPuzzleData, self.m_playerNotHoldBlocks = self:_ProcessAttachBlockData()
    self.m_placeholderCellCache:Refresh(#self.m_attachPuzzleData, function(cell, index)
        self:_UpdatePlaceholderCell(cell, index)
    end)
    self.m_id2BlockShadowIndex = {}
    self.m_puzzleBlockShadowCells:Refresh(#self.m_attachPuzzleData, function(cell, index)
        self:_UpdatePuzzleBlockShadow(cell, index)
    end)
    self.m_puzzleCanvasGroups = {}
    self.m_puzzleRootCells:Refresh(#self.m_attachPuzzleData, function(cell, index)
        self:_UpdatePuzzleCell(cell, index)
    end)
    self.view.cantPlayTips.gameObject:SetActiveIfNecessary(self.m_chessboardLock)
    self.view.selectHighlight.gameObject:SetActiveIfNecessary(false)
    local contentRect = self.view.placeHolderScrollView.content
    local viewportRect = self.view.placeHolderScrollView.viewport
    self.view.placeHolderScrollView.vertical = contentRect.sizeDelta.y > viewportRect.sizeDelta.y
end
PuzzleCtrl._UpdateNoticeTimer = HL.Method() << function(self)
    self.view.refAnswerGrid.gameObject:SetActiveIfNecessary(false)
    self.view.noticeNode.gameObject:SetActiveIfNecessary(false)
    if self.m_chessboardLock then
        return
    end
    self.m_stayNoticeTimerId = self:_ClearTimer(self.m_stayNoticeTimerId)
    self.m_stayNoticeTimerId = self:_StartTimer(self.m_stayNoticeThreshold, function()
        self:_ShowNoticeEntry()
    end)
    self:UpdateNoActionNoticeTimer()
end
PuzzleCtrl._ShowNoticeEntry = HL.Method() << function(self)
    self:_ClearNoticeTimer()
    self.view.noticeNode.gameObject:SetActiveIfNecessary(true)
    self.view.noticeNode:SetState("hint")
    local hintKey = lume.randomchoice(HINT_TEXT_POOL)
    self.view.tipsTxt.text = Language[hintKey]
    AudioAdapter.PostEvent("Au_UI_Event_Piece_Notice")
end
PuzzleCtrl._ClearNoticeTimer = HL.Method() << function(self)
    self.m_stayNoticeTimerId = self:_ClearTimer(self.m_stayNoticeTimerId)
    self.m_noActionNoticeTimerId = self:_ClearTimer(self.m_noActionNoticeTimerId)
end
PuzzleCtrl._OnClickReset = HL.Method() << function(self)
    self:Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_PUZZLE_RESET_CONFIRM_DESC,
        onConfirm = function()
            self.m_puzzleGame:ResetCurChessboard()
            self:_Refresh()
            self:_UpdateResetBtn()
            self:_UpdateNoticeTimer()
        end,
    })
    self:UpdateNoActionNoticeTimer()
end
PuzzleCtrl._OnClickNoticeBtn = HL.Method() << function(self)
    self.view.refAnswerGrid.gameObject:SetActiveIfNecessary(true)
    self.view.noticeNode:SetState("no_hint")
    AudioAdapter.PostEvent("Au_UI_Event_Piece_Hint")
end
PuzzleCtrl._OnClickNextBtn = HL.Method() << function(self)
    local wrapper = self.view.chessboardAnimationWrapper
    wrapper:Play("puzzle_notice_completetips_out", function()
        if self.m_puzzleGame:IsPuzzleComplete() then
            AudioAdapter.PostEvent("Au_UI_Event_Piece_Finish")
            wrapper:Play("puzzle_unlock_complete", function()
                self:_OnClickGameSucc()
            end)
        else
            wrapper:Play("puzzle_chessboard_out", function()
                AudioAdapter.PostEvent("Au_UI_Event_Piece_Refresh")
                self.m_puzzleGame:NextPuzzle()
                self:_UpdateProgress()
                wrapper:Play("puzzle_chessboard_in")
                self:_ToggleComponentInput(true)
            end)
        end
    end)
end
PuzzleCtrl._OnClickClose = HL.Method() << function(self)
    if self.m_chessboardLock then
        self:_DoExitGame()
    else
        self:Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_PUZZLE_EXIT_CONFIRM_DESC,
            onConfirm = function()
                self:_DoExitGame()
            end
        })
    end
end
PuzzleCtrl._DoExitGame = HL.Method() << function(self)
    GameInstance.player.miniGame.puzzleGame:ExitGame()
    PhaseManager:PopPhase(PhaseId.Puzzle)
    if self.m_info ~= nil and self.m_info.callback ~= nil then
        self.m_info.callback(false)
        self.m_info = nil
    end
end
PuzzleCtrl._OnClickGameSucc = HL.Method() << function(self)
    PhaseManager:PopPhase(PhaseId.Puzzle)
    if self.m_info ~= nil and self.m_info.callback ~= nil then
        self.m_info.callback(true)
        self.m_info = nil
    end
end
PuzzleCtrl._UpdateChessboardGrid = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local gridData = self.m_gridsData[index]
    cell:InitPuzzleChessboardGrid(gridData, function()
        self.m_puzzleGame:PutBlockOnChessboard(self.m_curActionBlockId, CSIndex(gridData.x), CSIndex(gridData.y), cell.transform.position)
    end, function()
        self.m_cachedGridVec = gridData
        self.m_cachedGridPos = cell.transform.position
        self:_OnSlotEnterChessboardGrid()
    end, function()
        self:ResetCachedGridData()
        self:_OnSlotOutChessboardGrid()
    end)
end
PuzzleCtrl._UpdateRefAnswerGridCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local gridData = self.m_gridsData[index]
    local refAnswerGrids = self.m_puzzleGame.currentChessboard.refAnswerGrids
    local refAnswerGrid = refAnswerGrids[CSIndex(gridData.x)][CSIndex(gridData.y)]
    local color = UIUtils.getPuzzleColorByColorType(refAnswerGrid.color)
    local colorTrans = Color(color.a, color.g, color.b, cell.grid.color.a)
    cell.grid.gameObject:SetActiveIfNecessary(refAnswerGrid.needNotice)
    cell.upLine.gameObject:SetActiveIfNecessary(refAnswerGrid.upLine)
    cell.downLine.gameObject:SetActiveIfNecessary(refAnswerGrid.downLine)
    cell.leftLine.gameObject:SetActiveIfNecessary(refAnswerGrid.leftLine)
    cell.rightLine.gameObject:SetActiveIfNecessary(refAnswerGrid.rightLine)
    cell.upRightDrop.gameObject:SetActiveIfNecessary(refAnswerGrid.upRightDrop)
    cell.upLeftDrop.gameObject:SetActiveIfNecessary(refAnswerGrid.upLeftDrop)
    cell.downRightDrop.gameObject:SetActiveIfNecessary(refAnswerGrid.downRightDrop)
    cell.downLeftDrop.gameObject:SetActiveIfNecessary(refAnswerGrid.downLeftDrop)
    if refAnswerGrid.needNotice then
        cell.lineNode.color = color
        cell.grid.color = colorTrans
    end
end
PuzzleCtrl._OnSlotEnterChessboardGrid = HL.Method() << function(self)
    if not self.m_cachedGridVec or not self.m_cachedGridPos then
        return
    end
    if not self.m_curActionBlockSlot or not self.m_curActionBlockSlot:IsStateDragging() then
        return
    end
    local index = self.m_id2BlockShadowIndex[self.m_curActionBlockId]
    local shadowCell = self.m_puzzleBlockShadowCells:GetItem(index)
    shadowCell:SetVisible(true)
    shadowCell:SetPosition(self.m_cachedGridPos)
    if self.m_puzzleGame:CheckBlockOnChessboardLegal(self.m_curActionBlockId, CSIndex(self.m_cachedGridVec.x), CSIndex(self.m_cachedGridVec.y)) then
        shadowCell:SetLegal(true)
        AudioAdapter.PostEvent("Au_UI_Event_Piece_Correct")
    else
        shadowCell:SetLegal(false)
        AudioAdapter.PostEvent("Au_UI_Event_Piece_Warning")
    end
end
PuzzleCtrl._OnSlotOutChessboardGrid = HL.Method() << function(self)
    if not self.m_curActionBlockSlot or not self.m_curActionBlockSlot:IsStateDragging() then
        return
    end
    self:SetShadowCellVisibleById(self.m_curActionBlockId, false)
end
PuzzleCtrl.SetShadowCellVisibleById = HL.Method(HL.String, HL.Boolean) << function(self, blockId, visible)
    local index = self.m_id2BlockShadowIndex[blockId]
    local shadowCell = self.m_puzzleBlockShadowCells:GetItem(index)
    shadowCell:SetVisible(visible)
end
PuzzleCtrl.RotateShadowById = HL.Method(HL.String) << function(self, blockId)
    local index = self.m_id2BlockShadowIndex[blockId]
    local shadowCell = self.m_puzzleBlockShadowCells:GetItem(index)
    local block = self.m_puzzleGame.currentChessboard.blocks:get_Item(blockId)
    shadowCell:Rotate(block.rotateCount)
end
PuzzleCtrl._ProcessGridsData = HL.Method().Return(HL.Table) << function(self)
    local tbl = {}
    for j = 1, self.m_chessboardHeightGridNum do
        for i = 1, self.m_chessboardWidthGridNum do
            table.insert(tbl, { x = i, y = j, state = EColor.Clear })
        end
    end
    for i = 0, self.m_chessboardRawData.bannedGrids.Count - 1 do
        local vec = self.m_chessboardRawData.bannedGrids[i]
        local index = (LuaIndex(vec.y) - 1) * self.m_chessboardWidthGridNum + LuaIndex(vec.x)
        tbl[index].state = EColor.Banned
    end
    for k, v in pairs(self.m_chessboardRawData.preGrids) do
        for i = 0, v.Count - 1 do
            local vec = v[i]
            local index = (LuaIndex(vec.y) - 1) * self.m_chessboardWidthGridNum + LuaIndex(vec.x)
            tbl[index].state = k
        end
    end
    return tbl
end
PuzzleCtrl._ProcessConditions = HL.Method(HL.Boolean).Return(HL.Table) << function(self, isRow)
    local resultConditions = {}
    local rawConditionsDic = isRow and self.m_chessboardRawData.rowCondition or self.m_chessboardRawData.columnCondition
    for eColor, rawConditions in pairs(rawConditionsDic) do
        local _, state
        if isRow then
            _, state = self.m_puzzleGame.currentChessboard.rowState:TryGetValue(eColor)
        else
            _, state = self.m_puzzleGame.currentChessboard.columnState:TryGetValue(eColor)
        end
        for i = 0, rawConditions.Length - 1 do
            local luaIndex = LuaIndex(i)
            if not resultConditions[luaIndex] then
                resultConditions[luaIndex] = {}
            end
            if not resultConditions[luaIndex][eColor] then
                resultConditions[luaIndex][eColor] = {}
                resultConditions[luaIndex][eColor].conditions = {}
            end
            resultConditions[luaIndex][eColor].stateCount = state[i]
            resultConditions[luaIndex][eColor].rawCount = rawConditions[i]
            local overflow = state[i] < 0
            local diffCount = overflow and state[i] or 0
            for j = 1, rawConditions[i] - diffCount do
                if overflow then
                    resultConditions[luaIndex][eColor].overflow = true
                    table.insert(resultConditions[luaIndex][eColor].conditions, { overflow = j > rawConditions[i], done = j <= rawConditions[i] })
                else
                    table.insert(resultConditions[luaIndex][eColor].conditions, { done = rawConditions[i] - state[i] >= j, overflow = false })
                end
            end
        end
    end
    return resultConditions
end
PuzzleCtrl._UpdateChessboardRowCondition = HL.Method(HL.Any, HL.Int) << function(self, cell, index)
    cell:InitPuzzleChessboardConditionItem(self.m_rowConditions[index], self.m_cellSize, self.m_spacing, self.m_chessboardWidthGridNum, true, self.m_conditionStyleRectangle)
end
PuzzleCtrl._UpdateRow = HL.Method() << function(self)
    self.m_rowConditions = self:_ProcessConditions(true)
    self.m_chessboardRowConditionCells:Update(function(cell, index)
        cell:InitPuzzleChessboardConditionItem(self.m_rowConditions[index], self.m_cellSize, self.m_spacing, self.m_chessboardWidthGridNum, true, self.m_conditionStyleRectangle)
    end)
end
PuzzleCtrl._UpdateChessboardColumnCondition = HL.Method(HL.Any, HL.Int) << function(self, cell, index)
    cell:InitPuzzleChessboardConditionItem(self.m_columnConditions[index], self.m_cellSize, self.m_spacing, self.m_chessboardHeightGridNum, false, self.m_conditionStyleRectangle)
end
PuzzleCtrl._UpdateColumn = HL.Method() << function(self)
    self.m_columnConditions = self:_ProcessConditions(false)
    self.m_chessboardColumnConditionCells:Update(function(cell, index)
        cell:InitPuzzleChessboardConditionItem(self.m_columnConditions[index], self.m_cellSize, self.m_spacing, self.m_chessboardHeightGridNum, false, self.m_conditionStyleRectangle)
    end)
end
PuzzleCtrl._OnConditionStyleToggleChange = HL.Method(HL.Boolean) << function(self, rectangle)
    self.m_conditionStyleRectangle = rectangle
    for _, rowCell in ipairs(self.m_chessboardRowConditionCells.m_items) do
        rowCell:Toggle(rectangle)
    end
    for _, columnCell in ipairs(self.m_chessboardColumnConditionCells.m_items) do
        columnCell:Toggle(rectangle)
    end
end
PuzzleCtrl._UpdateResetBtn = HL.Method() << function(self)
    local dirty = self.m_puzzleGame:IsPuzzleDirty()
    self.view.resetBtn.interactable = dirty
end
PuzzleCtrl._ProcessAttachBlockData = HL.Method().Return(HL.Table, HL.Table) << function(self)
    local attachBlocks = {}
    local playerNotHoldBlocks = {}
    local blocks = self.m_puzzleGame.currentChessboard.blocks
    local playerNotHolderKeys = {}
    for k, v in pairs(blocks) do
        local rawData = v.rawData
        local playerHold = v.blockSource == EPreBlockType.SystemAssign
        if not playerHold then
            local hasConfig, _ = Tables.itemTable:TryGetValue(rawData.blockID)
            if not hasConfig then
                logger.error(ELogChannel.MiniGame, string.format("存在未配置到物品表的拼块，blockID:%s", rawData.blockID))
                return attachBlocks, playerNotHoldBlocks
            end
            playerHold = v.blockSource == EPreBlockType.PlayerCollection and hasConfig and Utils.getItemCount(rawData.blockID) > 0
        end
        if playerHold or (not playerHold and not lume.find(playerNotHolderKeys, rawData.blockID)) then
            local blockUnit = {}
            blockUnit.id = k
            blockUnit.color = v.color
            blockUnit.sortId = v.sortId
            blockUnit.playerHold = playerHold
            blockUnit.playerHoldSortId = playerHold and 0 or 1
            blockUnit.resPath = rawData.resName
            blockUnit.originBlocks = rawData.originBlocks
            blockUnit.rawId = rawData.blockID
            blockUnit.rawRotationCount = v.rawRotationCount
            table.insert(attachBlocks, blockUnit)
            if not playerHold then
                self.m_chessboardLock = true
                table.insert(playerNotHolderKeys, rawData.blockID)
                table.insert(playerNotHoldBlocks, blockUnit)
            end
        end
    end
    table.sort(attachBlocks, Utils.genSortFunction({ "playerHoldSortId", "sortId" }))
    return attachBlocks, playerNotHoldBlocks
end
PuzzleCtrl._UpdatePlaceholderCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local data = self.m_attachPuzzleData[index]
    cell.locked.gameObject:SetActiveIfNecessary(not data.playerHold)
    if not data.playerHold then
        cell.iconGray:LoadSprite(UIConst.UI_SPRITE_MINIGAME_BLOCK, data.resPath .. UIConst.UI_MINIGAME_PUZZLE_GREY_BLOCK_SUFFIX)
        cell.lockedBtn.onClick:RemoveAllListeners()
        cell.lockedBtn.onClick:AddListener(function()
            PhaseManager:OpenPhase(PhaseId.PuzzleTrackPopup, { blocks = self.m_playerNotHoldBlocks, selectBlockId = data.rawId })
        end)
    end
end
PuzzleCtrl._UpdatePuzzleCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local data = self.m_attachPuzzleData[index]
    local placeholderCell = self.m_placeholderCellCache:GetItem(index)
    table.insert(self.m_puzzleCanvasGroups, cell.view.canvasGroup)
    cell:InitPuzzleSlot(data, self.m_cellSize, index, self, placeholderCell, self.m_chessboardLock)
    cell.gameObject:SetActiveIfNecessary(data.playerHold)
end
PuzzleCtrl._UpdatePuzzleBlockShadow = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local data = self.m_attachPuzzleData[index]
    cell:InitPuzzleBlockShadow(data)
    self.m_id2BlockShadowIndex[data.id] = index
end
PuzzleCtrl._UpdateProgress = HL.Method() << function(self)
    self.m_gridsData = {}
    self.m_rowConditions = {}
    self.m_columnConditions = {}
    self:ClearCurActionBlock()
    self:ResetCachedGridData()
    local chessboardData = self.m_puzzleGame.currentChessboard.rawData
    local width = (self.m_cellSize + self.m_spacing) * chessboardData.sizeX
    local height = (self.m_cellSize + self.m_spacing) * chessboardData.sizeY
    self.m_chessboardRawData = chessboardData
    self.m_chessboardWidthGridNum = chessboardData.sizeX
    self.m_chessboardHeightGridNum = chessboardData.sizeY
    self.m_noActionNoticeThreshold = chessboardData.noActionNoticeThreshold
    self.m_stayNoticeThreshold = chessboardData.stayNoticeThreshold
    self.view.chessboard.sizeDelta = Vector2(width, height)
    self.view.progressTxt.text = string.format(Language.LUA_PUZZLE_PANEL_PROGRESS_FORMAT, LuaIndex(self.m_puzzleGame.currentIndex), self.m_totalPuzzlesNum)
    self.view.cantPlayTips.gameObject:SetActiveIfNecessary(false)
    self.view.completeTips.gameObject:SetActiveIfNecessary(false)
    self.view.resetBtn.interactable = false
    self:_Refresh()
    self:_UpdateNoticeTimer()
end
PuzzleCtrl._ToggleComponentInput = HL.Method(HL.Boolean) << function(self, isOn)
    self.view.btnClose.enabled = isOn
    self.view.conditionStyleToggle.view.toggle.enabled = isOn
end
PuzzleCtrl.UpdateNoActionNoticeTimer = HL.Method() << function(self)
    self.m_noActionNoticeTimerId = self:_ClearTimer(self.m_noActionNoticeTimerId)
    self.m_noActionNoticeTimerId = self:_StartTimer(self.m_noActionNoticeThreshold, function()
        self:_ShowNoticeEntry()
    end)
end
PuzzleCtrl.PuzzleUnitComplete = HL.Method(HL.Any) << function(self)
    self:_ClearNoticeTimer()
    self:_ToggleComponentInput(false)
    self.view.btnClick.interactable = false
    local wrapper = self.view.chessboardAnimationWrapper
    wrapper:Play("puzzle_notice_completetips_in", function()
        self.view.btnClick.interactable = true
    end)
    AudioAdapter.PostEvent("Au_UI_Event_Piece_Success")
end
PuzzleCtrl.SetBlockOutScrollRect = HL.Method(Transform) << function(self, trans)
    trans:SetParent(self.view.outBlockArea)
end
PuzzleCtrl.SetOtherGraphicRaycasts = HL.Method(HL.Boolean) << function(self, on)
    for _, v in pairs(self.m_puzzleCanvasGroups) do
        v.blocksRaycasts = on
    end
end
PuzzleCtrl.SetChessboardGirdsHighlight = HL.Method(HL.Boolean) << function(self, isOn)
    local grids = self.m_chessboardGridCells:GetItems()
    for _, grid in pairs(grids) do
        grid:SetHighlight(isOn)
    end
end
PuzzleCtrl.SetOtherBlocksFading = HL.Method(HL.String, HL.Boolean) << function(self, blockId, isOn)
    local slots = self.m_puzzleRootCells:GetItems()
    for _, slot in pairs(slots) do
        slot:SetBlockFading(blockId, isOn)
    end
end
PuzzleCtrl.SetCurActionBlock = HL.Method(HL.String, HL.Forward("PuzzleSlot")) << function(self, blockId, slot)
    if self.m_curActionBlockId == blockId then
        return
    end
    local preActionBlockId = self.m_curActionBlockId
    local preActionBlockSlot = self.m_curActionBlockSlot
    self.m_curActionBlockId = blockId
    self.m_curActionBlockSlot = slot
    self.view.selectHighlight.gameObject:SetActiveIfNecessary(true)
    for _, slotShadow in ipairs(self.m_puzzleBlockShadowCells:GetItems()) do
        slotShadow:SetVisible(false)
    end
    if string.isEmpty(preActionBlockId) then
        return
    end
    preActionBlockSlot:ResetState()
    local preBlockData = self.m_puzzleGame.currentChessboard.blocks:get_Item(preActionBlockId)
    if preBlockData.locationOnChessboard and preBlockData.isIllegalLocate then
        local succ, _ = self.m_puzzleGame:PutBlockOnChessboard(preActionBlockId, preBlockData.location.x, preBlockData.location.y, preBlockData.forceLocation)
        if succ then
        else
            preActionBlockSlot:ResetToPlaceholder()
        end
    end
end
PuzzleCtrl.ClearCurActionBlock = HL.Method() << function(self)
    self.m_curActionBlockId = ""
    self.m_curActionBlockSlot = nil
    self.view.selectHighlight.gameObject:SetActiveIfNecessary(false)
end
PuzzleCtrl.RotateCurActionBlock = HL.Method(HL.Boolean) << function(self, isMouseClick)
    if self.m_curActionBlockSlot and (isMouseClick and self.m_curActionBlockSlot:IsStateDragging() or not isMouseClick) then
        self.m_curActionBlockSlot:Rotate(self.m_curActionBlockId)
        self:_OnSlotEnterChessboardGrid()
    end
end
PuzzleCtrl.ResetCachedGridData = HL.Method() << function(self)
    self.m_cachedGridVec = nil
    self.m_cachedGridPos = nil
end
HL.Commit(PuzzleCtrl)