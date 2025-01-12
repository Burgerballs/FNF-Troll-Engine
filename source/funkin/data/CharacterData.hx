package funkin.data;

import funkin.objects.Character;
import flixel.util.FlxColor;
using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	
	var position:Array<Float>;
	var camera_position:Array<Float>;
	
	var flip_x:Bool;
	var no_antialiasing:Bool;

	var healthbar_colors:Array<Int>;
	var healthicon:String;

	@:optional var renderType:CharacterRenderType;
	@:optional var x_facing:Float;
	@:optional var death_name:String;
	@:optional var script_name:String;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	@:optional var assetPath:String; // to be used for multisparrow.
	@:optional var cameraOffset:Array<Float>;
}

class CharacterData {
	public static function getCharacterFile(characterName:String):Null<CharacterFile>
	{
		var json:Null<Dynamic> = Paths.json('characters/$characterName.json');

		if (json == null){
			trace('Could not find character "$characterName" JSON file');
			return null;
		}

		switch (Reflect.field(json, "format")){
			case "andromeda": return fileFromAndromeda(json);
		}

		// this is bullshit but i'm gonna jump the gun and assume that anything with a version tag is v-slice char data
		// if you have a format with a version tag data you are probably as dumb as eric
		if (Reflect.field(json, "version") != null) {
			return fileFromVSlice(json);
		}

		var json:CharacterFile = json;
		
		try{
			for (anim in json.animations){
				try{
					if (anim.indices != null)
						anim.indices = parseIndices(anim.indices);
				}catch(e){
					trace('$characterName: Error parsing anim indices for ${anim.name}');
				}
			}

			if (json.healthbar_colors == null)
				json.healthbar_colors = [192, 192, 192];
			else if (json.healthbar_colors is String){
				var color:Null<FlxColor> = FlxColor.fromString(cast json.healthbar_colors);
				json.healthbar_colors = (color==null) ? null : [color.red, color.green, color.blue];
			}

			return json;
		}catch(e){
			trace('$characterName: Error loading character JSON file');
		}

		return null;
	}

	public static function parseIndices(indices:Array<Any>):Array<Int>
	{
		var parsed:Array<Int> = [];

		for (expr in indices)
		{
			if (expr is Int)
				parsed.push(expr);
			else if (expr is String)
			{
				var expr:String = Std.string(expr);
				var isRange:Bool = expr.contains("...");
				var exprArgs:Array<String> = expr.split(isRange ? "..." : "*");

				switch (exprArgs.length){
					case 0: 
						// Can't do anything lol
					case 1:
						parsed.push(Std.parseInt(exprArgs[0]));
					default:
						var exprA = Std.parseInt(exprArgs[0]);
						var exprB = Std.parseInt(exprArgs[1]);
						
						if (isRange){
							// starting from 'a' and ending on 'b'
							for (frameN in exprA...(exprB + 1))
								parsed.push(frameN);
						}else{
							// 'a' repeated 'b' times
							for (_ in 0...(exprB + 1))
								parsed.push(exprA);
						}
				}		
			}
		}

		return parsed;
	}

	/**	
		Returns "texture", "packer" or "sparrow"
	**/
	public static function getImageFileType(file:CharacterFile):String
	{
		if (file.renderType != null) {
			var type:String = file.renderType;
			if (type == 'animateatlas') type = 'texture';
			return type;
		}
		var path = file.image;
		if (Paths.fileExists('images/$path/Animation.json', TEXT))
			return "texture";
		else if (Paths.fileExists('images/$path.txt', TEXT))
			return "packer";
		else
			return "sparrow";
	}

	public static function returnCharacterPreload(characterName:String):Array<funkin.data.Cache.AssetPreload>{
		var char = getCharacterFile(characterName);

		if (char == null)
			return [];

		return [
			{path: char.image}, // spritesheet
			{path: 'icons/${char.healthicon}'} // icon
		];
	}

