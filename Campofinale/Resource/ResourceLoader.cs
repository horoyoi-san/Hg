using Newtonsoft.Json;
using System.Reflection;

namespace Campofinale.Resource
{
    public class ResourceLoader
    {
        /// <summary>
        /// Load table cfg automatically inside ResourceManager fields
        /// </summary>
        public static void LoadTableCfg()
        {
            var tableCfgTypes = GetAllTableCfgTypes();

            foreach (var type in tableCfgTypes)
            {
                var attr = type.GetCustomAttribute<TableCfgTypeAttribute>();
                string json = ResourceManager.ReadJsonFile(attr.Name);
                FieldInfo field = GetResourceField(type);
                if (field != null && json.Length > 0)
                {
                    object deserializedData = DeserializeJson(json, field.FieldType, type);
                    field.SetValue(null, deserializedData);
                    //Logger.Print($"Loaded {attr.Name} into {field.Name}");
                }
            }
        }
        private static object DeserializeJson(string json, Type fieldType, Type valueType)
        {
            if (fieldType.IsGenericType)
            {
                var genericTypeDef = fieldType.GetGenericTypeDefinition();

                if (genericTypeDef == typeof(Dictionary<,>))
                {
                    var keyType = fieldType.GetGenericArguments()[0];
                    var valType = fieldType.GetGenericArguments()[1];
                    return JsonConvert.DeserializeObject(json, typeof(Dictionary<,>).MakeGenericType(keyType, valType));
                }
                else if (genericTypeDef == typeof(List<>))
                {
                    return JsonConvert.DeserializeObject(json, typeof(List<>).MakeGenericType(valueType));
                }
            }

            return JsonConvert.DeserializeObject(json, valueType);
        }
        
        public static List<Type> GetAllTableCfgTypes()
        {
            return Assembly.GetExecutingAssembly()
                .GetTypes()
                .Where(t => t.IsClass && !t.IsAbstract && t.GetCustomAttribute<TableCfgTypeAttribute>() != null)
                .ToList();
        }
        public static FieldInfo GetResourceField(Type type)
        {
            var resourceManagerType = typeof(ResourceManager);
            var fields = resourceManagerType.GetFields(BindingFlags.Public | BindingFlags.Static);

            foreach (var field in fields)
            {
                var fieldType = field.FieldType;

                if (fieldType.IsGenericType)
                {
                    var genericTypeDef = fieldType.GetGenericTypeDefinition();

                    if (genericTypeDef == typeof(Dictionary<,>))
                    {
                        var valueType = fieldType.GetGenericArguments()[1];
                        if (valueType == type)
                        {
                            return field;
                        }
                    }
                    else if (genericTypeDef == typeof(List<>) && fieldType.GetGenericArguments()[0] == type)
                    {
                        return field;
                    }
                }
                else
                {
                    if (fieldType == type)
                    {
                        return field;
                    }
                }
            }

            return null;
        }
    }
}
