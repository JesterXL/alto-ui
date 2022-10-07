const express = require('express')
const app = express()
const port = 3000
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

const getUpdatedJSON = () => {
    const trip = originalRequest.trip
    
    const updatedTrip = {
        ...trip,
        estimated_arrival_posix: Date.parse(trip.estimated_arrival)
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
