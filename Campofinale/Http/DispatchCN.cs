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
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/v2/3/prod-cbt3/default/default/network_config")]
        public static async Task network_config_cn(HttpContext ctx)
        {
            string resp = "y6q2xWvK+XuOuBVy+Iwxy3fy1Ad8+LRYdHDAPyu4pXIxo1Bc8CgDJxY8JR564abU1mCR6p2lLXnZCpy/CM96LdDGE33i9MCjFSz5y+Aleedh/P9P5bLutzWlLwEd6qYRcLbOjciZTSg/GqD3J8+u/0eXx6rkRqbDfnSp4aGSgCqFBO3GBF6eTvhVv50UDUREEIuUouuWNvoIqmSvhS/UvmjswrJcFD1KMaDju/rI6fYc6SZfpdIDUd4nG0wa8ymbEVUG6Ald4muLqq2HyO6zr8/M8lUImh/BenV98+j6laq3nK0j0KzzGrXEAK05LfDv7JxrhIoBqY4Z93h3kr36R8qjiz4LysUPI5jip37afpzIHZzoo5KuDO+qBKtlrSPiA2VVA19tz76P+6k82e4VQQ==\r\n";

            ctx.Response.StatusCode = 200;
            ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/3/prod-engine/default/default/engine_config")]
        public static async Task engine_config_cn(HttpContext ctx)
        {
            string resp = "{\"CL\": 0, \"Configs\": \"{\\\"Windows\\\":{\\\"Platform\\\":\\\"Windows\\\",\\\"Params\\\":{\\\"disable-streamline-at-startup\\\":\\\"1\\\"}}}\", \"Version\": 0}";

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
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/v2/3/prod-cbt3/default/Windows/game_config")]
        public static async Task game_config_cn_windows(HttpContext ctx)
        {
            string resp = "zo00qjNIhRqTS+T7NCi7E8fTrD6ed0rFXDSQmQjyrttYRAQh6sFzcDdwkOII68xiHwtxqCYUqaQihMkD+RzScm0annv6LCAHiyWwRWf2xsyDf6JhSQqUNdzTny9Gk0FCLnFsTp3baXAYRYStEHSpBpLvVH6eTGQtTdoCepL4xGu/oZjgfzb0stxRbF/gszQl\r\n";

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
