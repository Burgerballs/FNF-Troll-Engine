package funkin.states;

import flixel.util.FlxGradient;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.input.keyboard.FlxKeyList;
import flixel.input.keyboard.FlxKeyboard;
import funkin.data.DiffCalc;
import funkin.data.Highscore;
import flixel.math.FlxMath;
import funkin.states.SongSelectState.SongChartSelec;
import funkin.data.Song;
import funkin.data.WeekData;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
using StringTools;
using funkin.CoolerStringTools;

@:injectMoreFunctions([
	"onSelectSong",
	"onAccept",
	"refreshScore",
	"changeDifficulty",
	"positionHighscore"
])
class FreeplayState extends MusicBeatState
{
	public static var difficultyColors:Array<Dynamic> = [
		['easy', [0xFF00FF22, 0xFF000000]],
		['normal', [0xFFFFFF00, 0xFF000000]],
		['hard', [0xFFFF0000, 0xFFFFFFFF]],
		['lunatic', [0xFF8800FF, 0xFFFFFFFF]]
	];
	
	public static var defaultDiffColor = [0xFFFFFFFF, 0xFF000000];

	public var curDiffColor(get, null):Array<FlxColor>;
	function get_curDiffColor():Array<FlxColor> {
		var ret:Array<FlxColor> = defaultDiffColor;
		for (diffs in difficultyColors) {
			if (curDiffStr == diffs[0])
				ret = diffs[1];
		}
		return ret;
	}

	public static var comingFromPlayState:Bool = false;

	var msd:Float = 0;
	var menu = new AlphabetMenu();
	var songData:Array<Song> = [];

	var bgGrp = new FlxTypedGroup<FlxSprite>();
	var diffGrp = new FlxTypedGroup<FlxText>();
	var bg:FlxSprite;
	var coverSprite:FlxSprite;

	var targetHighscore:Float = 0.0;
	var lerpHighscore:Float = 0.0;

	var targetRating:Float = 0.0;
	var lerpRating:Float = 0.0;

	var scoreBG:FlxSprite;
	var featuresBG:FlxSprite;
	var scoreText:FlxText;
	var msdText:FlxText;
	var bpmText:FlxText;
	var metaText:FlxText;
	var diffText:FlxText;
	var features:FlxText;
	
	var selectedDiffBG:FlxSprite;

	static var lastSelected:Int = 0;
	static var curDiffStr:String = "normal";
	static var curDiffIdx:Int = 1;

	var selectedSongData:Song;
	var selectedSongCharts:Array<String>;
	
	var tLength = (386 + 2) / 3;

	var hintText:FlxText;
	
