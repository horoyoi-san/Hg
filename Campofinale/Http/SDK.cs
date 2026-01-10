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
    public class SDK
    {

        [StaticRoute(HttpServerLite.HttpMethod.POST, "/user/info/v1/authenticate")]
        public static async Task cn_authenticate(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            Console.WriteLine(requestBody);
            string resp = "{}";
            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);

        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/user/pay/v1/query_app_order")]
        public static async Task query_app_order(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            Console.WriteLine(requestBody);
            string resp = "{\"data\":{\"paidApp\":true,\"hasMinorOrder\":false},\"msg\":\"OK\",\"status\":0,\"type\":\"A\"}";
            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);

        }
        [StaticRoute(HttpServerLite.HttpMethod.POST, "/user/auth/v1/token_by_phone_password")]
        public static async Task token_login_phone_cn(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            LoginJson body = Newtonsoft.Json.JsonConvert.DeserializeObject<LoginJson>(requestBody);
            Account account = DatabaseManager.db.GetAccountByUsername(body.phone);
            Console.WriteLine(requestBody);
            string resp = "{}";
            if (account != null)
            {
                resp = "{\"msg\":\"OK\",\"status\":0,\"type\":\"A\",\"data\":{\"token\":\"" + account.token + "\"}}";
            }
            else
            {
                resp = "{\"msg\":\"Account not found\",\"status\":2,\"type\":\"A\"}";
            }

            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);

        }
        [StaticRoute(HttpServerLite.HttpMethod.POST, "/user/auth/v1/token_by_email_password")]
        public static async Task token_login(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;
            LoginJson body = Newtonsoft.Json.JsonConvert.DeserializeObject<LoginJson>(requestBody);
            Account account = DatabaseManager.db.GetAccountByUsername(body.email.Split("@")[0]);
            Console.WriteLine(requestBody);
            string resp = "{}";
            if (account != null)
            {
                resp = "{\"msg\":\"OK\",\"status\":0,\"type\":\"A\",\"data\":{\"token\":\"" + account.token + "\"}}";
            }
            else
            {
                resp = "{\"msg\":\"Account not found\",\"status\":2,\"type\":\"A\"}";
            }

            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);

        }

        [StaticRoute(HttpServerLite.HttpMethod.GET, "/batch_event")]
        public static async Task batch_event(HttpContext ctx)
        {
            await ctx.Response.SendAsync("OK");
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/user/info/v1/basic")]
        public static async Task account_info_get(HttpContext ctx)
        {
            string requestToken = ctx.Request.Query.Elements["token"];
            Account account = DatabaseManager.db.GetAccountByToken(requestToken);
            string resp = "{\"data\":{\"hgId\":\"1799321925\",\"email\":\"dispatch@endfield.ps\",\"realEmail\":\"dispatch@endfield.ps\",\"isLatestUserAgreement\":true,\"nickName\":\"Campofinale\"},\"msg\":\"OK\",\"status\":0,\"type\":1}";
            if (account != null)
            {
                /*
                 * {"data":{"hgId":"**********","phone":"153****5243","email":null,"identityNum":"5002**********1619","identityName":"金*","isMinor":false,"isLatestUserAgreement":true},"msg":"OK","status":0,"type":"A"}
                 */
                resp = "{\"data\":{\"phone\":\"153****5243\", \"identityNum\": \"5002**********1619\",\"identityName\":\"金*\",\"isMinor\":false,\"hgId\":\"" + account.id + "\",\"email\":\"" + account.username + Server.config.dispatchServer.emailFormat + "\",\"realEmail\":\"" + account.username + Server.config.dispatchServer.emailFormat + "\",\"isLatestUserAgreement\":true,\"nickName\":\"" + account.username + "\"},\"msg\":\"OK\",\"status\":0,\"type\":\"A\"}";
            }
            else
            {
                resp = "{\"msg\":\"Account not found\",\"status\":2,\"type\":\"A\"}";
            }




            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }

        public class GrantReqData
        {
            public string token;
            public string encodeNonce;
            public string appCode;
        }
        public class GrantRsp
        {
            public Data data;
            public string msg;
            public int status;
            public string type;

            public class Data
            {
                public string token;
                public string code;
                public string hgId;
                public string uid;
                public string encodeSign;
            }
        }


        /*[StaticRoute(HttpServerLite.HttpMethod.POST, "/user/oauth2/v2/grant")]
        public static async Task account_ugrant_old(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;

            GrantReqData grant = Newtonsoft.Json.JsonConvert.DeserializeObject<GrantReqData>(requestBody);
            Account account = DatabaseManager.db.GetAccountByToken(grant.token);
            string resp = "{\"msg\": \"Error\",  \"status\": 2,  \"type\": \"A\"}";
            if (account != null)
            {
                resp = "{\"data\": {  \"uid\": \"" + account.id + "\",  \"code\": \"" + DatabaseManager.db.GrantCode(account) + "\"  },  \"msg\": \"OK\",  \"status\": 0,  \"type\": \"A\"}";
                if(grant.appCode== "2289f1dd2b923c53")
                {
                    var url = "https://as.hypergryph.com/user/oauth2/v2/grant";

                    var b = new
                    {
                        appCode = "2289f1dd2b923c53",
                        encodeNonce = grant.encodeNonce,
                        token = "/kKCPAzTCkGOKft+X7sE7T0W",
                        type = 1
                    };

                    var json = JsonSerializer.Serialize(b);

                    var handler = new HttpClientHandler
                    {
                        UseProxy = false,
                    };

                    using var client = new HttpClient(handler);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");

                    var response = await client.PostAsync(url, content);
                    var responseString = await response.Content.ReadAsStringAsync();
                    Logger.Print(responseString);
                    GrantRspOff rsp = JsonSerializer.Deserialize<GrantRspOff>(responseString);
                    resp = "{    \"data\": {        \"token\": \"" + DatabaseManager.db.GrantCode(account) + "\",        \"hgId\": \"" + account.id + "\",        \"encodeSign\": \""+ rsp.data.encodeSign + "\"    },    \"msg\": \"OK\",    \"status\": 0,    \"type\": \"A\"}";
                }
            }

            ctx.Response.StatusCode = 200;

            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }*/
        [StaticRoute(HttpServerLite.HttpMethod.POST, "/user/oauth2/v2/grant")]
        public static async Task account_ugrant(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;

            GrantReqData grant = Newtonsoft.Json.JsonConvert.DeserializeObject<GrantReqData>(requestBody);
            GrantRsp rsp = new GrantRsp();
            Account account = DatabaseManager.db.GetAccountByToken(grant.token);
            rsp.type = "A";
            if (account != null)
            {
                rsp.msg = "OK";
                string grantedToken = DatabaseManager.db.GrantCode(account);
                rsp.data = new()
                {
                    hgId = account.id,
                    uid = account.id,
                    token = grantedToken,
                    code = grantedToken
                };
            }
            else
            {
                rsp.status = 2;
                rsp.msg = "Error";

            }

            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";
            await ctx.Response.SendAsync(JsonConvert.SerializeObject(rsp));
        }
        [StaticRoute(HttpServerLite.HttpMethod.POST, "/u8/user/auth/v2/grant")]
        public static async Task account_grant(HttpContext ctx)
        {
            string requestBody = ctx.Request.DataAsString;

            GrantReqData grant = Newtonsoft.Json.JsonConvert.DeserializeObject<GrantReqData>(requestBody);
            GrantRsp rsp = new GrantRsp();
            Account account = DatabaseManager.db.GetAccountByTokenGrant(grant.token);
            rsp.type = "A";
            if (account != null)
            {
                rsp.msg = "OK";
                rsp.data = new()
                {
                    hgId = account.id,
                    uid = account.id,
                    token = account.token,
                    code = account.grantToken,
                };
            }
            else
            {
                rsp.status = 2;
                rsp.msg = "Error";
            }

            ctx.Response.StatusCode = 200;

            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(JsonConvert.SerializeObject(rsp));
        }

        public class TokenChannelData
        {
            public string channelToken;

        }
        public class ChannelTokenData
        {
            public string code;
        }
        [StaticRoute(HttpServerLite.HttpMethod.POST, "/u8/user/auth/v2/token_by_channel_token")]
        public static async Task token_channel_token(HttpContext ctx)
        {
            try
            {
                string requestBody = ctx.Request.DataAsString;
                Console.WriteLine(requestBody);
                TokenChannelData data = Newtonsoft.Json.JsonConvert.DeserializeObject<TokenChannelData>(requestBody);
                ChannelTokenData channelTokenBody = Newtonsoft.Json.JsonConvert.DeserializeObject<ChannelTokenData>(data.channelToken);
                string resp = "{  \"data\": {    \"token\":\"" + channelTokenBody.code + "\"  },  \"msg\": \"OK\",  \"status\": 0,  \"type\": \"A\"}";

                ctx.Response.StatusCode = 200;

                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }
        public struct RegisterFormData
        {
            public string appCode;
            public string code;
            public string email;
            public string password;
        }
        
       
        [StaticRoute(HttpServerLite.HttpMethod.POST, "/user/auth/v1/register")]
        public static async Task register(HttpContext ctx)
        {
            try
            {
                string requestBody = ctx.Request.DataAsString;
                Console.WriteLine(requestBody);
                RegisterFormData data = Newtonsoft.Json.JsonConvert.DeserializeObject<RegisterFormData>(requestBody);
                string username = data.email.Split("@")[0];
                (string, int) msg = DatabaseManager.db.CreateAccount(username, "");
                string resp = "";
                if (msg.Item2 > 0)
                {
                    resp = "{\"msg\": \"" + msg.Item1 + "\",  \"status\": " + msg.Item2 + ",  \"type\": \"\"}";
                }
                else
                {
                    Account account = DatabaseManager.db.GetAccountByUsername(username);
                    resp = "{\"data\": {    \"token\":\"" + account.token + "\"  }, \"msg\": \"" + msg.Item1 + "\",  \"status\": " + msg.Item2 + ",  \"type\": \"\"}";
                }


                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";

                await ctx.Response.SendAsync(resp);
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }

        }

        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/gachahistory")]
        public static async Task gachahistory_api(HttpContext ctx)
        {
            string requestId = ctx.Request.Query.Elements["id"];
            string banner = ctx.Request.Query.Elements["banner"];
            string page = ctx.Request.Query.Elements["page"];
            PlayerData data = DatabaseManager.db.GetPlayerById(requestId);
            GachaHistoryAPI transactions = new();
            if (data != null)
            {
                transactions = GetGachaHistoryPage(data, banner, int.Parse(page));
            }
            else
            {
                transactions.transactionList = new();
            }
            ctx.Response.StatusCode = 200;
            await ctx.Response.SendAsync(JsonConvert.SerializeObject(transactions));
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/gachahistory")]
        public static async Task gachahistory(HttpContext ctx)
        {
            string requestId = ctx.Request.Query.Elements["id"];

            PlayerData data = DatabaseManager.db.GetPlayerById(requestId);
            string resp = "";
            if (data != null)
            {
                resp = File.ReadAllText("Data/GachaHistory/index.html").Replace("%dispatchip%", $"http://{Server.config.dispatchServer.accessAddress}:{Server.config.dispatchServer.accessPort}");
            }
            else
            {
                resp = File.ReadAllText("Data/GachaHistory/index_noplayerfound.html");
            }

            ctx.Response.StatusCode = 200;

            await ctx.Response.SendAsync(resp);
        }
    }
}
