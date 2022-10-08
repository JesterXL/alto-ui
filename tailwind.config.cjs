module.exports = {
	content: [
		"./src/index.html",
		"./src/elm.js",
	],
	theme: {
		fontFamily: {
			optima: ["Optima"],
			pxgrotesk: ["Px Grotesk"],
			pxgrotesklight: ['PxGrotesk-Light']
		},
		extend: {
			colors: {
				'alto-primary': '#3F3825',
				'alto-secondary': '#6C685B',
				'alto-dark': '#AC826D',
				'alto-page-background': '#F7F3EF',
				'alto-line': '#EAE6DB'
			},
			fontSize: {
				'alto-base': '0.875rem',
				'alto-title': '0.75rem',
				'alto-subtitle': '0.5rem'
			}
		},
		screens: {
			small: "278px",
			medium: "530px",
			large: '745px'
		}
	}
}