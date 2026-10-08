/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        slate: {
          50: "#E8F1EE",
          100: "#D3E0DA",
          200: "#B8C9C2",
          300: "#A7BBB3",
          400: "#9AADA6",
          500: "#849991",
          600: "#6E827A",
          700: "#273631",
          800: "#182320",
          900: "#131C1A",
          950: "#0B1110"
        },
        emerald: {
          400: "#18B87A",
          500: "#20C987",
          600: "#18B87A",
          700: "#12895B"
        },
        severity: {
          low: "#34D399",
          medium: "#FACC15",
          high: "#FB923C",
          critical: "#F87171"
        }
      }
    }
  },
  plugins: []
};
