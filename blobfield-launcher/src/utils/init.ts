import { exists, mkdir, BaseDirectory, writeFile } from "@tauri-apps/plugin-fs";
import { fetch } from "@tauri-apps/plugin-http";
import { resourceDir } from "@tauri-apps/api/path";
import { getFullPath, Config } from "@utils/index";
import { Update } from "@tauri-apps/plugin-updater";
import { relaunch } from "@tauri-apps/plugin-process";

const config = new Config();

async function init() {
    const gameDir = await exists("EndField Game", {
        baseDir: BaseDirectory.Resource,
    });
    const tempDir = await exists("temp", { baseDir: BaseDirectory.Resource });
    const rescueDir = await exists("rescue", { baseDir: BaseDirectory.Resource });
    const zDir = await exists("7z", { baseDir: BaseDirectory.Resource });

    !gameDir && (await mkdir("EndField Game", { baseDir: BaseDirectory.Resource }));
    !tempDir && (await mkdir("temp", { baseDir: BaseDirectory.Resource }));
    !rescueDir && (await mkdir("rescue", { baseDir: BaseDirectory.Resource }));
    !zDir && (await mkdir("7z", { baseDir: BaseDirectory.Resource }));

    if ((await getFullPath()) === "") {
        config.setValue("gamePath", (await resourceDir()) + "\\EndField Game");
        config.setValue("gameExecutable", "Endfield_TBeta_OS.exe");
    }

    if (!(await exists("7z/7z.exe", { baseDir: BaseDirectory.Resource }))) {
        const url = "https://www.7-zip.org/a/7zr.exe";
        console.log("Downloading 7-Zip CLI...");
        const response = await fetch(url, { method: "GET" });
        const data = new Uint8Array(await response.arrayBuffer());

        if (!response.ok) {
        throw new Error(`Error while loading: ${response.status}`);
        }

        await writeFile(`7z/7z.exe`, new Uint8Array(data), {
        baseDir: BaseDirectory.Resource,
        });
    }
}

export async function update(update: Update) {
    try {
        if (update) {
            let downloaded = 0;
            let contentLength = 0;
            await update.downloadAndInstall((event) => {
            switch (event.event) {
                case 'Started':
                contentLength = (event.data.contentLength as number);
                console.log(`started downloading ${event.data.contentLength} bytes`);
                break;
                case 'Progress':
                downloaded += event.data.chunkLength;
                console.log(`downloaded ${downloaded} from ${contentLength}`);
                break;
                case 'Finished':
                console.log('download finished');
                break;
            }
            });
        
            console.log('update installed');
            await relaunch();  
        }
    } catch(err) {
        console.log(err);
    }
}

export default init;