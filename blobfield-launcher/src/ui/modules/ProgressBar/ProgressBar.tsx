import clsx from "clsx";
import React from "react";

type ProgressBarProps = {
  progress: number;
  message?: string;
  style?: string;
  stats?: string;
  visible?: boolean;
};

const ProgressBar: React.FC<ProgressBarProps> = ({ progress, style, message = "Loading resources...", stats, visible }) => {
    const className = clsx(style, "w-full h-4 bg-gray-300 rounded-full overflow-hidden");
  return (
    <div className="w-full grid gap-2 font-second">
        <div className="flex">
          <p className="flex-1 w-full">// {message}</p>
          <p className="flex-2 text-right w-fit">{stats}</p>
        </div>
        {visible && <div className={className}>
            <div
                className="h-full bg-gradient-to-r from-[#cccc00] to-ak-yellow transition-all duration-300"
                style={{ width: `${progress}%` }}
            />
        </div>}
    </div>
  );
};

export default ProgressBar;