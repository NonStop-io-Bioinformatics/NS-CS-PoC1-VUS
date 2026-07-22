import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// In the container, nginx proxies /api -> report-service. For local `npm run dev`
// this proxy does the same against the host-published backend port (8088).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8088',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/api/, ''),
      },
    },
  },
})
