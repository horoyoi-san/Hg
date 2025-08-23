namespace Campofinale
{
    using Pastel;
    using System;
    using System.Collections.Generic;
    using System.Drawing;
    using System.Collections.Immutable;
    using System.Linq.Expressions;
    using System.Reflection;
    using Campofinale.Protocol;
    using Campofinale.Network;

    internal static class NotifyManager
    {
        private static List<Type> s_handlerTypes = new List<Type>();
        private static ImmutableDictionary<CsMsgId, (Server.HandlerAttribute, Server.HandlerAttribute.HandlerDelegate)> s_notifyReqGroup;

        public static void Init()
        {
            var handlers = ImmutableDictionary.CreateBuilder<CsMsgId, (Server.HandlerAttribute, Server.HandlerAttribute.HandlerDelegate)>();

            foreach (var type in s_handlerTypes)
            {
                foreach (var method in type.GetMethods())
                {
                    var attribute = method.GetCustomAttribute<Server.HandlerAttribute>();
                    if (attribute == null)
                        continue;

                    var parameterInfo = method.GetParameters();

                    var sessionParameter = Expression.Parameter(typeof(Player));
                    var cmdIdParameter = Expression.Parameter(typeof(int));
                    var packetParameter = Expression.Parameter(typeof(Packet));

                    var call = Expression.Call(method,
                        Expression.Convert(sessionParameter, parameterInfo[0].ParameterType),
                        Expression.Convert(cmdIdParameter, parameterInfo[1].ParameterType),
                        Expression.Convert(packetParameter, parameterInfo[2].ParameterType));

                    var lambda = Expression.Lambda<Server.HandlerAttribute.HandlerDelegate>(call, sessionParameter, cmdIdParameter, packetParameter);

                    if (!handlers.TryGetKey(attribute.CmdId, out _))
                        handlers.Add(attribute.CmdId, (attribute, lambda.Compile()));
                }
            }
            s_notifyReqGroup = handlers.ToImmutable();
        }

        public static async void Notify(Player session, CsMsgId cmdId, Network.Packet packet)
        {
            await Task.Run(() =>
            {

                if (s_notifyReqGroup.TryGetValue(cmdId, out var handler))
                {

                    handler.Item2.Invoke(session, ((int)cmdId), packet);
                }
                else
                {
                    if (!Server.csMessageToHide.Contains(cmdId) && Server.config.logOptions.packets)
                        Logger.PrintWarn($"Can't find handler for {(Enum.GetName(typeof(CsMsgId), cmdId)).ToString().Pastel(Color.FromArgb(165, 229, 250))} ({(cmdId).ToString().Pastel(Color.FromArgb(165, 229, 250))})");
                }
            });
            
        }

        public static void AddReqGroupHandler(Type type)
        {
            s_handlerTypes.Add(type);
        }
    }
}
