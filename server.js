/*
    Local server to show the UI working. Adds POSIX time and stringified dollars
    to the JSON to ensure it's safer/better practice for the UI. See the
    server.test.js unit test for details.
*/
const express = require('express')
const cors = require('cors')

const app = express()
app.use(cors())
const port = 3000
// original JSON from the assets folder
const originalRequest = require('./original.json')

const setupRoutes = app => {
    app.get('/', (req, res) => {
        res.json(getUpdatedJSON())
    })
    return true
}

const startServer = (app, port) =>
    new Promise(
        resolve => {
            app.listen(port, () => {
                console.log(`Example app listening on port ${port}`)
                resolve(true)
            })
        }
    )
    

const stopServer = app =>
    new Promise(
        resolve => {
            app.close(
                () =>
                    resolve(true)
            )
        }
    )

// adds poxis time, and updates the estimated fares to safer strings
// TODO/FIXME: ensure if any math fails, we fail the request here
const getUpdatedJSON = () => {
    const trip = originalRequest.trip
    const updatedTrip = {
        ...trip,
        estimated_arrival_posix: Date.parse(trip.estimated_arrival),
        estimated_fare_min: `$${String((trip.estimated_fare_min / 100).toFixed(2))}`,
        estimated_fare_max: `$${String((trip.estimated_fare_max / 100).toFixed(2))}` // unsafe as all get out
    }
    return {
        ...originalRequest,
        trip: updatedTrip
    }
}

module.exports = {
    setupRoutes,
    startServer,
    stopServer,
    getUpdatedJSON
}

if(require.main === module) {
    setupRoutes(app)
    startServer(app, port)
}
