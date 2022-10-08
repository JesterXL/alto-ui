describe('01 - Ping', () => {
    it('can see the site at localhost', () => {
        cy.intercept('GET', 'http://localhost:3000/', { fixture: 'stub.json' })
        cy.visit('http://localhost:8001')
        cy.get('[data-logo="Alto"]').should('have.length', 1)
    })
})