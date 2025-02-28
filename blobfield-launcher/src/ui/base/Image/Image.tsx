
type Image = {
    source: string;
    style?: string;
}

const Image = ({source, style}: Image) => {
    return(
        <img src={source} className={style}/>
    );
}

export default Image;