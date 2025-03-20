package funkin.data;

typedef SrtData = {
    timeStart:Float,
    timeEnd:Float,
    text:String
};

/*
    These will be used for both cutscenes and songs.
    EXAMPLE: songs/milf/subtitles.srt
    EXAMPLE: videos/mp4name.srt
    
    If you have a difficulty with differing audio, you name the subtitles with the differing prefix.
    EXAMPLE: songs/milf/subtitles-hard.srt

    If you want to intitialize the subtitles yourself, you can using hscript.
    example unavailable cuz i am in the middle of making this you dunce
*/

class Srt {
    public var subtitleData:Array<SrtData> = [];

    public function new(path:String, filterMarkdown:String) {
        
    }
}