	public static function getDefaultAnimCamOffset(name:String) return {
		if (!name.startsWith('sing'))
			[0.0, 0.0];
		else if (name.startsWith('singLEFT'))
			[-30.0, 0.0];
		else if (name.startsWith('singDOWN'))
			[0.0, 30.0];
		else if (name.startsWith('singUP'))
			[0.0, -30.0];
		else if (name.startsWith('singRIGHT'))
			[30.0, 0.0];
		else
			[0.0, 0.0];
	}
	
	private static function fileFromAndromeda(data:Dynamic):CharacterFile {
		var data:AndromedaCharJson = data;
		var conv:CharacterFile = {
			animations: [for (anim in data.anims) andromedaToPsychAnim(anim)],
			image: 'characters/'+data.spritesheet,
			scale: data.scale,
			sing_duration: data.singDur,
			
			position: data.charOffset,
			camera_position: data.camOffset,
	
			flip_x: data.flipX,
			no_antialiasing: data.antialiasing==false,
	
			healthicon: data.iconName,
			healthbar_colors: funkin.scripts.Wrappers.SowyColor.toRGBArray(CoolUtil.colorFromString(data.healthColor))
		};
	
		return conv;
	}

	private static function fileFromVSlice(data:Dynamic):CharacterFile {
		var data:VSliceCharacterData = data;
		var conv:CharacterFile = {
			animations: [for (anim in data.animations) VSliceToPsychAnim(anim)],
			image: data.assetPath,
			scale: data.scale ?? 1,
			sing_duration: data.singTime ?? 8.0,
			
			position: data.offsets ?? [0,0],
			camera_position: data.cameraOffsets ?? [0,0],
	
			renderType: data.renderType ?? null,
			flip_x: data.flipX ?? true,
			no_antialiasing: data.isPixel ?? false,
			healthicon: data?.healthIcon?.id ?? 'face',
			//
			healthbar_colors: [255,255,255]
		};
	
		return conv;
	}
	private static function VSliceToPsychAnim(anim:AnimationData):AnimArray {
		return {
			anim: anim.name,
			name: anim.prefix,
			fps: anim.frameRate ?? 24,
			indices: anim.frameIndices ?? null,
			loop: anim.looped ?? false,
			offsets: [Std.int(anim.offsets[0] ?? 0), Std.int(anim.offsets[1] ?? 0)],
			assetPath: anim.assetPath ?? null
		}
	}

	private static function andromedaToPsychAnim(anim:AndromedaAnimShit):AnimArray {
		return {
			anim: anim.name,
			name: anim.prefix,
			fps: anim.fps,
			indices: anim.indices,
			loop: anim.looped,
			offsets: [Std.int(anim.offsets[0]), Std.int(anim.offsets[1])]
		}
	}

	public static function charToPsychData(char:Character){
		return {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.baseScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,
			"renderType": getImageFileType(char.characterFile),

			"position": char.positionArray,
			"camera_position": char.cameraPosition,

			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray
		};
	}
	
	public static function psychToFunkinAnim(anim:AnimArray) return {
		"name": anim.anim,
		"prefix": anim.name,
		"offsets": anim.offsets,
		"looped": anim.loop,
		"frameRate": 24,
		"flipX": false,
		"flipY": false
	}

	public static function charToFunkinData(char:Character){
		return {
			"generatedBy": "TROLL ENGINE",
			"version": "1.0.0",

			"name": char.curCharacter,
			"assetPath": char.imageFile,
			"renderType": CharacterData.getImageFileType(char.characterFile),
			"flipX": char.originalFlipX,
			"scale": char.baseScale,
			"isPixel": char.noAntialiasing == true, // i think // isPixel also assumes its scaled up by 6 so

			"offsets": char.positionArray,
			"cameraOffsets": char.cameraPosition,

			"singTime": char.singDuration, 
			"danceEvery": char.danceEveryNumBeats,
			"startingAnimation": char.danceIdle ? "danceLeft" : "idle",

			"healthIcon": {
				"id": char.healthIcon,
				"offsets": [0, 0],
				"isPixel": StringTools.endsWith(char.healthIcon, "-pixel"),
				"flipX": false,
				"scale": 1
			},

			"animations": [for (anim in char.animationsArray) psychToFunkinAnim(anim)],
		};
	}

