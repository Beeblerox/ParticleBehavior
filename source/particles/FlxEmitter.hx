package particles;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import particles.FlxParticle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxVelocity;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;
import flixel.util.helpers.FlxBounds;
import flixel.util.helpers.FlxRange;
import flixel.util.helpers.FlxRangeBounds;
import flixel.util.helpers.FlxPointRangeBounds;

typedef FlxEmitter = FlxTypedEmitter<FlxParticle>;

/**
 * FlxTypedEmitter is a lightweight particle emitter.
 * It can be used for one-time explosions or for
 * continuous fx like rain and fire.  FlxEmitter
 * is not optimized or anything; all it does is launch
 * FlxParticle objects out at set intervals
 * by setting their positions and velocities accordingly.
 * It is easy to use and relatively efficient,
 * relying on FlxGroup's RECYCLE POWERS.
 */
class FlxTypedEmitter<T:(FlxSprite, IFlxParticle)> extends FlxTypedGroup<T>
{
	/*
	public static function circleLaunchMode(behavior:IFlxParticleBehavior):Void
	{
		var particleAngle:Float = FlxRandom.float(settings.launchAngle.min, settings.launchAngle.max);
		// Calculate launch velocity
		_point = FlxVelocity.velocityFromAngle(particleAngle, FlxMath.vectorLength(FlxRandom.float(settings.velocity.start.min.x, settings.velocity.start.max.x), FlxRandom.float(settings.velocity.start.min.y, settings.velocity.start.max.y)));
		parent.velocity.x = _point.x;
		parent.velocity.y = _point.y;
		velocityRange.start.set(_point.x, _point.y);
		// Calculate final velocity
		_point = FlxVelocity.velocityFromAngle(particleAngle, FlxMath.vectorLength(FlxRandom.float(settings.velocity.end.min.x, settings.velocity.end.max.x), FlxRandom.float(settings.velocity.end.min.y, settings.velocity.end.max.y)));
		velocityRange.end.set(_point.x, _point.y);
	}
	*/
		
	/**
	 * Set your own particle class type here. The custom class must extend FlxParticle. Default is FlxParticle.
	 */
	public var particleClass:Class<T>;
	
	public var settings:ParticleSettings;
	
	/**
	 * Determines whether the emitter is currently emitting particles. It is totally safe to directly toggle this.
	 */
	public var emitting:Bool = false;
	/**
	 * How often a particle is emitted (if emitter is started with Explode == false).
	 */
	public var frequency:Float = 0.1;
	/**
	 * The x position of this emitter.
	 */
	public var x:Float = 0;
	/**
	 * The y position of this emitter.
	 */
	public var y:Float = 0;
	/**
	 * The width of this emitter. Particles can be randomly generated from anywhere within this box.
	 */
	public var width:Float = 0;
	/**
	 * The height of this emitter.  Particles can be randomly generated from anywhere within this box.
	 */
	public var height:Float = 0;
	
	/**
	 * Internal helper for deciding how many particles to launch.
	 */
	private var _quantity:Int = 0;
	/**
	 * Internal helper for the style of particle emission (all at once, or one at a time).
	 */
	private var _explode:Bool = true;
	/**
	 * Internal helper for deciding when to launch particles or kill them.
	 */
	private var _timer:Float = 0;
	/**
	 * Internal counter for figuring out how many particles to launch.
	 */
	private var _counter:Int = 0;
	/**
	 * Internal point object, handy for reusing for memory management purposes.
	 */
	private var _point:FlxPoint;
	/**
	 * Internal helper for automatically calling the kill() method
	 */
	private var _waitForKill:Bool = false;
	
	/**
	 * Creates a new FlxTypedEmitter object at a specific position.
	 * Does NOT automatically generate or attach particles!
	 * 
	 * @param	X		The X position of the emitter.
	 * @param	Y		The Y position of the emitter.
	 * @param	Size	Optional, specifies a maximum capacity for this emitter.
	 */
	public function new(X:Float = 0, Y:Float = 0, Size:Int = 0)
	{
		super(Size);
		
		x = X;
		y = Y;
		
		settings = new ParticleSettings();
		particleClass = cast FlxParticle;
		
		exists = false;
		_point = FlxPoint.get();
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		settings = FlxDestroyUtil.destroy(settings);
		_point = FlxDestroyUtil.put(_point);
		super.destroy();
	}
	
