define( function ( require ) {
	'use strict';

	var _     = require( 'underscore' );
	var THREE = require( 'THREE' );
	var TWEEN = require( 'TWEEN' );


	var viscosity = 1000;
	var colors    = [ 0xEFEFEF, 0xFF6348, 0xF2CB05, 0x49F09F, 0x52B0ED ];
	var min       = 1;
	var max       = 100;
	var minSpeed  = 10;

	var movements = [
		TWEEN.Easing.Linear.None,
		TWEEN.Easing.Quadratic.In,
		TWEEN.Easing.Quadratic.Out,
		TWEEN.Easing.Quadratic.InOut,
		TWEEN.Easing.Quartic.In,
		TWEEN.Easing.Quartic.Out,
		TWEEN.Easing.Quartic.InOut,
		TWEEN.Easing.Quintic.In,
		TWEEN.Easing.Quintic.Out,
		TWEEN.Easing.Quintic.InOut,
		TWEEN.Easing.Cubic.In,
		TWEEN.Easing.Cubic.Out,
		TWEEN.Easing.Cubic.InOut,
		TWEEN.Easing.Exponential.In,
		TWEEN.Easing.Exponential.Out,
		TWEEN.Easing.Exponential.InOut,
		TWEEN.Easing.Circular.In,
		TWEEN.Easing.Circular.Out,
		TWEEN.Easing.Circular.InOut,
		TWEEN.Easing.Back.Out
	];

	var defaults = function () {
		var color    = colors[ Math.floor( Math.random() * colors.length ) ];
		var sight    = Math.round( Math.random() * ( max - min ) + min, 0 );
		var strength = Math.round( Math.random() * ( max - min ) + min, 0 );
		var size     = Math.round( Math.max( 2, Math.min( strength / 10, 5 ) ), 0 );
		var movement = movements[ Math.floor( Math.random() * movements.length ) ];
		var speed    = Math.floor( Math.random() * ( max - minSpeed ) + minSpeed );
		var gender   = Math.random() < 0.5 ? 'male' : 'female';

		return {
			'color'    : color,
			'sight'    : sight,
			'strength' : strength,
			'size'     : size,
			'movement' : movement,
			'speed'    : speed,
			'gender'   : gender
		};
	};

	var Cell = function ( options ) {
		options = options || {};

		THREE.Mesh.call( this );

		this.traits     = options.traits || defaults();
        this.geometry   = options.geometry || this.getGeometry();
        this.material   = options.material || this.getMaterial();
        this.position   = options.position || this.getRandomPoint();
        this.energy     = options.energy || 100;
        this.nextMating = options.nextMating || 100;
        this.canMate    = options.canMate || false;
	};

	Cell.prototype = Object.create( THREE.Mesh.prototype );

	Cell.prototype.getMaterial = function () {
		return new THREE.MeshBasicMaterial( { 'color' : this.traits.color } );
	};

	// Returns different geometry for the different genders
	Cell.prototype.getGeometry = function () {

		if ( this.traits.gender === 'female' ) {
			return new THREE.SphereGeometry( this.traits.size, 12, 12 );
		}

		return new THREE.CubeGeometry( this.traits.size * 1.75, this.traits.size * 1.75, this.traits.size * 1.75 );
	};

	Cell.prototype.update = function () {
		this.detectCollisions();
		this.resetColor();
		this.move();

		if ( this.ecosystem.tick > this.nextMating ) {
			this.canMate = true;
		}
	};

	Cell.prototype.reproduce = function ( mate ) {

		console.log( 'check mating' );

		if ( !this.canMate ) {
			return;
		}

		if ( !mate.canMate ) {
			return;
		}

		this.nextMating += 1000;
		mate.nextMating += 1000;

		this.canMate = false;
		mate.canMate = false;

		var cell = new Cell( {
			'position'   : this.position.clone(),
			'nextMating' : this.ecosystem.tick + 5000,
			'canMate'    : false,

			'traits' : {
				'color'    : this.traits.color,
				'sight'    : this.traits.sight,
				'strength' : this.traits.strength,
				'size'     : this.traits.size,
				'movement' : this.traits.movement,
				'speed'    : this.traits.speed,
				'gender'   : this.traits.gender
			}
		} );

		this.ecosystem.spawnCell( cell );
	};

	Cell.prototype.resetColor = function () {
		setTimeout( function () {
			this.material.color.setHex( this.traits.color );
		}.bind( this ), 2000 );
	};

	Cell.prototype.move = function () {

		if ( !this.target ) {
			this.tween();
		} else if ( this.position.x === this.target.x && this.position.y === this.target.y ) {
			this.tween();
		}

		this.showPath();
	};

	Cell.prototype.tween = function () {
		this.target = this.getRandomPoint();

		var distance = this.position.distanceTo( this.target );
		var time     = distance / this.traits.speed * viscosity;

		new TWEEN.Tween( this.position ).to( this.target, time )
			.easing( this.traits.movement )
			.start();
	};

	Cell.prototype.showPath = function () {
		if ( !this.path ) {
			var mat = new THREE.LineDashedMaterial( {
				'color'       : this.traits.color,
				'opacity'     : 0.05,
				'transparent' : true
			} );

			this.path = new THREE.Line( new THREE.Geometry(), mat );
			this.parent.add( this.path );
		}

		this.path.geometry.vertices = [ this.position, this.target ];
		this.path.geometry.verticesNeedUpdate = true;
	};

	Cell.prototype.getRandomPoint = function () {
		var minX = 0 + this.traits.size + 1;
		var maxX = window.innerWidth - this.traits.size - 1;

		var minY = 0 + this.traits.size + 1;
		var maxY = window.innerHeight - this.traits.size - 1;

		var minZ = 0 + this.traits.size + 1;
		var maxZ = window.innerHeight - this.traits.size - 1;

		var x = Math.floor( Math.random() * ( maxX - minX ) + minX );
		var y = Math.floor( Math.random() * ( maxY - minY ) + minY );
		var z = 0.5 || Math.floor( Math.random() * ( maxZ - minZ ) + minZ );

		return new THREE.Vector3( x, y, z );
	};

	Cell.prototype.detectCollisions = function () {
		var i;

		var position   = this.position;
		var intersects = [];

		// Maximum distance from the origin before we consider collision
		var cells = this.ecosystem.octree.search( position, 5, true );
		if ( cells.length === 1 ) {
			return intersects;
		}

		// For each ray
		for ( i = 0; i < this.ecosystem.rays.length; i += 1 ) {

			// We reset the raycaster to this direction
			this.ecosystem.rayCaster.set( position, this.ecosystem.rays[ i ] );

			// Test if we intersect with any obstacle mesh
			intersects = this.ecosystem.rayCaster.intersectOctreeObjects( cells );

			// // And disable that direction if we do
			if ( intersects.length > 0 ) {
				var target = intersects[ 0 ];

				// TODO: Loop over intersections (only does one)
				var intersectDistance = target.distance;
				if ( intersectDistance <= this.traits.size ) {

					if (
						this.ecosystem.tick > this.nextMating &&
						this.ecosystem.tick > target.object.nextMating &&
						this.traits.color === target.object.traits.color &&
						this.traits.gender !== target.object.traits.gender
					) {
						this.reproduce( target.object );
					}

					// collision
					this.material.color.setRGB( 1, 0, 0 );

				} else {
					// in sight
					// this.material.color = 0xffcc00;
					// console.log( 'sight' );
				}
			}

		}
	};

	return Cell;
} );