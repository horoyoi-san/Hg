namespace Campofinale.Game
{
    public static class GameConstants
    {
        //TODO, have to check if this is really userful for support different platform or if android version doesn't need the GAME_VERSION_ASSET_URL (probably not?)
        //So, in case is useful only if the android build it's different than 0.5.28
        /*public static List<GameVersionConst> GAME_VERSIONS = new()
        {
            new GameVersionConst("0.5.28"), //Windows CBT2
            new GameVersionConst("0.5.5"), //Android CBT2

        };*/

        //Not used on top ^
        public static string GAME_VERSION = "0.5.28"; //CBT 2 
        public static string GAME_VERSION_ANDROID = "0.5.5"; //CBT 2 ANDROID
        public static string GAME_VERSION_ASSET_URL = "https://beyond.hg-cdn.com/uXUuLlNbIYmMMTlN/0.5/update/6/1/Windows/0.5.28_U1mgxrslUitdn3hb/files";//CBT 2 
        public static int MAX_TEAMS_NUMBER = 5; //Not used yet
        public static (long, string) SERVER_UID = (99, "99"); //Not used yet, no friend chat in current Beta
    }
    
   /* public class GameVersionConst
    {
        public string GAME_VERSION = "0.5.28";
        public string GAME_VERSION_ASSET_URL = "https://beyond.hg-cdn.com/uXUuLlNbIYmMMTlN/0.5/update/6/1/Windows/0.5.28_U1mgxrslUitdn3hb/files";//CBT 2 
        public GameVersionConst() { }

        public GameVersionConst(string version)
        {
            this.GAME_VERSION = version;
        }
    }*/
}
