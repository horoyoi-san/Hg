local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonWorldUI
local config = require_ex('UI/Panels/CommonWorldUI/CommonWorldUIConfig')
CommonWorldUICtrl = HL.Class('CommonWorldUICtrl', uiCtrl.UICtrl)
CommonWorldUICtrl.m_gameObjectPool = HL.Field(HL.Table)
CommonWorldUICtrl.m_showingGameObjects = HL.Field(HL.Table)
CommonWorldUICtrl.m_prefabCache = HL.Field(HL.Table)
CommonWorldUICtrl.s_messages = HL.StaticField(HL.Table) << {}
CommonWorldUICtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_gameObjectPool = {}
    self.m_showingGameObjects = {}
    self.m_prefabCache = {}
end
CommonWorldUICtrl.OnClose = HL.Override() << function(self)
    self.m_gameObjectPool = {}
    self.m_showingGameObjects = {}
    self.m_prefabCache = {}
end
CommonWorldUICtrl._OnAddWorldUI = HL.StaticMethod(HL.Table) << function(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    local entity, id, configKey = unpack(args)
    local config = config.CommonWorldUIConfig[configKey]
    if config == nil or config.path == nil then
        logger.error(ELogChannel.UI, "{0} Not Found,请检查或在CommonWorldUIConfig.lua中增加配置", configKey)
        return
    end
    local path = config.path
    local obj = self:_GetOrCreateGameObject(id, path)
    obj.gameObject:SetActiveIfNecessary(true)
    local comp = obj:GetComponent("WorldUIController")
    if comp ~= nil then
        comp:Init(entity, path)
    end
end
CommonWorldUICtrl._GetOrCreateGameObject = HL.Method(HL.String, HL.String).Return(HL.Any) << function(self, id, path)
    if self.m_showingGameObjects[id] == nil then
        self.m_showingGameObjects[id] = {}
    end
    if self.m_showingGameObjects[id][path] == nil then
        self.m_showingGameObjects[id][path] = self:_GetGameObject(path)
    end
    return self.m_showingGameObjects[id][path]
end
CommonWorldUICtrl._GetGameObject = HL.Method(HL.String).Return(HL.Any) << function(self, path)
    if self.m_gameObjectPool[path] ~= nil and #self.m_gameObjectPool[path] > 0 then
        local pool = self.m_gameObjectPool[path]
        local obj = pool[#pool]
        table.remove(pool, #pool)
        return obj
    end
    if self.m_prefabCache[path] == nil then
        self.m_prefabCache[path] = self:LoadGameObject(path)
    end
    local obj = self:_CreateWorldGameObject(self.m_prefabCache[path])
    return obj
end
CommonWorldUICtrl._OnRemoveWorldUI = HL.StaticMethod(HL.Table) << function(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    local id, path = unpack(args)
    if self.m_showingGameObjects[id] ~= nil then
        for key, obj in pairs(self.m_showingGameObjects[id]) do
            if path == nil or path == key then
                if self.m_gameObjectPool[key] == nil then
                    self.m_gameObjectPool[key] = {}
                end
                local pool = self.m_gameObjectPool[key]
                if #pool < self.view.config.POOL_CAPACITY then
                    obj.gameObject:SetActiveIfNecessary(false)
                    table.insert(pool, obj)
                else
                    GameObject.Destroy(obj)
                end
                self.m_showingGameObjects[id][key] = nil
            end
        end
    end
end
HL.Commit(CommonWorldUICtrl)