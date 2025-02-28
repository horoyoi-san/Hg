import { BaseConfig } from "@data/index";
import { ProgressBar } from "@modules/index";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { BaseDirectory, join, resourceDir } from "@tauri-apps/api/path";
import { exists, readTextFile, writeFile } from "@tauri-apps/plugin-fs";
import { sendNotification } from "@tauri-apps/plugin-notification";
import { Config } from "@utils/index";
import { useEffect, useRef, useState } from "react";
import { create } from "zustand";

export const UseIntegrityStore = create<IntegrityState>((set) => ({
    progress: 0,
    message: "Initializing...",
    stats: "",
    isScanning: false,
    setProgress: (progress) => set({ progress }),
    setStats: (stats) => set({ stats }),
    setMessage: (message) => set({ message }),
    startScan: () => { set({ isScanning: true, progress: 0, message: "Starting check..." }) },
    stopScan: () => set({ isScanning: false, message: "Done!" }),
}));

const CheckFileIntegrity = () => {
    const { progress, message, stats, isScanning, setProgress, setMessage, setStats, stopScan } = UseIntegrityStore();
    const [visible, setVisible] = useState(true);
    const [files, setFiles] = useState("");
    const filesRef = useRef("");

    useEffect(() => {
        const unlistenProgress = listen("integrity_progress", (event: any) => {
            const [progress, checked, totalFiles] = event.payload;
            setProgress(progress);
            setMessage("Checking files...")
            setStats(`${progress.toFixed(2)}% | Checked: ${checked}/${totalFiles} files`);
        });

        const unlistenDownload = listen("download_progress", (event: any) => {
            const [progress, speed] = event.payload;
            setVisible(true);
            setProgress(progress);
            setMessage("Downloading resources...");
            setStats(`${progress.toFixed(2)}% (${speed > 1024 ? (speed / 1024).toFixed(2) + " MB/s" : speed + " KB/s"}) | File ${filesRef.current}`);
        });

        const unlistenExtract = listen("extract_progress", () => {
            setVisible(false);
            setMessage("Unpacking data, please wait...");
            setStats(`File ${filesRef.current}`);
        });

        return () => {
            unlistenProgress.then((f) => f());
            unlistenDownload.then((f) => f());
            unlistenExtract.then((f) => f());
        };
    }, [])

    useEffect(() => {
        if (isScanning) checkFiles();
    }, [isScanning])

    useEffect(() => {
        filesRef.current = files;
    }, [files]);

    async function checkFiles() {
        setVisible(true);
        const config = new Config();
        const resourcePath = await resourceDir();
        const gamePath = await config.getValue("gamePath");
        const manifest = await join(resourcePath, "rescue/manifest.json");
        const archivesPath = await join(resourcePath, "rescue/archives.json");

        if (!await exists(manifest)) {
            try {
                const response = await fetch(BaseConfig.MANIFEST_URL, { method: "GET" });
                const data = new Uint8Array(await response.arrayBuffer());

                await writeFile("rescue/manifest.json", new Uint8Array(data), {
                    baseDir: BaseDirectory.Resource,
                });
            } catch (err) {
                return sendNotification({ title: "Failed to check file integrity", body: `${err}` });
            }
        }

        if (!await exists(archivesPath)) {
            try {
                const response = await fetch(BaseConfig.ARCHIVES_TABLE, { method: "GET" });
                const data = new Uint8Array(await response.arrayBuffer());

                await writeFile("rescue/archives.json", new Uint8Array(data), {
                    baseDir: BaseDirectory.Resource,
                });
            } catch (err) {
                return sendNotification({ title: "Failed to check file integrity", body: `${err}` });
            }
        }

        const archives = JSON.parse((await readTextFile(archivesPath)));

        await invoke("check_integrity", { gameDir: gamePath, manifestPath: manifest }).then(async (res) => {
            const needToDownload: string[] = [];

            for (const [entry, file] of Object.entries<string[]>(archives)) {
                for (const archive of res as string[]) {
                    if (file.find(e => e.includes(archive))) {
                        needToDownload.push(entry);
                        break;
                    }
                }
            }

            try {
                for (let i = 0; i < needToDownload.length; i++) {
                    const archive = needToDownload[i];
                    setFiles(`${i + 1}/${needToDownload.length}`);
                    console.log()
                    await invoke("download_file", {
                        url: `${BaseConfig.RESTORE_FILES_URL}${archive}`,
                        resourcePath: resourcePath
                    });
                    await invoke("extract_archive", {
                        archivePath: `${resourcePath}/temp/${archive}`,
                        extractPath: gamePath,
                        sevenZipPath: `${resourcePath}/7z/7z.exe`,
                        manifestPath: manifest
                    });
                }

                stopScan();
                setVisible(false);
                sendNotification({ title: "Checking file integrity was completed!", body: (res as Array<string>).length === 0 ? "All files have been successfully checked!" : `${(res as Array<string>).length} files were corrupted or didn't exist and were redownloaded` });
            } catch (err) {
                sendNotification({ title: "Failed to download files", body: `${err}` });
            }
        });
    }

    return (
        <div className="w-full flex flex-col">
            {isScanning && <ProgressBar style="w-full" progress={progress} message={message} stats={stats} visible={visible} />}
        </div>
    );
}

export default CheckFileIntegrity;