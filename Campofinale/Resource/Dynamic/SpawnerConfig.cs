using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Resource.Dynamic
{
    public class SpawnerConfig
    {
        public string configId;
        public Dictionary<string, SpawnerWave> waveMap = new();
        public List<EnemyLibraryData> enemyLibrary = new();

        
        public SpawnerConfig() { }
        public class EnemyLibraryData
        {
            public string key;
            public string enemyId;
            public int enemyLevel;

        }
        public class SpawnerWave
        {
            public int waveId;
            public bool repeatable;
            public int waveModeKillCount;


            public Dictionary<string, WaveGroup> groupMap = new();

        }
        public class WaveGroup
        {
            public int groupId;
            public string groupMode;
            public int groupModeKillCount;
            public float timestamp;
            public Dictionary<string, GroupAction> actionMap = new();


        }
        public class GroupAction
        {
            [JsonPropertyName("$type")]
            public string type;
            public int actionId;
            public float timestamp;
            public string libraryKey;
            public int spawnCount;
            public float spawnInterval;
            public Vector3f position;
            public Vector3f rotation;
            public float randomizeRadius;
            public int routeId;
        }
    }
}
