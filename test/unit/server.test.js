/*
    Tests for our mock server. We have to test 2 important things:
    
    1. The UI deals in Posix dates, not "whatever JavaScript/JSON says" or pray ISO-8601 works. For
    now we convert it to UTC POSIX, and assume the client's timezone is UTC as well. This allows the
    client to choose what timezone they are in, and we don't care vs. letting JavaScript parse it.

    2. We shouldn't be passing money as ints/number across the wire as JSON. Money should be BigDecimal
    in those languages that support it, and we as the UI "just show things". Any calculations can
    either be done correctly in the back-end that supports it, or esimated on the UI. For now,
    I fix it to both be a string which ensures JSON cannot screw up the decimal amont if it's big,
    as well as ensuring it's in USD. We can change currency later, but for now, we'll just let the
    server say "show this" vs. us doing a bunch of UI logic & dangerous math on it.
*/
const { expect } = require('chai')
const { getUpdatedJSON } = require('../../server')

describe("server.js", () => {
    it('should modify dates to posix time', () => {
        const result = getUpdatedJSON()
        expect(result.trip.estimated_arrival_posix).to.equal(1538144537000)
    })
    it('should modify fares min to string money', () => {
        const result = getUpdatedJSON()
        expect(result.trip.estimated_fare_min).to.equal("$65.00")
    })
    it('should modify fares max to string money', () => {
        const result = getUpdatedJSON()
        expect(result.trip.estimated_fare_max).to.equal("$75.00")
    })
})