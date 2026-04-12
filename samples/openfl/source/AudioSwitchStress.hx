package;

import haxe.Timer;
import hxvlc.openfl.AudioGroup;
import openfl.display.Sprite;
import openfl.events.Event;

class AudioSwitchStress extends Sprite
{
	private var group:AudioGroup;
	private var urls:Array<String>;
	private var index:Int = 0;

	public static function main():Void
	{
		#if android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.os.Build.VERSION.SDK_INT > 30 ? extension.androidtools.content.Context.getObbDir() : extension.androidtools.content.Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.documentsDirectory);
		#end

		openfl.Lib.current.addChild(new AudioSwitchStress());
	}

	public function new():Void
	{
		super();

		if (stage != null)
			onAddedToStage();
		else
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	private function onAddedToStage(?event:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		group = new AudioGroup();
		urls = [
			'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
			'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'
		];

		group.addTrack(urls[0], null, 1);
		group.play();

		final timer:Timer = new Timer(50);
		timer.run = function():Void
		{
			index = (index + 1) % urls.length;
			group.addTrack(urls[index], null, 1);
			group.play();
		};
	}
}

