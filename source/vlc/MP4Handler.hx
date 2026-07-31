package vlc;

import flixel.FlxG;
import flixel.util.FlxTimer;
import haxe.io.Bytes;
import haxe.io.Path;
import hxvlc.externs.Types;
import hxvlc.openfl.VideoFix as Video;
import hxvlc.util.Location;
import hxvlc.util.macros.DefineMacro;
import openfl.events.Event;
import openfl.utils.Assets;
import sys.FileSystem;

using StringTools;

//hxcodec 2.5.0-2.5.1

class MP4Handler extends Video
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	private var pauseMusic:Bool;
	private var shouldRepeat:Bool = false;
	private var resumeOnFocus:Bool = false;

	public function new(width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		super(true);

		// Align FlxInternalVideo behavior
		onOpening.add(function():Void
		{
			role = LibVLC_Role_Game;

			if (!FlxG.signals.focusGained.has(onFocusGained))
				FlxG.signals.focusGained.add(onFocusGained);

			if (!FlxG.signals.focusLost.has(onFocusLost))
				FlxG.signals.focusLost.add(onFocusLost);

			#if (FLX_SOUND_SYSTEM && flixel >= version("5.9.0"))
			if (!FlxG.sound.onVolumeChange.has(onVolumeChange))
				FlxG.sound.onVolumeChange.add(onVolumeChange);
			#elseif (FLX_SOUND_SYSTEM && flixel < version("5.9.0"))
			if (!FlxG.signals.postUpdate.has(onVolumeUpdate))
				FlxG.signals.postUpdate.add(onVolumeUpdate);
			#end

			// Keep original ready callback contract
			onVLCVideoReady();
		});

		// Finish on end reached when not repeating
		onEndReached.add(function():Void
		{
			if (shouldRepeat)
			{
				// Restart playback from beginning to mimic legacy repeat behavior
				position = 0;
				startPlay();
			}
			else
			{
				finishVideo();
			}
		});

		// Error mapping to original handler
		onEncounteredError.add(function(err:String):Void
		{
			onVLCError();
		});

		FlxG.addChildBelowMouse(this);

		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);
	}

	function update(e:Event)
	{
		if ((FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) && isPlaying)
			finishVideo();

		// Let FlxInternalVideo volume mapping drive actual volume; this keeps legacy behavior for non-FLX_SOUND_SYSTEM
		#if !(FLX_SOUND_SYSTEM)
		if (FlxG.sound.muted || FlxG.sound.volume <= 0)
			volume = 0;
		else
			volume = Math.floor((FlxG.sound.volume + 0.4) * 100);
		#end
	}

	// Path/asset resolution ported from FlxInternalVideo.load
	public function playVideo(path:String, ?repeat:Bool = false, pauseMusic:Bool = false)
	{
		this.pauseMusic = pauseMusic;
		this.shouldRepeat = repeat;

		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.pause();

		#if sys
		var loaded:Bool = load(path);
		if (!loaded)
		{
			// Try using FlxInternalVideo's robust path logic
			if (!Video.URL_VERIFICATION_REGEX.match(path))
			{
				final absolutePath:String = FileSystem.absolutePath(path);

				if (FileSystem.exists(absolutePath))
					loaded = super.load(absolutePath);
				else if (Assets.exists(path))
				{
					final assetPath:Null<String> = Assets.getPath(path);
					if (assetPath != null)
					{
						if (FileSystem.exists(assetPath) && Path.isAbsolute(assetPath))
							loaded = super.load(assetPath);
						else if (FileSystem.exists(assetPath) && !Path.isAbsolute(assetPath))
							loaded = super.load(FileSystem.absolutePath(assetPath));
						else if (!Path.isAbsolute(assetPath))
						{
							try
							{
								final assetBytes:Bytes = Assets.getBytes(path);
								if (assetBytes != null)
									loaded = super.load(assetBytes);
							}
							catch (e:Dynamic)
							{
								FlxG.log.error('Error loading asset bytes from location "$path": $e');
								loaded = false;
							}
						}
					}
				}
			}
		}

		if (!loaded)
			throw 'Unable to load video at "$path"';

		startPlay();
		#else
		throw "Doesn't support sys";
		#end
	}

	public function finishVideo()
	{
		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.resume();

		FlxG.stage.removeEventListener(Event.ENTER_FRAME, update);

		dispose();

		if (FlxG.game.contains(this))
		{
			FlxG.game.removeChild(this);

			if (finishCallback != null)
				finishCallback();
		}
	}

	// Legacy callbacks
	function onVLCVideoReady()
	{
		trace("Video loaded!");
		if (readyCallback != null)
			readyCallback();
	}

	function onVLCError()
	{
		throw "VLC caught an error!";
	}

	// Focus/volume hooks from FlxInternalVideo
	@:noCompletion
	private function onFocusGained():Void
	{
		#if !mobile
		if (!FlxG.autoPause)
			return;
		#end
		if (resumeOnFocus)
		{
			resumeOnFocus = false;
			resume();
		}
	}

	@:noCompletion
	private function onFocusLost():Void
	{
		#if !mobile
		if (!FlxG.autoPause)
			return;
		#end
		resumeOnFocus = isPlaying;
		pause();
	}

	#if (FLX_SOUND_SYSTEM && flixel < version("5.9.0"))
	@:noCompletion
	private function onVolumeUpdate():Void
	{
		onVolumeChange(#if FLX_SOUND_SYSTEM (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume #else 1 #end);
	}
	#end

	@:noCompletion
	private function onVolumeChange(vol:Float):Void
	{
		final currentVolume:Int = Math.floor((vol * DefineMacro.getFloat('HXVLC_FLIXEL_VOLUME_MULTIPLIER', 125)));
		if (volume != currentVolume)
			volume = currentVolume;
	}

	/** Frees the memory that is used to store the Video object. */
	public override function dispose():Void
	{
		if (FlxG.signals.focusGained.has(onFocusGained))
			FlxG.signals.focusGained.remove(onFocusGained);

		if (FlxG.signals.focusLost.has(onFocusLost))
			FlxG.signals.focusLost.remove(onFocusLost);

		#if (FLX_SOUND_SYSTEM && flixel >= version("5.9.0"))
		if (FlxG.sound.onVolumeChange.has(onVolumeChange))
			FlxG.sound.onVolumeChange.remove(onVolumeChange);
		#elseif (FLX_SOUND_SYSTEM && flixel < version("5.9.0"))
		if (FlxG.signals.postUpdate.has(onVolumeUpdate))
			FlxG.signals.postUpdate.remove(onVolumeUpdate);
		#end

		super.dispose();
	}
}
