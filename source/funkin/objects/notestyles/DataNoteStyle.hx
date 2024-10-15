package funkin.objects.notestyles;

import funkin.objects.NoteObject.IColorable;
import haxe.io.Path;
import sys.io.File;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.scripts.FunkinHScript;
import funkin.objects.shaders.ColorSwap;
import funkin.data.NoteStyles;
import funkin.CoolUtil.structureToMap;

class DataNoteStyle extends BaseNoteStyle
{
	private static function getData(name:String):NoteStyleData {
		var path = Paths.getPath('notestyles/$name.json');
		var json = Paths.getJson(path);
		if (json == null) return null;

		var assetsMap = structureToMap(json.assets);
		json.assets = assetsMap;
		if (json.scale == null) json.scale = 1.0;

		for (name => asset in assetsMap) {
			asset.canBeColored = asset.canBeColored != false;
			//if (asset.scale == null) asset.scale = 1.0;
			if (asset.alpha == null) asset.alpha = 1.0;

/* 			if (asset.animations != null)
				asset.animations = structureToMap(asset.animations); */
		}

		return cast json;
	}

	public static function getDefault():DataNoteStyle {
		return new DataNoteStyle('default', getData('default'));
	}

	public static function fromName(name:String):Null<DataNoteStyle> {
		var data = getData(name);
		return data == null ? null : new DataNoteStyle(name, data);
	}

	////

	final loadedNotes:Array<Note> = []; 
	final data:NoteStyleData;

	var script:FunkinHScript;

	private function new(id:String, data:NoteStyleData) {
		this.data = data;
		this.scale = data.scale;

		// maybe this can be moved to fromName? idk lol
		var scriptPath:String = Paths.getHScriptPath('notestyles/$id');

		if (scriptPath != null) {
			script = FunkinHScript.fromFile(scriptPath, scriptPath, [
				"this" => this,
				"getStyleData" => (() -> return this.data)
			], false);
		}

		super(id);
	}

	function updateNoteColours(note:Note):Void {
		var hsb:Array<Int> = note.isQuant ? ClientPrefs.quantHSV[Note.quants.indexOf(note.quant)] : ClientPrefs.arrowHSV[note.column];
		var colorSwap:ColorSwap = note.colorSwap;

		if (colorSwap != null) {
			colorSwap.setHSBIntArray(hsb);
		}
	}
	
	inline function updateColours(obj:NoteObject){
		if (!(obj is IColorable))return;
		var colorableObj:IColorable = cast obj;

		colorableObj.colorSwap.setHSBIntArray(ClientPrefs.arrowHSV[obj.column]);
	}
	

	function getAsset(name:String):Null<NoteStyleAsset> {
		var usingQuants = ClientPrefs.noteSkin == "Quants";
		if (usingQuants) {
			trace("QUANT" + name, data.assets.exists("QUANT" + name));
			if (data.assets.exists("QUANT" + name)) {
				var asset:NoteStyleAsset = data.assets.get("QUANT" + name);
				asset.quant = true;
				return asset;
			}
		}
		return data.assets.get(name);
	}

	function getNoteObjectAsset(obj:NoteObject):Null<NoteStyleAsset> {
		var name:String = switch(obj.objType){
			case STRUM: 'receptor';
			case SPLASH: 'noteSplash';
			case NOTE: 'tap'; // shouldnt happen tho!!
			default: obj.assetKey;
		}
		if(name == '')
			return null;
		if(name == 'tap')
			return getNoteAsset(cast(obj, Note));

		return getAsset(name);
	}

	function getNoteAsset(note:Note):Null<NoteStyleAsset> {
		var name:String = switch(note.holdType) {
			default: "tap";
			case PART: "hold";
			case END: "holdEnd";
			// what abt rolls
			// maybe note.holdSubtype??
			// NORMAL and ROLL
			// then we can just .replace("hold", "roll") if subType == ROLL
			// then everything the roll script does we can just hardcode because honestly dont think it needs to be soft-coded
		}

		return getAsset(name);
	}

	inline function getNoteAnim(note:Note, asset:NoteStyleAnimatedAsset<Any>):Null<Any> {
		if (asset.animation != null) 
			return asset.animation 
		else if (asset.data != null)
			return asset.data[note.column % asset.data.length];
		else
			return null;
	}

