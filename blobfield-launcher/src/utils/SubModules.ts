import { join, resourceDir } from "@tauri-apps/api/path";
import { sendNotification } from "@tauri-apps/plugin-notification";
import { open } from "@tauri-apps/plugin-dialog";
import { Config } from "@utils/index";

const config = new Config();

export async function getFullPath(): Promise<string> {
    try {
        return await join(await config.getValue<string>('gamePath'), await config.getValue<string>('gameExecutable'))
    } catch {
        return "";
    };
}

export async function setDefaultDirectory() {
    await config.setValue("gamePath", await resourceDir() + "\\EndField Game");
    await config.setValue("gameExecutable", "Endfield_TBeta_OS.exe");
    sendNotification({ title: `Default path changed`, body: `Path changed to ${await getFullPath()}` });
}

export async function customDirectory() {
    try {
        const customPath = await open({ directory: true, multiple: false });
        
        if(customPath === null) return;

        config.setValue("gamePath", customPath as string);
        console.log("edited");
    } catch(err) {
        console.log(err);
    }
}