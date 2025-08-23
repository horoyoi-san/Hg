using Campofinale.Database;
using HttpServerLite;
using MongoDB.Driver;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Metadata;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using static Campofinale.Http.GateBulletin.DetailRsp;
using static Campofinale.Http.GateBulletin.DetailRsp.DetailData;
using static System.Net.Mime.MediaTypeNames;

namespace Campofinale.Http
{
    public class GateBulletin
    {
        //http://192.168.1.3:5000/bulletin/aggregate?lang=en-us&platform=Windows&server=EUAndUS&type=0&code=endfield_cbt2_overseas&hideDetail=1
        public class AggregateRsp
        {
            public int code = 0;
            public string msg = "";

            public Data data = new Data();
            public class Data
            {
                public string topicCid = "2113";
                public int type = 1;
                public string platform = "Windows";
                public string server = "#DEFAULT";
                public string channel = "#DEFAULT";
                public string lang = "en";
                public string key = "1:Windows:#DEFAULT:#DEFAULT:en";
                public string version = "d41d8cd98f00b204e9800998ecf8427e";
                public List<string> onlineList = new();
                public List<string> popupList = new();
                public int popupVersion;
                public int updatedAt = 0;
                public List<BulletinEntry> list = new();

                public class BulletinEntry
                {
                    public string cid;
                    public string type;

                    public string tab;
                    public string title;
                    public int startAt;
                    public string? tag;
                    public int? sort;
                }
            }
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/bulletin/aggregate")]
        public static async Task bulletin_aggregate(HttpContext ctx)
        {
            string resp = "{}";
            AggregateRsp rsp = new();
            rsp.data.list.Add(new AggregateRsp.Data.BulletinEntry()
            {
                cid = "1",
                title = "Endfield Private Server",
                type = "news",
                tab = "news",
                sort = 0,
                tag = "campaign",
                startAt = 0,
            });
            rsp.data.list.Add(new AggregateRsp.Data.BulletinEntry()
            {
                cid = "2",
                title = "Informations",
                type = "news",
                tab = "news",
                sort = 1,
                tag = "campaign",
                startAt = 0,
            });
            resp = JsonConvert.SerializeObject(rsp);
            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        public class DetailRsp
        {
            public int code = 0;
            public string msg = "";
            public DetailData data=new();
            

            public class DetailData
            {
                public string title = "Test";
                public string header = "Test";
                public TextData data = new();
                public string content = "null";
                public string displayType = "rich_text";

                public class TextData
                {
                    public string html;
                    public string text;
                }
            }
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/bulletin/detail/2")]
        public static async Task bulletin_1(HttpContext ctx)
        {
            string resp = "{}";
            DetailRsp rsp = new();
            rsp.data.title = "Informations";
            rsp.data.header = "Informations";
            rsp.data.data = new TextData()
            {
                html= "Repository <a href='https://git.muiegratis.online/suikoakari/Campofinale'>https://git.muiegratis.online/suikoakari/Campofinale</a>",
            };
            resp = JsonConvert.SerializeObject(rsp);
            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/bulletin/detail/1")]
        public static async Task bulletin_2(HttpContext ctx)
        {
            string resp = "{}";
            DetailRsp rsp = new();
            rsp.data.title = "Endfield Private Server";
            rsp.data.header = "Endfield Private Server";
            rsp.data.data = new TextData()
            {
                html = "Welcome to Campofinale! A private server for Arknights: Endfield!",
            };
            resp = JsonConvert.SerializeObject(rsp);
            ctx.Response.StatusCode = 200;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
    }
}