	inline function loadAnimations(obj:NoteObject, asset:NoteStyleAsset)
	{
		inline function getAnimData(a:Dynamic){
			// HACK: Check if array[0] is Int. If it's Int, then it's indices and we shouldn't be randomizing as we should only randomize if its ["a", "b"] / [[0], [1]] etc
			if (a is Array && a.length > 0 && !(a[0] is Int)) {
				var data:Array<Any> = cast a;
				return data[Std.random(data.length)];
			} else
				return a;
		}

		inline function getAnimation(animation:NoteStyleAnimationData<Any>):Null<Any>
		{
			return switch(animation.type){
				case COLUMN:
					(animation.data == null) ? null : getAnimData(animation.data[obj.column]);

				case STATIC: 
					getAnimData(animation.animation);
					
				default: 
					null;
			}
		}


		var imageKey:String = asset.imageKey;
		if (ClientPrefs.noteSkin == 'Quants' && !obj.isQuant) {
			var quantKey = Note.getQuantTexture(Path.directory(imageKey) + "/", Path.withoutDirectory(imageKey), imageKey);
			if (quantKey != null) {
				obj.isQuant = true;
				imageKey = quantKey;
			}
		}
		

		// TODO: add stuff for other animation things (data, animation)
		switch(asset.type){
			case INDICES:var asset:NoteStyleIndicesAsset = cast asset;
				
				var graphic = Paths.image(imageKey);
				var hInd = asset.columns != null ? Math.floor(graphic.width / asset.columns) : asset.hInd;
				var vInd = asset.rows != null ? Math.floor(graphic.height / asset.rows) : asset.vInd;
				obj.loadGraphic(graphic, true, hInd, vInd);

				if (asset.animations != null){
					for(animation in asset.animations){
						var animData:Array<Int> = getAnimation(animation);
						obj.animation.add(animation.name, animData, 
							animation.framerate == null ? (asset.framerate ?? 24) : animation.framerate, animation.looped ?? false);
					}
					obj.animation.play(asset.animations[0].name);
				}

			case MULTISPARROW:
				var asset:NoteStyleMultiSparrowAsset = cast asset;
				var baseAsset:FlxAtlasFrames = Paths.getSparrowAtlas(imageKey);
				var atlases:Array<String> = [];
				if (asset.animations != null) {
					for (anim in asset.animations) {
						if (anim.imageKey != null)
							atlases.push(anim.imageKey); // TODO: check for quants
					}
				}

				for (atlas in asset.additionalAtlases)
					atlases.push(atlas);

				for (atlas in atlases) {
					var subAtlas:FlxAtlasFrames = Paths.getSparrowAtlas(atlas);
					if (subAtlas == null)
						continue;

					baseAsset.addAtlas(subAtlas);
				}

				obj.frames = baseAsset;
				if (asset.animations != null) {
					for (animation in asset.animations) {
						var animData:String = getAnimation(animation);
						obj.animation.addByPrefix(animation.name, animData,
							animation.framerate == null ? (asset.framerate ?? 24) : animation.framerate, animation.looped == null ? (asset.looped ?? false) : animation.looped);
					}
					obj.animation.play(asset.animations[0].name);
				}

			case SPARROW:var asset:NoteStyleIndicesAsset = cast asset;
				obj.frames = Paths.getSparrowAtlas(imageKey);
				if (asset.animations != null) {
					for (animation in asset.animations) {
						var animData:String = getAnimation(animation);
						obj.animation.addByPrefix(animation.name, animData,
							animation.framerate == null ? (asset.framerate ?? 24) : animation.framerate, animation.looped == null ? (asset.looped ?? false) : animation.looped);
					}
					obj.animation.play(asset.animations[0].name);
				}

			case SINGLE:
				obj.loadGraphic(Paths.image(imageKey));

			case SOLID:
				obj.makeGraphic(1, 1, CoolUtil.colorFromString(imageKey), false, imageKey);
			
			default:
		}	
	}

	override function optionsChanged(changed) { // Maybe we should add an event to PlayState for this
		// Or maybe a global OptionsState.updated event
		// then we dont need to call this manually everywhere lol

		if (changed.contains("customizeColours")) {
			for (note in loadedNotes)
				updateNoteColours(note);
		}

		if(script != null)
			script.executeFunc("optionsChanged", [changed]);
	}

	override function noteUpdate(note:Note, dt:Float){
		if (script != null)
			script.executeFunc("noteUpdate", [note, dt]);
	}

	override function destroy() {
		if (script != null) {
			script.executeFunc("destroy");
			script.stop();
			script=null;
		}

		super.destroy();
		// JUST to make sure shit is cleared properly lol
		loadedNotes.resize(0); 
	}

	override function unloadNote(note:Note){
		loadedNotes.remove(note);
		if (script != null)
			script.executeFunc("unloadNote", [note]);
	}
	
