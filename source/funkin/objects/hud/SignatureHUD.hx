package funkin.objects.hud;

import flixel.util.FlxStringUtil;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class SignatureHUD extends CommonHUD {
    
    var scoreTxt:FlxText;
	var accuracyTxt:FlxText;
	var statsTxt:FlxText;

    public function new(iP1:String, iP2:String, songName:String, stats:Stats)
    {
        super(iP1, iP2, songName, stats);

        scoreTxt = new FlxText(healthBarBG.x + 32, healthBarBG.y + healthBarBG.height, healthBarBG.width - 32, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1;
		scoreTxt.antialiasing = true;

        add(healthBarBG);
        add(healthBar);
        add(iconP1);
		add(iconP2);

        add(scoreTxt);

        accuracyTxt = new FlxText(-8, 8, 1280, "100%", 32);
		accuracyTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		accuracyTxt.scrollFactor.set();
		accuracyTxt.borderSize = 2;
		add(accuracyTxt);
		accuracyTxt.antialiasing = true;

        statsTxt = new FlxText(-8, accuracyTxt.y + accuracyTxt.height, 1280, "", 24);
		statsTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		statsTxt.scrollFactor.set();
		statsTxt.borderSize = 2;
		add(statsTxt);
		statsTxt.antialiasing = true;
    }

    var scoreString = Paths.getString("score");

	override function update(elapsed:Float){
		super.update(elapsed);
		var shownScore:Float = 0;
		if (ClientPrefs.showWifeScore)
			shownScore = Math.floor(stats.totalNotesHit * 100);
		else
			shownScore = stats.score;

		if (ClientPrefs.botplayMarker != 'Off' && PlayState.instance.cpuControlled)
			scoreTxt.text = 'Botplay Enabled';
		else
			scoreTxt.text = '$scoreString: ${FlxStringUtil.formatMoney(shownScore, false, true)}';

        accuracyTxt.text = '${Highscore.floorDecimal(ratingPercent * 100, 3)}%';
        statsTxt.text = 'Misses: ${stats.misses}\n${ratingFC} - ${grade}';
	}

    override function reloadHealthBarColors(dadColor:FlxColor, bfColor:FlxColor)
    {
        if (healthBar != null)
        {
            if (healthBar.isOpponentMode)
                healthBar.createFilledBar(bfColor, dadColor);
            else
                healthBar.createFilledBar(dadColor, bfColor);
            
            healthBar.updateBar();
        }
    }
}