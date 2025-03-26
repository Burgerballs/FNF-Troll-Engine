package funkin.objects.hud;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;

using StringTools;

// Should we incluide this?? Should we just have it as part of base HealthIcon if icon has an xml??
/* class SparrowHealthIcon extends HealthIcon
{
	public static final IDLE_PREFIX = 'idle';
	public static final LOSING_PREFIX = 'losing';
	public static final WINNING_PREFIX = 'winning';
	override function swapOldIcon()
		trace("TODO");

	// I am just trusting the user on this one that the icon is formatted correctly lol
	// Maybe the prefix constants should be in the health icon instead???
	
	override function changeIcon(char:String){
		frames = Paths.getSparrowAtlas('icons/$char');
		animation.addByPrefix("idle", IDLE_PREFIX, 24);
		animation.addByPrefix("losing", LOSING_PREFIX, 24);
		final animFrames:Array<FlxFrame> = new Array<FlxFrame>();
		animation.findByPrefix(animFrames, WINNING_PREFIX);
		if (animFrames.length > 0)
			animation.addByPrefix("winning", WINNING_PREFIX, 24);
		else
			animation.addByPrefix("winning", IDLE_PREFIX, 24);
	}
} */
class HealthIcon extends FlxSprite
{
	public var autoUpdatesAnims:Bool = true;

	public var sprTracker:FlxObject;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public var previousPercent:Float = 0; // For transition calculating
	public var relativePercent(default, set):Float = 0;

	function set_relativePercent(percent:Float){
		if (autoUpdatesAnims)
			updateState(percent);
		previousPercent = relativePercent;
		return relativePercent = percent;
	}

	public var losingPercent:Float = 20;
	public var winningPercent:Float = 80;

	// Done to allow more customization by simply extending HealthIcon
	// Can also be used by scripts to do stuff w/ health icons
	// I.e adding transitions between animations
	
	public function getWithTransitionables() {
		// transition
		if (getAnimation(previousPercent) != getAnimation(relativePercent)) {
			isTransitioning = true;
			return getAnimation(previousPercent) + 'To' + getAnimation(relativePercent);
		} else {
			isTransitioning = false;
			return getAnimation(relativePercent);
		}
	}

	public function getAnimation(relativePercent:Float){
		if (relativePercent <= losingPercent)
			return 'losing';
		else if(relativePercent >= winningPercent)
			return 'winning';

		return 'idle';

	}
	
	// ignore abrupt animation playing during a transition!
	var isTransitioning = false;
	public function updateState(relativePercent:Float){
		if (canTransition && !isTransitioning)
			animation.play(getWithTransitionables(), true);
		else
			animation.play(getAnimation(relativePercent), true);
	}

	public function onAnimFinished(name:String) {
		var toSplit = name.split('To');
		if (isTransitioning) {
			isTransitioning = false;
			animation.play(toSplit[1], true);
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
	public static final IDLE_TO_LOSE_PREFIX = 'T';
	public static final IDLE_TO_WIN_PREFIX = 'TW';
	public static final LOSE_TO_IDLE_PREFIX = 'TR';
	public static final WIN_TO_IDLE_PREFIX = 'TWR';

	public function setupSparrow(char:String){
		var file:Null<FlxGraphic> = Paths.getWithFallbacks(Paths.getSparrowAtlas, ['icons/$char','icons/icon-$char']);
		animation.addByPrefix("idle", IDLE_PREFIX, 24);
		animation.addByPrefix("losing", LOSING_PREFIX, 24);
		addIfExists('winning', WINNING_PREFIX, 24, IDLE_PREFIX);
		var t:Bool = addIfExists('idleTolosing', IDLE_TO_LOSE_PREFIX, 24);
		var tw:Bool = addIfExists('idleTowinning', IDLE_TO_WIN_PREFIX, 24);
		var tr:Bool = addIfExists('losingToidle', LOSE_TO_IDLE_PREFIX, 24);
		var twr:Bool = addIfExists('winningToIdle', WIN_TO_IDLE_PREFIX, 24);

		// This is spaghetti ignore
		if (t == false && tr == true) {
			var aFrames = animation.getByName('losingToidle').frames;
			aFrames.reverse();
			animation.addByIndices('idleTolosing', IDLE_TO_LOSE_PREFIX, aFrames, '', 24);
			t = true;
		} else if (t == true && tr == false) {
			var aFrames = animation.getByName('idleTolosing').frames;
			aFrames.reverse();
			animation.addByIndices('losingToidle', LOSE_TO_IDLE_PREFIX, aFrames, '', 24);
			tr = true;
		}
		if (tw == false && twr == true) {
			var aFrames = animation.getByName('winningToIdle').frames;
			aFrames.reverse();
			animation.addByIndices('idleTowinning', WIN_TO_IDLE_PREFIX, aFrames, '', 24);
			tw = true;
		} else if (tw == true && twr == false) {
			var aFrames = animation.getByName('idleTowinning').frames;
			aFrames.reverse();
			animation.addByIndices('winningToIdle', IDLE_TO_WIN_PREFIX, aFrames, '', 24);
			twr = true;
		}

		canTransition = (t == tw == tr == twr == true);
	}

	public function addIfExists(name, prefix, framerate, ?fallback) {

		final animFrames:Array<FlxFrame> = new Array<FlxFrame>();
		@:privateAccess
		animation.findByPrefix(animFrames, prefix);
		if (animFrames.length > 0) {
			animation.addByPrefix(name, prefix, 24);
			return true;
		} else if (fallback != null) {
			animation.addByPrefix(name, fallback, 24);
		}
		return false;
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if (Paths.getWithFallbacks(Paths.getText, ['images/icons/$char.xml','images/icons/icon-$char.xml']) != null) {
			setupSparrow(char);
		} else {
			var file:Null<FlxGraphic> = Paths.getWithFallbacks(Paths.image, ['icons/$char','icons/icon-$char', 'icons/face']);
			trace(file);

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