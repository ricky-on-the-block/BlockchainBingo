/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "index.html",
    "./src/**/*.{html,js,ts,jsx,tsx}"
  ],
  theme: {
    fontFamily: {
      display: ['Pally', 'Comic Sans MS', 'sans-serif'],
      body: ['Pally', 'Comic Sans MS', 'sans-serif'],
    },
    extend: {
      colors: {
        brand: "#0fa9e6",
        "brand-light": "#3fbaeb",
        "brand-dark": "#0c87b8"
      },
      fontFamily: {
        "brand-headline": "'Luckiest Guy', sans-serif"
      }
    },
  },
  plugins: [],
}
