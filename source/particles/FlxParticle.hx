package particles;

import flixel.FlxObject;
import particles.FlxEmitter.FlxEmitterMode;
import particles.FlxParticle.ParticleBehavior;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxVelocity;
import flixel.util.FlxColor;
import flixel.util.FlxColor;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxBounds;
import flixel.util.helpers.FlxPointRangeBounds;
import flixel.util.helpers.FlxRange;
import flixel.util.helpers.FlxRangeBounds;
import openfl.display.BlendMode;

/**
 * This is a simple particle class that extends the default behavior
 * of FlxSprite to have slightly more specialized behavior
 * common to many game scenarios.  You can override and extend this class
 * just like you would FlxSprite. While FlxEmitter
 * used to work with just any old sprite, it now requires a
 * FlxParticle based class.
*/
class FlxParticle extends FlxSprite implements IFlxParticle
{
	public var behavior:IFlxParticleBehavior;
	
	/**
	 * Instantiate a new particle. Like FlxSprite, all meaningful creation
	 * happens during loadGraphic() or makeGraphic() or whatever.
	 */
	public function new(behaviorFactory:FlxSprite->IFlxParticleBehavior)
	{
		super();
		behavior = behaviorFactory(this);
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		behavior = FlxDestroyUtil.destroy(behavior);
		super.destroy();
	}
	
	/**
	 * The particle's main update logic. Basically updates properties if alive, based on ranged properties.
	 */
	override public function update():Void
	{
		behavior.update();
		super.update();
	}
	
	override public function reset(X:Float, Y:Float):Void 
	{
		super.reset(X, Y);
		behavior.reset();
	}	
}

interface IFlxParticle extends IFlxSprite
{
	public var behavior:IFlxParticleBehavior;
}

interface IFlxParticleBehavior extends IFlxDestroyable
{
	public var parent:FlxSprite;
	public function start(settings:ParticleSettings):Void;
	public function update():Void;
	public function reset():Void;
	public function onEmit():Void;
	public function onFinish():Void;
}

class ParticleBehavior implements IFlxParticleBehavior
{
	public static function behaviorFactory(sprite:FlxSprite):ParticleBehavior
	{
		return new ParticleBehavior(sprite);
	}
	
	public var parent:FlxSprite;
	
	/**
	 * How long this particle lives before it disappears. Set to 0 to never kill() the particle automatically.
	 * NOTE: this is a maximum, not a minimum; the object could get recycled before its lifespan is up.
	 */
	public var lifespan:Float = 0;
	/**
	 * How long this particle has lived so far.
	 */
	public var age(default, null):Float = 0;
	/**
	 * What percentage progress this particle has made of its total life. Essentially just (age / lifespan) on a scale from 0 to 1.
	 */
	public var percent(default, null):Float = 0;
	/**
	 * Whether or not the hitbox should be updated each frame when scaling.
	 */
	public var autoUpdateHitbox:Bool = false;
	/**
	 * The range of values for velocity over this particle's lifespan.
	 */
	public var velocityRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for angularVelocity over this particle's lifespan.
	 */
	public var angularVelocityRange:FlxRange<Float>;
	/**
	 * The range of values for scale over this particle's lifespan.
	 */
	public var scaleRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for alpha over this particle's lifespan.
	 */
	public var alphaRange:FlxRange<Float>;
	/**
	 * The range of values for color over this particle's lifespan.
	 */
	public var colorRange:FlxRange<FlxColor>;
	/**
	 * The range of values for drag over this particle's lifespan.
	 */
	public var dragRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for acceleration over this particle's lifespan.
	 */
	public var accelerationRange:FlxRange<FlxPoint>;
	/**
	 * The range of values for elasticity over this particle's lifespan.
	 */
	public var elasticityRange:FlxRange<Float>;
	/**
	 * The amount of change from the previous frame.
	 */
	private var _delta:Float = 0;
	
	private var _point:FlxPoint;
	
	public function new(parent:FlxSprite)
	{
		this.parent = parent;
		
		velocityRange = new FlxRange<FlxPoint>(FlxPoint.get(), FlxPoint.get());
		angularVelocityRange = new FlxRange<Float>(0);
		scaleRange = new FlxRange<FlxPoint>(FlxPoint.get(1,1), FlxPoint.get(1,1));
		alphaRange = new FlxRange<Float>(1, 1);
		colorRange = new FlxRange<FlxColor>(FlxColor.WHITE);
		dragRange = new FlxRange<FlxPoint>(FlxPoint.get(), FlxPoint.get());
		accelerationRange = new FlxRange<FlxPoint>(FlxPoint.get(), FlxPoint.get());
		elasticityRange = new FlxRange<Float>(0);
		parent.exists = false;
		
		_point = FlxPoint.get();
	}
	
