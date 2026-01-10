using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using StardustUtils;
using static Campofinale.Resource.ResourceManager;
using static Campofinale.Resource.ResourceManager.LevelScene.LevelData;

namespace Campofinale.Game.Entities
{
    public class EntityInteractive : Entity
    {
        public string templateId;
        public Dictionary<InteractiveComponentType, List<ParamKeyValue>> componentProperties = new();
        public EntityInteractive()
        {

        }

        public EntityInteractive(string templateId, ulong worldOwner, Vector3f pos, Vector3f rot, int scene, ulong g = 0)
        {
            if (g == 0)
            {
                this.guid = (ulong)new Random().NextInt64();
            }
            else
            {
                this.guid = g;
            }
            this.level = 1;
            this.worldOwner = worldOwner;
            this.Position = pos;
            this.Rotation = rot;
            this.BornPos = pos;
            this.BornRot = rot;
            this.templateId = templateId;
            this.sceneNumId = scene;

        }

        public void InitDefaultProperties()
        {
            InteractiveData data = ResourceManager.interactiveData.Find(i => i.id == templateId);
            if (data != null)
            {
                properties.AddRange(data.saveProperties);
            }
        }
        public void SetPropValue(uint val, string key)
        {
            ParamKeyValue keyValue = properties.Find(p => p.key == key);
            if (keyValue != null)
            {
                keyValue.value.valueArray[0].valueBit64 = val;
            }
        }
        public SceneInteractive ToProto()
        {

            SceneInteractive proto = new SceneInteractive()
            {
                CommonInfo = new()
                {
                    Hp = 1,

                    Id = guid,
                    Templateid = templateId,
                    BelongLevelScriptId = belongLevelScriptId,

                    SceneNumId = sceneNumId,
                    Position = Position.ToProto(),
                    Rotation = Rotation.ToProto(),

                    Type = (int)5,
                },

                //Meta =dependencyGroupId,
                BattleInfo = new()
                {

                },
                Properties =
                {

                }

            };

            foreach (var prop in properties)
            {
                DynamicParameter p = prop.ToProto();
                // Root-level properties: isComponentProperty = false
                (bool, int) index = GetPropertyIndex(prop.key, proto.Properties.Keys.Count > 0 ? proto.Properties.Keys.Max() : 0, isComponentProperty: false);
                if (p != null && index.Item1)
                {
                    proto.Properties[index.Item2] = p;

                }

            }
            foreach (var comp in componentProperties)
            {
                foreach (var prop in comp.Value)
                {
                    DynamicParameter p = prop.ToProto();
                    // Component properties: isComponentProperty = true (suppresses warnings for missing keys)
                    (bool, int) index = GetPropertyIndex(prop.key, proto.Properties.Keys.Count > 0 ? proto.Properties.Keys.Max() : 0, isComponentProperty: true);
                    if (p != null && index.Item1)
                    {
                        // Ensure component properties override or extend without throwing duplicate key errors.
                        proto.Properties[index.Item2] = p;

                    }
                }
            }


            return proto;
        }

        /// <summary>
        /// Get property index from propertyKeyToIdMap.
        /// Component properties that are not in the root-level propertyKeyToIdMap will be silently skipped
        /// (they are component-internal and don't need to be sent to client).
        /// </summary>
        /// <param name="key">Property key to look up</param>
        /// <param name="maxCur">Current max property index (used as fallback if key not found)</param>
        /// <param name="isComponentProperty">Whether this property comes from componentProperties (used to suppress warnings)</param>
        /// <returns>Tuple (found, index): found=true if key exists in map, index=propertyId if found, otherwise maxCur+1</returns>
        public (bool, int) GetPropertyIndex(string key, int maxCur, bool isComponentProperty = false)
        {
            try
            {
                // Get original template ID from interactiveTable
                if (!ResourceManager.interactiveTable.interactiveDataDict.TryGetValue(templateId, out var interactiveTableEntry))
                {
                    Logger.PrintWarn($"[EntityInteractive.GetPropertyIndex] TemplateId '{templateId}' not found in interactiveTable.interactiveDataDict");
                    return (false, maxCur + 1);
                }

                string oriTemplateId = interactiveTableEntry.templateId;
                InteractiveData data = ResourceManager.interactiveData.Find(i => i.id == oriTemplateId);

                if (data != null && data.propertyKeyToIdMap != null)
                {
                    // Use TryGetValue to avoid KeyNotFoundException
                    if (data.propertyKeyToIdMap.TryGetValue(key, out int propertyId))
                    {
                        return (true, propertyId);
                    }
                    else
                    {
                        // Property key not found in map - this is expected for component properties
                        // Component properties are often component-internal and don't need to be sent to client
                        // Only log warnings for root-level properties, not component properties
                        if (!isComponentProperty)
                        {
                            Logger.PrintWarn($"[EntityInteractive.GetPropertyIndex] Property key '{key}' not found in propertyKeyToIdMap for templateId '{templateId}' (oriTemplateId='{oriTemplateId}')");
                        }
                        return (false, maxCur + 1);
                    }
                }
                else
                {
                    Logger.PrintWarn($"[EntityInteractive.GetPropertyIndex] InteractiveData not found for oriTemplateId '{oriTemplateId}' (templateId='{templateId}')");
                    return (false, maxCur + 1);
                }
            }
            catch (Exception ex)
            {
                Logger.PrintError($"[EntityInteractive.GetPropertyIndex] Exception for templateId='{templateId}', key='{key}': {ex.Message}");
                Logger.PrintError($"[EntityInteractive.GetPropertyIndex] Stack trace: {ex.StackTrace}");
                return (false, maxCur + 1);
            }
        }
        public override void Damage(double dmg)
        {

        }
        public override bool Interact(string eventName, Google.Protobuf.Collections.MapField<string, DynamicParameter> props)
        {

            if (eventName == "open_chest")
            {
                ScSceneUpdateInteractiveProperty update = new()
                {
                    Id = guid,
                    SceneNumId = GetOwner().curSceneNumId,
                    Properties =
                    {
                        {4, new DynamicParameter()
                        {
                            RealType=3,
                            ValueType=3,
                            ValueIntList={1}
                        } }
                    }
                };

                GetOwner().Send(ScMsgId.ScSceneUpdateInteractiveProperty, update);
                GetOwner().inventoryManager.AddRewards(properties.Find(p => p.key == "reward_id").value.valueArray[0].valueString, Position, 1);
                GetOwner().sceneManager.KillEntity(guid, true, 1);
                GetOwner().noSpawnAnymore.Add(guid);
                GetOwner().sceneManager.GetScene(sceneNumId).AddCollection("int_trchest_common", 1);
                GetOwner().Send(new PacketScSceneCollectionSync(GetOwner()));
                return true;
            }
            else if (eventName == "pick_inst")
            {
                //TODO
            }
            else if (eventName == "set_state_true")
            {
                ScSceneUpdateInteractiveProperty update = new()
                {
                    Id = guid,
                    SceneNumId = GetOwner().curSceneNumId,
                    Properties =
                    {
                        {1, new DynamicParameter()
                        {
                            RealType=3,
                            ValueType=3,
                            ValueIntList={1}
                        } }
                    }
                };
                GetOwner().sceneManager.KillEntity(guid, true, 1);
                GetOwner().noSpawnAnymore.Add(guid);
                GetOwner().sceneManager.GetScene(sceneNumId).AddCollection(templateId, 1);
                GetOwner().Send(ScMsgId.ScSceneUpdateInteractiveProperty, update);
            }
            return false;
        }
        public override void Heal(double heal)
        {

        }

    }
}
