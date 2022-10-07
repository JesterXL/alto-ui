module.exports = {
	content: [
		"./src/index.html",
		"./src/elm.js",
	],
	theme: {
		fontFamily: {
			optima: ["Optima"],
			pxgrotesk: ["Px Grotesk"]
		},
		extend: {
			colors: {
				'alto-primary': '#3F3825',
				'alto-secondary': '#6C685B',
				'alto-page-background': '#F7F3EF',
				'alto-line': '#EAE6DB'
			},
			fontSize: {
				'alto-base': '0.875rem',
				'alto-title': '0.75rem'
			}
		}
	}
}