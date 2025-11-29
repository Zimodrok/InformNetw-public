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
  const currentPort = window.location.port;

  const cfg = window.__MUSICAPP_CONFIG;
  if (cfg && cfg.api_port) return `${protocol}//${host}:${cfg.api_port}`;

  if (window.__MUSICAPP_API_BASE) return window.__MUSICAPP_API_BASE;

  // If we're served from the frontend port, try the port just below (API) first.
  if (currentPort) {
    const p = parseInt(currentPort, 10);
    if (!isNaN(p) && p > 0) {
      return `${protocol}//${host}:${p - 1}`;
    }
    return `${protocol}//${host}:${currentPort}`;
  }

  // Last resort: hard default to 8080.
  return `${protocol}//${host}:8080`;
}

export function getPortsConfig() {
  return window.__MUSICAPP_CONFIG;
}
