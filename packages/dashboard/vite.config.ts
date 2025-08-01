import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { mud } from "vite-plugin-mud";

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    mud({ worldsFile: "../contracts/worlds.json" }),
  ],
  build: {
    target: "es2022",
    minify: true,
    sourcemap: true,
  },
  server: {
    allowedHosts: [".tunnel.offchain.dev"],
  },
});
