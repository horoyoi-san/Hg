import { BaseConfig } from "@data/index";
import { fetch } from "@tauri-apps/plugin-http";

export async function getImages(): Promise<ImageSlider[]> {
    try {
        const response = await fetch(BaseConfig.IMAGES_URL, { method: "GET" });
        if (!response.ok) throw new Error("Failed to load images");

        const images: ImageSlider[] = await response.json();
        return images;
    } catch (error) {
        console.error("Error fetching images:", error);
        return [];
    }
}

export async function getNews(): Promise<News[]> {
    try {
        const response = await fetch(BaseConfig.NEWS_URL, { method: "GET" });
        if (!response.ok) throw new Error("Failed to load news");

        const news: News[] = await response.json();
        console.log(response);
        return news;
    } catch (error) {
        console.error("Error fetching news:", error);
        return [];
    }
}