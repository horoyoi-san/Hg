using Campofinale.Resource;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game
{
    public class BitsetManager
    {
        public Player player;
        public Dictionary<int, List<int>> bitsets = new Dictionary<int, List<int>>();


        public BitsetManager(Player player) {
        
            this.player = player;
        }
        
        public void Load(Dictionary<int, List<int>> savedBitset)
        {
            if (savedBitset != null)
            {
                bitsets=savedBitset;
            }
            InitBitsets();
            List<ulong> hardcodedLevelHaveBeen = new()
            {
                51810140172,
                531424959210205184,
                590604267523,
                17039360
            };
            LongBitSet levelHaveBeen=new LongBitSet(hardcodedLevelHaveBeen.ToArray());
            List<ulong> hardcodedReadActiveBlackbox = new()
            {
                1081145935319335202,
                2267743508524
            };
            LongBitSet readActiveBlackbox = new LongBitSet(hardcodedReadActiveBlackbox.ToArray());
            foreach (var v in ResourceManager.levelDatas)
            {
                AddValue(BitsetType.LevelHaveBeen, v.idNum);
            }
            foreach (var v in levelShortIdTable.Values)
            {
                foreach(int vl in v.ids.Values)
                {
                    AddValue(BitsetType.InteractiveActive, vl);
                }
                
            }
            foreach (int v in strIdNumTable.char_doc_id.dic.Values)
            {
                AddValue(BitsetType.CharDoc, v);
            }
            foreach (int v in strIdNumTable.char_voice_id.dic.Values)
            {
                AddValue(BitsetType.CharVoice, v);
            }
            foreach(int v in ResourceManager.strIdNumTable.wiki_id.dic.Values)
            {
                AddValue(BitsetType.Wiki, v);
            }
            foreach (int v in ResourceManager.strIdNumTable.user_avatar_id.dic.Values)
            {
                AddValue(BitsetType.UnlockUserAvatar, v);
            }
            foreach (int v in ResourceManager.strIdNumTable.business_card_topic_id.dic.Values)
            {
                AddValue(BitsetType.UnlockBusinessCardTopic, v);
            }
            foreach (int v in ResourceManager.strIdNumTable.user_avatar_frame_id.dic.Values)
            {
                AddValue(BitsetType.UnlockUserAvatarFrame, v);
            }
        }
        public void InitBitsets()
        {
            foreach (BitsetType bitsetType in Enum.GetValues(typeof(BitsetType)))
            {
                int id=(int)bitsetType;
                if (!bitsets.ContainsKey(id))
                {
                    bitsets.Add(id, new List<int>());
                }
            }
        }
        public void AddValue(BitsetType type, int value)
        {
            int id = (int)type;
            if (!bitsets[id].Contains(value))
            {
                bitsets[id].Add(value);
            }
            
        }
        public void RemoveValue(BitsetType type, int value)
        {
            int id = (int)type;
            if (bitsets[id].Contains(value))
            {
                bitsets[id].Remove(value);
            }

        }


    }
}
