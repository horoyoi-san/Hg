import clsx from "clsx";
import React, { useState, useRef, useEffect } from "react";

const ContextMenu = ({ items, children, style }: ContextMenuProps) => {
  const [visible, setVisible] = useState(false);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const menuRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const handleClick = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setVisible(false);
      }
    };
    document.addEventListener("click", handleClick);
    return () => document.removeEventListener("click", handleClick);
  }, []);

  const handleContextMenu = (event: React.MouseEvent) => {
    event.preventDefault();
    setPosition({ x: event.clientX, y: event.clientY });
    setVisible(true);
  };
  const className = clsx("h-full font-second min-w-[200px]", style)

  return (
    <div className={className} onContextMenu={handleContextMenu}>
      {children}
      {visible && (
        <div
          ref={menuRef}
          className="absolute bg-[#202020]/50 shadow-lg min-w-[200px] border border-[#707070] backdrop-blur-sm rounded-md py-1 z-50"
          style={{ top: position.y, left: position.x }}
        >
          {items.map((item, index) => (
            <div
              key={index}
              className="px-4 py-2 hover:bg-[#646464]/25 cursor-pointer"
              onClick={() => {
                item.onClick();
                setVisible(false);
              }}
            >
              {item.label}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default ContextMenu;
