using Campofinale.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Game.MissionSys
{
    public class GameMission
    {
        public string missionId;
        public MissionState state;

        public GameMission()
        {

        }
        public GameMission(string id, MissionState state = MissionState.Available)
        {
            missionId = id;
            this.state = state;
        }
    }
}
