package hxvlc.openfl;

import openfl.Lib;
import haxe.Int64;
import lime.app.Event;

/**
 * A group of Audio instances that can be played, paused, and stopped in synchronization.
 */
class AudioGroup
{
	/**
	 * The list of Audio instances in the group.
	 */
	public var members(default, null):Array<Audio> = [];

	/** Event triggered when the first member's media is opening. */
	public var onOpening(default, null):Event<Void->Void> = new Event<Void->Void>();

	/** Event triggered when the first member's playback starts. */
	public var onPlaying(default, null):Event<Void->Void> = new Event<Void->Void>();

	/** Event triggered when the first member's playback stops. */
	public var onStopped(default, null):Event<Void->Void> = new Event<Void->Void>();

	/** Event triggered when the first member's playback is paused. */
	public var onPaused(default, null):Event<Void->Void> = new Event<Void->Void>();

	/** Event triggered when the first member reaches the end of the media. */
	public var onEndReached(default, null):Event<Void->Void> = new Event<Void->Void>();

	/** Event triggered when an error occurs in the first member. */
	public var onEncounteredError(default, null):Event<String->Void> = new Event<String->Void>();

	/** Event triggered when the first member's time changes. */
	public var onTimeChanged(default, null):Event<Int64->Void> = new Event<Int64->Void>();

	/** Event triggered when the first member's position changes. */
	public var onPositionChanged(default, null):Event<Single->Void> = new Event<Single->Void>();

	/** Event triggered when the first member's length changes. */
	public var onLengthChanged(default, null):Event<Int64->Void> = new Event<Int64->Void>();

	/**
	 * Total length of the media in milliseconds (from the first member).
	 */
	public var length(get, never):Int64;

	/**
	 * Duration of the media in microseconds (from the first member).
	 */
	public var duration(get, never):Int64;

	/**
	 * Current time position in milliseconds.
	 * Getting returns the time of the first member.
	 * Setting updates all members.
	 */
	public var time(get, set):Int64;

	/**
	 * Current playback position as a percentage (0.0 to 1.0).
	 * Getting returns the position of the first member.
	 * Setting updates all members.
	 */
	public var position(get, set):Single;

	/**
	 * Volume level (0 to 100).
	 * Getting returns the volume of the first member.
	 * Setting updates all members.
	 */
	public var volume(get, set):Int;

	/**
	 * Playback rate of the media.
	 * Getting returns the rate of the first member.
	 * Setting updates all members.
	 */
	public var rate(get, set):Single;

	/**
	 * Indicates whether any member in the group is currently playing.
	 */
	public var isPlaying(get, never):Bool;

	@:noCompletion
	private var _firstMember:Null<Audio> = null;

	/**
	 * Creates a new AudioGroup.
	 */
	public function new()
	{
	}

	/**
	 * Adds an Audio instance to the group.
	 * 
	 * @param audio The Audio instance to add.
	 */
	public function add(audio:Audio):Void
	{
		if (audio != null && !members.contains(audio))
		{
			members.push(audio);

			if (members.length == 1)
				updateFirstMemberListeners();
		}
	}

	/**
	 * Removes an Audio instance from the group.
	 * 
	 * @param audio The Audio instance to remove.
	 */
	public function remove(audio:Audio):Void
	{
		if (members.remove(audio))
		{
			updateFirstMemberListeners();
		}
	}

	/**
	 * Adds a new Audio instance to the group by loading it from the specified location.
	 * 
	 * @param location The path or URL of the audio file.
	 * @param options Additional options for loading.
	 * @return The created Audio instance, or `null` if loading failed.
	 */
	public function addTrack(location:String, ?options:Array<String>):Bool
	{
		final audio:Audio = new Audio();

		if (audio.load(location, options))
		{
			add(audio);

			return true;
		}

		audio.dispose();

		return false;
	}

	/**
	 * Starts playback for all members in the group in synchronization.
	 * 
	 * @param delay Optional delay in milliseconds before starting playback (default is 50ms for buffer padding).
	 */
	public function play(delay:Int = 10):Void
	{
		final syncTime:Float = Lib.getTimer() + delay;

		for (audio in members)
		{
			audio.syncStartTime = syncTime;
			audio.play();
		}
	}

