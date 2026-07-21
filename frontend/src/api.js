// API base: '/api' in the container (nginx proxy) or via the vite dev proxy.
const BASE = import.meta.env.VITE_API_BASE || '/api'

async function get(path) {
  const res = await fetch(BASE + path)
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
  return res.json()
}

export const api = {
  stats: () => get('/stats'),
  reports: () => get('/reports'),
  report: (id) => get(`/reports/${id}`),
  history: (id) => get(`/reports/${id}/history`),
  audit: (id) => get(`/reports/${id}/audit`),
}
