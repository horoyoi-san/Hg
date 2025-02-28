import { LazyStore } from '@tauri-apps/plugin-store';

const store = new LazyStore("./config.json")

class Config {
    constructor() {

    }

    public async getValue<T extends string | number>(key: string): Promise<T> {
        return (await store.get<T>(key) as T);
    }

    public async setValue(key: string, value: string | number) {
        await store.set(key, value);
        await store.save();
        return;
    }
}

export default Config;