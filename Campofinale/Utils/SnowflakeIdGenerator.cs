using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Utils
{
    public class SnowflakeIdGenerator
    {
        private static readonly DateTime Epoch = new DateTime(2020, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        private readonly int _machineId; // es. 0–31 (5 bit)
        private int _sequence = 0;
        private long _lastTimestamp = -1L;

        private readonly object _lock = new object();

        public SnowflakeIdGenerator(int machineId)
        {
            _machineId = machineId & 0x1F; // 5 bit
        }

        public long GenerateId()
        {
            lock (_lock)
            {
                long timestamp = GetCurrentTimestamp();

                if (timestamp == _lastTimestamp)
                {
                    _sequence = (_sequence + 1) & 0xFFF; // 12 bit
                    if (_sequence == 0)
                    {
                        // Attendi il prossimo millisecondo
                        while ((timestamp = GetCurrentTimestamp()) <= _lastTimestamp) ;
                    }
                }
                else
                {
                    _sequence = 0;
                }

                _lastTimestamp = timestamp;

                return ((timestamp << 22) | ((long)_machineId << 12) | (long)_sequence);
            }
        }

        private long GetCurrentTimestamp()
        {
            return (long)(DateTime.UtcNow - Epoch).TotalMilliseconds;
        }
    }

}
