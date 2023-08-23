package hud;

import PlayState.FNFHealthBar;
import flixel.ui.FlxBar;
import flixel.tweens.FlxEase;
import flixel.util.FlxStringUtil;
import JudgmentManager.JudgmentData;
import flixel.util.FlxColor;
import playfields.*;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;


// includes basic HUD stuff

class CommonHUD extends BaseHUD
{
	// just some extra variables lol
	public var healthBar:FNFHealthBar;
	@:isVar
	public var healthBarBG(get, null):FlxSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	
	function get_healthBarBG()
		return healthBar.healthBarBG;

	override function set_displayedHealth(value:Float){
		healthBar.value = value;
		displayedHealth = value;
		return value;
	}

	public var timeBar:FlxBar;
	public var timeTxt:FlxText;

	private var timeBarBG:FlxSprite;

	public function new(iP1:String, iP2:String, songName:String, stats:Stats)
	{
		super(iP1, iP2, songName, stats);
		this.stats = stats;
		this.songName = songName;
		if (!ClientPrefs.useEpics)
			displayedJudges.remove("epic");

		healthBar = new FNFHealthBar(iP1, iP2);
		iconP1 = healthBar.iconP1;
		iconP2 = healthBar.iconP2;

		// prob gonna do my own time bar too lol but for now idc
		timeTxt = new FlxText(FlxG.width * 0.5 - 200, 0, 400, "", 32);
		timeTxt.setFormat(Paths.font("calibri.ttf"), 32, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;

		var bgGraphic = Paths.image('timeBar');
		if (bgGraphic == null)
			bgGraphic = CoolUtil.makeOutlinedGraphic(400, 20, 0xFFFFFFFF, 5, 0xFF000000);

		timeBarBG = new FlxSprite(timeTxt.x, 0, bgGraphic);
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.scrollFactor.set();

		timeBar = new FlxBar(timeBarBG.x + 5, 0, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 10), Std.int(timeBarBG.height - 10), this, 'songPercent', 0, 1);
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.scrollFactor.set();

		updateTimeBarType();

		add(timeBarBG);
		add(timeBar);
		add(timeTxt);
	}

	function updateTimeBarType()
	{
		// trace("time bar update", ClientPrefs.timeBarType); // the text size doesn't get updated sometimes idk why

		updateTime = (ClientPrefs.timeBarType != 'Disabled' && ClientPrefs.timeOpacity > 0);

		timeTxt.exists = updateTime;
		timeBarBG.exists = updateTime;
		timeBar.exists = updateTime;

		if (ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = songName;
			timeTxt.size = 24;
			timeTxt.offset.y = -3;
		}
		else
		{
			timeTxt.text = "";
			timeTxt.size = 32;
			timeTxt.offset.y = 0;
		}

		timeTxt.y = ClientPrefs.downScroll ? (FlxG.height - 44) : 19;
		timeBarBG.y = timeTxt.y + (timeTxt.height * 0.25);
		timeBar.y = timeBarBG.y + 5;

		updateTimeBarAlpha();
	}

    override function changedCharacter(id:Int, char:Character){

        switch(id){
            case 1:
				iconP1.changeIcon(char.healthIcon);
            case 2:
				iconP2.changeIcon(char.healthIcon);
            case 3:
                // gf icon
            default:
                // idk
        }
        
		super.changedCharacter(id, char);
    }

	function updateTimeBarAlpha()
	{
		var timeBarAlpha = ClientPrefs.timeOpacity * alpha * tweenProg;

		timeBarBG.alpha = timeBarAlpha;
		timeBar.alpha = timeBarAlpha;
		timeTxt.alpha = timeBarAlpha;
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon();

		if (updateTime)
		{
			var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
			if (curTime < 0)
				curTime = 0;

			songPercent = (curTime / songLength);
			time = curTime;

			var timeCalc:Null<Float> = null;

			switch (ClientPrefs.timeBarType)
			{
				case "Percentage":
					timeTxt.text = Math.floor(songPercent * 100) + "%";
				case "Time Left":
					timeCalc = (songLength - time);
				case "Time Elapsed":
					timeCalc = time;
			}

			if (timeCalc != null)
			{
				if (timeCalc <= 0)
					timeTxt.text = "0:00"
				else
					timeTxt.text = FlxStringUtil.formatTime(timeCalc / FlxG.timeScale / 1000, false);
			}
		}

		super.update(elapsed);
	}

	override function beatHit(beat:Int)
	{
		healthBar.iconScale = 1.2;
	}

	override function changedOptions(changed:Array<String>)
	{
		healthBar.healthBarBG.y = FlxG.height * (ClientPrefs.downScroll ? 0.11 : 0.89);
		healthBar.y = healthBarBG.y + 5;
		healthBar.iconP1.y = healthBar.y - 75;
		healthBar.iconP2.y = healthBar.y - 75;

		updateTimeBarType();
	}

	var tweenProg:Float = 0;

	override function songStarted()
	{
		FlxTween.num(0, 1, 0.5, {
			ease: FlxEase.circOut,
			onComplete: function(tw:FlxTween)
			{
				tweenProg = 1;
				updateTimeBarAlpha();
			}
		}, function(prog:Float)
		{
			tweenProg = prog;
			updateTimeBarAlpha();
		});
	}

	override function songEnding()
	{
		timeBarBG.exists = false;
		timeBar.exists = false;
		timeTxt.exists = false;
	}

}