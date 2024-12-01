package funkin.modchart.modifiers;

import flixel.math.FlxAngle;
import flixel.FlxSprite;
import funkin.ui.*;
import funkin.modchart.*;
import flixel.math.FlxPoint;
import math.Vector3;
import flixel.math.FlxMath;
import flixel.FlxG;
using StringTools;
import math.*;
import funkin.objects.playfields.NoteField;

// NOTE: THIS SHOULDNT HAVE ITS PERCENTAGE MODIFIED
// THIS IS JUST HERE TO ALLOW OTHER MODIFIERS TO HAVE PERSPECTIVE

// did my research
// i now know what a frustrum is lmao
// stuff ill forget after tonight

// its the next day and yea i forgot already LOL
// something somethng clipping idk

// either way
// perspective projection woo

class PerspectiveModifier extends NoteModifier 
{
	override function getName() return '__perspective';
	override function getOrder() return Modifier.ModifierOrder.LAST + 1000; // should ALWAYS go last
	override function shouldExecute(player:Int, val:Float) return true;
	override function isRenderMod() return true;

	override function getSubmods()
	{
		var subMods:Array<String> = ["fieldRoll", "fieldYaw", "fieldPitch", "fieldX", "fieldY", "fieldZ"];

        for(col in 0...PlayState.keyCount){
            subMods.push('${col}Roll');
			subMods.push('${col}Yaw');
			subMods.push('${col}Pitch');
            // I dont see any real practical use for [col]X, Y, Z esp since transform[col]X/Y/Z exists
            // however theres no good way to rotate the columns seperately atm
        }

		return subMods;
	}

	var origin = new Vector3(FlxG.width * 0.5, FlxG.height * 0.5); // vertex origin
	var fieldPos = new Vector3();
	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField):Vector3
	{
		fieldPos.setTo( // playfield pos
			-getSubmodValue("fieldX", player),
			-getSubmodValue("fieldY", player),
			1280 + getSubmodValue("fieldZ", player)
		); 
		
		// moves the vertex to the appropriate position on screen based on origin
		pos.decrementBy(origin); 
		
		// rotate the vertex properly
		VectorHelpers.rotateV3(pos, 
			getSubmodValue("fieldPitch", player) * FlxAngle.TO_RAD, 
			getSubmodValue("fieldYaw", player) * FlxAngle.TO_RAD, 
			getSubmodValue("fieldRoll", player) * FlxAngle.TO_RAD,
			pos
		); 
		
		// perpsective projection
		pos.decrementBy(fieldPos);
		VectorHelpers.project(pos, pos); 

		// TODO: move alot of this into a ColumnRenderer class and do some rewriting to fields etc YET AGAIN
        // mainly for like.. column-based rotation etc etc lole

		// puts the vertex back to default pos 
		pos.incrementBy(origin);

		return pos;
	}

	override function modifyVert(beat:Float, vert:Vector3, idx:Int, sprite:FlxSprite, pos:Vector3, player:Int, data:Int, field:NoteField):Vector3
	{
		if (sprite is Note) {
			var shit:Note = cast sprite;
			if (shit.isSustainNote) return vert;
		}

		fieldPos.setTo( // playfield pos
			-getSubmodValue("fieldX", player), 
			-getSubmodValue("fieldY", player), 
			1280 + getSubmodValue("fieldZ", player)
		); 

		// moves the vertex to the appropriate position on screen based on origin
		vert.incrementBy(pos);
		vert.decrementBy(origin);

		// rotate the vertex properly
		VectorHelpers.rotateV3(vert, 
			getSubmodValue("fieldPitch", player) * FlxAngle.TO_RAD, 
			getSubmodValue("fieldYaw", player) * FlxAngle.TO_RAD, 
			getSubmodValue("fieldRoll", player) * FlxAngle.TO_RAD,
			vert
		);

		// perpsective projection
		vert.decrementBy(fieldPos);
		VectorHelpers.project(vert, vert);

		// puts the vertex back to default pos
		vert.decrementBy(pos);
		vert.incrementBy(origin); 

		return vert;
	}
}
