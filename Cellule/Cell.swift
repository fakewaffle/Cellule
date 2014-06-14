//
//  Cell.swift
//  Cellule
//
//  Created by Justin Morris on 6/12/14.
//  Copyright (c) 2014 Justin Morris. All rights reserved.
//

import SpriteKit

class Cell: SKSpriteNode {

    let colors = [ "Red", "Blue", "Green" ]

    var traits = [
        "strength"    : 100,
        "maxVelocity" : 100
    ]

    let redCategory: UInt32   = 1 << 0
    let blueCategory: UInt32  = 1 << 1
    let greenCategory: UInt32 = 1 << 2

    init( location: CGPoint ) {
        let index = Int( arc4random_uniform( UInt32( colors.count ) ) )

        super.init( imageNamed: "Cell-" + colors[ index ] )

        self.setTraits()

        let scale = CGFloat( randRange( 30, upper: 50 ) ) / 1000

        self.setScale( scale )
        self.position = location

        let duration = Double( arc4random_uniform( UInt32( 15 ) ) ) + 5
        let grow     = SKAction.scaleTo( 0.05, duration: duration )
        let shrink   = SKAction.scaleTo( 0.03, duration: duration )

        self.runAction( SKAction.repeatActionForever( SKAction.sequence( [ shrink, grow ] ) ) )

        self.physicsBody                = SKPhysicsBody( circleOfRadius: self.size.height / 2.0 )
        self.physicsBody.mass           = 100 // CGFloat( arc4random_uniform( UInt32( 100 ) ) ) + 1
        self.physicsBody.dynamic        = true
        self.physicsBody.allowsRotation = true

        self.physicsBody.categoryBitMask    = 1 << UInt32( index )
        self.physicsBody.collisionBitMask   = redCategory | blueCategory | greenCategory
        self.physicsBody.contactTestBitMask = redCategory | blueCategory | greenCategory
        
        self.physicsBody.velocity = getRandomVelocity( 10 )
    }

    init( texture: SKTexture ) {
        super.init( texture: texture )
    }

    init( texture: SKTexture?, color: SKColor?, size: CGSize ) {
        super.init( texture: texture, color:color, size:size )
    }

    func setTraits() {
        self.traits[ "strength" ]    = self.randRange( 1, upper: 100 )
        self.traits[ "maxVelocity" ] = self.randRange( 1, upper: 500 )
    }

    func collidedWith( other: SKPhysicsBody ) {
        if let enemy = other.node as? Cell {
            if self.traits[ "strength" ] > enemy.traits[ "strength" ] {
                enemy.removeFromParent()
            }
        }
    }

    func move() {
        if self.physicsBody.velocity.dx < 50 && self.physicsBody.velocity.dy < 50 {
            self.physicsBody.applyImpulse( self.getRandomVelocity( self.traits[ "maxVelocity" ]! ) )
        }
    }

    func getRandomPoint() -> CGPoint {
        var x: Int = Int( arc4random_uniform( UInt32( size.width - 10 ) ) ) + 10
        var y: Int = Int( arc4random_uniform( UInt32( size.height - 10 ) ) ) + 10

        return CGPoint( x: x, y: y )
    }

    func randRange( lower: Int, upper: Int ) -> Int {
        return lower + Int( arc4random_uniform( UInt32( upper - lower + 1 ) ) )
    }

    func getRandomVelocity( r: Int ) -> CGVector {
        let x = randRange( -r, upper: r )
        let y = randRange( -r, upper: r )

        return CGVector( x, y )
    }

}