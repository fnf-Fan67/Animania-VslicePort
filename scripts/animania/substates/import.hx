package animania.substates;

import funkin.save.Save;

import funkin.input.Control;
import funkin.input.Device;
import funkin.input.PreciseInputManager;

import funkin.Paths;
import funkin.Conductor;
import funkin.Preferences;
import funkin.PlayerSettings;

import funkin.audio.FunkinSound;

import funkin.graphics.FunkinSprite;

import funkin.play.PlayState;
import funkin.play.PauseSubState;
import funkin.play.PlayStatePlaylist;

import funkin.ui.freeplay.FreeplayState;
import funkin.ui.story.StoryMenuState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.transition.stickers.StickerSubState;

import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.song.SongRegistry;

import funkin.util.Constants;
import funkin.util.InputUtil;
import funkin.util.TouchUtil;

import flixel.FlxG;

import flixel.addons.transition.FlxTransitionableState;

import flixel.effects.FlxFlicker;

import flixel.math.FlxRect;

import flixel.util.FlxTimer;
import flixel.util.FlxColor;

import flixel.text.FlxText;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import lime.ui.WindowVSyncMode;

import Reflect;