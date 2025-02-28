import clsx from "clsx";
import { useEffect, useState } from "react";
import { getNews, getImages } from "./Request";
import SimpleImageSlider from "react-simple-image-slider";
import { openUrl } from '@tauri-apps/plugin-opener';

const NewsBlock = () => {
    const [news, setNews] = useState<News[]>();
    const [images, setImages] = useState<ImageSlider[]>();
    const className = clsx('absolute bottom-0 left-0 p-28 z-5 flex gap-5 justify-center place-items-center font-second');

    useEffect(() => {
        const fetchData = async () => {
            try {
                const newsData = await getNews();
                const imagesData = await getImages();

                setNews(newsData);
                setImages(imagesData);
            } catch (error) {
                console.error("Error fetching data", error);
            }
        };

        fetchData();
    }, []);

    return (
        <div className={className}>
            <div className="w-[320px] h-[180px] bg-black/25 rounded-lg overflow-hidden place-content-center">
                {images?.length == 0 && <div className="text-center">Failed to fetch news images ☹️</div>}
                {images?.length !== 0 && <SimpleImageSlider
                    images={images || []}
                    width={320}
                    height={180}
                    showNavs={true}
                    showBullets={true}
                    autoPlay={true}
                    navSize={32}
                    navStyle={2}
                    navMargin={15}
                    useGPURender={true}
                    style={{
                        borderRadius: "5px",
                        overflow: "hidden",
                        cursor: "pointer"
                    }}
                    onClick={async (index) => images && await openUrl((images[index]?.link as string))}
                />}
            </div>
            <div className="w-[600px] h-[170px] bg-black/25 rounded-lg overflow-hidden grid">
                <div className="bg-black/50 h-fit">
                    <div className="p-2 bg-ak-yellow text-black w-fit rounded-br-lg font-default">News</div>
                </div>
                <div className="overflow-y-scroll">
                    {news?.length == 0 && <div className="text-center">Failed to fetch news ☹️</div>}
                    {
                        news?.map((title, index) => (
                            <div className="p-2 flex w-full" key={index}>
                                {title.url ? (
                                    <a className="flex-1 hover:text-ak-yellow transition duration-150"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        href={title.url}
                                    >{title.data}</a>
                                ) : (
                                    <div className="flex-1">{title.data}</div>
                                )}
                                <div className="right-0 text-gray-300">{new Date(title.time).toLocaleString(undefined, { dateStyle: 'short' })}</div>
                            </div>
                        ))
                    }
                </div>
            </div>
        </div>
    );
}

export default NewsBlock;