using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using static Campofinale.Resource.Table.DomainDataTable;

namespace Campofinale.Packets.Sc
{
    public class PacketScDomainDevelopmentSystemSync : Packet
    {

        public PacketScDomainDevelopmentSystemSync(Player client)
        {

            ScDomainDevelopmentSystemSync proto = new()
            {

            };

            foreach (var c in client.factoryManager.chapters)
            {
                // Ensure domain development level is at least 12 (maximum)
                if (c.domainDevelopmentLevel == 0 || c.domainDevelopmentLevel < 12)
                {
                    c.domainDevelopmentLevel = 12;
                }
                DomainDataTable DomainData = ResourceManager.domainDataTable[c.chapterId];
                DomainDevelopmentLevel? devLvl = DomainData.domainDevelopmentLevel.Find(D => D.domainDevelopmentLevel == c.domainDevelopmentLevel);
                if (devLvl == null) continue;
                proto.Domains.Add(new DomainDevelopment()
                {
                    ChapterId = c.chapterId,
                    DevDegree = new()
                    {
                        Level = (uint)c.domainDevelopmentLevel,

                    },
                    Version = devLvl.versionStart
                });
            }
            SetData(ScMsgId.ScDomainDevelopmentSystemSync, proto);
        }

    }
}
