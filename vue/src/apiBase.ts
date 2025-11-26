declare global {
  interface Window {
    __MUSICAPP_API_BASE?: string
    __MUSICAPP_CONFIG?: { api_port?: number; frontend_port?: number; sftp_port?: number }
  }
}

export function getApiBase(): string {
  return window.__MUSICAPP_API_BASE || "http://localhost:8080"
}

export function getPortsConfig() {
  return window.__MUSICAPP_CONFIG
}