	/**
		Returns an array with every character file in the characters folder(s).
	**/
	#if !sys
	@:noCompletion private static var _listCache:Null<Array<String>> = null;
	#end
	public static function getAllCharacters(modsOnly = false):Array<String>
	{
		#if !sys
		if (_listCache != null)
			return _listCache;

		var characters:Array<String> = _listCache = [];
		#else
		var characters:Array<String> = [];
		#end

		var _characters = new Map<String, Bool>();

		function readFileNameAndPush(fileName:String){
			if (fileName==null || !fileName.endsWith(".json"))
				return;

			var name = fileName.substr(0, fileName.length - 5);
			_characters.set(name, true);
		}
		
		for (folderPath in Paths.getFolders("characters", true)){
			Paths.iterateDirectory(folderPath, readFileNameAndPush);
		}

		if (!modsOnly){
			Paths.iterateDirectory(Paths.getPreloadPath('characters/'), readFileNameAndPush);
		}

		for (name in _characters.keys())
			characters.push(name);

		return characters;
	}
}

////
typedef AndromedaAnimShit = {
	var prefix:String;
	var name:String;
	var fps:Int;
	var looped:Bool;
	var offsets:Array<Float>;
	@:optional var indices:Array<Int>;
}

typedef AndromedaCharJson = {
	var anims:Array<AndromedaAnimShit>;
	var spritesheet:String;
	var singDur:Float; // dadVar
	var iconName:String;
	var healthColor:String;
	var charOffset:Array<Float>;
	var beatDancer:Bool; // dances every beat like gf and spooky kids
	var flipX:Bool;

	@:optional var format:String;
	@:optional var camMovement:Float;
	@:optional var camOffset:Array<Float>;
	@:optional var scale:Float;
	@:optional var antialiasing:Bool;
}

enum abstract CharacterRenderType(String) from String to String
{
	/**
	 * Renders the character using a single spritesheet and XML data.
	 */
	public var Sparrow = 'sparrow';

	/**
	 * Renders the character using a single spritesheet and TXT data.
	 */
	public var Packer = 'packer';

	/**
	 * Renders the character using multiple spritesheets and XML data.
	 */
	public var MultiSparrow = 'multisparrow';

	/**
	 * Renders the character using a spritesheet of symbols and JSON data.
	 */
	public var AnimateAtlas = 'animateatlas';
}

typedef VSliceCharacterData =
{
	var version:String;
	var name:String;
	var renderType:CharacterRenderType;
	var assetPath:String;
	var scale:Null<Float>;
	var healthIcon:Null<HealthIconData>;
	var offsets:Null<Array<Float>>;
	var cameraOffsets:Array<Float>;
	var isPixel:Null<Bool>;
	@:optional
	@:default(1.0)
	var danceEvery:Null<Float>;
	var singTime:Null<Float>;
	var animations:Array<AnimationData>;
	var startingAnimation:Null<String>;
	var flipX:Null<Bool>;
};
typedef AnimationData =
{
	> UnnamedAnimationData,
	var name:String;
}

/**
 * A data structure representing an animation in a spritesheet.
 * This animation doesn't specify a name, that's presumably specified by the parent data structure.
 */
typedef UnnamedAnimationData =
{
	@:optional
	var prefix:String;
	@:optional
	var assetPath:Null<String>;
	@:default([0, 0])
	@:optional
	var offsets:Null<Array<Float>>;
	@:default(false)
	@:optional
	var looped:Bool;
	@:default(false)
	@:optional
	var flipX:Null<Bool>;
	@:default(false)
	@:optional
	var flipY:Null<Bool>;
	@:default(24)
	@:optional
	var frameRate:Null<Int>;
	@:default([])
	@:optional
	var frameIndices:Null<Array<Int>>;
}

/**
 * The JSON data schema used to define the health icon for a character.
 */
typedef HealthIconData =
{
	@:optional
	@:default([200,200,200])
	var colorRGB:Array<Int>;
	/**
	 * The ID to use for the health icon.
	 * @default The character's ID
	 */
	var id:Null<String>;
}