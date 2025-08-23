using Campofinale;

using Pastel;
using System.Diagnostics;
public static class Logger
{

    public static Dictionary<string, string> ClassColors = new Dictionary<string, string>()
    {
        {"Server","03fcce" },
        {"Dispatch", "0307fc" }
    };
    private static string GetCallingClassName()
    {
        StackTrace stackTrace = new StackTrace();

        var frame = stackTrace.GetFrame(2);
        var method = frame?.GetMethod();
        return method?.DeclaringType?.Name ?? "Server";
    }
    /// <summary>
    /// Print a text in the console
    /// </summary>
    /// <param name="text"></param>
    public static void Print(string text)
    {
        string className = GetCallingClassName();
        Logger.Log(text);
        string prefix = "<" + "INFO".Pastel("03fcce") + $":{className.Pastel("999")}>";
        Console.WriteLine($"{prefix} " + text);
    }
    /// <summary>
    /// Print a text in the console as Error
    /// </summary>
    /// <param name="text"></param>
    public static void PrintError(string text)
    {
        string className = GetCallingClassName();
        Logger.Log(text);
        string prefix = "<" + "ERROR".Pastel("eb4034") + $":{className.Pastel("999")}>";
        Console.WriteLine($"{prefix} " + text.Pastel("917e7e"));
    }
    /// <summary>
    /// Print a text in the console as a Warn
    /// </summary>
    /// <param name="text"></param>
    public static void PrintWarn(string text)
    {
        if (!Server.config.logOptions.packetWarnings)
            return;

        string className = GetCallingClassName();
        Logger.Log(text);
        string prefix = "<" + "WARN".Pastel("ff9100") + $":{className.Pastel("999")}>";
        Console.WriteLine($"{prefix} " + text);
    }
    public static string GetColor(string c)
    {
        if (ClassColors.ContainsKey(c))
            return ClassColors[c];
        
        return "999";
    }
    private static StreamWriter logWriter;
    private static bool hideLogs;

    public static void Initialize(bool hideLogs = false)
    {
        Logger.hideLogs = hideLogs;
        
        logWriter = new StreamWriter("latest.log", false);
        logWriter.AutoFlush = true;
    }
    /// <summary>
    /// Log a message
    /// </summary>
    /// <param name="message"></param>
    private static void Log(string message)
    {
        if(hideLogs)
            return;
        
        try
        {
            logWriter.WriteLine($"{DateTime.Now}: {message}");
        }
        catch(Exception e)
        {

        }
    }

    public static void Close()
    {
        logWriter.Close();
    }
}
