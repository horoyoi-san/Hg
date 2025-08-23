using HttpServerLite;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Http
{
    internal class DispatchCN
    {
        //SERVER
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/get_remote_config/3/prod-cbt/default/default/server_config_China")]
        public static async Task server_config_China(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            Console.WriteLine(requestBody);
            string resp = "{\"addr\": \"" + Server.config.gameServer.accessAddress + "\", \"port\": " + Server.config.gameServer.accessPort + "}";



            ctx.Response.StatusCode = 200;

            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        //DEFAULT
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/get_remote_config/3/prod-cbt/default/default/network_config")]
        public static async Task network_config_cn(HttpContext ctx)
        {
            string resp = "{  \"asset\": \"https://beyond.hycdn.cn/asset/\",  \"hgage\": \"https://web.hycdn.cn/endfield/protocol/cadpa-age.txt\",  \"sdkenv\": \"2\",  \"u8root\": \"https://as.hypergryph.com/u8\",  \"appcode\": 4,  \"channel\": \"prod\",  \"netlogid\": \"56RqF5G2gU9j\",  \"gameclose\": false,  \"netlogurl\": \"http://native-log-collect.hypergryph.com:32000\",  \"accounturl\": \"https://binding-api-account-prod.hypergryph.com\",  \"launcherurl\": \"https://launcher.hypergryph.com\"}";

            ctx.Response.StatusCode = 200;
            ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        //WINDOWS
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/get_remote_config/3/prod-cbt/default/Windows/res_version")]
        public static async Task cn_res_version(HttpContext ctx)
        {

            string resp = "{\"version\": \"2089329-32\", \"kickFlag\": false}";
            ctx.Response.StatusCode = 200;
            //ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/get_remote_config/3/prod-cbt/default/Windows/game_config")]
        public static async Task game_config_cn_windows(HttpContext ctx)
        {
            string resp = "{\"mockLogin\": false, \"selectSrv\": false, \"enableHotUpdate\": true, \"enableEntitySpawnLog\": false, \"enableCBT2AccessForbidden\": false}";

            ctx.Response.StatusCode = 200;
            ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        //ANDROID
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/get_remote_config/3/prod-cbt/default/Android/res_version")]
        public static async Task cn_android_res_version(HttpContext ctx)
        {

            string resp = "{\"version\": \"2377591-182\", \"kickFlag\": false}";


            ctx.Response.StatusCode = 200;
            //ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/get_remote_config/3/prod-cbt/default/Android/game_config")]
        public static async Task game_config_cn_android(HttpContext ctx)
        {
            string resp = "{\"mockLogin\": false, \"selectSrv\": false, \"enableHotUpdate\": true, \"enableNpcOptimize\": false, \"enableEntitySpawnLog\": false, \"enableCBT2AccessForbidden\": false, \"enableMobileFullScreenWaterMark\": false}";

            ctx.Response.StatusCode = 200;
            ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
       
    }
}
