import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The administrator/staff web app uses the same Node backend as Flutter.
// Set VITE_API_BASE_URL to override the default (http://127.0.0.1:5050).
export default defineConfig({
  plugins: [react()],
  server: { port: 5173 },
});