	override public function create()
	{
		#if DISCORD_ALLOWED
		funkin.api.Discord.DiscordClient.changePresence('In the menus');
		#end

		for (week in WeekData.reloadWeekFiles(true))
		{
			Paths.currentModDirectory = week.directory;

			if (week.songs == null)
				continue;

			for (songName in week.songs){
				var song = new Song(
					Paths.formatToSongPath(songName), 
					week.directory
				);
				
				if (Main.showDebugTraces && song.charts.length == 0) {
					trace('"$song" doesn\'t have any available charts!');
					continue;
				}
				
				menu.addTextOption(song.getMetadata().songName).ID = songData.length;
				songData.push(song);
			}
		}

		////
		add(bgGrp);

		add(menu);
		menu.controls = controls;
		menu.callbacks.onSelect = (selectedIdx, _) -> onSelectSong(songData[selectedIdx]);
		menu.callbacks.onAccept = (_, _) -> onAccept();


		var keyHintGameplayChangers = new KeyHint(14, FlxG.height - 36, 'Gameplay Changers', [FlxKey.CONTROL #if mac , FlxKey.WINDOWS #end], controls);
		keyHintGameplayChangers.scrollFactor.set();
		add(keyHintGameplayChangers);

		var keyHintDown = new KeyHint(14, FlxG.height - 72, 'Reset Score', [FlxKey.R], controls);
		add(keyHintDown);
		keyHintDown.scrollFactor.set();

		////
		scoreText = new FlxText(0, 5, 0, 'PERSONAL BEST: 0', 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, RIGHT);

		scoreBG = CoolUtil.blankSprite(386, 720, 0xFF999999);
		scoreBG.setPosition(FlxG.width - 386, 0);
		scoreBG.blend = MULTIPLY;
		add(scoreBG);

		// diffText = new FlxText(scoreText.x, scoreText.y + 36, 100, "", 24);
		// diffText.alignment = CENTER;
		// diffText.font = scoreText.font;
		// add(diffText);

		selectedDiffBG = new FlxSprite(0,0).makeGraphic(1,1,0xFFFFFFFF);
		add(selectedDiffBG);

		add(diffGrp);
		generateDiffGroup(['easy', 'normal', 'hard']);

		msdText = new FlxText(scoreText.x, scoreText.y + 60, 100, "Rating: 10.0pts", 24);
		msdText.alignment = LEFT;
		msdText.font = scoreText.font;
		add(msdText);

		add(scoreText);

		coverSprite = new FlxSprite(0,0);
		add(coverSprite);

		coverSprite.x = scoreBG.x;
		coverSprite.y = 96;

		coverSprite.visible = false;

		bpmText = new FlxText(scoreBG.x + 2, coverSprite.y + 62, 386, "BPM: 120", 32);
		bpmText.alignment = LEFT;
		bpmText.font = scoreText.font;
		add(bpmText);

		metaText = new FlxText(scoreBG.x + 2, bpmText.y + 32, 386, "BPM: 120", 24);
		metaText.alignment = LEFT;
		metaText.font = scoreText.font;
		add(metaText);

		featuresBG = FlxGradient.createGradientFlxSprite(386, 96, [0xFF000000, 0x00000000], 1, 270);
		featuresBG.setPosition(FlxG.width - 386, FlxG.height - 96);
		add(featuresBG);

		features = new FlxText(scoreBG.x + 2, FlxG.height - 24, 386, "Features: SV, Modcharts", 16);
		features.alignment = LEFT;
		features.font = scoreText.font;
		add(features);

		////
		menu.curSelected = lastSelected;
		if (comingFromPlayState) playSelectedSongMusic();

		super.create();
		comingFromPlayState = false;
	}

	function reloadFont(){
		scoreText.font = Paths.font("vcr.ttf");
	}

	function generateDiffGroup(diffList:Array<String>) {
		diffGrp.clear();
		tLength = (scoreBG.width - 2) / diffList.length;
		var xOffset = scoreBG.x + 2;
		var yOffset = scoreText.y + 36;
		for (idx in 0...diffList.length)
		{
			var tabName = diffList[idx];

			var strKey = 'opt_tabName_$tabName';
			var text = new FlxText(0, 0, 0, Paths.getString(strKey, tabName).toUpperCase(), 24);
			text.alignment = CENTER;
			text.font = scoreText.font;

			var button = new FlxSprite(xOffset, yOffset).makeGraphic(1,1,difficultyColors[idx]);
			button.ID = idx;
			button.alpha = 1;
			
			button.scale.set(tLength - 2, 24);
			button.updateHitbox();

			text.setPosition(
				button.x,
				button.y + ((button.height - text.height) / 2)
			);
			text.fieldWidth = button.width;
			text.updateHitbox();

			xOffset = button.x + button.width + 2;
			diffGrp.add(text);

		}

	}

	var songLoaded:String = null;
	var selectedSong:String = null;
	function onAccept() {
		var proceed:Bool = false;
		
		if (selectedSongCharts.length == 0)
			proceed = false;
		else{
			proceed = songLoaded == selectedSong && PlayState.SONG != null;
		
			if (!proceed) {
				Song.loadSong(selectedSongData, curDiffStr);
				proceed = PlayState.SONG != null;
			}
		}

		if (!proceed) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		menu.controls = null;

		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.16);

		if (FlxG.keys.pressed.SHIFT)
			LoadingState.loadAndSwitchState(new funkin.states.editors.ChartingState());
		else
			LoadingState.loadAndSwitchState(new PlayState());
	}

	function playSelectedSongMusic() {
		// load song json and play inst
		if (songLoaded != selectedSong){
			songLoaded = selectedSong;
			Song.loadSong(selectedSongData, curDiffStr);
			
			if (PlayState.SONG != null){
				var instAsset = Paths.track(PlayState.SONG.song, PlayState.SONG.tracks.inst[0]);
				FlxG.sound.playMusic(instAsset, 0.6);
			}
		}
	}

	// disable menu class controls for one update cycle Dx 
	var stunned:Bool = false;
	inline function stun(){
		stunned = true;
		menu.controls = null;
	}

	public function updateMSD():Float {
		if (selectedSongCharts.length == 0) return 0;
		var song = Song.loadSong(selectedSongData, curDiffStr);
		if (song != null) {
			return DiffCalc.CalculateDiff(song, .98) * 1000;
		}
		return 0;
	}

	override public function update(elapsed:Float)
	{
		if (stunned){
			stunned = false;
			menu.controls = controls;
		}

		if (controls.UI_LEFT_P){
			changeDifficulty(-1);
			msd = updateMSD();
		}
		if (controls.UI_RIGHT_P){
			changeDifficulty(1);
			msd = updateMSD();
		}

		if (FlxG.keys.justPressed.SPACE){
			stun();
			playSelectedSongMusic();

		}else if (controls.BACK){
			menu.controls = null;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new funkin.states.MainMenuState());	
			
		}else if (controls.RESET){
			var songName:String = selectedSongData.songId;
			var _dStrId:String = 'difficultyName_$curDiffStr';
			
			var diffName:String = Paths.getString(_dStrId, curDiffStr);
			var displayName:String = '$songName ($diffName)'; // maybe don't specify the difficulty if it's the only available one

			openSubState(new ResetScoreSubState(
				songName, 
				curDiffStr.toLowerCase() == 'normal' ? '' : curDiffStr, 
				false, 
				displayName
			));
			this.subStateClosed.addOnce((_) -> refreshScore());
			
		}else if (FlxG.keys.justPressed.CONTROL #if mac || FlxG.keys.justPressed.WINDOWS #end){
			openSubState(new GameplayChangersSubstate());
			this.subStateClosed.addOnce((_) -> refreshScore());
		}

		super.update(elapsed);
	}

