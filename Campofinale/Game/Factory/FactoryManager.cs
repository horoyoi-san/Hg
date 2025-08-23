using Campofinale.Database;
using Campofinale.Game.Entities;
using Campofinale.Game.Factory.Components;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory
{
    public class FactoryManager
    {
        public Player player;
        public List<FactoryChapter> chapters = new();
        public ObjectId _id;

        public class FactoryData
        {
            public ulong roleId;
            public ObjectId _id;
            public List<FactoryChapter> chapters = new();
        }
        public FactoryManager(Player player)
        {
            this.player = player;
        }
        public void Load()
        {
            FactoryData data = DatabaseManager.db.LoadFactoryData(player.roleId);
            if (data != null)
            {
                _id=data._id;
                chapters = data.chapters;
            }
            if(!ChapterExist("domain_1")) chapters.Add(new FactoryChapter("domain_1", player.roleId));
            if(!ChapterExist("domain_2")) chapters.Add(new FactoryChapter("domain_2", player.roleId));
        }
        public bool ChapterExist(string id)
        {
            return chapters.Find(c=>c.chapterId==id)!=null;
        }
        public void Save()
        {
            DatabaseManager.db.UpsertFactoryData(new FactoryData()
            {
                _id= _id,
                roleId=player.roleId,
                chapters=chapters
            });
        }
        public void ExecOp(CsFactoryOp op, ulong seq)
        {
            FactoryChapter chapter = GetChapter(op.ChapterId);
            if (chapter != null)
            {
                chapter.ExecOp(op, seq);
                
            }
            else
            {
                ScFactoryOpRet ret = new()
                {
                    RetCode = FactoryOpRetCode.Fail,
                    
                };
                player.Send(ScMsgId.ScFactoryOpRet, ret, seq);
            }
        }
        public void SendFactoryHsSync()
        {
            if (!player.Initialized) return;
            if (player.GetCurrentChapter() == "") return;
            List<FactoryNode> nodeUpdateList = new();
            foreach (var node in GetChapter(player.GetCurrentChapter()).nodes)
            {
                if (node != null)
                {
                    if (node.position.DistanceXZ(player.position) < 150 && node.nodeBehaviour!=null)
                    {
                        nodeUpdateList.Add(node);
                    }
                }
            }
            player.Send(new PacketScFactoryHsSync(player,GetChapter(player.GetCurrentChapter()), nodeUpdateList));
        }
        public void Update()
        {
            if (!player.Initialized) return;
            foreach (FactoryChapter chapter in chapters)
            {
                chapter.Update();
            }

        }
        public FactoryChapter GetChapter(string id)
        {
            return chapters.Find(c=>c.chapterId==id);
        }
    }
    
    

}
