// TODO/FIXME: Vibes hides the dots so you can't nav,
// maybe fixing to routing is the easiest fix
describe('02 - Navigation', () => {
    
    beforeEach('can see the site at localhost', () => {
        cy.intercept('GET', 'http://localhost:3000/', { fixture: 'stub.json' })
        cy.viewport(320, 600)
        cy.visit('http://localhost:8001')
    })
    
    it('should navigate to My Trip', () => {
        cy.get('[data-dot="My Trip"]').click()
        cy.get('[data-title="Your Trip"]').should('have.length', 1)
    })

    it('should navigate to My Driver', () => {
        cy.get('[data-dot="My Driver"]').click()
        cy.get('[data-title="Your Driver"]').should('have.length', 1)
    })

    it('should navigate to Vehicle', () => {
        cy.get('[data-dot="Vehicle"]').click()
        cy.get('[data-title="Your Vehicle"]').should('have.length', 1)
    })

    it('should navigate to Vibes', () => {
        cy.get('[data-dot="Dat Vibe Tho"]').click()
        cy.get('[data-title="Vibe"]').should('have.length', 1)
    })
})