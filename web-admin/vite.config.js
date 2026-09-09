import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The admin web app talks to the same Node backend as the Flutter client.
// Set VITE_API_BASE_URL to override the default (http://127.0.0.1:5050).
// Runs on a different port than the staff app so both can run locally.
export default defineConfig({
  plugins: [react()],
  server: { port: 5174 },
});
