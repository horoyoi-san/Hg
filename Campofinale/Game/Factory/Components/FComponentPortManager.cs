using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentPortManager : FComponent
    {
        public class FPort
        {
            public int index = 0;
            public uint ownerComId;
            public uint touchComId;

            public ScdFacComSubPort ToProto()
            {
                return new ScdFacComSubPort()
                {
                    InBlock = false,
                    Index = index,
                    OwnerComId = ownerComId,
                    TouchComId = touchComId
                };
            }
        }
        public List<FPort> ports = new();
        public FComponentPortManager(uint id, uint mainId) : base(id, FCComponentType.PortManager)
        {
            for(int i=0; i < 14; i++)
            {
                ports.Add(new FPort()
                {
                    index = i,
                    ownerComId = mainId,
                    touchComId = 0
                });
            }
        }
        public FComponentPortManager(uint id, int size) : base(id, FCComponentType.PortManager)
        {
            for (int i = 0; i < size; i++)
            {
                ports.Add(new FPort()
                {
                    index = i,
                    ownerComId = 0,
                    touchComId = 0
                });
            }
        }
        public FComponentPortManager(uint id, int size, FComponentCache cache) : base(id, FCComponentType.PortManager)
        {
            if( cache.customPos == FCComponentPos.CacheIn1 ||
                cache.customPos == FCComponentPos.CacheIn2 ||
                cache.customPos == FCComponentPos.CacheIn3 ||
                cache.customPos == FCComponentPos.CacheIn4)
            {
                customPos = FCComponentPos.PortInManager;
            }
            else
            {
                customPos = FCComponentPos.PortOutManager;
            }
            
            for (int i = 0; i < size; i++)
            {
                ports.Add(new FPort()
                {
                    index = i,
                    ownerComId = cache.compId,
                    touchComId = 0
                });
            }
        }
        public override void SetComponentInfo(ScdFacCom proto)
        {

            proto.PortManager = new();
            foreach(FPort port in ports)
            {
                proto.PortManager.Ports.Add(port.ToProto());
            }
        }
    }
}
