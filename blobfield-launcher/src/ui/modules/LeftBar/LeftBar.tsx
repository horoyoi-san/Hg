import clsx from "clsx";
import { IoIosArrowForward } from "react-icons/io";
import { useEffect, useRef, useState } from "react";
import { ContextMenu } from "@base/index";

const items = [
    { label: "Option 1", onClick: () => alert("Option 1") },
    { label: "Option 2", onClick: () => alert("Option 2") },
]

const LeftBar = () => {
    const [open, setOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement | null>(null);


    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
                setOpen(false);
            }
        };

        if (open) {
            document.addEventListener("click", handleClickOutside);
        } else {
            document.removeEventListener("click", handleClickOutside);
        }

        return () => {
            document.removeEventListener("click", handleClickOutside);
        };
    }, [open]);

    const className = clsx(
        'absolute bg-black/75 h-full w-[390px] translation duration-300 ease-[cubic-bezier(0.8,0.05,0.05,0.8)] flex flex-col z-30 bg-[url(/src/assets/bg.png)] bg-center bg-no-repeat bg-cover',
        open ? 'left-0' : 'left-[-326px]'
    );
    const arrowClassName = clsx(
        "w-[42px] h-[42px] m-2 translation absolute right-0 bottom-0 duration-300 ease-[cubic-bezier(0.8,0.05,0.05,0.8)] hover:bg-white/25 rounded-lg",
        open && "-rotate-180"
    );
    return (
        <div ref={menuRef} className={className} onClick={() => setOpen(true)}>
            <div className="place-items-end">
                <IoIosArrowForward className={arrowClassName} onClick={(e) => {
                    e.stopPropagation();
                    setOpen(!open);
                }} />
            </div>
            <div className="overflow-y-auto scrollbar-hidden grid gap-4 p-20">
                <ContextMenu items={items}>
                    <div className="bg-black/50 p-5 rounded-lg">
                        Originally there was supposed to be presets here, but there aren't ¯\\_(ツ)_/¯
                        <br />
                        <br />
                        Maybe I'll do something here, maybe not
                    </div>
                </ContextMenu>
            </div>
        </div>
    );
}

export default LeftBar;