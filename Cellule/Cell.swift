//
//  Cell.swift
//  Cellule
//
//  Created by Justin Morris on 6/12/14.
//  Copyright (c) 2014 Justin Morris. All rights reserved.
//

import SpriteKit

class Cell: SKSpriteNode {

    let textures = [ "Cell-Red", "Cell-Blue", "Cell-Green" ]

    let species: Int?
    var matingTimer: NSTimer?

    // TODO: move traits to a struct
    let strength       = randRange( 10, 50 )
    let maxVelocity    = randRange( 1, 200 )
    let matingInterval = randRange( 3, 30 )

    var canMate = true

    let redCategory: UInt32   = 1 << 0
    let blueCategory: UInt32  = 1 << 1
    let greenCategory: UInt32 = 1 << 2

    init( location: CGPoint, species: Int ) {
        super.init( imageNamed: textures[ species ] )

        self.species = species

        let scale = CGFloat( self.strength ) / 1000

        self.setLocation( location )
        self.setScale( scale )
        self.animate( scale )
        self.setPhysics( species )
    }

    init( texture: SKTexture ) {
        super.init( texture: texture )
    }

    init( texture: SKTexture?, color: SKColor?, size: CGSize ) {
        super.init( texture: texture, color:color, size:size )
    }

    func setLocation( location: CGPoint ) {
        self.position = location
    }

    func setPhysics( species: Int ) {
        self.physicsBody                = SKPhysicsBody( circleOfRadius: self.size.height / 2.0 )
        self.physicsBody.mass           = CGFloat( self.strength )
        self.physicsBody.dynamic        = true
        self.physicsBody.allowsRotation = true

        self.physicsBody.categoryBitMask    = 1 << UInt32( species )
        self.physicsBody.collisionBitMask   = redCategory | blueCategory | greenCategory
        self.physicsBody.contactTestBitMask = redCategory | blueCategory | greenCategory

        self.physicsBody.velocity = getRandomVelocity( 10 )
    }

    func update() {
        self.move()
    }

    func animate( scale: CGFloat ) {
        let duration = Double( arc4random_uniform( UInt32( 15 ) ) ) + 5
        let grow     = SKAction.scaleTo( scale * 1.1, duration: duration )
        let shrink   = SKAction.scaleTo( scale * 0.9, duration: duration )

        self.runAction( SKAction.repeatActionForever( SKAction.sequence( [ shrink, grow ] ) ) )
    }

    func move() {
        if self.physicsBody.velocity.dx < 50 && self.physicsBody.velocity.dy < 50 {
            self.physicsBody.applyImpulse( self.getRandomVelocity( self.maxVelocity ) )
        }
    }

    // TODO: should probably fire an event on enemy that lets the GameScene know to remove
    func attack( enemy: Cell ) -> Cell? {
        if self.strength >= enemy.strength {
            return enemy
        }

        return nil
    }

    func mate( mate: Cell ) -> Cell {
        var location  = CGPoint( x: self.position.x + self.size.height, y: self.position.y + self.size.width )
        var offspring = Cell( location: location, species: self.species! )

        self.canMate      = false
        mate.canMate      = false
        offspring.canMate = false

        let selector = Selector( "matingTimerTrigger" )

        self.matingTimer      = NSTimer.scheduledTimerWithTimeInterval( NSTimeInterval( self.matingInterval ), target: self, selector: selector, userInfo: nil, repeats: false )
        mate.matingTimer      = NSTimer.scheduledTimerWithTimeInterval( NSTimeInterval( mate.matingInterval ), target: mate, selector: selector, userInfo: nil, repeats: false )
        offspring.matingTimer = NSTimer.scheduledTimerWithTimeInterval( NSTimeInterval( offspring.matingInterval ), target: offspring, selector: selector, userInfo: nil, repeats: false )

        return offspring
    }

    func matingTimerTrigger() {
        self.canMate = true
    }

    func getRandomVelocity( r: Int ) -> CGVector {
        let x = randRange( -r, r )
        let y = randRange( -r, r )

        return CGVector( x, y )
    }

}