import clsx from "clsx";
import React from "react";

type Button = {
    children?: React.ReactNode;
    color?: 'white' | 'black' | 'red' | 'blue' | 'yellow';
    size?: 'small' | 'medium' | 'large';
    style?: string;
    rounded?: boolean;
    disabled?: boolean;
    onClick?: () => void;
}

const Button = ({children, color, size, style, rounded = false, disabled = false, onClick}: Button) => {
    let appliedColor: string = '';
    let appliedSize: string = '';
    switch(color) {
        case 'white':
            appliedColor = 'bg-white text-black';
            break;
        case 'black':
            appliedColor = 'bg-black text-white';
            break;
        case 'red':
            appliedColor = 'bg-red-600 text-white';
            break;
        case 'blue':
            appliedColor = 'bg-blue text-white';
            break;
        case 'yellow':
            appliedColor = 'bg-ak-yellow text-black';
            break;
    }

    switch(size) {

    }

    const className = clsx(
        "p-2 drop-shadow-md",
        rounded && "rounded-md",
        appliedColor,
        appliedSize,
        style
    );
    return(
        <button className={className} onClick={onClick} disabled={disabled}>{children}</button>
    );
}

export default Button;