	override public function loadReceptor(strum:StrumNote){
		if (script != null) {
			var rVal:Dynamic = script.executeFunc("loadReceptor", [strum]);
			if (rVal is Bool)
				return rVal;
		}
		var asset:NoteStyleAsset = getNoteObjectAsset(strum);
		
		strum.isQuant = asset.quant ?? false;

		strum.antialiasing = (data.antialiasing ?? asset.antialiasing) ?? true;
		strum.useDefaultAntialiasing = strum.antialiasing;

		loadAnimations(strum, asset);
		strum.animation.play("static", true);
		// this is dealt with in strum.playanim
		
/* 		if (asset.canBeColored == false) {
			strum.colorSwap.setHSB();
		} else
			updateColours(strum);
 */
		strum.scale.x = strum.scale.y = (asset.scale ?? data.scale);
		strum.defScale.copyFrom(strum.scale);
		strum.updateHitbox();

		if (script != null)
			script.executeFunc("loadReceptorPost", [strum]);


		return true;
	}

	override function loadNote(note:Note) {
		if (script != null){
			var rVal:Dynamic = script.executeFunc("loadNote", [note]);
			if(rVal is Bool)
				return rVal;
		}

		var asset:NoteStyleAsset = getNoteAsset(note);
		if (asset == null)return false; // dont set the style!!!
		loadedNotes.push(note);

		note.isQuant = asset.quant ?? false;
		
		var imageKey:String = asset.imageKey;

		if (ClientPrefs.noteSkin == 'Quants' && !note.isQuant){
			var quantKey = Note.getQuantTexture(Path.directory(imageKey) + "/", Path.withoutDirectory(imageKey), imageKey);
			if (quantKey != null){
				note.isQuant = true;
				imageKey = quantKey;
			}	
		}

		switch (asset.type) {
			case MULTISPARROW: var asset:NoteStyleMultiSparrowAsset = cast asset;
				var baseAtlas:FlxAtlasFrames = Paths.getSparrowAtlas(imageKey);
				var frames:FlxAtlasFrames = new FlxAtlasFrames(baseAtlas.parent); 
				frames.parent.destroyOnNoUse = false;
				frames.addAtlas(baseAtlas, true);
				var atlases:Array<String> = [];
				if(asset.animations != null){
					for (anim in asset.animations) {
						if (anim.imageKey != null && !atlases.contains(anim.imageKey))
							atlases.push(anim.imageKey);
					}
				}

				for (atlas in asset.additionalAtlases)if(!atlases.contains(atlas))atlases.push(atlas);
				
				for(atlas in atlases){
					// TODO: check quant first lol

					var subAtlas:FlxAtlasFrames = Paths.getSparrowAtlas(atlas);
					if(subAtlas==null)continue;
					subAtlas.parent.destroyOnNoUse = false;
					frames.addAtlas(subAtlas, true);
				}
				
				note.frames = frames;

				var anim:String = getNoteAnim(note, asset);


				note.animation.addByPrefix('', anim, asset.framerate ?? 24, asset.looped ?? false); // might want to use the json anim name, whatever
				note.animation.play('', true);
			case SPARROW: var asset:NoteStyleSparrowAsset = cast asset;
				note.frames = Paths.getSparrowAtlas(imageKey);

				var anim:String = getNoteAnim(note, asset);
				note.animation.addByPrefix('', anim, asset.framerate ?? 24, asset.looped ?? false); // might want to use the json anim name, whatever
				note.animation.play('');


			case INDICES: var asset:NoteStyleIndicesAsset = cast asset;
				var graphic = Paths.image(imageKey);
				var hInd:Int = (asset.columns != null) ? Math.floor(graphic.width / asset.columns) : asset.hInd;
				var vInd:Int = (asset.rows != null) ? Math.floor(graphic.height / asset.rows) : asset.vInd;
				note.loadGraphic(graphic, true, hInd, vInd);
				
				var anim:Array<Int> = getNoteAnim(note, asset);
				note.animation.add('', anim, 24, false);
				note.animation.play('');

			case SINGLE:
				note.loadGraphic(Paths.image(imageKey));

			case SOLID: // lol
				note.makeGraphic(1, 1, CoolUtil.colorFromString(imageKey), false, imageKey);

			default: //case NONE: 
				note.makeGraphic(1,1,0,false,'invisible'); // idfk something might want to change .visible so
		}

		// note.alpha = asset.alpha;

		note.antialiasing = (data.antialiasing ?? asset.antialiasing) ?? true;
		note.useDefaultAntialiasing = note.antialiasing;
		
		if (asset.canBeColored == false) {
			note.colorSwap.setHSB();
		}else
			updateNoteColours(note);
		
		
		note.scale.x = note.scale.y = (asset.scale ?? data.scale);
		note.defScale.copyFrom(note.scale);
		note.updateHitbox();

		if (script != null)
			script.executeFunc("loadNotePost", [note]);

		return true; 
	}
}