	var curMeta:SongMetadata = null;

	function onSelectSong(data:Song)
	{	
		selectedSongData = data;
		selectedSongCharts = data.charts;
		Paths.currentModDirectory = data.folder;
		if (data.songCover != null) {
			coverSprite.loadGraphic(data.songCover);
			coverSprite.scale.x = 386 / coverSprite.frameWidth;
			coverSprite.scale.y = 60 / coverSprite.frameHeight;
			coverSprite.updateHitbox();
			coverSprite.visible = true;
			coverSprite.antialiasing = false;
		}	
		else {
			coverSprite.visible = false;
		}

		changeDifficulty(CoolUtil.updateDifficultyIndex(curDiffIdx, curDiffStr, selectedSongCharts), true);

		msd = updateMSD();
		bpmText.text = 'BPM: ${selectedSongData.bpm}';
		curMeta = data.getMetadata();

		var modBgGraphic = Paths.image('menuBGBlue');
		reloadFont();
		if (bg == null || modBgGraphic != bg.graphic)
			fadeToBg(modBgGraphic);
	}


	function refreshScore()
	{
		var data = selectedSongData;
		var record = Highscore.getRecord(data.songId, curDiffStr);

		targetRating = Highscore.getRatingRecord(record) * 100;
		if(ClientPrefs.showWifeScore)
			targetHighscore = record.accuracyScore * 100;
		else
			targetHighscore = record.score;
	}

