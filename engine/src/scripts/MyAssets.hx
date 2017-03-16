package scripts;

import com.stencyl.AssetLoader;

class MyAssets implements AssetLoader
{
	//Game
	public static var landscape:Bool;
	public static var autorotate:Bool;
	public static var scaleMode:Int;
	public static var stageWidth:Int;
	public static var stageHeight:Int;
	public static var initSceneID:Int;
	public static var physicsMode:Int;
	public static var gameScale:Float;
	public static var gameImageBase:String;
	public static var antialias:Bool;
	public static var pixelsnap:Bool;
	public static var startInFullScreen:Bool;

	//APIs
	public static var adPositionBottom:Bool;
	public static var testAds:Bool;
	public static var whirlID:String;
	public static var whirlID1:String;
	public static var ioswhirlID:String;
	public static var ioswhirlID1:String;
	public static var cpmstarID:String;
	public static var newgroundsID:String;
	public static var newgroundsKey:String;
	
	//Other
	public static var releaseMode:Bool;
	public static var showConsole:Bool;
	public static var debugDraw:Bool;
	public static var always1x:Bool;
	public static var maxScale:Float;
	public static var disableBackButton:Bool;
	
	//Keys
	public static var androidPublicKey:String;

	public function new()
	{
		
	}
	
	public function loadResources(resourceMap:Map<String,Dynamic>):Void
	{
		
	}
	
	public function loadScenes(scenesXML:Map<Int,String>):Void
	{
		
	}
}