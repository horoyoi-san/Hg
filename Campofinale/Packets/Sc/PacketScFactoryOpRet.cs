using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScFactoryOpRet : Packet
    {

        public PacketScFactoryOpRet(Player client, uint val, CsFactoryOp op)
        {

            ScFactoryOpRet proto = new ScFactoryOpRet()
            {
                RetCode = FactoryOpRetCode.Ok,
                OpType = op.OpType,

            };
            if (op.OpType == FactoryOpType.Place)
            {
                proto.Place = new()
                {
                    NodeId = val
                };
            }
            if (op.OpType == FactoryOpType.MoveNode)
            {
                proto.MoveNode = new()
                {

                };
            }
            if (op.OpType == FactoryOpType.AddConnection)
            {
                proto.AddConnection = new()
                {
                    Index = val,
                };
            }
            if (op.OpType == FactoryOpType.Dismantle)
            {
                proto.Dismantle = new()
                {

                };
            }
            if (op.OpType == FactoryOpType.DismantleBoxConveyor)
            {
                proto.DismantleBoxConveyor = new()
                {

                };
            }
            if (op.OpType == FactoryOpType.ChangeProducerMode)
            {
                proto.ChangeProducerMode = new()
                {

                };
            }
            if (op.OpType == FactoryOpType.SetTravelPoleDefaultNext)
            {
                proto.SetTravelPoleDefaultNext = new()
                {

                };
            }
            if (op.OpType == FactoryOpType.EnableNode)
            {
                proto.EnableNode = new()
                {

                };
            }

            if (op.OpType == FactoryOpType.MoveItemBagToCache)
            {
                proto.MoveItemBagToCache = new()
                {

                };
            }
            if (op.OpType == FactoryOpType.MoveItemCacheToBag)
            {
                proto.MoveItemCacheToBag = new();
            }
            proto.Index = op.Index;
            SetData(ScMsgId.ScFactoryOpRet, proto);
        }
        public PacketScFactoryOpRet(Player client, List<uint> val, CsFactoryOp op)
        {

            ScFactoryOpRet proto = new ScFactoryOpRet()
            {
                RetCode = FactoryOpRetCode.Ok,
                OpType = op.OpType,

            };

            if (op.OpType == FactoryOpType.PlaceConveyor)
            {
                proto.PlaceConveyor = new()
                {
                    NodeId =
                    {
                        val
                    }
                };
            }
            proto.Index = op.Index;
            SetData(ScMsgId.ScFactoryOpRet, proto);
        }

        /// <summary>
        /// Constructor for failure response.
        /// </summary>
        public PacketScFactoryOpRet(Player client, CsFactoryOp op, ulong seq)
        {
            ScFactoryOpRet proto = new ScFactoryOpRet()
            {
                RetCode = FactoryOpRetCode.Fail,
                OpType = op.OpType,
                Index = op.Index
            };
            SetData(ScMsgId.ScFactoryOpRet, proto);
        }
    }
}