	/**
	 * This function generates a new array of particle sprites to attach to the emitter.
	 * 
	 * @param	Graphics		If you opted to not pre-configure an array of FlxParticle objects, you can simply pass in a particle image or sprite sheet.
	 * @param	Quantity		The number of particles to generate when using the "create from image" option.
	 * @param	BakedRotations	How many frames of baked rotation to use (boosts performance).  Set to zero to not use baked rotations.
	 * @param	Multiple		Whether the image in the Graphics param is a single particle or a bunch of particles (if it's a bunch, they need to be square!).
	 * @param	AutoBuffer		Whether to automatically increase the image size to accomodate rotated corners.  Default is false.  Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @return	This FlxEmitter instance (nice for chaining stuff together).
	 */
	public function loadParticles(Graphics:FlxGraphicAsset, Quantity:Int = 50, bakedRotationAngles:Int = 16, Multiple:Bool = false, AutoBuffer:Bool = false):FlxTypedEmitter<T>
	{
		maxSize = Quantity;
		var totalFrames:Int = 1;
		
		if (Multiple)
		{ 
			var sprite = new FlxSprite();
			sprite.loadGraphic(Graphics, true);
			totalFrames = sprite.frames;
			sprite.destroy();
		}
		
		var randomFrame:Int;
		var i:Int = 0;
		
		while (i < Quantity)
		{
			var particle:T = Type.createInstance(particleClass, [settings.behaviorFactory]);
			
			if (Multiple)
			{
				randomFrame = FlxRandom.int(0, totalFrames - 1);
				
				if (bakedRotationAngles > 0)
				{
					#if FLX_RENDER_BLIT
					particle.loadRotatedGraphic(Graphics, bakedRotationAngles, randomFrame, false, AutoBuffer);
					#else
					particle.loadGraphic(Graphics, true);
					#end
				}
				else
				{
					particle.loadGraphic(Graphics, true);
				}
				particle.animation.frameIndex = randomFrame;
			}
			else
			{
				if (bakedRotationAngles > 0)
				{
					#if FLX_RENDER_BLIT
					particle.loadRotatedGraphic(Graphics, bakedRotationAngles, -1, false, AutoBuffer);
					#else
					particle.loadGraphic(Graphics);
					#end
				}
				else
				{
					particle.loadGraphic(Graphics);
				}
			}
			
			add(particle);
			i++;
		}
		
		return this;
	}
	
	/**
	 * Similar to FlxSprite's makeGraphic, this function allows you to quickly make single-color particles.
	 * 
	 * @param	Width           The width of the generated particles. Default is 2 pixels.
	 * @param	Height          The height of the generated particles. Default is 2 pixels.
	 * @param	Color           The color of the generated particles. Default is white.
	 * @param	Quantity        How many particles to generate. Default is 50.
	 * @return  This FlxEmitter instance (nice for chaining stuff together).
	 */
	public function makeParticles(Width:Int = 2, Height:Int = 2, Color:FlxColor = FlxColor.WHITE, Quantity:Int = 50):FlxTypedEmitter<T>
	{
		var i:Int = 0;
		
		while (i < Quantity)
		{
			var particle:T = Type.createInstance(particleClass, [settings.behaviorFactory]);
			particle.makeGraphic(Width, Height, Color);
			add(particle);
			
			i++;
		}
		
		return this;
	}
	
	/**
	 * Called automatically by the game loop, decides when to launch particles and when to "die".
	 */
	override public function update():Void
	{
		if (emitting)
		{
			if (_explode)
			{
				emitting = false;
				_waitForKill = true;
				
				var i:Int = 0;
				var l:Int = _quantity;
				
				if ((l <= 0) || (l > length))
				{
					l = length;
				}
				
				while (i < l)
				{
					emitParticle();
					i++;
				}
				
				_quantity = 0;
			}
			else
			{
				// Spawn a particle per frame
				if (frequency <= 0)
				{
					emitParticle();
					
					if ((_quantity > 0) && (++_counter >= _quantity))
					{
						emitting = false;
						_waitForKill = true;
						_quantity = 0;
					}
				}
				else
				{
					_timer += FlxG.elapsed;
					
					while (_timer > frequency)
					{
						_timer -= frequency;
						emitParticle();
						
						if ((_quantity > 0) && (++_counter >= _quantity))
						{
							emitting = false;
							_waitForKill = true;
							_quantity = 0;
						}
					}
				}
			}
		}
		else if (_waitForKill)
		{
			_timer += FlxG.elapsed;
			
			if ((settings.lifespan.max > 0) && (_timer > settings.lifespan.max))
			{
				kill();
				return;
			}
		}
		
		super.update();
	}
	
	/**
	 * Call this function to turn off all the particles and the emitter.
	 */
	override public function kill():Void
	{
		emitting = false;
		_waitForKill = false;
		
		super.kill();
	}
	
	/**
	 * Call this function to start emitting particles.
	 * 
	 * @param	Explode			Whether the particles should all burst out at once.
	 * @param	Frequency		Ignored if Explode is set to true. Frequency is how often to emit a particle. 0 = never emit, 0.1 = 1 particle every 0.1 seconds, 5 = 1 particle every 5 seconds.
	 * @param	Quantity		Ignored if Explode is set to true. How many particles to launch. 0 = "all of the particles".
	 * @return	This FlxEmitter instance (nice for chaining stuff together).
	 */
	public function start(Explode:Bool = true, Frequency:Float = 0.1, Quantity:Int = 0):FlxTypedEmitter<T>
	{
		revive();
		visible = true;
		emitting = true;
		
		_explode = Explode;
		frequency = Frequency;
		_quantity += Quantity;
		
		_counter = 0;
		_timer = 0;
		
		_waitForKill = false;
		
		return this;
	}
	
	/**
	 * This function can be used both internally and externally to emit the next particle.
	 */
	public function emitParticle():Void
	{
		var particle:T = cast recycle(cast particleClass);
		
		particle.reset(FlxRandom.float(x, x + width), FlxRandom.float(y, y + height));
		particle.behavior.start(settings);
		particle.behavior.onEmit();
	}
	
	/**
	 * Change the emitter's midpoint to match the midpoint of a FlxObject.
	 * 
	 * @param	Object		The FlxObject that you want to sync up with.
	 */
	public function focusOn(Object:FlxObject):Void
	{
		Object.getMidpoint(_point);
		
		x = _point.x - (Std.int(width) >> 1);
		y = _point.y - (Std.int(height) >> 1);
	}
}

enum FlxEmitterMode
{
	SQUARE;
	CIRCLE;
}