	public function start(settings:ParticleSettings):Void
	{
		// Particle blend settings
		parent.blend = settings.blend;
		
		// Particle velocity/launch angle settings
		
		velocityRange.active = !velocityRange.start.equals(velocityRange.end);
		
		if (settings.launchMode == FlxEmitterMode.CIRCLE)
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
		else
		{
			velocityRange.start.x = FlxRandom.float(settings.velocity.start.min.x, settings.velocity.start.max.x);
			velocityRange.start.y = FlxRandom.float(settings.velocity.start.min.y, settings.velocity.start.max.y);
			velocityRange.end.x = FlxRandom.float(settings.velocity.end.min.x, settings.velocity.end.max.x);
			velocityRange.end.y = FlxRandom.float(settings.velocity.end.min.y, settings.velocity.end.max.y);
			parent.velocity.x = velocityRange.start.x;
			parent.velocity.y = velocityRange.start.y;
		}
		
		// Particle angular velocity settings
		
		angularVelocityRange.active = settings.angularVelocity.start != settings.angularVelocity.end;
		
		if (!settings.ignoreAngularVelocity)
		{
			angularVelocityRange.start = FlxRandom.float(settings.angularVelocity.start.min, settings.angularVelocity.start.max);
			angularVelocityRange.end = FlxRandom.float(settings.angularVelocity.end.min, settings.angularVelocity.end.max);
			parent.angularVelocity = angularVelocityRange.start;
		}
		else
		{
			parent.angularVelocity = (FlxRandom.float(settings.angle.end.min, settings.angle.end.max) - FlxRandom.float(settings.angle.start.min, settings.angle.start.max)) / FlxRandom.float(settings.lifespan.min, settings.lifespan.max);
			angularVelocityRange.active = false;
		}
		
		// Particle angle settings
		
		parent.angle = FlxRandom.float(settings.angle.start.min, settings.angle.start.max);
		
		// Particle lifespan settings
		
		lifespan = FlxRandom.float(settings.lifespan.min, settings.lifespan.max);
		
		// Particle scale settings
		
		scaleRange.start.x = FlxRandom.float(settings.scale.start.min.x, settings.scale.start.max.x);
		scaleRange.start.y = FlxRandom.float(settings.scale.start.min.y, settings.scale.start.max.y);
		scaleRange.end.x = FlxRandom.float(settings.scale.end.min.x, settings.scale.end.max.x);
		scaleRange.end.y = FlxRandom.float(settings.scale.end.min.y, settings.scale.end.max.y);
		scaleRange.active = scaleRange.start != scaleRange.end;
		parent.scale.x = scaleRange.start.x;
		parent.scale.y = scaleRange.start.y;
		
		// Particle alpha settings
		
		alphaRange.start = FlxRandom.float(settings.alpha.start.min, settings.alpha.start.max);
		alphaRange.end = FlxRandom.float(settings.alpha.end.min, settings.alpha.end.max);
		alphaRange.active = alphaRange.start != alphaRange.end;
		parent.alpha = alphaRange.start;
		
		// Particle color settings
		
		colorRange.start = FlxRandom.color(settings.color.start.min, settings.color.start.max);
		colorRange.end = FlxRandom.color(settings.color.end.min, settings.color.end.max);
		colorRange.active = colorRange.start != colorRange.end;
		parent.color = colorRange.start;
		
		// Particle drag settings
		
		dragRange.start.x = FlxRandom.float(settings.drag.start.min.x, settings.drag.start.max.x);
		dragRange.start.y = FlxRandom.float(settings.drag.start.min.y, settings.drag.start.max.y);
		dragRange.end.x = FlxRandom.float(settings.drag.end.min.x, settings.drag.end.max.x);
		dragRange.end.y = FlxRandom.float(settings.drag.end.min.y, settings.drag.end.max.y);
		dragRange.active = !dragRange.start.equals(dragRange.end);
		parent.drag.x = dragRange.start.x;
		parent.drag.y = dragRange.start.y;
		
		// Particle acceleration settings
		
		accelerationRange.start.x = FlxRandom.float(settings.acceleration.start.min.x, settings.acceleration.start.max.x);
		accelerationRange.start.y = FlxRandom.float(settings.acceleration.start.min.y, settings.acceleration.start.max.y);
		accelerationRange.end.x = FlxRandom.float(settings.acceleration.end.min.x, settings.acceleration.end.max.x);
		accelerationRange.end.y = FlxRandom.float(settings.acceleration.end.min.y, settings.acceleration.end.max.y);
		accelerationRange.active = !accelerationRange.start.equals(accelerationRange.end);
		parent.acceleration.x = accelerationRange.start.x;
		parent.acceleration.y = accelerationRange.start.y;
		
		// Particle elasticity settings
		
		elasticityRange.start = FlxRandom.float(settings.elasticity.start.min, settings.elasticity.start.max);
		elasticityRange.end = FlxRandom.float(settings.elasticity.end.min, settings.elasticity.end.max);
		elasticityRange.active = elasticityRange.start != elasticityRange.end;
		parent.elasticity = elasticityRange.start;
		
		// Particle collision settings
		
		parent.immovable = settings.immovable;
		parent.solid = settings.solid;
		parent.allowCollisions = settings.allowCollisions;
		autoUpdateHitbox = settings.autoUpdateHitbox;
		
		onEmit();
	}
	
