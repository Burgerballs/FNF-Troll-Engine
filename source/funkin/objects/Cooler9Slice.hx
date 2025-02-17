package funkin.objects;

import flixel.addons.ui.FlxUI9SliceSprite;

class Cooler9Slice extends FlxUI9SliceSprite {
    override function set_width(value:Float):Float {
        var oldWidth = width;
        return super.set_width(value);
    }

    override function set_height(value:Float):Float {
        var oldHeight = height;
        return super.set_height(value);
    }
}