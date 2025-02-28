import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import init from "@utils/init";

window.addEventListener("contextmenu", (event) => event.preventDefault());

(async () => {
    await init();
    ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
        <React.StrictMode>
            <App />
        </React.StrictMode>,
    );
})();