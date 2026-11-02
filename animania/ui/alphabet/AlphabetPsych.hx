package animania.ui.alphabet;

class AlphabetPsych extends FlxTypedSpriteGroup
{
	var AlphaCharacterPsych = ScriptedFlxSprite.init('AlphaCharacterPsych');

	public var delay:Float = 0.05;
	public var paused:Bool = false;

	public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var isMenuItem:Bool = false;
	public var textSize:Float = 1.0;

	public var text:String = "";

	var _finalText:String = "";
	var yMulti:Float = 1;

	var lastSprite:AlphaCharacterPsych;
	var xPosResetted:Bool = false;

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	public var lettersArray:Array<AlphaCharacterPsych> = [];

	public var finishedText:Bool = false;
	public var typed:Bool = false;

	public var typingSpeed:Float = 0.05;

	public function new(X, Y, _text:String = "", bold:Bool = false, isTyped:Bool = false, typedSpeed:Float = 0.01, size:Float = 1)
	{
		super(X, Y);
		forceX = Math.NEGATIVE_INFINITY;
		this.textSize = size;

		_finalText = _text;
		this.text = _text;
		this.typed = isTyped;
		isBold = bold;

		if (text != "")
			typed ? startTypedText(typedSpeed) : addText();
		else
			finishedText = true;
		trace(finishedText);
	}

	public function changeText(newText:String, newTypingSpeed:Float = -1)
	{
		for (i in 0...lettersArray.length)
		{
			var letter = lettersArray[0];
			remove(letter, true);
			lettersArray.remove(letter);
		}
		lettersArray = [];
		splitWords = [];
		loopNum = 0;
		xPos = 0;
		curRow = 0;
		consecutiveSpaces = 0;
		xPosResetted = false;
		finishedText = false;
		lastSprite = null;

		var lastX = x;
		x = 0;
		_finalText = newText;
		text = newText;
		if (newTypingSpeed != -1)
			typingSpeed = newTypingSpeed;

		if (text != "")
			typed ? startTypedText(typingSpeed) : addText();
		else
			finishedText = true;

		x = lastX;
	}

	public function addText()
	{
		doSplitWords();

		var xPos:Float = 0;
		for (character in splitWords)
		{
			var spaceChar:Bool = (character == " " || (isBold && character == "_"));
			if (spaceChar)
				consecutiveSpaces++;

			var isNumber:Bool = numbers.indexOf(character) != -1;
			var isSymbol:Bool = symbols.indexOf(character) != -1;
			var isAlphabet:Bool = alphabet.indexOf(character.toLowerCase()) != -1;
			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null)
					xPos = lastSprite.x + lastSprite.width * .5;

				if (consecutiveSpaces > 0)
					xPos += 20 * consecutiveSpaces * textSize;

				consecutiveSpaces = 0;

				var letter = ScriptedFlxSprite.scriptInit('AlphaCharacterPsych', xPos, 0, textSize);

				if (isBold)
				{
					if (isNumber)
						letter.scriptCall('createBoldNumber', [character]);
					else if (isSymbol)
						letter.scriptCall('createBoldSymbol', [character]);
					else
						letter.scriptCall('createBoldLetter', [character]);
				}
				else
				{
					if (isNumber)
						letter.scriptCall('createNumber', [character]);
					else if (isSymbol)
						letter.scriptCall('createSymbol', [character]);
					else
						letter.scriptCall('createLetter', [character]);
				}

				add(letter);
				lettersArray.push(letter);

				lastSprite = letter;
			}

			loopNum += 1;
		}
	}

	function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	var loopNum:Int = 0;
	var xPos:Float = 0;

	public var curRow:Int = 0;

	var dialogueSound:FlxSound = null;
	var consecutiveSpaces:Int = 0;

	var typeTimer:FlxTimer = null;

	public function startTypedText(speed:Float):Void
	{
		_finalText = text;
		doSplitWords();

		speed2 = speed;

		if (speed <= 0)
		{
			while (!finishedText)
			{
				timerCheck();
			}
			if (dialogueSound != null)
				dialogueSound.stop();
			dialogueSound = FlxG.sound.play(Paths.sound('dialogue'));
		}
		else
		{
			typeTimer = new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				typeTimer = new FlxTimer().start(speed2, function(tmr:FlxTimer)
				{
					timerCheck(tmr);
				}, 0);
			});
		}
	}

	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";

	var LONG_TEXT_ADD:Float = -24;

	public function timerCheck(?tmr:FlxTimer = null)
	{
		var autoBreak:Bool = false;
		if ((loopNum <= splitWords.length - 2 && splitWords[loopNum] == "\\" && splitWords[loopNum + 1] == "n")
			|| ((autoBreak = true) && xPos >= FlxG.width * 0.65 && splitWords[loopNum] == ' '))
		{
			final toBrake = autoBreak ? 1 : 2;
			if (tmr != null)
				tmr.loops -= toBrake;
			loopNum += toBrake;

			yMulti += 1;
			xPosResetted = true;
			xPos = 0;
			curRow += 1;
			if (curRow == 2)
				y += LONG_TEXT_ADD;
		}

		if (loopNum <= splitWords.length && splitWords[loopNum] != null)
		{
			var spaceChar:Bool = (splitWords[loopNum] == " " || (isBold && splitWords[loopNum] == "_"));
			if (spaceChar)
				consecutiveSpaces++;

			var isNumber:Bool = numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = symbols.indexOf(splitWords[loopNum]) != -1;
			var isAlphabet:Bool = alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1;

			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null && !xPosResetted)
				{
					lastSprite.updateHitbox();
					xPos += lastSprite.width * lastSprite.scale.x;

				}
				else
					xPosResetted = false;

				xPos += 10 * consecutiveSpaces * textSize;

				consecutiveSpaces = 0;

				var letter = ScriptedFlxSprite.scriptInit('AlphaCharacterPsych', xPos, 55 * yMulti, textSize);
				letter.scriptSet('row', curRow);
				var boldSuffix = isBold ? "Bold" : "";
				if (isNumber)
				{
					letter.scriptCall('create' + boldSuffix + 'Number', [splitWords[loopNum]]);
				}
				else if (isSymbol)
				{
					letter.scriptCall('create' + boldSuffix + 'Symbol', [splitWords[loopNum]]);
				}
				else
				{
					letter.scriptCall('create' + boldSuffix + 'Letter', [splitWords[loopNum]]);
				}
				letter.x += 10;

				if (tmr != null)
				{
					if (dialogueSound != null)
						dialogueSound.stop();
					dialogueSound = FlxG.sound.play(Paths.sound('dialogue'));
				}

				add(letter);

				lastSprite = letter;
			}
		}

		loopNum++;
		if (loopNum >= splitWords.length)
		{
			if (tmr != null)
			{
				typeTimer = null;
				tmr.cancel();
				tmr.destroy();
			}
			finishedText = true;
		}
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
			x = (forceX != Math.NEGATIVE_INFINITY) ? forceX : FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
		}

		super.update(elapsed);
	}

	public function killTheTimer()
	{
		if (typeTimer != null)
		{
			typeTimer.cancel();
			typeTimer.destroy();
		}
		typeTimer = null;
	}
}
