import { openUrl } from "@tauri-apps/plugin-opener";

export const settingsConfig: SettingsGroup[] = [
    {
        name: "General",
        settings: [
            // { type: "toggle", label: "blob", value: false }
            { type: "info", value: "Work in progress"}
        ],
        style: "p-2"
    },
    // {
    //     name: "Awesome settings",
    //     settings: [
    //         { type: "select", label: "blob", value: "blob_id", options: ["yes", "no"], style: "w-full h-[42px] bg-white rounded-lg inset-shadow-sm inset-shadow-gray-200 outline-none" }
    //     ],
    //     style: "p-2"
    // },
    {
        name: "About",
        settings: [
            { type: "info", value: "Awesome launcher 3000", style: "text-center" },
            { 
                type: "info", 
                value: "Github link", 
                style: "text-center cursor-pointer hover:text-ak-yellow hover:underline w-fit", 
                onClick: async () => await openUrl("https://github.com/Xannix246/BlobField-Launcher"),
                containerStyle: "flex justify-center"
            }
        ],
        style: "p-2"
    }
];