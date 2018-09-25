package;

import haxe.Template;
import hxp.*;
import lime.tools.*;
import lime.project.*;
import sys.io.File;
import sys.FileSystem;

class CppiaPlatform extends PlatformTarget {
	
	
	private var applicationDirectory:String;
	private var executablePath:String;
	private var targetType:String = "cppia";
	
	public static var hostExecutablePath = "";
	public static var projectPath = "";
	
	public function new (command:String, _project:HXProject, targetFlags:Map <String, String> ) {
		
		super (command, _project, targetFlags);
		
		targetDirectory = project.app.path + "/cppia";
		applicationDirectory = targetDirectory;
		executablePath = applicationDirectory + "/" + project.app.file + ".cppia";
	}
	
	
	public override function build ():Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}

		//XXX: Needs to be debug right now so the output is cppia, and cpp.Object info can be stripped out of it.
		//type = "debug";
		
		var hxml = targetDirectory + "/haxe/" + type + ".hxml";
		
		System.mkdir (targetDirectory);
		
		for (dependency in project.dependencies) {
			
			if (StringTools.endsWith (dependency.path, ".dll")) {
				
				var fileName = Path.withoutDirectory (dependency.path);
				System.copyIfNewer (dependency.path, applicationDirectory + "/" + fileName);
				
			}
			
		}
		
		if (!project.targetFlags.exists ("static"))
		{
			var platform = System.hostPlatform;
			var is64 = System.hostArchitecture == HostArchitecture.X64;
			
			if(platform == HostPlatform.WINDOWS)
				is64 = false;
			
			var platformID = platform + (is64  ? "64" : "");
			platformID = platformID.substr(0, 1).toUpperCase() + platformID.substr(1);
			
			var libExtension = switch(platform) {
				case WINDOWS:
					".dll";
				case MAC:
					".dylib";
				case LINUX:
					".dso";
				case _:
					"";
			}
			
			for (ndll in project.ndlls)
			{
				ProjectHelper.copyLibrary (project, ndll, platformID, "", (ndll.haxelib != null && (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? libExtension : ".ndll", applicationDirectory, project.debug);
			}
		}
		
		var icons = project.icons;
		
		if (icons.length == 0) {
			
			icons = [ new Icon (System.findTemplate (project.templatePaths, "default/icon.svg")) ];
			
		}
		
		//IconHelper.createIcon (project.icons, 32, 32, Path.combine (applicationDirectory, "icon.png"));
		
		var haxeArgs = [ hxml ];
		var flags = [];
		
		if (!project.environment.exists ("SHOW_CONSOLE")) {
			
			haxeArgs.push ("-D");
			haxeArgs.push ("no_console");
			flags.push ("-Dno_console");
			
		}
		
		if (!project.targetFlags.exists ("static")) {
			
			System.runCommand("", "haxe", haxeArgs);

			//CppiaScriptUtils.removeClass(executablePath, "cpp.Object");

			//Right now we take care of the bad link on the hxcpp side
			
			/*
			linkingClass = classes[i];
			if(strcmp(linkingClass->name.c_str(),"cpp._Object.Object_Impl_") != 0)
			  classes[i]->link();
			*/
			
		} else {
			
			System.runCommand ("", "haxe", haxeArgs.concat ([ "-D", "static_link" ]));

		}
	}
	
	
	public override function clean ():Void {
		
		if (FileSystem.exists (targetDirectory)) {
			
			System.removeDirectory (targetDirectory);
			
		}
		
	}
	
	
	public override function deploy ():Void {

	}
	
	
	public override function display ():Void {
		
		var type = "release";
		
		if (project.debug) {
			
			type = "debug";
			
		} else if (project.targetFlags.exists ("final")) {
			
			type = "final";
			
		}
		
		var hxml = System.findTemplate (project.templatePaths, targetType + "/hxml/" + type + ".hxml");
		var template = new Template (File.getContent (hxml));
		Sys.println (template.execute (generateContext ()));
		
	}
	
	
	private function generateContext ():Dynamic {
		
		var context = project.templateContext;
		
		context.CPP_DIR = targetDirectory + "/" + project.app.file + ".cppia";
		context.BUILD_DIR = project.app.path + "/cppia";

		var prefix = null;

		context.HAXE_FLAGS =
			context.HAXE_FLAGS + "\n" +
			[
				for(arg in additionalArguments)
					if(arg == "-D") arg + " "
					else            arg + "\n"
			].join("");

		return context;
		
	}
	
	
	public override function rebuild ():Void {
		
	}
	
	
	public override function run ():Void {
		
		/*var arguments = additionalArguments.copy ();
		
		if (LogHelper.verbose) {
			
			arguments.push ("-verbose");
			
		}
		
		arguments = arguments.concat ([ "-livereload" ]);*/
		
		var scriptFolder = Path.combine(projectPath, targetDirectory);
		var fullScriptPath = Path.combine(projectPath, executablePath);

		System.runCommand(scriptFolder, hostExecutablePath, [fullScriptPath]);
		
	}
	
	
	public override function update ():Void {
		
		project = project.clone ();
		
		if (project.targetFlags.exists ("xml")) {
			
			project.haxeflags.push ("-xml " + targetDirectory + "/types.xml");
			
		}
		
		var context = generateContext ();
		
		if (project.targetFlags.exists ("static")) {
			
			for (i in 0...project.ndlls.length) {
				
				var ndll = project.ndlls[i];
				
				if (ndll.path == null || ndll.path == "") {
					
					context.ndlls[i].path = NDLL.getLibraryPath (ndll, "Windows", "lib", ".lib", project.debug);
					
				}
				
			}
			
		}
		
		System.mkdir (targetDirectory);
		System.mkdir (targetDirectory + "/haxe");
		
		//SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");
		
		System.recursiveCopyTemplate (project.templatePaths, "haxe", targetDirectory + "/haxe", context);
		System.recursiveCopyTemplate (project.templatePaths, targetType + "/hxml", targetDirectory + "/haxe", context);
		
		if (project.targetFlags.exists ("static")) {
			
			System.recursiveCopyTemplate (project.templatePaths, "cpp/static", targetDirectory + "/obj", context);
			
		}
		
		/*if (IconHelper.createIcon (project.icons, 32, 32, Path.combine (applicationDirectory, "icon.png"))) {
			
			context.HAS_ICON = true;
			context.WIN_ICON = "icon.png";
			
		}*/
		
		for (asset in project.assets) {
			
			if (asset.embed != true) {
				
				var path = Path.combine (applicationDirectory, asset.targetPath);
				
				if (asset.type != AssetType.TEMPLATE) {
					
					System.mkdir (Path.directory (path));
					AssetHelper.copyAssetIfNewer (asset, path);
					
				} else {
					
					System.mkdir (Path.directory (path));
					AssetHelper.copyAsset (asset, path, context);
					
				}
				
			}
			
		}
		
		AssetHelper.createManifest (project, Path.combine (applicationDirectory, "manifest"));
		
	}
	
	
	@ignore public override function install ():Void {}
	@ignore public override function trace ():Void {}
	@ignore public override function uninstall ():Void {}
	
	
}