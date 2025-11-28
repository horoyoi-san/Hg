local LuaSystemBase = require_ex('LuaSystem/LuaSystemBase')
GachaSystem = HL.Class('GachaSystem', LuaSystemBase.LuaSystemBase)
GachaSystem.m_camCullingEnabled = HL.Field(HL.Boolean) << false
GachaSystem.m_camEnableSettingKeys = HL.Field(HL.Table)
GachaSystem.m_sunSourceLayer = HL.Field(HL.Any)
GachaSystem.m_curIVPath = HL.Field(HL.Any)
GachaSystem.GachaSystem = HL.Constructor() << function(self)
    self.m_camEnableSettingKeys = {}
end
GachaSystem.UpdateGachaSettingState = HL.Method() << function(self)
    if self:_IsInCharGacha() then
        self:_AutoUpdateGachaIV()
        self:ToggleGachaCamSetting("CalcByPhase", true)
    else
        self:_AutoUpdateGachaIV()
        self:ToggleGachaCamSetting("CalcByPhase", false)
    end
    self:UpdateGachaMusicState()
    self:_UpdateIsInGacha()
end
GachaSystem.UpdateGachaWeaponSettingState = HL.Method() << function(self)
    if self:_IsInWeaponGacha() then
        self:_AutoUpdateGachaIV()
        self:ToggleGachaCamSetting("CalcByPhase", true)
    else
        self:_AutoUpdateGachaIV()
        self:ToggleGachaCamSetting("CalcByPhase", false)
    end
    self:UpdateGachaMusicState()
    self:_UpdateIsInGacha()
end
local GachaPhaseIds = { PhaseId.GachaDropBin, PhaseId.GachaChar, PhaseId.GachaWeaponPreheat, PhaseId.GachaWeapon, PhaseId.GachaWeaponResult, PhaseId.GachaPool, PhaseId.GachaWeaponPool, }
GachaSystem._UpdateIsInGacha = HL.Method() << function(self)
    local inGacha = false
    for _, phaseId in pairs(GachaPhaseIds) do
        local isOpen, _ = PhaseManager:IsOpenAndValid(phaseId)
        if isOpen then
            inGacha = true
            break
        end
    end
    GameInstance.world.inGacha = inGacha
end
local GachaCharPhaseIds = { [PhaseId.GachaPool] = true, [PhaseId.GachaDropBin] = true, [PhaseId.GachaChar] = true, }
local GachaWeaponPhaseIds = { [PhaseId.GachaWeaponPool] = true, [PhaseId.GachaWeaponPreheat] = true, [PhaseId.GachaWeapon] = true, [PhaseId.GachaWeaponResult] = true, }
GachaSystem.UpdateGachaMusicState = HL.Method() << function(self)
    local topPhaseId = PhaseManager:GetTopPhaseId()
    if topPhaseId == PhaseId.GachaDropBin then
        GameInstance.audioManager.music:SetGachaState(true)
        AudioManager.PostEvent(UIConst.GACHA_MUSIC_DROP_BIN)
    elseif GachaCharPhaseIds[topPhaseId] or GachaWeaponPhaseIds[topPhaseId] then
        GameInstance.audioManager.music:SetGachaState(true)
        AudioManager.PostEvent(UIConst.GACHA_MUSIC_UI)
    else
        if PhaseManager:IsOpenAndValid(PhaseId.GachaPool) or PhaseManager:IsOpenAndValid(PhaseId.GachaChar) or PhaseManager:IsOpenAndValid(PhaseId.GachaWeaponPool) or PhaseManager:IsOpenAndValid(PhaseId.GachaWeaponResult) then
            GameInstance.audioManager.music:SetGachaState(true)
            AudioManager.PostEvent(UIConst.GACHA_MUSIC_UI)
        else
            GameInstance.audioManager.music:SetGachaState(false)
        end
    end
end
GachaSystem._IsInCharGacha = HL.Method(HL.Opt(HL.Number)).Return(HL.Boolean) << function(self, topPhaseId)
    topPhaseId = topPhaseId or PhaseManager:GetTopOpenAndValidPhaseId()
    return GachaCharPhaseIds[topPhaseId] == true
