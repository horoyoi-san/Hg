import "./css/App.css";
import "./css/text.css";
import { getVersion } from '@tauri-apps/api/app';
import { useEffect, useState } from "react";
import { CheckFileIntegrity, DownloadManager, update, UpdatePopup } from "@utils/index";
import { GameButton, LeftBar, NewsBlock, Settings, TopBar } from "@modules/index";
import { check, Update } from "@tauri-apps/plugin-updater";


const App = () => {
    const [version, setVersion] = useState("");
    const [message, setMessage] = useState("");
    const ver = async () => {
        setVersion(await getVersion());

        try {
            const update = await check({ target: "windows-x86_64"});
            if(update !== null) setMessage(`Found update ${update?.version} (current: ${await getVersion()}) from ${update?.date?.split(" ")[0].split("-").reverse().join(" ")}. Do you want install it?`);
        } catch {
            console.log("failed to fetch update");
        }
    }

    const doUpdate = async () => {
        await update(await check({ target: "windows-x86_64"}) as Update);
    }

    useEffect(() => {
        ver();
    }, []);

    return (
        <div className="h-screen w-full bg-[url(/src/assets/base_bg.jpg)] bg-center bg-no-repeat bg-cover font-default">
            <div className="absolute w-[320px] h-[200px] bg-center bg-[url(/src/assets/logo_white.png)] bg-no-repeat bg-cover mx-24 my-12"/>
            {message !== "" && <UpdatePopup 
                message={message}
                onConfirm={doUpdate}
            />}
            <Settings />
            <TopBar />
            <LeftBar />
            <div className="absolute bottom-0 right-0 my-10 z-10 flex flex-nowrap justify-end place-items-center gap-20 w-[90%]">
                <div className="w-full">
                    <DownloadManager/>
                    <CheckFileIntegrity/>
                </div>
                <div className="bg-transparent rounded-full overflow-hidden w-[350px] h-fit mr-10">
                    <div className="rounded-full shadow-inner border border-gray-500 flex">
                        <GameButton />
                    </div>
                </div>
            </div>
            <NewsBlock />

            <div className="absolute w-full h-[512px] bottom-0 right-0">
                <div className="absolute inset-0 bg-gradient-to-t from-[#1b1b1b] from-25%" />
                <div
                    className="absolute inset-0 bg-[url('/src/assets/heights.png')] bg-no-repeat bg-cover bg-bottom"
                    style={{
                        WebkitMaskImage: "linear-gradient(to top, rgba(0,0,0,1), rgba(0,0,0,0))",
                        maskImage: "linear-gradient(to top, rgba(0,0,0,1), rgba(0,0,0,0))"
                    }}
                />
            </div>
            <div className="absolute right-0 bottom-0 m-2 font-second font-light text-xs">
                Launcher version: {version}
            </div>
        </div>
    );
}

export default App;
