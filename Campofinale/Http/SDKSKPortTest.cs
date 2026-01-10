using Campofinale.Database;
using HttpServerLite;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using StardustUtils;
using System;
using System.Collections;
using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Threading.Channels;
using System.Xml.Linq;
using static Campofinale.Game.Gacha.GachaManager;
using static Campofinale.Http.Dispatch;

namespace Campofinale.Http
{
    public class SDKSPORTTest
    {

       
        [StaticRoute(HttpServerLite.HttpMethod.POST, "/api/v1/user/auth/generate_cred_by_code")]
        public static async Task generate_cred_by_code(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            try
            {
                string resp = "{\"message\": \"OK\",  \"code\": 0}";
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    cred = "a",
                    userId = "1",
                    token = "a",
                    data = new
                    {
                        cred="a",
                        userId="1",
                        token="a"
                    }
                };
                resp = JsonConvert.SerializeObject(rsp);
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v1/user/check")]
        public static async Task check_skport(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            try
            {
                string resp = "{\"message\": \"OK\",  \"code\": 0}";
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        policyList = Array.Empty<string>(),
                        isNewUser = false,
                        nickname = "SuikoAkari"
                    }
                };
                resp = JsonConvert.SerializeObject(rsp);
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v1/home/index")]
        public static async Task home_skport(HttpContext ctx)
        {
            try
            {
                using HttpClient client = new HttpClient();

                // Query string originale
                string query = ctx.Request.Url.Full.Split("?")[1]; // es: ?pageSize=10&sortType=1...

                // Endpoint remoto
                string url = "https://zonai.skport.com/web/v1/home/index?" + query;

                // Fetch remoto
                string remoteJson = await client.GetStringAsync(url);

                // Parse JSON
                JObject remoteObj = JObject.Parse(remoteJson);

                // Estrai data.list
                JToken list = remoteObj["data"]?["list"] ?? new JArray();

                // Risposta API tua
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        list = list
                    }
                };

                string resp = JsonConvert.SerializeObject(rsp);

                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";
                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.ToString());

                ctx.Response.StatusCode = 500;
                await ctx.Response.SendAsync("{\"message\":\"Internal Server Error\",\"code\":500}");
            }
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v1/pendant/all")]
        public static async Task pendant_skport(HttpContext ctx)
        {
            try
            {
                using HttpClient client = new HttpClient();

                // Query string originale
                string query = ctx.Request.Url.Full.Split("?")[1]; // es: ?pageSize=10&sortType=1...

                // Endpoint remoto
                string url = "https://cdn1.teamstardust.org/skport-test/pendant.json?" + query;

                // Fetch remoto
                string remoteJson = await client.GetStringAsync(url);

                // Parse JSON
                JObject remoteObj = JObject.Parse(remoteJson);

                // Estrai data.list
                JToken list = remoteObj["data"]?["list"] ?? new JArray();

                // Risposta API tua
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        list = list
                    }
                };

