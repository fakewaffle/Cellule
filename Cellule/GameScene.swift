//
//  GameScene.swift
//  Cellule
//
//  Created by Justin Morris on 6/11/14.
//  Copyright (c) 2014 Justin Morris. All rights reserved.
//

import SpriteKit

func randRange( lower: Int, upper: Int ) -> Int {
    return lower + Int( arc4random_uniform( UInt32( upper - lower + 1 ) ) )
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var cells: Cell[] = []

    override func didMoveToView( view: SKView ) {

        // setup physics
        self.physicsWorld.gravity         = CGVectorMake( 0, 0 )
        self.physicsWorld.contactDelegate = self

        self.physicsBody         = SKPhysicsBody( edgeLoopFromRect: self.frame )
        self.physicsBody.dynamic = false;

        self.physicsBody.contactTestBitMask = 1 << 10

        // setup background color
        self.backgroundColor = SKColor( red: 50 / 255.0, green: 50 / 255.0, blue: 50 / 255.0, alpha: 1.0 )

        for index in 1...200 {
            var cell = Cell( location: getRandomPoint(), species: randRange( 0, 2 ) )

            self.addChild( cell )
            self.cells.append( cell )
        }

    }
    
    override func touchesBegan( touches: NSSet, withEvent event: UIEvent ) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode( self )

            var cell = Cell( location: location, species: randRange( 0, 2 ) )

            self.addChild( cell )
            self.cells.append( cell )
        }
    }
    
    override func update( currentTime: CFTimeInterval ) {
        for cell in self.cells {
            cell.update()
        }
    }

    func addCell( offspring: Cell ) {
        self.cells.append( offspring )
        self.addChild( offspring )
    }

    func removeCell( killed: Cell ) {
        killed.removeFromParent()

        for (i, value) in enumerate( self.cells ) {
            if killed == value {
                self.cells.removeAtIndex( i )
            }
        }
    }

    func didBeginContact( contact: SKPhysicsContact ) {
        if contact.bodyA.categoryBitMask != contact.bodyB.categoryBitMask {

            if let cell = contact.bodyA.node as? Cell {
                if let enemy = contact.bodyB.node as? Cell {
                    var dead = cell.attack( enemy )

                    if let killed = dead as? Cell {
                        self.removeCell( killed )
                    }
                }
            }

            if let cell = contact.bodyB.node as? Cell {
                if let enemy = contact.bodyA.node as? Cell {
                    var dead = cell.attack( enemy )

                    if let killed = dead as? Cell {
                        self.removeCell( killed )
                    }
                }
            }

        } else {

            if let cell = contact.bodyA.node as? Cell {
                if let mate = contact.bodyB.node as? Cell {
                    if cell.canMate == true && mate.canMate == true {
                        var offspring = cell.mate( mate )

                        self.addCell( offspring )
                    }
                }
            }

            if let cell = contact.bodyB.node as? Cell {
                if let mate = contact.bodyA.node as? Cell {
                    if cell.canMate == true && mate.canMate == true {
                        var offspring = cell.mate( mate )

                        self.addCell( offspring )
                    }
                }
            }

        }
    }

    func getRandomPoint() -> CGPoint {
        var x: Int = Int( arc4random_uniform( UInt32( size.width - 10 ) ) ) + 10
        var y: Int = Int( arc4random_uniform( UInt32( size.height - 10 ) ) ) + 10
        
        return CGPoint( x: x, y: y )
    }


}
