package animania.gameplay.solotime;

class SoloTime extends Module
{
    var MULTI_SHIT = .5;
    var OFFSET = 0.25;

    override function onSongEvent(event:SongEventScriptEvent) {
		var camHUD:FunkinCamera = PlayState.instance.camHUD;
        if (event.eventData.eventKind == "SoloTime")
        {
            var suffix = event.eventData.getString("randParam") ?? "";
            FunkinSound.playOnce(Paths.sound("gameplay/solo_time/solotime" + suffix , "shared"));

            var texturePath = "ui/times/solo_time" + suffix;
            var soloTimeTxtSplash = new FunkinSprite();
            soloTimeTxtSplash.loadSparrow(texturePath);
            soloTimeTxtSplash.animation.addByPrefix("anim", "solo_time", 24, false);
            soloTimeTxtSplash.animation.onFinish.add(function(name:String)
            {
                FlxTween.tween(soloTimeTxtSplash, {alpha: 0}, 0.5);
            });
            soloTimeTxtSplash.scale.set(0.75, 0.75);
            soloTimeTxtSplash.zIndex = 150;
            soloTimeTxtSplash.screenCenter(0x10);
            soloTimeTxtSplash.camera = camHUD;
            soloTimeTxtSplash.zIndex = 20;
            soloTimeTxtSplash.x = -120;
            soloTimeTxtSplash.animation.timeScale = 1 / MULTI_SHIT;
            soloTimeTxtSplash.animation.play("anim", true);
            soloTimeTxtSplash.angle = FlxG.random.float(-2, 2);
            FlxTween.tween(soloTimeTxtSplash, {x: soloTimeTxtSplash.x + 20, angle: 0}, 1 * MULTI_SHIT, {ease: FlxEase.cubeOut});
            PlayState.instance.add(soloTimeTxtSplash);

            createCoolBackLine(100, 1, 140, -180, 300);
            createCoolBackLine(350, 1, 60, -180, 650);
            createCoolBackLine(560, 1, 15, -180, 950);

            createBlackLine(-(FlxG.height / 4), -(FlxG.height / 6));
            createBlackLine(FlxG.height, FlxG.height - (FlxG.height / 8));

            PlayState.instance.refresh();
        }
    }

    function constructSoloText()
    {
        var txt = new FlxText();
        txt.setFormat(Paths.font("Blueprint.ttf"), 96, 0xffffffff);
        txt.scale.y *= 0.8;
        return txt;
    }

    function createBlackLine(yPos:Float, targetY:Float):FunkinSprite
    {
        var blackLine:FunkinSprite = new FunkinSprite(0, yPos).makeSolidColor(FlxG.width, Std.int(FlxG.height / 4), FlxColor.BLACK);
        blackLine.camera = PlayState.instance.camHUD;
        blackLine.alpha = 1;
        blackLine.zIndex = 5;
        PlayState.instance.add(blackLine);

        FlxTween.tween(blackLine, {y: targetY}, 10 / 24 * MULTI_SHIT, {
            startDelay: 4 / 24 * MULTI_SHIT,
            ease: FlxEase.quadOut,
            onComplete: function(_) {
                FlxTween.tween(blackLine, {y: yPos}, 10 / 24 * MULTI_SHIT, {
                    startDelay: 30 / 24 * MULTI_SHIT,
                    ease: FlxEase.quadOut,
                    onComplete: function(_)
                    {
                        PlayState.instance.remove(blackLine, true);
                        blackLine.destroy();
                    }
                });
            }
        });
        return blackLine;
    }

    function createCoolBackLine(xPos:Float, zIndex:Int, scaleX:Float, moveAmount:Float, moveEnd:Float)
    {
        var coolBackLine:FunkinSprite = new FunkinSprite(xPos, -100).makeSolidColor(1, Std.int(FlxG.height * 1.75), FlxColor.BLACK);
        coolBackLine.cameras = [PlayState.instance.camHUD];
        coolBackLine.angle = -20;
        coolBackLine.zIndex = zIndex;
        coolBackLine.scale.x = 0.001;
        coolBackLine.updateHitbox();
        PlayState.instance.add(coolBackLine);

        FlxTween.tween(coolBackLine.scale, {x: scaleX}, 9 / 24 * MULTI_SHIT, {startDelay: OFFSET, ease: FlxEase.quadOut});
        FlxTween.tween(coolBackLine, {x: coolBackLine.x - moveAmount}, 10 / 24 * MULTI_SHIT, {startDelay: OFFSET, ease: FlxEase.quadOut});
        FlxTween.tween(coolBackLine.scale, {x: 0.0}, 9 / 24 * MULTI_SHIT, {startDelay: 38 / 24 * MULTI_SHIT + OFFSET, ease: FlxEase.quadOut});
        FlxTween.tween(coolBackLine, {x: coolBackLine.x + moveEnd}, 10 / 24 * MULTI_SHIT, {
            startDelay: 38 / 24 * MULTI_SHIT + OFFSET,
            ease: FlxEase.quadOut,
            onComplete: function(_)
            {
                PlayState.instance.remove(coolBackLine, true);
                coolBackLine.destroy();
            }
        });
    }
}
