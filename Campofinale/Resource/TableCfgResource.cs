namespace Campofinale.Resource
{
    public abstract class TableCfgResource
    {
        /// <summary>
        /// Not implemented yet
        /// </summary>
        public void OnLoad()
        {

        }
    }
    [AttributeUsage(AttributeTargets.Class, Inherited = false)]
    public class TableCfgTypeAttribute : Attribute
    {
        /// <summary>
        /// Path of the Resource
        /// </summary>
        public string Name { get; }
        /// <summary>
        /// Priority of load (still not implemented)
        /// </summary>
        public LoadPriority Priority { get; }

        public TableCfgTypeAttribute(string name, LoadPriority priority)
        {
            Name = name;
            Priority = priority;
        }
    }

    public enum LoadPriority
    {
        HIGH,
        MEDIUM,
        LOW
    }
}
