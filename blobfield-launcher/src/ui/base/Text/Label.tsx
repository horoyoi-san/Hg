import React from "react";
import clsx from "clsx";

type Label = {
    children: React.ReactNode;
    color?: 'white' | 'black' | 'red' | 'blue' | 'yellow';
    size?: string;
    style?: string;
}

const Label = ({children, color = 'white', size, style}: Label) => {
    let appliedColor: string = '';
    switch(color) {
        case 'white':
            appliedColor = 'text-white';
            break;
        case 'black':
            appliedColor = 'text-black';
            break;
        case 'red':
            appliedColor = 'text-red-600';
            break;
        case 'blue':
            appliedColor = 'text-blue';
            break;
        case 'yellow':
            appliedColor = 'text-ak-yellow';
            break;
    }

    const className = clsx(
        appliedColor,
        size,
        style
    );
    return(
        <div className={className}>{children}</div>
    );
}

export default Label;