import { createApp } from "vue";
import App from "./App.vue";
import { router } from "./router";
import "./style.css";

async function bootstrap() {
  let apiBase = "";
  let cfg: any = null;
  try {
    const res = await fetch("/config/ports", { credentials: "include" });
    if (res.ok) {
      cfg = await res.json();
      const host = window.location.hostname || "localhost";
      const protocol = window.location.protocol || "http:";
      if (cfg && cfg.api_port) {
        apiBase = `${protocol}//${host}:${cfg.api_port}`;
      }
    }
  } catch (e) {
    console.warn("ports config fetch failed, using defaults", e);
  }

  (window as any).__MUSICAPP_API_BASE = apiBase || undefined;
  (window as any).__MUSICAPP_CONFIG = cfg || undefined;

  createApp(App).use(router).mount("#app");
}

bootstrap();
