/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../lua/view/**/*.html", "../home/**/*.{html,js,ts}"],
  theme: {
    extend: {},
  },
  plugins: [],
  variants: {
    rotate: ['group-open']
  }
}

