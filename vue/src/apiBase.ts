declare global {
  interface Window {
    __MUSICAPP_API_BASE?: string;
    __MUSICAPP_CONFIG?: {
      api_port?: number;
      frontend_port?: number;
      sftp_port?: number;
    };
  }
}

export function getApiBase(): string {
  const envBase = (import.meta as any).env?.VITE_API_BASE?.trim?.();
  if (envBase) return envBase;

  const host = window.location.hostname || "localhost";
  const protocol = window.location.protocol || "http:";

  const cfg = window.__MUSICAPP_CONFIG;
  if (cfg && cfg.api_port) return `${protocol}//${host}:${cfg.api_port}`;

  if (window.__MUSICAPP_API_BASE) return window.__MUSICAPP_API_BASE;

  // Hard default to 8080 to avoid accidentally calling the frontend port.
  return `${protocol}//${host}:8080`;
}

export function getPortsConfig() {
  return window.__MUSICAPP_CONFIG;
}