                string resp = JsonConvert.SerializeObject(rsp);

                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";
                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.ToString());

                ctx.Response.StatusCode = 500;
                await ctx.Response.SendAsync("{\"message\":\"Internal Server Error\",\"code\":500}");
            }
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v1/sidebar/resource")]
        public static async Task resource_skport(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            try
            {
                string resp = "{\"message\": \"OK\",  \"code\": 0}";
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        communityRuleUrl="",
                        customerServiceUrl="",
                        myPrizesUrl=""
                    }
                };
                resp = JsonConvert.SerializeObject(rsp);
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }

       [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v2/user/config")]
        public static async Task userconfig_skport(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            try
            {
                string resp = "{\"message\": \"OK\",  \"code\": 0}";
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        privacy = new
                        {
                            collectionOnOff=true,
                            commentOnOff=true,
                            fansOnOff=true,
                            followOnOff=true,
                            watermarkOnOff=true,
                            gamePrivacy = new[]
                            {
                                new{
                                    id=999,
                                    privacy = new
                                    {
                                        cardOn=true,
                                        detailOn=true,
                                        gameRelationOn=true,
                                        itemGameNameCardOnOff=true,
                                    },
                                }
                            }
                        }
                    }
                };
                resp = JsonConvert.SerializeObject(rsp);
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v1/game/cards")]
        public static async Task cards_skport(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            try
            {
                string resp = "{\"message\": \"OK\",  \"code\": 0}";
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        list = new[]
                        {
                            new
                            {
                                bgUrl="https://static.skport.com/image/common/20251212/7f8d5e3d2ab0a6ecffbfc9a7944fdf0a.jpg?x-oss-process=style/thumbnail",
                                channelId=6,
                                gameChar="test",
                                icon="https://static.skport.com/asset/game/endfield.png?x-oss-process=style/game_icon",
                                iconBorderColor="#FFF",
                                id=999,
                                link="https://static.skport.com/image/common/20251212/7f8d5e3d2ab0a6ecffbfc9a7944fdf0a.jpg?x-oss-process=style/thumbnail",
                                name="Arknights: Endfield",
                                privacy = new
                                {
                                    cardOn=true,
                                    detailOn=true,
                                    gameRelationOn=true,
                                    itemGameNameCardOnOff=true,
                                },
                                decoration = new
                                {
                                    backgroundUrl="https://static.skport.com/image/common/20251212/7f8d5e3d2ab0a6ecffbfc9a7944fdf0a.jpg?x-oss-process=style/thumbnail",
                                    characterKvName="test",
                                    coverUrl="https://static.skport.com/image/common/20251212/7f8d5e3d2ab0a6ecffbfc9a7944fdf0a.jpg?x-oss-process=style/thumbnail",
                                    id=999,
                                    kind=5,
                                    resourceKind=6,
                                    textColor="#FFF",
                                    topColor="#FFF",
                                    url="https://static.skport.com/image/common/20251212/7f8d5e3d2ab0a6ecffbfc9a7944fdf0a.jpg?x-oss-process=style/thumbnail",
                                },
                                endfield = new
                                {
                                    achievementCount=10,
                                    charCount=10,
                                    createdAtTs="1767034375",
                                    level=60,
                                    name="Endministrator",
                                    serverName="EUandUS"
                                }
                            }
                        }
                    }
                };
                resp = JsonConvert.SerializeObject(rsp);
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v1/bulletins/list")]
        public static async Task bulletins_skport_list(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            try
            {
                string resp = "{\"message\": \"OK\",  \"code\": 0}";
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        list = new[]
        {
            new
            {
                id = 1041,
                gameId = 999,
                cateId = 0,
                kind = 1,
                subkind = 0,
                rank = 2,
                content = new
                {
                    cover = new
                    {
                        id = "",
                        url = "https://static.skport.com/image/common/20251224/a19b0ce284a225d6cd886609dec50b3a.png",
                        width = 1200,
                        height = 675,
                        size = 394179,
                        format = "png",
                        darkModeUrl = ""
                    },
                    backgroundImage = (object?)null,
                    title = "",
                    i18nTitle = new { },
                    i18nCover = new { },
                    appCover = (object?)null,
                    i18nAppCover = new { }
                },
                link = "https://www.skport.com/article?id=2003405037840078253",
                createdAtTs = 1766575800,
                updatedAtTs = 1766575800
            },
            new
            {
                id = 1032,
                gameId = 999,
                cateId = 0,
                kind = 1,
                subkind = 0,
                rank = 1,
                content = new
                {
                    cover = new
                    {
                        id = "",
                        url = "https://static.skport.com/image/common/20251212/11503b788f7cb4addcf29c9156a0f223.jpg",
                        width = 1200,
                        height = 675,
                        size = 485816,
                        format = "jpg",
                        darkModeUrl = ""
                    },
                    backgroundImage = (object?)null,
                    title = "",
                    i18nTitle = new { },
                    i18nCover = new { },
                    appCover = (object?)null,
                    i18nAppCover = new { }
                },
                link = "http://act.skport.com/endfield/ob?header=0&hg_media=skport&hg_link_campaign=homebanner",
                createdAtTs = 1765468800,
                updatedAtTs = 1765468800
            },
            new
            {
                id = 1025,
                gameId = 999,
                cateId = 0,
                kind = 1,
                subkind = 0,
                rank = 3,
                content = new
                {
                    cover = new
                    {
                        id = "",
                        url = "https://static.skport.com/image/common/20251121/100596c3c261315651c752db81e590ca.png",
                        width = 1200,
                        height = 675,
                        size = 400918,
                        format = "png",
                        darkModeUrl = ""
                    },
                    backgroundImage = (object?)null,
                    title = "",
                    i18nTitle = new { },
                    i18nCover = new { },
                    appCover = (object?)null,
                    i18nAppCover = new { }
                },
                link = "https://game.skport.com/endfield/reservation?hg_media=skport&hg_link_campaign=homebanner",
                createdAtTs = 1763701989,
                updatedAtTs = 1763701989
            }
        }
                    }
                };
                resp = JsonConvert.SerializeObject(rsp);
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/v2/user")]
        public static async Task user_skport(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            try
            {
                string resp = "{\"message\": \"OK\",  \"code\": 0}";
                object rsp = new
                {
                    message = "OK",
                    code = 0,
                    data = new
                    {
                        user = new
                        {
                            basicUser = new
                            {
                                id = "1",
                                nickname = "CrackedTheLogin",
                                profile = "proxy on iPad is so easy LOL",
                                avatarCode = 70,
                                avatar = "https://static.skport.com/image/common/20251031/bfac9ac1bac6205f1585f3232a5c89aa.png",
                                gender = 1,
                                status = 1,
                                operationStatus = 30,
                                identity = 1,
                                kind = 1,
                                birthday = "0",
                                moderatorStatus = 4,
                                moderatorChangeTime = 0,
                                createdAt = "1761638322",
                                latestLoginAt = "1767027699"
                            },
                            pendant = new
                            {
                                id = 13,
                                iconUrl = "https://static.skport.com/image/common/20251121/1464c2e5fded7c2ab4fcc404edd79336.webp",
                                title = "Wulfgard",
                                description = "Join the Arknights: Endfield pre-registration to claim"
                            },
                            background = "https://image.api.playstation.com/vulcan/ap/rnd/202511/1910/e802ae938f75723e31a5c50d04eb6fa494c1ac6fa934b185.png"
                        },
                        userRts = new
                        {
                            follow = "99999",
                            fans = "9999",
                            liked = "9999"
                        },
                        userSanctionList = new object[] { },
                        userInfoApply = new { },
                        moderator = new
                        {
                            isModerator = true,
                            operations = new object[] { },
                            role = "ROLE_UNSPECIFIED",
                            since = "0",
                            status = 0
                        }
                    }
                };
                resp = JsonConvert.SerializeObject(rsp);
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }
        
    }
}
