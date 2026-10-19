package animania;

// para que llenar de imports el MegaScript si los puedo poner aqui xdlol67ezggezez

/*
* BASE GAME IMPORTS
*/

// funkin package
import funkin.Paths;
import funkin.FunkinMemory;
import funkin.Conductor;
import funkin.Preferences;
import funkin.Highscore;
import funkin.Assets;
import funkin.InitState;

// funkin.modding package
import funkin.modding.module.Module;
import funkin.modding.module.ModuleHandler;

import funkin.modding.IPlayStateScriptedClass;

import funkin.modding.base.ScriptedFlxSprite;
import funkin.modding.base.ScriptedMusicBeatState;

import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.events.ScriptEvent.CountdownScriptEvent;
import funkin.modding.events.ScriptEvent.StateChangeScriptEvent;
import funkin.modding.events.ScriptEvent.SongRetryEvent;
import funkin.modding.events.ScriptEvent.HitNoteScriptEvent;

// funkin.play package
import funkin.play.song.Song;

import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.GameOverSubState;
import funkin.play.Countdown;
import funkin.play.CountdownStep;
import funkin.play.PauseSubState;

import funkin.play.stage.StageProp;
import funkin.play.stage.Bopper;
import funkin.play.stage.Stage;
import funkin.play.stage.ScriptedStage;

import funkin.play.components.PopUpStuff;
import funkin.play.components.HealthIcon;

import funkin.play.notes.NoteSplash;
import funkin.play.notes.NoteHoldCover;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.Strumline;
import funkin.play.notes.SustainTrail;

import funkin.play.notes.notestyle.ScriptedNoteStyle;
import funkin.play.notes.notestyle.NoteStyle;

import funkin.play.notes.notekind.NoteKind;
import funkin.play.notes.notekind.NoteKindManager;

import funkin.play.scoring.Scoring;

import funkin.play.cutscene.VideoCutscene;
import funkin.play.cutscene.VideoCutscene.CutsceneType;

import funkin.play.event.SongEvent;

import funkin.play.character.MultiAnimateAtlasCharacter;
import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.character.ScriptedMultiAnimateAtlasCharacter;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.BaseCharacter;
import funkin.play.character.BaseCharacter.CharacterType;

// funkin.ui package
import funkin.ui.MusicBeatState;
import funkin.ui.FullScreenScaleMode;
#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.ui.debug.charting.ChartEditorState;
#end
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.title.TitleState;

import funkin.ui.options.OptionsState;

import funkin.ui.MusicBeatState;

import funkin.ui.story.Level;
import funkin.ui.story.LevelProp;
import funkin.ui.story.StoryMenuState;

import funkin.ui.transition.LoadingState;

// funkin.audio package
import funkin.audio.FunkinSound;
import funkin.audio.VoicesGroup;

import funkin.audio.waveform.WaveformSprite;
import funkin.audio.waveform.WaveformSprite.WaveformOrientation;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;

// funkin.api package
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end

// funkin.graphics package
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;

import funkin.graphics.shaders.AdjustColorShader;
import funkin.graphics.shaders.DropShadowShader;
import funkin.graphics.shaders.RuntimeRainShader;
import funkin.graphics.shaders.OverlayBlend;

import funkin.graphics.video.FunkinVideoSprite;

import funkin.graphics.rendering.MeshRender;

// funkin.util package
import funkin.util.FlxTweenUtil;
import funkin.util.MathUtil;
import funkin.util.Constants;
import funkin.util.MathUtil;

import funkin.util.tools.FloatTools;

// funkin.effects package
import funkin.effects.IntervalShake;
import funkin.effects.FunkTrail;

// funkin.data package
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.song.SongRegistry;
import funkin.data.event.SongEventSchema;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.notestyle.NoteStyleData;

// funkin.group package
import funkin.group.FunkinGroup;

// funkin.save package
import funkin.save.Save;

// funkin.vis package
import funkin.vis.dsp.SpectralAnalyzer;
/*
* FLIXEL IMPORTS
*/

// flixel package
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxState;

// flixel.group package
import flixel.group.FlxTypedGroup;
import flixel.group.FlxTypedSpriteGroup;

// flixel.addons package
import flixel.addons.transition.FlxTransitionableState;

import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.display.FlxBackdrop;

import flixel.addons.effects.FlxTrail;

// flixel.ui package
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;

// flixel.text package
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxTextFormat;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxText;

// flixel.math package
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMath;

// flixel.util package
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxTimerManager;
import flixel.util.FlxGradient;

// flixel.graphics package
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;

import animate.FlxAnimateFrames;

// flixel.system package
import flixel.system.FlxAssets;
import flixel.system.FlxAssets.FlxShader;

// flixel.tweens package
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

// flixel.effects package
import flixel.effects.FlxFlicker;

// flixel.sound package
import flixel.sound.FlxSound;

/*
* OPENFL IMPORTS
*/

// openfl.display package
import openfl.display.BlendMode;
import openfl.display.BitmapData;

// openfl.filters package
import openfl.filters.ShaderFilter;

/*
* LIME IMPORTS
*/

// lime.system package
import lime.system.System;

/*
* HAXE IMPORTS
*/

// haxe package
import haxe.Json;

// haxe.ds package
import haxe.ds.StringMap;

/*
* NO PACKAGE IMPORTS
*/

import StringTools;
import Reflect;
import Main;
import Type;


using StringTools;