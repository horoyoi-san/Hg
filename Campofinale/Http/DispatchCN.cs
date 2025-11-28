using HttpServerLite;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Http
{
    internal class DispatchCN
    {
        public static string AES_KEY = "Wgxugl5qVirx7r3km6nXtA==";
        public static string EncryptWithTextIV(string plainText)
        {
            // Decodifica la chiave Base64
            byte[] keyBytes = Convert.FromBase64String(AES_KEY);

            using (Aes aes = Aes.Create())
            {
                aes.Key = keyBytes;
                aes.Mode = CipherMode.CBC;
                aes.Padding = PaddingMode.PKCS7;

                // Converti il testo in byte
                byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);

                // Prendi i primi 16 byte come IV
                byte[] iv = new byte[16];
                Array.Copy(plainBytes, iv, Math.Min(16, plainBytes.Length));

                // Se il testo è più corto di 16 byte, riempi il resto con zeri
                if (plainBytes.Length < 16)
                {
                    Array.Resize(ref iv, 16);
                }

                aes.IV = iv;

                using (MemoryStream ms = new MemoryStream())
                {
                    // Scrive l'IV all'inizio
                    ms.Write(iv, 0, iv.Length);

                    using (CryptoStream cs = new CryptoStream(ms, aes.CreateEncryptor(), CryptoStreamMode.Write))
                    {
                        cs.Write(plainBytes, 0, plainBytes.Length);
                        cs.FlushFinalBlock();
                    }

                    // Restituisce IV + ciphertext in Base64
                    return Convert.ToBase64String(ms.ToArray());
                }
            }
        }
        //DEFAULT
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/v2/3/prod-cbt3/default/default/network_config")]
        public static async Task network_config_cn(HttpContext ctx)
        {
            string resp = "{\"hgage\": \"https://web.hycdn.cn/endfield/protocol/cadpa-age.txt\", \"hggov\": \"https://beian.miit.gov.cn/\", \"u8root\": \"https://u8.hypergryph.com/u8\", \"gameclose\": false, \"netlogurl\": \"http://native-log-collect.hypergryph.com:32000\", \"launcherurl\": \"https://launcher.hypergryph.com\"}";
            resp = EncryptWithTextIV(resp);
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
        
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/v2/3/prod-cbt3/default/Windows/game_config")]
        public static async Task game_config_cn_windows(HttpContext ctx)
        {
            string resp = "{\"enableHotUpdate\": false, \"enableSRSAEncLog\": true, \"selectSrv\": false, \"enableIFixHotKeyReload\": true}";
            resp = EncryptWithTextIV(resp);
            ctx.Response.StatusCode = 200;
            ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
        
        [StaticRoute(HttpServerLite.HttpMethod.GET, "/api/remote_config/v2/3/prod-cbt3/default/Android/game_config")]
        public static async Task game_config_cn_android(HttpContext ctx)
        {
            string resp = "{\"mockLogin\": false, \"selectSrv\": false, \"enableHotUpdate\": true, \"enableNpcOptimize\": false, \"enableEntitySpawnLog\": false, \"enableCBT2AccessForbidden\": false, \"enableMobileFullScreenWaterMark\": false}";
            resp = EncryptWithTextIV(resp);
            ctx.Response.StatusCode = 200;
            ctx.Response.ContentLength = resp.Length;
            ctx.Response.ContentType = "application/json";

            await ctx.Response.SendAsync(resp);
        }
       
    }
}
