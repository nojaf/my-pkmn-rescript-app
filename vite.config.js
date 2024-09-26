import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import rescript from "@nojaf/vite-plugin-rescript"

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [rescript(), react({
    include: /\.(jsx|re.js)$/
  })],
})
