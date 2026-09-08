import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The staff web app talks to the same Node backend as the Flutter client.
// Set VITE_API_BASE_URL to override the default (http://127.0.0.1:5050).
export default defineConfig({
  plugins: [react()],
  server: { port: 5173 },
});