	public function update():Void
	{
		if (age < lifespan)
		{
			age += FlxG.elapsed;
		}
		
		if (age >= lifespan && lifespan != 0)
		{
			parent.kill();
		}
		else
		{
			_delta = FlxG.elapsed / lifespan;
			percent = age / lifespan;
			
			if (velocityRange.active)
			{
				parent.velocity.x += (velocityRange.end.x - velocityRange.start.x) * _delta;
				parent.velocity.y += (velocityRange.end.y - velocityRange.start.y) * _delta;
			}
			
			if (angularVelocityRange.active)
			{
				parent.angularVelocity += (angularVelocityRange.end - angularVelocityRange.start) * _delta;
			}
			
			if (scaleRange.active)
			{
				parent.scale.x += (scaleRange.end.x - scaleRange.start.x) * _delta;
				parent.scale.y += (scaleRange.end.y - scaleRange.start.y) * _delta;
			}
			
			if (alphaRange.active)
			{
				parent.alpha += (alphaRange.end - alphaRange.start) * _delta;
			}
			
			if (colorRange.active)
			{
				parent.color = FlxColor.interpolate(colorRange.start, colorRange.end, percent);
			}
			
			if (dragRange.active)
			{
				parent.drag.x += (dragRange.end.x - dragRange.start.x) * _delta;
				parent.drag.y += (dragRange.end.y - dragRange.start.y) * _delta;
			}
			
			if (accelerationRange.active)
			{
				parent.acceleration.x += (accelerationRange.end.x - accelerationRange.start.x) * _delta;
				parent.acceleration.y += (accelerationRange.end.y - accelerationRange.start.y) * _delta;
			}
			
			if (elasticityRange.active)
			{
				parent.elasticity += (elasticityRange.end - elasticityRange.start) * _delta;
			}
			
			if (autoUpdateHitbox && scaleRange.active)
			{
				parent.updateHitbox();
			}
		}
	}
	
	public function reset():Void
	{
		parent.alpha = 1.0;
		parent.scale.set(1, 1);
		parent.color = FlxColor.WHITE;
		age = 0;
		parent.visible = true;
		velocityRange.set(FlxPoint.get(), FlxPoint.get());
		angularVelocityRange.set(0);
		scaleRange.set(FlxPoint.get(), FlxPoint.get());
		alphaRange.set(1);
		colorRange.set(FlxColor.WHITE);
		dragRange.set(FlxPoint.get(), FlxPoint.get());
		accelerationRange.set(FlxPoint.get(), FlxPoint.get());
		elasticityRange.set(0);
		
		if (parent.animation.curAnim != null)
		{
			parent.animation.curAnim.restart();
		}
	}
	
	/**
	 * Triggered whenever this object is launched by a FlxEmitter.
	 * You can override this to add custom behavior like a sound or AI or something.
	 */
	public function onEmit():Void
	{
		
	}
	
	public function onFinish():Void
	{
		
	}
	
	public function destroy():Void
	{
		FlxDestroyUtil.put(velocityRange.start);
		FlxDestroyUtil.put(velocityRange.end);
		FlxDestroyUtil.put(scaleRange.start);
		FlxDestroyUtil.put(scaleRange.end);
		FlxDestroyUtil.put(dragRange.start);
		FlxDestroyUtil.put(dragRange.end);
		FlxDestroyUtil.put(accelerationRange.start);
		FlxDestroyUtil.put(accelerationRange.end);
		
		_point = FlxDestroyUtil.put(_point);
		
		velocityRange = null;
		angularVelocityRange = null;
		scaleRange = null;
		alphaRange = null;
		colorRange = null;
		dragRange = null;
		accelerationRange = null;
		elasticityRange = null;
		
		parent = null;
	}
}

class ParticleSettings implements IFlxDestroyable
{
	/**
	 * Sets particle's blend mode. null by default. Warning: Expensive on flash target.
	 */
	public var blend:BlendMode;
	
