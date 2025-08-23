using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Resource.Json
{
    public class LevelScriptEvent
    {
        public string eventName;
        public string comment;
        public List<ScriptAction> actions;
    }
    public class ScriptAction
    {
        public ScriptActionType action;
        public string[] valueStr = new string[0];
        public ulong[] valueUlong = new ulong[0];
    }
    public enum ScriptActionType
    {
        None = 0,
        CompleteQuest = 1,
        ProcessQuest = 2,
        SpawnEnemy = 3,
        UnlockSystem = 4,
        EnterScene = 5,
        AddMission = 6,
        CompleteMission = 7,
        SpawnEnemyByScriptId = 8,
        CallClientEvent = 9,
        StartScript = 10,
        ChangeScriptPropertyBool = 11,
        StartSpawner = 12,
        AddCharacter = 13
    }
}
