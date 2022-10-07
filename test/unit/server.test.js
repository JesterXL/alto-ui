const { expect } = require('chai')
const { getUpdatedJSON } = require('../../server')

describe("server.js", () => {
    it('should modify dates to posix time', () => {
        const result = getUpdatedJSON()
        expect(result.trip.estimated_arrival_posix).to.equal(1538144537000)
    })
})