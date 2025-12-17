/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#007AFF", // iOS System Blue
        "ios-bg": "#F2F2F7", // iOS System Background (Light Gray)
        "ios-card": "#FFFFFF", // iOS Card Background
        "ios-text": "#000000",
        "ios-subtext": "#8E8E93", // iOS System Gray
      },
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          "San Francisco",
          "Helvetica Neue",
          "Helvetica",
          "Arial",
          "sans-serif",
        ],
      },
      boxShadow: {
        'ios': '0 2px 8px rgba(0, 0, 0, 0.04), 0 1px 2px rgba(0, 0, 0, 0.02)',
        'ios-lg': '0 8px 16px rgba(0, 0, 0, 0.08), 0 4px 6px rgba(0, 0, 0, 0.04)',
      },
      borderRadius: {
        'ios': '12px',
        'ios-lg': '20px',
      }
    },
  },
  plugins: [],
}