end
GachaSystem._IsInWeaponGacha = HL.Method(HL.Opt(HL.Number)).Return(HL.Boolean) << function(self, topPhaseId)
    topPhaseId = topPhaseId or PhaseManager:GetTopOpenAndValidPhaseId()
    return GachaWeaponPhaseIds[topPhaseId] == true
end
GachaSystem._AutoUpdateGachaIV = HL.Method() << function(self)
    local ivPath
    if self:_IsInCharGacha() then
        ivPath = "IrradianceVolume/gacha/character/index.bytes"
    elseif self:_IsInWeaponGacha() then
        ivPath = "IrradianceVolume/gacha/weapon/index.bytes"
    end
    if ivPath == self.m_curIVPath then
        return
    end
    self:SetGachaIV(ivPath)
end
GachaSystem.SetGachaIV = HL.Method(HL.Opt(HL.String)) << function(self, ivPath)
    if self.m_curIVPath == ivPath then
        return
    end
    local oldPath = self.m_curIVPath
    self.m_curIVPath = ivPath
    if oldPath ~= nil then
        CS.HG.Rendering.Runtime.HGManagerContext.currentManagerContext.ivManager:DestroyGachaIV()
        logger.info("GachaSystem.SetGachaIV DestroyGachaIV")
    end
    if ivPath then
        CS.HG.Rendering.Runtime.HGManagerContext.currentManagerContext.ivManager:CreateGachaIV(ivPath)
        logger.info("GachaSystem.SetGachaIV", ivPath)
    end
end
GachaSystem.ToggleGachaCamSetting = HL.Method(HL.String, HL.Boolean) << function(self, key, active)
    logger.info("ToggleGachaCamSetting", key, active)
    if active then
        self.m_camEnableSettingKeys[key] = true
    else
        self.m_camEnableSettingKeys[key] = nil
    end
    self:_UpdateGachaCamSettingEnabled()
end
GachaSystem._UpdateGachaCamSettingEnabled = HL.Method() << function(self)
    local active = next(self.m_camEnableSettingKeys) ~= nil
    if active then
        if not self.m_camCullingEnabled then
            self.m_camCullingEnabled = true
            CameraManager:AddMainCamCullingMaskConfig("Gacha", UIConst.LAYERS.Gacha)
            CameraManager:SetMainCameraVolumeLayerMask(UIConst.LAYERS.Gacha)
            CameraManager.mainCamera.useOcclusionCulling = false
            local light = CS.UnityEngine.Light.GetSunSourceLight()
            if light ~= nil then
                self.m_sunSourceLayer = light.gameObject.layer
                light.gameObject.layer = UIConst.GACHA_LAYER
                light.gameObject.gameObject:SetActive(false)
                light.gameObject.gameObject:SetActive(true)
            end
            CS.HG.Rendering.Runtime.VFXPPManager.instance:SetVFXXPPLayer(UIConst.GACHA_LAYER)
        end
    else
        if self.m_camCullingEnabled then
            CameraManager:RemoveMainCamCullingMaskConfig("Gacha")
            CameraManager:ResetMainCameraVolumeLayerMask()
            CameraManager.mainCamera.useOcclusionCulling = true
            local light = CS.UnityEngine.Light.GetSunSourceLight()
            if light ~= nil then
                light.gameObject.layer = self.m_sunSourceLayer
                light.gameObject.gameObject:SetActive(false)
                light.gameObject.gameObject:SetActive(true)
            end
            CS.HG.Rendering.Runtime.VFXPPManager.instance:ResetVFXXPPLayer(UIConst.GACHA_LAYER)
            self.m_camCullingEnabled = false
        end
    end
end
GachaSystem.PreloadDropBin = HL.Method() << function(self)
end
GachaSystem.GetDropBin = HL.Method() << function(self)
end
GachaSystem.DesDropBin = HL.Method() << function(self)
end
GachaSystem.OnRelease = HL.Override() << function(self)
    self:SetGachaIV()
    self.m_camEnableSettingKeys = {}
    self:_UpdateGachaCamSettingEnabled()
end
HL.Commit(GachaSystem)
return GachaSystem