	/**
	 * Pauses playback for all members in the group.
	 */
	public function pause():Void
	{
		for (audio in members)
			audio.pause();
	}

	/**
	 * Resumes playback for all members in the group.
	 */
	public function resume():Void
	{
		for (audio in members)
			audio.resume();
	}

	/**
	 * Stops playback for all members in the group, disposes them, and clears the group.
	 */
	public function stop():Void
	{
		for (audio in members)
		{
			audio.syncStartTime = -1;
			audio.stop();
			audio.dispose();
		}

		members = [];

		updateFirstMemberListeners();
	}

	/**
	 * Sets the playback time for all members in the group.
	 * 
	 * @param time The time position in milliseconds.
	 */
	public function setTime(time:Int64):Void
	{
		for (audio in members)
			audio.time = time;
	}

	/**
	 * Disposes all members and clears the group.
	 */
	public function dispose():Void
	{
		for (audio in members)
			audio.dispose();

		members = [];

		updateFirstMemberListeners();
	}

	@:noCompletion
	private function get_length():Int64
	{
		return members.length > 0 ? members[0].length : -1;
	}

	@:noCompletion
	private function get_duration():Int64
	{
		return members.length > 0 ? members[0].duration : -1;
	}

	@:noCompletion
	private function get_time():Int64
	{
		return members.length > 0 ? members[0].time : -1;
	}

	@:noCompletion
	private function set_time(value:Int64):Int64
	{
		for (audio in members)
			audio.time = value;

		return value;
	}

	@:noCompletion
	private function get_position():Single
	{
		return members.length > 0 ? members[0].position : 0;
	}

	@:noCompletion
	private function set_position(value:Single):Single
	{
		for (audio in members)
			audio.position = value;

		return value;
	}

	@:noCompletion
	private function get_volume():Int
	{
		return members.length > 0 ? members[0].volume : -1;
	}

	@:noCompletion
	private function set_volume(value:Int):Int
	{
		for (audio in members)
			audio.volume = value;

		return value;
	}

	@:noCompletion
	private function get_rate():Single
	{
		return members.length > 0 ? members[0].rate : 1;
	}

	@:noCompletion
	private function set_rate(value:Single):Single
	{
		for (audio in members)
			audio.rate = value;

		return value;
	}

	@:noCompletion
	private function get_isPlaying():Bool
	{
		for (audio in members)
		{
			if (audio.isPlaying)
				return true;
		}

		return false;
	}

	@:noCompletion
	private function updateFirstMemberListeners():Void
	{
		if (_firstMember != null)
		{
			_firstMember.onOpening.remove(onOpening.dispatch);
			_firstMember.onPlaying.remove(onPlaying.dispatch);
			_firstMember.onStopped.remove(onStopped.dispatch);
			_firstMember.onPaused.remove(onPaused.dispatch);
			_firstMember.onEndReached.remove(onEndReached.dispatch);
			_firstMember.onEncounteredError.remove(onEncounteredError.dispatch);
			_firstMember.onTimeChanged.remove(onTimeChanged.dispatch);
			_firstMember.onPositionChanged.remove(onPositionChanged.dispatch);
			_firstMember.onLengthChanged.remove(onLengthChanged.dispatch);
		}

		_firstMember = members.length > 0 ? members[0] : null;

		if (_firstMember != null)
		{
			_firstMember.onOpening.add(onOpening.dispatch);
			_firstMember.onPlaying.add(onPlaying.dispatch);
			_firstMember.onStopped.add(onStopped.dispatch);
			_firstMember.onPaused.add(onPaused.dispatch);
			_firstMember.onEndReached.add(onEndReached.dispatch);
			_firstMember.onEncounteredError.add(onEncounteredError.dispatch);
			_firstMember.onTimeChanged.add(onTimeChanged.dispatch);
			_firstMember.onPositionChanged.add(onPositionChanged.dispatch);
			_firstMember.onLengthChanged.add(onLengthChanged.dispatch);
		}
	}
}
