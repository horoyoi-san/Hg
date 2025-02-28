import { useState } from 'react';

const UpdatePopup = ({ message, onConfirm }: { message: string, onConfirm: () => void }) => {
    const [open, setOpen] = useState(true);

    return (
        <>
            {open && <div className="fixed inset-0 flex items-center justify-center bg-black/50 backdrop-blur-sm z-50 text-black">
                <div className="bg-white p-6 rounded-lg shadow-lg w-1/3 text-center">
                    <p className="relative text-lg mb-4">{message}</p>
                    <div className="relative h-[70px] flex justify-center gap-4">
                        <button
                            className="absolute left-0 bottom-0 w-fit bg-ak-yellow drop-shadow-md px-4 py-2 rounded-lg transition duration-150 hover:bg-ak-yellow/25 cursor-pointer"
                            onClick={() => setOpen(false)}
                        >
                            Maybe later
                        </button>
                        <button
                            className="absolute right-0 bottom-0 w-fit bg-[#f0f0f0] drop-shadow-md px-4 py-2 rounded-lg transition duration-150 hover:bg-black/5 cursor-pointer"
                            onClick={onConfirm}
                        >
                            Yep!
                        </button>
                    </div>
                </div>
            </div>}
        </>
    );
};

export default UpdatePopup;