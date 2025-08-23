using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncAllDialog : Packet
    {
        public PacketScSyncAllDialog(Player player) {
            ScSyncAllDialog dialogues = new()
            {

            };
            foreach (var item in ResourceManager.dialogIdTable.dialogStrToNum)
            {
                try
                {
                    dialogues.DialogList.Add(new Dialog()
                    {
                        DialogId = item.Value,

                    });
                }
                catch (Exception ex)
                {

                }

            }

            SetData(ScMsgId.ScSyncAllDialog, dialogues);
        }
    }
}
