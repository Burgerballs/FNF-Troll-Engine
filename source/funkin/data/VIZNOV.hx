package funkin.data;

typedef VIZNOVDialogue = {

    @:optional
    var startEvent:String;

    var dialogueContent:String;

    @:optional
    var endEvent:String;
}

typedef VIZNOV = {

    @:optional
    var initEvent:String;

    var dialogue:Array<VIZNOVDialogue>;

    @:optional
    var endEvent:String;
}