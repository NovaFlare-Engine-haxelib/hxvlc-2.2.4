package;

import hxvlc.openfl.Audio;
import hxvlc.openfl.AudioGroup;

class CompileAudioGroup
{
	public static function main():Void
	{
		final group = new AudioGroup();
		final a = new Audio();

		group.add(a);
		group.volume = 0.5;
		group.remove(a);
		group.dispose();
	}
}

