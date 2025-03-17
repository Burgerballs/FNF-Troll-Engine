package funkin.data;

typedef SrtData = {
    timeStart:Float,
    timeEnd:Float,
    text:String
};

class Srt {
    public var subtitleData:Array<SrtData> = [];

    public function new(path:String, filterMarkdown:String) {
        
    }
}