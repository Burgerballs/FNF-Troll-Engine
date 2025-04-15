package funkin.objects.hud;

import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import sys.FileSystem;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;

using StringTools;

// Okay so this class contains
// Mic'd Up style winning icon system
// Kero Icon System 2025 Edition
// canTransition
class HealthIcon extends FlxSprite
{
	public var autoUpdatesAnims:Bool = true;

	public var sprTracker:FlxObject;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public var previousPercent:Float = 50; // For transition calculating
	public var relativePercent(default, set):Float = 50;

	function set_relativePercent(percent:Float){
		if (autoUpdatesAnims)
			updateState(percent);
		return relativePercent = percent;
	}

	public var losingPercent:Float = 20;
	public var winningPercent:Float = 80;

	// Done to allow more customization by simply extending HealthIcon
	// Can also be used by scripts to do stuff w/ health icons
	// I.e adding transitions between animations
	
	public function getWithTransitionables() {
		// transition
		var f = getAnimation(previousPercent);
		var n = getAnimation(relativePercent);
		if (f != n) {
			isTransitioning = true;
			previousPercent = relativePercent;
			if (animation.exists(f + 'To' + n))
				return f + 'To' + n;
			else if (animation.exists(n + 'To' + f))
				return n+'To'+f+'-r';
		}
		isTransitioning = false;
		return getAnimation(relativePercent);
	}

	public function getAnimation(perc:Float){
		if (perc <= losingPercent)
			return 'losing';
		else if(perc >= winningPercent)
			return 'winning';

		return 'idle';

	}
	
	// ignore abrupt animation playing during a transition!
	var isTransitioning = false;
	public function updateState(relativePercent:Float){
		if (canTransition && !isTransitioning) {
			var anim:String = getWithTransitionables();
			var reverse = anim.endsWith("-r");
			anim = anim.split('-')[0];
			animation.play(anim, false, reverse);
		}
		else if (!isTransitioning)
			animation.play(getAnimation(relativePercent), false);
	}

	public function onAnimFinished(name:String) {
		if (name.contains('To')) {
			if (isTransitioning) {
				isTransitioning = false;
			}
		}
	}



	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		animation.finishCallback = onAnimFinished;

		this.isPlayer = isPlayer;

		changeIcon(char);

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	
		super.update(elapsed);
	}

	var hasWinning:Bool = false;
	function changeIconGraphic(graphic:FlxGraphic)
	{
		hasWinning = graphic.width >= (graphic.height * 3);
		loadGraphic(graphic, true, Math.floor(graphic.width / (hasWinning ? 3 : 2)), Math.floor(graphic.height));
		iconOffsets[0] = (width - 150) * 0.5;
		iconOffsets[1] = (width - 150) * 0.5;
		updateHitbox();
		//trace(iconOffsets[0], iconOffsets[1]);

		animation.add("idle", [0], 0, false, isPlayer);
		animation.add("losing", [1], 0, false, isPlayer);
		animation.add("winning", [hasWinning ? 2 : 0], 0, false, isPlayer);

		animation.play('idle');
	}

	public function swapOldIcon() 
	{
		if (!isOldIcon){
			var oldIcon = Paths.image('icons/$char-old');
			
			if(oldIcon == null)
				oldIcon = Paths.image('icons/icon-$char-old'); // base game compat

			if (oldIcon != null){
				changeIconGraphic(oldIcon);
				isOldIcon = true;
				return;
			}
		}

		changeIcon(char);
		isOldIcon = false;
	}

	var canTransition = false;
	// Apologies for the rather unorthadox way of naming these prefixes
	// bub's fruit salad is one drug!
	public static final IDLE_PREFIX = 'N';
	public static final LOSING_PREFIX = 'L';
	public static final WINNING_PREFIX = 'W';
	public static final IDLE_TO_LOSE_PREFIX = 'T ';
	public static final IDLE_TO_WIN_PREFIX = 'TW';
	public static final LOSE_TO_IDLE_PREFIX = 'TR';
	public static final WIN_TO_IDLE_PREFIX = 'TWR';

	public function setupSparrow(char:String){
		frames = Paths.getWithFallbacks(Paths.getSparrowAtlas, ['icons/$char','icons/icon-$char']);
		animation.addByPrefix("idle", IDLE_PREFIX, 24, true);
		animation.addByPrefix("losing", LOSING_PREFIX, 24, true);
		addIfExists('winning', WINNING_PREFIX, 24, IDLE_PREFIX, true);
		var t:Bool = addIfExists('idleTolosing', IDLE_TO_LOSE_PREFIX, 24, false);
		var tw:Bool = addIfExists('idleTowinning', IDLE_TO_WIN_PREFIX, 24, false);
		var tr:Bool = addIfExists('losingToidle', LOSE_TO_IDLE_PREFIX, 24, false);
		var twr:Bool = addIfExists('winningToidle', WIN_TO_IDLE_PREFIX, 24, false);
		canTransition = (t == tw == true);
	}

	public function addIfExists(name, prefix, framerate, ?fallback, ?loop) {

		final animFrames:Array<FlxFrame> = new Array<FlxFrame>();
		@:privateAccess
		animation.findByPrefix(animFrames, prefix);
		if (animFrames.length > 0) {
			animation.addByPrefix(name, prefix, 24, loop);
			return true;
		} else if (fallback != null) {
			animation.addByPrefix(name, fallback, 24, loop);
		}
		return false;
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {

		var d:Null<Bool> = Paths.getWithFallbacks(Paths.fileExists, ['images/icons/$char.xml','images/icons/icon-$char.xml']);
		if (d != null) {
			setupSparrow(char);
		} else {
			var file:Null<FlxGraphic> = Paths.getWithFallbacks(Paths.image, ['icons/$char','icons/icon-$char', 'icons/face']);

			if (file != null){
				//// TODO: sparrow atlas icons? would make the implementation of extra behaviour (ex: winning icons) way easier
				changeIconGraphic(file);
				this.char = char;
			}
		}
		if (char.endsWith("-pixel")){
			antialiasing = false;
			useDefaultAntialiasing = false;
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}
}