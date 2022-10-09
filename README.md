# What

Alto UI is a web UI and light server API built for the Alto UI Test. The Alto UI shows the user's current Trip, Driver, Vehicle, and Vibe through a web UI that has 3 breakpoints for mobile, tablet, larger.

## UI

The UI is a web UI built in [Elm](https://elm-lang.org/) and [TailwindCSS](https://tailwindcss.com/). It includes [Cypress](https://www.cypress.io/) end to end tests to ensure the UI works at various breakpoints (currently they're only whitebox tests as I mock the server). The local dev server uses [elm-live](https://github.com/wking-io/elm-live). For linting, we run [elm-review](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/).

## API

There is a light [Express.js](https://expressjs.com/) API used to server the JSON data for the UI as well as fix some of the data such as changing dates to POSIX and changing the currency to USD and safe formatted strings.

# How to Run The Code

1. Checkout the code and `cd` to the root
2. ensure you have at least Node 16 (18 preferable because of the various ES6 modules)
3. run `npm i`
4. run `node server.js`; this'll start the API server so we can get trip data JSON to the UI.
5. open a new terminal and run `npm run watch:css`. This'll start Tailwindcss's compiler, and ensure it compiles the freshest CSS.
6. open a new terminal and run `npm start`. You should now have 3 terminals separately; one running the Node.js Express.js server serving JSON on http://localhost:3000, one compiling CSS, and one running the local ui dev server at http://localhost:8001.

Depending on which breakpoint you're on, you can either click the black dots to navigate between screens, or the tabs. Additionally, if you have mobile emulation on Firefox/Chrome, you can swipe left and right to navigate back and forth between the various screens. There are 3 mobile breakpoints at 278px, 530px, and 745px.

# How to Run the Tests

To run the unit tests for the server, run `npm test`.

To run the end to end tests for the UI, run `npx cypress open`; there are 3 specs you can run. All 3 only need the UI + TailwindCSS compile running, they emulate the server.

# How to Run Linting Rules

To run [elm-review](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) against the `Main.elm` Elm code, run `npm run review`. I've checked in code that passes all linting rules, but just in case, you can violate some of the rules to see it work.

Examples include adding a single item to a list, like in the `viewButton` function. I currently have:

```elm
(class enabledButtonStyles :: attributes)
```

But if you use the old school adding 2 lists together:
```elm
([class enabledButtonStyles] ++ attributes)
```

... and run `npm run review`, the Elm Review rules won't like that. I don't have --force/fix on, so you'll have to manually fix, or revert.

I don't have ESLint/TSLint as there isn't enough JavaScript in the `server.js` to justify it for this excercise.