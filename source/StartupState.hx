package;

import math.CoolMath;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import funkin.*;
import funkin.states.MusicBeatState;
import funkin.states.FadeTransitionSubstate;

import funkin.data.Highscore;
import funkin.input.PlayerSettings;

import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;

#if sys
import Sys.time as getTime;
#else
import haxe.Timer.stamp as getTime;
#end

#if MULTICORE_LOADING
import sys.thread.Thread;
import sys.thread.Mutex;
#end

#if (DO_AUTO_UPDATE || display)
import funkin.states.UpdaterState;
#end

using StringTools;

// Loads the title screen, alongside some other stuff.

class StartupState extends FlxTransitionableState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var fullscreenKeys:Array<FlxKey> = [FlxKey.F11];
	public static var specialKeysEnabled(default, set):Bool;

	@:noCompletion inline public static function set_specialKeysEnabled(val)
	{
		if (val) {
			FlxG.sound.muteKeys = StartupState.muteKeys;
			FlxG.sound.volumeDownKeys = StartupState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = StartupState.volumeUpKeys;
		}
		else {
			final emptyArr = [];
			FlxG.sound.muteKeys = emptyArr;
			FlxG.sound.volumeDownKeys = emptyArr;
			FlxG.sound.volumeUpKeys = emptyArr;
		}

		return specialKeysEnabled = val;
	}

	public function new()
	{
		super();
		// this.canBeScripted = false; // vv wait this isnt a musicbeatstate LOL!

		persistentDraw = true;
		persistentUpdate = true;
	}

	public static var loadActions:Array<() -> Void> = [
		function():Void {
			Paths.init();
			Paths.getAllStrings();
		},
		function():Void {
			actionTxt.text = 'Initializing Player Settings...';
			PlayerSettings.init();
		},
		function():Void {
			actionTxt.text = 'Initializing Client Preferences...';
			ClientPrefs.initialize();
			ClientPrefs.load();
		},
		function():Void {
			actionTxt.text = 'Loading Player Highscores...';
			Highscore.load();
		},
		function():Void {
			actionTxt.text = 'Doing Flixel System Junk...';
			FlxG.sound.onVolumeChange.add((vol:Float) -> {
				ClientPrefs.masterVolume = vol;
	
				@:privateAccess {
					Reflect.setField(ClientPrefs.optionSave.data, "masterVolume", vol);
					ClientPrefs.optionSave.flush();
				}
			});
	
			specialKeysEnabled = true;
			FlxG.fixedTimestep = false;
			FlxG.keys.preventDefaultKeys = [TAB];

			#if (windows || linux || mac) // No idea if this also applies to any other targets
			FlxG.stage.addEventListener(
				openfl.events.KeyboardEvent.KEY_DOWN, 
				(e)->{
					// Prevent Flixel from listening to key inputs when switching fullscreen mode
					if (e.keyCode == FlxKey.ENTER && e.altKey)
						e.stopImmediatePropagation();
	
					// Also add F11 to switch fullscreen mode
					if (specialKeysEnabled && fullscreenKeys.contains(e.keyCode))
						FlxG.fullscreen = !FlxG.fullscreen;
				}, 
				false, 
				100
			);
	
			FlxG.stage.addEventListener(
				openfl.events.FullScreenEvent.FULL_SCREEN, 
				(e) -> FlxG.save.data.fullscreen = e.fullScreen
			);
			#end

			#if DISCORD_ALLOWED
			FlxG.stage.application.onExit.add((exitCode) -> funkin.api.Discord.DiscordClient.shutdown(true));
			#end
	
			FlxTransitionableState.defaultTransIn = FadeTransitionSubstate;
			FlxTransitionableState.defaultTransOut = FadeTransitionSubstate;
		},
		function() {
			actionTxt.text = 'Loading up the Title Screen...';
		}
	];

	public static var nextState:Class<FlxState> = funkin.states.TitleState;
	public static var loadPercent:Float = 0;
	private static var loaded = false;
	public static function load():Void
	{
		if (loaded)
			return;
		loaded = true;

		var it:Float = 0;
		for (action in loadActions) {
			action();
			loadPercent = 50;
			loadBar.value = loadPercent;
			it++;
		}
	}

	static var loadBar:FlxBar;
	static var actionTxt:FlxText;
	override function create()
	{
		this.transIn = null;
		this.transOut = null;

		var versionShit:FlxText = new FlxText(2, 2, 0, 'Loading...', 18);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		actionTxt = new FlxText(2, 22, 0, 'Initializing Paths and Localization Strings...', 18);
		actionTxt.scrollFactor.set();
		actionTxt.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(actionTxt);

		loadBar = new FlxBar(versionShit.x + versionShit.width + 32, 2, LEFT_TO_RIGHT, Std.int(FlxG.width - (versionShit.x + versionShit.width + 32) - 32), 16, null, null, 0, 100);
		loadBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		add(loadBar);
		super.create();
	}


	private var step:Int = 0;
	private var loadingTime:Float = getTime();

	#if MULTICORE_LOADING
	private var loadingMutex:Null<Mutex> = null;
	#end

	inline private function doLoading()
	{
		load();
		final stateLoad:Dynamic = Reflect.getProperty(nextState, "load");
		if (stateLoad != null) Reflect.callMethod(null, stateLoad, []);

		loadingTime = getTime() - loadingTime;
	}

	var fadeTwn:FlxTween = null;
	override function update(elapsed:Float)
	{
		switch (step){
			case 0:
				#if !MULTICORE_LOADING
				doLoading();
				step = 10;

				#else
				if (loadingMutex == null){
					loadingMutex = new Mutex();
					Thread.create(() -> {
						loadingMutex.acquire();
						doLoading();
						loadingMutex.release();
					});
				}
				else if (loadingMutex.tryAcquire()){
					// is this necessary or at least favorable
					loadingMutex.release();
					loadingMutex = null;

					step = 10;
				}
				#end
				
			#if !tgt
			case 10:
				trace('loading lasted $loadingTime');
				step = 50;
			#end
			
			#if tgt
			case 10:
				trace('loading lasted $loadingTime');
				#if debug
				final waitTime:Float = 0.0;
				#else
				final waitTime:Float = (nextState == funkin.states.PlayState || nextState == funkin.states.editors.ChartingState) ? 0.0 : Math.max(0.0, 1.6 - loadingTime);
				#end

				step = 30;

				fadeTwn = FlxTween.tween(warning, {alpha: 0}, 1.0, {
					ease: FlxEase.expoIn,
					startDelay: waitTime,
					onStart: (twn)->{step = 40;},
					onComplete: (twn)->{step = 50;}
				});
				
			case 30:
				if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed){
					fadeTwn.startDelay = 0;
					step = 40;
				}
			case 40:
				if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed){
					fadeTwn.percent = (1.0 + fadeTwn.percent) * 0.5;
				}
			#end

			case 50:
				#if(DO_AUTO_UPDATE || display)
				if (Main.outOfDate)
					MusicBeatState.switchState(new UpdaterState(Main.recentRelease)); // UPDATE!!
				else
				#end
				{
					MusicBeatState.switchState(Type.createInstance(nextState, []));
				}
				step = 100000;
		}

		super.update(elapsed);
	}
}