	/**
	 * How particles should be launched. If CIRCLE, particles will use launchAngle and velocity. Otherwise, particles will just use velocity.x and velocity.y.
	 */
	public var launchMode:FlxEmitterMode = FlxEmitterMode.CIRCLE;
	
	/**
	 * Sets the velocity range of particles launched from this emitter.
	 */
	public var velocity(default, null):FlxPointRangeBounds;
	/**
	 * The angular velocity range of particles launched from this emitter.
	 */
	public var angularVelocity(default, null):FlxRangeBounds<Float>;
	/**
	 * The angle range of particles launched from this emitter. angle.end is ignored unless ignoreAngularVelocity is set to true.
	 */
	public var angle(default, null):FlxRangeBounds<Float>;
	/**
	 * Set this if you want to specify the beginning and ending value of angle, instead of using angularVelocity.
	 */
	public var ignoreAngularVelocity:Bool = false;
	/**
	 * The angle range at which particles will be launched from this emitter. Ignored unless launchMode is set to FlxEmitterMode.CIRCLE
	 */
	public var launchAngle(default, null):FlxBounds<Float>;
	/**
	 * The life, or duration, range of particles launched from this emitter.
	 */
	public var lifespan(default, null):FlxBounds<Float>;
	/**
	 * Sets scale range of particles launched from this emitter.
	 */
	public var scale(default, null):FlxPointRangeBounds;
	/**
	 * Sets alpha range of particles launched from this emitter.
	 */
	public var alpha(default, null):FlxRangeBounds<Float>;
	/**
	 * Sets color range of particles launched from this emitter.
	 */
	public var color(default, null):FlxRangeBounds<FlxColor>;
	/**
	 * Sets X and Y drag component of particles launched from this emitter.
	 */
	public var drag(default, null):FlxPointRangeBounds;
	/**
	 * Sets the acceleration range of particles launched from this emitter. Set acceleration y-values to give particles gravity.
	 */
	public var acceleration(default, null):FlxPointRangeBounds;
	/**
	 * Sets the elasticity, or bounce, range of particles launched from this emitter.
	 */
	public var elasticity(default, null):FlxRangeBounds<Float>;
	/**
	 * Sets the immovable flag for particles launched from this emitter.
	 */
	public var immovable:Bool = false;
	/**
	 * Sets the autoUpdateHitbox flag for particles launched from this emitter. If true, the particles' hitbox will be updated to match scale.
	 */
	public var autoUpdateHitbox:Bool = false;
	
	/**
	 * Sets the allowCollisions value for particles launched from this emitter. Set to NONE by default. Don't forget to call FlxG.collide() in your update loop!
	 */
	public var allowCollisions:Int = FlxObject.NONE;
	/**
	 * Shorthand for toggling allowCollisions between ANY (if true) and NONE (if false). Don't forget to call FlxG.collide() in your update loop!
	 */
	public var solid(get, set):Bool;
	
	public var behaviorFactory:FlxSprite->IFlxParticleBehavior;
	
	public function new()
	{
		velocity = new FlxPointRangeBounds(-100, -100, 100, 100);
		angularVelocity = new FlxRangeBounds<Float>(0, 0);
		angle = new FlxRangeBounds<Float>(0);
		launchAngle = new FlxBounds<Float>(-180, 180);
		lifespan = new FlxBounds<Float>(3);
		scale = new FlxPointRangeBounds(1, 1);
		alpha = new FlxRangeBounds<Float>(1);
		color = new FlxRangeBounds<FlxColor>(FlxColor.WHITE, FlxColor.WHITE);
		drag = new FlxPointRangeBounds(0, 0);
		acceleration = new FlxPointRangeBounds(0, 0);
		elasticity = new FlxRangeBounds<Float>(0);
		
		behaviorFactory = ParticleBehavior.behaviorFactory;
	}
	
	public function destroy():Void
	{
		velocity = FlxDestroyUtil.destroy(velocity);
		scale = FlxDestroyUtil.destroy(scale);
		drag = FlxDestroyUtil.destroy(drag);
		acceleration = FlxDestroyUtil.destroy(acceleration);
		
		blend = null;
		angularVelocity = null;
		angle = null;
		launchAngle = null;
		launchMode = null;
		lifespan = null;
		alpha = null;
		color = null;
		elasticity = null;
	}
	
	private inline function get_solid():Bool
	{
		return (allowCollisions & FlxObject.ANY) > FlxObject.NONE;
	}
	
	private function set_solid(Solid:Bool):Bool
	{
		if (Solid)
		{
			allowCollisions = FlxObject.ANY;
		}
		else
		{
			allowCollisions = FlxObject.NONE;
		}
		return Solid;
	}
}