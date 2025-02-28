import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { useState, useEffect } from "react";
import { CgMenu } from "react-icons/cg";
import { exists, BaseDirectory, readDir } from '@tauri-apps/plugin-fs';
import { getFullPath, useDownloadStore, customDirectory, setDefaultDirectory, UseIntegrityStore } from "@utils/index";
import { Button } from "@base/index";
import clsx from "clsx";
import { sendNotification } from "@tauri-apps/plugin-notification";
import { Popover, PopoverTrigger, PopoverContent, PopoverPortal } from "@radix-ui/react-popover";

export default function GameButton() {
    const { startDownload, isDownloading } = useDownloadStore();
    const { startScan, isScanning } = UseIntegrityStore();
    const [isRunning, setIsRunning] = useState(false);
    const [isInstalled, setInstalled] = useState(false);
    const [hasArchive, setHasArchive] = useState(false);
    const [editedDirectory, setEditedDirectory] = useState(false);
    const [open, setOpen] = useState(false);

    const updateGameStatus = async () => {
        try {
            const installed = await exists(await getFullPath());
            setInstalled(installed);
            if (!installed) {
                const dir = await readDir('temp', { baseDir: BaseDirectory.Resource });
                setHasArchive(dir.length > 0);
            }
        } catch (err) {
            if (!isInstalled) {
                sendNotification({ title: `Failed to load game directory`, body: `${err}` });
            }
            setInstalled(false);
        }
    };

    useEffect(() => {
        updateGameStatus();
        const unlistenPromise = listen("game_started", (event) => {
            setIsRunning(event.payload as boolean);
        });
        return () => {
            unlistenPromise.then(unlisten => unlisten());
        };
    }, []);

    useEffect(() => {
        if (editedDirectory) {
            updateGameStatus();
            setEditedDirectory(false);
        }
    }, [editedDirectory]);

    useEffect(() => { updateGameStatus() }, [isDownloading]);
    useEffect(() => { updateGameStatus() }, [isScanning]);

    const startGame = async () => {
        try {
            await invoke("run_game", { gamePath: await getFullPath() });
        } catch (err) {
            sendNotification({ title: `Failed to start game`, body: `${err}` });
        }
    };

    const className = clsx("hover:bg-[#cccc00] w-full cursor-pointer transition duration-150 disabled:cursor-not-allowed disabled:bg-[#cccc00]")

    return (
        <div className="w-full flex">
            {
                isInstalled ? (
                    <Button
                        color="yellow"
                        style={className}
                        disabled={isRunning || isScanning}
                        onClick={startGame}
                    >{isRunning ? "Game is running" : (isScanning ? "Scanning" : "Run game")}</Button>
                ) : (
                    <Button
                        color="yellow"
                        style={className}
                        disabled={isDownloading || isScanning}
                        onClick={startDownload}
                    >{isDownloading ? "Installing" : (hasArchive ? "Continue download" : (isScanning ? "Scanning" : "Install game"))}</Button>
                )
            }
            {<Button
                color="yellow" style="hover:bg-[#cccc00] cursor-pointer transition duration-150 disabled:cursor-not-allowed disabled:bg-[#cccc00]"
                disabled={isRunning || isDownloading || isScanning}
            >
                <div className="w-full h-full justify-center hover:bg-[#cccc00] transition duration-150" >
                    <Popover open={open} onOpenChange={setOpen}>
                        <PopoverTrigger asChild>
                            <div className="w-[24px] h-[24px] cursor-pointer">
                                <CgMenu className="w-full h-full" />
                            </div>
                        </PopoverTrigger>
                        <PopoverPortal>
                            <PopoverContent className="text-white bg-[#202020]/50 shadow-lg border border-[#707070] backdrop-blur-sm text-black rounded w-56 z-50 mr-12">
                                <div className="w-full hover:bg-black/25 transition duration-150 cursor-pointer p-3"
                                    onClick={async () => {
                                        await setDefaultDirectory();
                                        setEditedDirectory(true);
                                        setOpen(false);
                                    }}>
                                    Set default directory
                                </div>
                                <div className="w-full hover:bg-black/25 transition duration-150 cursor-pointer p-3"
                                    onClick={async () => {
                                        await customDirectory();
                                        setEditedDirectory(true);
                                        setOpen(false);
                                    }}>
                                    Select game path
                                </div>
                                <div className="w-full hover:bg-black/25 transition duration-150 cursor-pointer p-3"
                                    onClick={async () => {
                                        if (!isScanning) {
                                            startScan();
                                        }
                                        setOpen(false);
                                    }}>
                                    Check file integrity
                                </div>
                            </PopoverContent>
                        </PopoverPortal>
                    </Popover>
                </div>
            </Button>}
        </div>
    );
}
