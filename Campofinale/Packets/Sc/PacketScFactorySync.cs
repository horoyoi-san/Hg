using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource.Table;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScFactorySync : Packet
    {

        public PacketScFactorySync(Player client)
        {
            ScFactorySync proto = new()
            {
                FormulaMan = new()
                {
                    Unlocked =
                    {
                        "battle_frost_1",
                        "battle_laser_2",
                        "handwork_angles_flower2_1",
                        "handwork_corp1_flower1_1",
                        "handwork_animal_angles_1",
                        "handwork_bottled_rec_hp_1",
                        "miner_2",
                        "handwork_plant_moss_powder_2",
                        "battle_shockwave_1",
                        "handwork_erosionm_grass2_1",
                        "travel_pole_2",
                        "loader_1",
                        "handwork_anglem_flower2_1",
                        "handwork_plant_moss_spc_powder_1",
                        "furnance_1",
                        "handwork_port_soil_grass_1",
                        "component_mc_1",
                        "battle_sniper_1",
                        "filling_powder_mc_1",
                        "handwork_port_soil_moss_3",
                        "handwork_bottled_flower1spc_1",
                        "handwork_port_soil_moss_1",
                        "shaper_1",
                        "handwork_bottled_rec_hp_2",
                        "planter_1",
                        "miner_3",
                        "handwork_anglel_flower2_1",
                        "handwork_bottled_insec2_1",
                        "miner_1",
                        "tools_assebling_mc_1",
                        "power_station_1",
                        "unloader_1",
                        "storager_1",
                        "power_diffuser_1",
                        "handwork_port_soil_bbflower_1",
                        "battle_lightning_1",
                        "battle_cannon_1",
                        "handwork_ebm_flower1_1",
                        "handwork_ebl_flower1_1",
                        "handwork_bottled_insec1_1",
                        "seedcollector_1",
                        "winder_1",
                        "thickener_1",
                        "handwork_bottled_flower2spc_1",
                        "handwork_port_soil_sp_1",
                        "battle_medic_1",
                        "handwork_ebs_flower1_1",
                        "handwork_plant_moss_powder_1",
                        "handwork_plant_grass_powder_1",
                        "handwork_port_soil_moss_2",
                        "handwork_bottled_food_1",
                        "power_pole_2",
                        "battle_turret_2",
                        "handwork_bottled_flower1spc_2",
                        "handwork_corp2_flower2_1",
                        "handwork_port_soil_sp_2",
                        "battle_laser_1",
                        "battle_turret_1",
                        "battle_cannon_2",
                        "travel_pole_1",
                        "handwork_plant_moss_spc_powder_2",
                        "grinder_1"
                    },
                },
                Stt = new()
                {
                    Nodes =
                    {
                    },
                    Layers =
                    {

                    },
                    Packages =
                    {
                        new ScdFactorySttPackage()
                        {
                            Id="tech_group_jinlong",
                            State=1
                        },
                        new ScdFactorySttPackage()
                        {
                            Id="tech_group_tundra",
                            State=1,
                        }
                    },
                    Categories =
                    {

                    }
                },
                ProgressStatus = new()
                {

                }
            };
            foreach (var c in client.factoryManager.chapters)
            {
                DomainDataTable DomainData = domainDataTable[c.chapterId];
                if (DomainData == null) continue;
                ScdFactoryBuildingDomainPlaceLimit dLimit = new ScdFactoryBuildingDomainPlaceLimit()
                {

                };
                foreach (var item in DomainData.levelGroup)
                {
                    dLimit.BuildingLimit.Add(item, 100);
                }
                proto.ProgressStatus.DomainPlaceLimit.Add(c.chapterId, dLimit);
            }

            foreach (var node in facSTTCategoryTable)
            {
                proto.Stt.Categories.Add(new ScdFactorySttCategory()
                {
                    Id = node.Value.category,
                    Hidden = false

                });
            }
            foreach (var node in facSTTNodeTable)
            {
                proto.Stt.Nodes.Add(new ScdFactorySttNode()
                {
                    Id = node.Value.techId,
                    State = 1, // Unlocked
                    Hidden = false
                });
            }
            foreach (var layer in facSTTLayerTable)
            {
                proto.Stt.Layers.Add(new ScdFactorySttLayer()
                {
                    Id = layer.Value.layerId,
                    State = 1,
                });
            }

            SetData(ScMsgId.ScFactorySync, proto);
        }

    }
}
