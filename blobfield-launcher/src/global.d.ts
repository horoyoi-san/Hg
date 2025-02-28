declare type Config = {
    game_directory: string;
    is_installed: boolean;
    //idk what to add also
}

declare type ImageSlider = {
    url: string;
    link?: string;
}

declare type News = {
    data: string;
    time: string;
    url?: string;
}

declare type Setting = {
    type: "input" | "select" | "toggle" | "info";
    label?: string;
    value: string | boolean;
    options?: string[];
    style?: string;
    containerStyle?: string;
    labelStyle?: string;
    onClick?: () => void;
}

declare type SettingsGroup = {
    name: string;
    settings: Setting[];
    style?: string;
}

declare type MenuItem = {
  label: string;
  onClick: () => void;
};

declare type ContextMenuProps = {
    items: { label: string; onClick: () => void }[];
    children: React.ReactNode;
    style?: string;
}

declare type DownloadState = {
    progress: number;
    message: string;
    stats: string | undefined;
    isDownloading: boolean;
    isExtracting: boolean;
    isDownloaded: boolean;
    setProgress: (progress: number) => void;
    setStats: (stats: string | undefined) => void;
    setMessage: (message: string) => void;
    setDownloaded: (value: boolean) => void;
    startDownload: () => void | boolean;
    startExtract: () => void;
    stopDownload: () => void;
}

declare type IntegrityState = {
    progress: number;
    message: string;
    stats: string;
    isScanning: boolean;
    setProgress: (progress: number) => void;
    setStats: (stats: string | undefined) => void;
    setMessage: (message: string) => void;
    startScan: () => void;
    stopScan: () => void;
}