	function fadeToBg(graphic){
		var prevBg = bg;

		if (bgGrp.length < 6){
			bg = bgGrp.recycle(FlxSprite);
		}else{ /// fixed size flxgroups are wack
			bg =  bgGrp.members[0];
			FlxTween.cancelTweensOf(bg);
			bg.alpha = 1.0;
			bg.revive();
		};
		bg.loadGraphic(graphic);
		bg.screenCenter();
		
		if (prevBg == null)
			return;

		bg.alpha = 0.0;
		FlxTween.tween(bg, {alpha: 1.0}, 0.4, {
			ease: FlxEase.sineInOut,
			onComplete: (_) -> prevBg.kill()
		});
		
		bgGrp.remove(bg, true);
		bgGrp.add(bg);
	}

	function changeDifficulty(val:Int = 0, ?isAbs:Bool)
	{
		var charts = selectedSongCharts;

		switch (charts.length){
			case 0:
				generateDiffGroup(['NO CHARTS AVAILABLE']);
				curDiffStr = 'NONE';
				//diffText.text = "NO CHARTS AVAILABLE";

			case 1:
				generateDiffGroup(charts);
				curDiffStr = charts[0];
				curDiffIdx = 0;

			default:
				generateDiffGroup(charts);
				selectedDiffBG.color = curDiffColor[0];
				curDiffIdx = isAbs ? val : FlxMath.wrap(curDiffIdx + val, 0, charts.length - 1);
				curDiffStr = charts[curDiffIdx];
		}

		for (i in 0...diffGrp.members.length) {
			if (i == curDiffIdx) {
				diffGrp.members[i].color = curDiffColor[1];
				continue;
			}
			diffGrp.members[i].color = 0xFFFFFFFF;

		}

		selectedSong = '$selectedSongData-$curDiffStr';
		refreshScore();
	}

	var sinus:Float = 0;

	override function draw()
	{
		var elapsed = FlxG.elapsed;
		sinus += elapsed;
		lerpHighscore = CoolUtil.coolLerp(lerpHighscore, targetHighscore, FlxG.elapsed * 12);
		lerpRating = CoolUtil.coolLerp(lerpRating, targetRating, FlxG.elapsed * 8);

		var score = Math.round(lerpHighscore);
		var rating = formatRating(lerpRating);

		scoreText.text = 'PERSONAL BEST: $score ($rating%)';
		positionHighscore();
		msdText.text = 'Rating: ' + '${msd}pts';
		metaText.text = Song.getMetadataInfo(curMeta).join('\n');
		var featuresS:String = Song.getFeatureList(curMeta).join(', ');
		features.text = featuresS != '' ? ('Features: ' + featuresS) : '';

		if (diffGrp.members[curDiffIdx] != null) {
			selectedDiffBG.x = CoolUtil.coolLerp(selectedDiffBG.x, diffGrp.members[curDiffIdx].x, elapsed*21);
			selectedDiffBG.y = diffGrp.members[curDiffIdx].y;
			selectedDiffBG.scale.x = CoolUtil.coolLerp(selectedDiffBG.scale.x, diffGrp.members[curDiffIdx].width, elapsed*21);
			selectedDiffBG.scale.y = diffGrp.members[curDiffIdx].height;
			selectedDiffBG.color =  FlxColor.interpolate(selectedDiffBG.color, curDiffColor[0], elapsed*21);	
		}
		

		selectedDiffBG.updateHitbox();

		super.draw();
	}


	private static function formatRating(val:Float):String
	{
		var str = Std.string(Math.floor(val * 100.0) / 100.0);
		var dot = str.indexOf('.');

		if (dot == -1)
			return str + '.00';

		dot += 3;
		while (str.length < dot)
			str += '0';

		return str;
	}

	private function positionHighscore() {
		var bgWidth = 386;

		scoreText.x = scoreBG.x;
		scoreText.scale.x = scoreBG.width / scoreText.frameWidth;
		scoreText.updateHitbox();
		msdText.x = scoreText.x = scoreBG.x + 3;
		msdText.fieldWidth = bgWidth;
	}

	override public function destroy()
	{
		lastSelected = menu.curSelected;
		
		super.destroy();
	}
}