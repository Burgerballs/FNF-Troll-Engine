package funkin.states.scripting;

import funkin.scripts.FunkinHScript;

#if SCRIPTABLE_STATES

@:autoBuild(funkin.macros.ScriptingMacro.addScriptingCallbacks([
	"create",
	"update",
	"destroy",
	"openSubState",
	"closeSubState",
	"stepHit",
	"beatHit",
	"sectionHit"
]))
#end
class HScriptedSubstate extends MusicBeatSubstate
{
	public var scriptPath:String;

	public function new(scriptFullPath:String, ?scriptVars:Map<String, Dynamic>)
	{
		super();

		scriptPath = scriptFullPath;

		var vars = _getScriptDefaultVars();

		if (scriptVars != null) {
			for (k => v in scriptVars)
				vars[k] = v;
		}

		_extensionScript = FunkinHScript.fromFile(scriptPath, scriptPath, vars, false);
		_extensionScript.call("new", []);
		_extensionScript.set("add", this.add);
		_extensionScript.set("remove", this.remove);
		_extensionScript.set("this", this);
		_extensionScript.set("insert", this.insert);
		_extensionScript.set("members", this.members);
	}
	
	static public function fromFile(name:String, ?scriptVars:Map<String, Dynamic>)
	{
		for (filePath in Paths.getFolders("substates"))
		{
			for(ext in Paths.HSCRIPT_EXTENSIONS){
				var fullPath = filePath + '$name.$ext';
				if (Paths.exists(fullPath))
					return new HScriptedSubstate(fullPath, scriptVars);
			}
		}

		return null;
	}
}