% Qiuhan (Leo) Wang, Zachary Finucci
% January 16, 2015
% StickCombat
% Simple one or two player fighting game with three maps to choose from.

View.Set ("graphics:max;max, offscreenonly") % Set screen size to max and makes all operations offscreen unless specified

% Scale of characters

const x : int := 9 % Size ratio for width
const y : int := 16 % Size ratio for height
const scale : int := 10 % Amount each side is scaled up by

const speed : int := 10 % Speed of each character (pixels per loop iteration)

const punchTime : int := 200 % Duration of punch (milliseconds)
const kickTime : int := 400 % Duration of kick (milliseconds)

const punchCool : int := 600 % Cooldown time before one can punch again (milliseconds)
const kickCool : int := 1250 % Cooldown time before one can kick again (milliseconds)

const punchDmg : int := 100 % Amount of damage a punch does
const kickDmg : int := 200 % Amount of damage a kick does

const punchForce : int := 4 % Amount of knockback force of a punch
const kickForce : int := 20 % Amount of knockback force of a kick

const animTime := 100 % Time of each running animation

var usingAI : boolean := false % Whether or not person choose singleplayer(using AI)
var lastPunch : int := 0 % Last punch made by AI
var lastKick : int := 0 % Last kick made by AI

var mapID : int % Which map is choosen
var map : int := Pic.FileNew ("map1.bmp") % Map data

% Variables for each character

type character :

    record

	x1, x2, y1, y2 : int % Position of character
	xVel, yVel : int % Horizontal velocity and Vertical Velocity

	Grav : boolean % If gravity is in action
	canJump : boolean % If character can jump
	jumpHeight : int % Current height of jump

	health : int % Health of character
	punching, kicking : boolean % Whether character is in process of punching/kicking
	stunned : boolean % If character is stunned

	punchTime, kickTime : int % Time since last punch/kick

	ID : int % Which character is being used

	Right : boolean % If character is facing right or not

	pic : int % Picture of character data
	picStat : int % Which picture is being used

	animCount : int % Which stage the running animation is int
	animLast : int % Time since last change in animation

	score : int % Character score

    end record

% Declaring variable values for each character

var Purple, Green : character

% Position of Purple

Purple.x1 := 100
Purple.x2 := Purple.x1 + (x * scale)
Purple.y1 := 7
Purple.y2 := Purple.y1 + (y * scale)

% Movement of Purple

Purple.xVel := 0
Purple.yVel := 0

Purple.canJump := true
Purple.Grav := false
Purple.jumpHeight := 0

% Status of Purple

Purple.health := 900
Purple.punching := false
Purple.kicking := false
Purple.stunned := false

Purple.punchTime := 0
Purple.kickTime := 0

Purple.ID := 0

Purple.Right := true

% Visuals of Purple

Purple.pic := Pic.FileNew ("p_idle.bmp")
Purple.picStat := 1

Purple.animCount := 0
Purple.animLast := 0

% Position of Green

Green.x2 := maxx - 100
Green.x1 := Green.x2 - (x * scale)
Green.y1 := 7
Green.y2 := Green.y1 + (y * scale)

% Movement of Green

Green.xVel := 0
Green.yVel := 0

Green.canJump := true
Green.Grav := false
Green.jumpHeight := 0

% Status of Green

Green.health := 900
Green.punching := false
Green.kicking := false
Green.stunned := false

Green.punchTime := 0
Green.kickTime := 0

Green.ID := 1

Green.Right := false

% Visuals of Green

Green.pic := Pic.FileNew ("rg_idle.bmp")
Green.picStat := -1

Green.animCount := 0
Green.animLast := 0

% Movement variables

const maxJump := 150 % Max jump height
const gravity := 5 % Force of gravity

var chars : array char of boolean % Array storing key input

var isUp, isLeft, isRight : boolean := false % Controls for moving Green

var isW, isA, isD : boolean := false % Controls for moving Purple

var noDown, noUp, noLeft, noRight := false % Collision with walls for Green

var noS, noW, noA, noD := false % Collision with walls for Green

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure resetVars % Resets variables to original state before fight

    % Purple

    Purple.x1 := 100
    Purple.x2 := Purple.x1 + (x * scale)
    Purple.y1 := 7
    Purple.y2 := Purple.y1 + (y * scale)

    Purple.xVel := 0
    Purple.yVel := 0

    Purple.canJump := true
    Purple.Grav := false
    Purple.jumpHeight := 0

    Purple.health := 900
    Purple.punching := false
    Purple.kicking := false
    Purple.stunned := false

    Purple.punchTime := 0
    Purple.kickTime := 0

    Purple.ID := 0

    Purple.Right := true

    Pic.Free (Purple.pic)
    Purple.pic := Pic.FileNew ("p_idle.bmp")
    Purple.picStat := 1

    Purple.animCount := 0
    Purple.animLast := 0

    % Green

    Green.x2 := maxx - 100
    Green.x1 := Green.x2 - (x * scale)
    Green.y1 := 7
    Green.y2 := Green.y1 + (y * scale)

    Green.xVel := 0
    Green.yVel := 0

    Green.canJump := true
    Green.Grav := false
    Green.jumpHeight := 0

    Green.health := 900
    Green.punching := false
    Green.kicking := false
    Green.stunned := false

    Green.punchTime := 0
    Green.kickTime := 0

    Green.ID := 1

    Green.Right := false

    Pic.Free (Green.pic)
    Green.pic := Pic.FileNew ("rg_idle.bmp")
    Green.picStat := -1

    Green.animCount := 0
    Green.animLast := 0

end resetVars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure resetScore % Resets the scores of each character to 0

    Purple.score := 0

    Green.score := 0

end resetScore

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

process playHit % Plays hitsound

    Music.PlayFile ("hit.wav")

end playHit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function getTimePassed (lastTime : int) : int % Get time passed since inputted time

    var currentTime := Time.Elapsed % Current time since program start

    result currentTime - lastTime % Returns the difference between the current time and the inputted time

end getTimePassed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure drawForm % Draws boxes

    var font := Font.New ("sans serif:24:bold") % Font of sans serif, bold, at size 24

    cls

    Pic.Draw (map, 0, 0, picCopy) % Draws map

    % Bounds

    Draw.FillBox (0, 0, maxx, 6, black)
    Draw.FillBox (0, maxy, maxx, maxy - 6, black)
    Draw.FillBox (0, 0, 6, maxy, black)
    Draw.FillBox (maxx - 6, 0, maxx, maxy, black)

    % Purple
    
    Pic.Draw (Purple.pic, Purple.x1, Purple.y1, picMerge)

    % Green
    
    Pic.Draw (Green.pic, Green.x1, Green.y1, picMerge)

    % Purple health bar and score

    Draw.FillBox (15, 915, 925, 945, black)
    Draw.FillBox (20, 920, 920, 940, red)
    Draw.FillBox (20, 920, 20 + Purple.health, 940, purple)
    Font.Draw ("Purple", 15, 880, font, purple)
    Font.Draw (intstr (Purple.score), 15, 840, font, purple)

    % Green health bar and score

    Draw.FillBox (maxx - 15, 915, maxx - 925, 945, black)
    Draw.FillBox (maxx - 20, 920, maxx - 920, 940, red)
    Draw.FillBox (maxx - 20, 920, maxx - 20 - Green.health, 940, green)
    Font.Draw ("Green", maxx - 110, 880, font, green)
    Font.Draw (intstr (Green.score), maxx - 110, 840, font, green)

    View.Update

end drawForm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

process stun (player, stunForce : int) % Process to stun given player with given force

    if player = 0 then % When Purple is stunned

	Purple.stunned := true

	if Green.Right then

	    if Green.punching then

		Purple.picStat := -8

	    elsif Green.kicking then

		Purple.picStat := -7

	    end if

	    Purple.xVel := stunForce

	else

	    if Green.punching then

		Purple.picStat := 8

	    elsif Green.kicking then

		Purple.picStat := 7

	    end if

	    Purple.xVel := -stunForce

	end if

	loop % Maintains stun animation

	    exit when Purple.xVel = 0

	    if Green.Right then

		if Green.punching then

		    Purple.picStat := -8

		elsif Green.kicking then

		    Purple.picStat := -7

		end if

	    else

		if Green.punching then

		    Purple.picStat := 8

		elsif Green.kicking then

		    Purple.picStat := 7

		end if

	    end if

	end loop

    end if

    if player = 1 then % When Green is stunned

	Green.stunned := true

	if Purple.Right then

	    if Purple.punching then

		Green.picStat := -8

	    elsif Purple.kicking then


		Green.picStat := -7

	    end if

	    Green.xVel := stunForce

	else

	    if Purple.punching then

		Green.picStat := 8

	    elsif Green.kicking then

		Purple.picStat := 7

	    end if

	    Green.xVel := -stunForce

	end if

	loop % Maintains stun animation

	    exit when Green.xVel = 0

	    if Purple.Right then

		if Purple.punching then

		    Green.picStat := -8

		elsif Purple.kicking then


		    Green.picStat := -7

		end if

	    else

		if Purple.punching then

		    Green.picStat := 8

		elsif Purple.kicking then


		    Green.picStat := 7

		end if

	    end if

	end loop

    end if

end stun

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

process punch (player : int) % Punch for a given player

    var punchx1, punchx2, punchy1, punchy2 : int % Hitbox for the punch

    var timeStart : int % Time when punch started

    if player = 0 then % When Purple punches

	timeStart := Time.Elapsed

	if Purple.Right then

	    Purple.picStat := 4

	    punchx1 := Purple.x2 - 50
	    punchx2 := Purple.x2 + 5
	    punchy1 := Purple.y1 + 100
	    punchy2 := Purple.y1 + 110

	else

	    Purple.picStat := -4

	    punchx1 := Purple.x1 - 5
	    punchx2 := Purple.x1 + 50
	    punchy1 := Purple.y1 + 100
	    punchy2 := Purple.y1 + 110

	end if


	if ((punchx2 >= Green.x1 & punchx2 <= Green.x2)| (punchx1 >= Green.x1 & punchx1 <= Green.x2)) & ((punchy1 >= Green.y1 & punchy1 <= Green.y2)| (punchy2 >= Green.y2 & punchy1 <=
		Green.y2)) then % Checks is Green is in punch hitbox

	    Green.health -= punchDmg

	    fork playHit

	    fork stun (Green.ID, punchForce)

	end if

	loop % Maintains punch animation

	    exit when getTimePassed (timeStart) >= punchTime

	    if Purple.Right then

		Purple.picStat := 4

	    else

		Purple.picStat := -4

	    end if

	end loop

	Purple.punching := false


    end if

    if player = 1 then % When Green punches

	timeStart := Time.Elapsed

	if Green.Right then

	    Green.picStat := 4

	    punchx1 := Green.x2 - 50
	    punchx2 := Green.x2 + 5
	    punchy1 := Green.y1 + 100
	    punchy2 := Green.y1 + 110

	else

	    Green.picStat := -4

	    punchx1 := Green.x1 - 5
	    punchx2 := Green.x1 + 50
	    punchy1 := Green.y1 + 100
	    punchy2 := Green.y1 + 110

	end if

	if ((punchx2 >= Purple.x1 & punchx2 <= Purple.x2)| (punchx1 >= Purple.x1 & punchx1 <= Purple.x2)) & ((punchy1 >= Purple.y1 & punchy1 <= Purple.y2)| (punchy2 >= Purple.y2 & punchy1 <=
		Purple.y2)) then % Checks is Purple is in punch hitbox

	    Purple.health -= punchDmg

	    fork playHit

	    fork stun (Purple.ID, punchForce)

	end if

	loop % Maintains punch animation

	    exit when getTimePassed (timeStart) >= punchTime

	    if Green.Right then

		Green.picStat := 4

	    else

		Green.picStat := -4

	    end if

	end loop

	Green.punching := false

    end if

end punch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

process kick (player : int) % Kicks for a given character

    var kickx1, kickx2, kicky1, kicky2 : int % Kick hitbox

    var timeStart : int % Time when kick started

    if player = 0 then % When Purple kicks

	timeStart := Time.Elapsed

	if Purple.Right then

	    Purple.picStat := 5

	    kickx1 := Purple.x2 - 50
	    kickx2 := Purple.x2 + 10
	    kicky1 := Purple.y1 + 50
	    kicky2 := Purple.y1 + 60



	else

	    Purple.picStat := 5

	    kickx1 := Purple.x1 - 10
	    kickx2 := Purple.x1 + 50
	    kicky1 := Purple.y1 + 50
	    kicky2 := Purple.y1 + 60

	end if

	if ((kickx2 >= Green.x1 & kickx2 <= Green.x2)| (kickx1 >= Green.x1 & kickx1 <= Green.x2)) & ((kicky1 >= Green.y1 & kicky1 <= Green.y2)| (kicky2 >= Green.y2 & kicky1 <=
		Green.y2)) then % Checks if Green is in hitbox

	    Green.health -= kickDmg

	    fork playHit

	    fork stun (Green.ID, kickForce)

	end if

	loop % Maintains kick animation

	    exit when getTimePassed (timeStart) >= kickTime

	    if Purple.Right then

		Purple.picStat := 5

	    else

		Purple.picStat := -5

	    end if

	end loop

	Purple.kicking := false

    end if

    if player = 1 then % If Green kicks

	timeStart := Time.Elapsed

	if Green.Right then

	    Green.picStat := 5

	    kickx1 := Green.x2 - 50
	    kickx2 := Green.x2 + 10
	    kicky1 := Green.y1 + 50
	    kicky2 := Green.y1 + 60

	else

	    Green.picStat := -5

	    kickx1 := Green.x1 - 10
	    kickx2 := Green.x1 + 50
	    kicky1 := Green.y1 + 50
	    kicky2 := Green.y1 + 60

	end if


	if ((kickx2 >= Purple.x1 & kickx2 <= Purple.x2)| (kickx1 >= Purple.x1 & kickx1 <= Purple.x2)) & ((kicky1 >= Purple.y1 & kicky1 <= Purple.y2)| (kicky2 >= Purple.y2 & kicky1 <=
		Purple.y2)) then % Checks if Purple is in hitbox

	    Purple.health -= kickDmg

	    fork playHit

	    fork stun (Purple.ID, kickForce)

	end if
	
	loop % Maintains kick animation

	    exit when getTimePassed (timeStart) >= kickTime

	    if Green.Right then

		Green.picStat := 5

	    else

		Green.picStat := -5

	    end if

	end loop

	Green.kicking := false

    end if

end kick

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure getInput     % Gets user input from keyboard

    Input.KeyDown (chars)

    % Purple Controls

    if chars ('w') & (not Purple.stunned) & (not Purple.kicking) then

	isW := true

    end if

    if chars ('a') & (not Purple.stunned) & (not Purple.kicking) then

	isA := true

    end if

    if chars ('d') & (not Purple.stunned) & (not Purple.kicking) then

	isD := true

    end if

    if chars (KEY_SHIFT) then

	if getTimePassed (Purple.punchTime) >= punchCool then

	    if not Purple.punching then

		Purple.punching := true

		Purple.punchTime := Time.Elapsed

		fork punch (Purple.ID)

	    end if

	end if

    end if

    if chars (KEY_CTRL) then

	if getTimePassed (Purple.kickTime) >= kickCool then

	    if not Purple.kicking then

		Purple.kicking := true

		Purple.kickTime := Time.Elapsed

		fork kick (Purple.ID)

	    end if

	end if

    end if

    % Green Controls

    if not usingAI then

	if chars (KEY_UP_ARROW) & (not Green.stunned) & (not Green.kicking) then

	    isUp := true

	end if

	if chars (KEY_RIGHT_ARROW) & (not Green.stunned) & (not Green.kicking) then

	    isRight := true

	end if

	if chars (KEY_LEFT_ARROW) & (not Green.stunned) & (not Green.kicking) then

	    isLeft := true

	end if

	if chars ('m') then

	    if getTimePassed (Green.punchTime) >= punchCool then

		if not Green.punching then

		    Green.punching := true

		    Green.punchTime := Time.Elapsed

		    fork punch (Green.ID)

		end if

	    end if

	end if

	if chars ('n') then

	    if getTimePassed (Green.kickTime) >= kickCool then

		if not Green.kicking then

		    Green.kicking := true

		    Green.kickTime := Time.Elapsed

		    fork kick (Green.ID)

		end if

	    end if

	end if

    end if

end getInput

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure movement     % Movement of characters

    % Purple Movement

    if isA & (not noA) then

	Purple.Right := false

	Purple.xVel += -speed

	Purple.x1 += Purple.xVel
	Purple.x2 += Purple.xVel

    end if

    if isD & (not noD) then

	Purple.Right := true

	Purple.xVel += speed

	Purple.x1 += Purple.xVel
	Purple.x2 += Purple.xVel

    end if

    if isW & (not noW) then

	if Purple.canJump then

	    Purple.yVel += 15

	    Purple.Grav := true

	end if

    end if

    if Purple.Grav then

	if Purple.Right then

	    Purple.picStat := 6

	else

	    Purple.picStat := -6

	end if

	Purple.yVel -= gravity

	Purple.jumpHeight += Purple.yVel

	if Purple.jumpHeight >= maxJump then

	    Purple.canJump := false

	end if

	Purple.y1 += Purple.yVel
	Purple.y2 += Purple.yVel


    end if

    if Purple.stunned then

	Purple.x1 += Purple.xVel
	Purple.x2 += Purple.xVel

    end if

    % Green Movement

    if isLeft & (not noLeft) then

	Green.Right := false

	Green.xVel += -speed

	Green.x1 += Green.xVel
	Green.x2 += Green.xVel

    end if

    if isRight & (not noRight) then

	Green.Right := true

	Green.xVel += speed

	Green.x1 += Green.xVel
	Green.x2 += Green.xVel

    end if

    if isUp & (not noUp) then

	if Green.canJump then

	    Green.yVel += 15

	    Green.Grav := true

	end if

    end if

    if Green.Grav then

	if Green.Right then

	    Green.picStat := 6

	else

	    Green.picStat := -6

	end if

	Green.yVel -= gravity

	Green.jumpHeight += Green.yVel

	if Green.jumpHeight >= maxJump then

	    Green.canJump := false

	end if

	Green.y1 += Green.yVel
	Green.y2 += Green.yVel

    end if

    if Green.stunned then

	Green.x1 += Green.xVel
	Green.x2 += Green.xVel

    end if

end movement

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure collision % Creates all collision for the entire program, including character puching and kicking as well as all velocities

    % Purple collision

    if Purple.y1 <= 6 then

	noS := true

	Purple.Grav := false
	Purple.canJump := true
	Purple.jumpHeight := 0

	Purple.y1 := 7
	Purple.y2 := Purple.y1 + (y * scale)
	Purple.yVel := 0

    end if

    if Purple.x1 <= 7 then

	Purple.x1 := 7
	Purple.x2 := 7 + (x * scale)
	noA := true

    else

	noA := false

    end if

    if Purple.x2 >= maxx - 7 then

	Purple.x2 := maxx - 7
	Purple.x1 := maxx - (7 + (x * scale))
	noD := true

    else

	noD := false

    end if

    % Green collision

    if Green.y1 <= 6 then

	noDown := true

	Green.Grav := false
	Green.canJump := true
	Green.jumpHeight := 0

	Green.y1 := 7
	Green.y2 := Green.y1 + (y * scale)
	Green.yVel := 0

    end if

    if Green.x1 <= 7 then

	Green.x1 := 7
	Green.x2 := 7 + (x * scale)
	noLeft := true

    else

	noLeft := false

    end if

    if Green.x2 >= maxx - 7 then

	Green.x2 := maxx - 7
	Green.x1 := maxx - (7 + (x * scale))
	noRight := true

    else

	noRight := false

    end if

end collision

procedure clearVar

    % Purple Horizontal Velocity

    if Purple.stunned then

	if Purple.xVel > 0 then

	    Purple.xVel -= 1

	else

	    Purple.xVel += 1

	end if

	if Purple.xVel = 0 then

	    Purple.stunned := false

	end if

    else

	Purple.xVel := 0

    end if

    % Green Horizontal Velocity

    if Green.stunned then

	if Green.xVel > 0 then

	    Green.xVel -= 1

	else

	    Green.xVel += 1

	end if

	if Green.xVel = 0 then

	    Green.stunned := false

	end if

    else

	Green.xVel := 0

    end if

    isW := false
    isA := false
    isD := false

    isUp := false
    isLeft := false
    isRight := false

end clearVar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure animatePurple % Animates the characters based on user input and collision bounds

    if Purple.Right & (not Purple.Grav) & (not Purple.stunned) & (not Purple.kicking) & (not Purple.punching) then

	if ((Purple.animCount = 0) & (getTimePassed (Purple.animLast) >= animTime))| (not isA & not isD) then

	    Purple.picStat := 1
	    Purple.animCount := 1
	    Purple.animLast := Time.Elapsed

	elsif (Purple.animCount = 1) & (getTimePassed (Purple.animLast) >= animTime) & (isA| isD) then

	    Purple.picStat := 2
	    Purple.animCount += 1
	    Purple.animLast := Time.Elapsed

	elsif (Purple.animCount = 2) & (getTimePassed (Purple.animLast) >= animTime) & (isA| isD) then

	    Purple.picStat := 3
	    Purple.animCount += 1
	    Purple.animLast := Time.Elapsed

	elsif (Purple.animCount = 3) & (getTimePassed (Purple.animLast) >= animTime) & (isA| isD) then

	    Purple.picStat := 2
	    Purple.animCount := 0
	    Purple.animLast := Time.Elapsed

	end if

    elsif (not Purple.Right) & (not Purple.Grav) & (not Purple.stunned) & (not Purple.kicking) & (not Purple.punching) then

	if ((Purple.animCount = 0) & (getTimePassed (Purple.animLast) >= animTime))| (not isA & not isD) then

	    Purple.picStat := -1
	    Purple.animCount := 1
	    Purple.animLast := Time.Elapsed

	elsif (Purple.animCount = 1) & (getTimePassed (Purple.animLast) >= animTime) & (isA| isD) then

	    Purple.picStat := -2
	    Purple.animCount += 1
	    Purple.animLast := Time.Elapsed

	elsif (Purple.animCount = 2) & (getTimePassed (Purple.animLast) >= animTime) & (isA| isD) then

	    Purple.picStat := -3
	    Purple.animCount += 1
	    Purple.animLast := Time.Elapsed

	elsif (Purple.animCount = 3) & (getTimePassed (Purple.animLast) >= animTime) & (isA| isD) then

	    Purple.picStat := -2
	    Purple.animCount := 0
	    Purple.animLast := Time.Elapsed

	end if

    end if

    if Purple.Right & Purple.punching then

	Purple.picStat := 4

    elsif Purple.punching & (not Purple.Right) then

	Purple.picStat := -4

    end if

    if Purple.Right & Purple.kicking then

	Purple.picStat := 5

    elsif Purple.kicking & (not Purple.Right) then

	Purple.picStat := -5

    end if

end animatePurple

procedure animateGreen

    if Green.Right & (not Green.Grav) & (not Green.stunned) & (not Green.kicking) & (not Green.punching) then

	if ((Green.animCount = 0) & (getTimePassed (Green.animLast) >= animTime))| (not isLeft & not isRight) then

	    Green.picStat := 1
	    Green.animCount := 1
	    Green.animLast := Time.Elapsed

	elsif (Green.animCount = 1) & (getTimePassed (Green.animLast) >= animTime) & (isLeft| isRight) then

	    Green.picStat := 2
	    Green.animCount += 1
	    Green.animLast := Time.Elapsed

	elsif (Green.animCount = 2) & (getTimePassed (Green.animLast) >= animTime) & (isLeft| isRight) then
	    Green.picStat := 3
	    Green.animCount += 1
	    Green.animLast := Time.Elapsed

	elsif (Green.animCount = 3) & (getTimePassed (Green.animLast) >= animTime) & (isLeft| isRight) then

	    Green.picStat := 2
	    Green.animCount := 0
	    Green.animLast := Time.Elapsed

	end if

    elsif (not Green.Right) & (not Green.Grav) & (not Green.stunned) & (not Green.kicking) & (not Green.punching) then

	if ((Green.animCount = 0) & (getTimePassed (Green.animLast) >= animTime))| (not isLeft & not isRight) then

	    Green.picStat := -1
	    Green.animCount := 1
	    Green.animLast := Time.Elapsed

	elsif (Green.animCount = 1) & (getTimePassed (Green.animLast) >= animTime) & (isLeft| isRight) then

	    Green.picStat := -2
	    Green.animCount += 1
	    Green.animLast := Time.Elapsed

	elsif (Green.animCount = 2) & (getTimePassed (Green.animLast) >= animTime) & (isLeft| isRight) then

	    Green.picStat := -3
	    Green.animCount += 1
	    Green.animLast := Time.Elapsed

	elsif (Green.animCount = 3) & (getTimePassed (Green.animLast) >= animTime) & (isLeft| isRight) then

	    Green.picStat := -2
	    Green.animCount := 0
	    Green.animLast := Time.Elapsed

	end if

    end if

    if Green.Right & Green.punching then

	Green.picStat := 4

    elsif Green.punching & (not Green.Right) then

	Green.picStat := -4

    end if

    if Green.Right & Green.kicking then

	Green.picStat := 5

    elsif Green.kicking & (not Green.Right) then

	Green.picStat := -5

    end if


end animateGreen

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure drawPics % Retrieves Sprites of Both Characters from all angles and all positions

    case Purple.picStat of

	label 0 :

	label 1 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_idle.bmp") % Idle animation

	    Purple.picStat := 0

	label - 1 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_idle.bmp") % Reverse Idle animation

	    Purple.picStat := 0

	label 2 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_run1.bmp") % Running animation

	    Purple.picStat := 0

	label - 2 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_run1.bmp") % Reverse running animation

	    Purple.picStat := 0

	label 3 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_run2.bmp") % Second running animation

	    Purple.picStat := 0

	label - 3 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_run2.bmp") % Reverse second running animation

	    Purple.picStat := 0

	label 4 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_punch.bmp") % Punching animation

	    Purple.picStat := 0

	label - 4 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_punch.bmp") % Reverse punching animation

	    Purple.picStat := 0

	label 5 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_kick.bmp") % Kicking animation

	    Purple.picStat := 0

	label - 5 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_kick.bmp") % Reverse kicking animation

	    Purple.picStat := 0

	label 6 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_jump.bmp") % Jumping animation

	    Purple.picStat := 0

	label - 6 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_jump.bmp") % Reverse jumping animation

	    Purple.picStat := 0

	label 7 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_stun.bmp") % Stun animation

	    Purple.picStat := 0

	label - 7 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_stun.bmp") % Reverse Stun animation

	    Purple.picStat := 0

	label 8 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("p_pstun.bmp") % Punch stun

	    Purple.picStat := 0

	label - 8 :

	    Pic.Free (Purple.pic)

	    Purple.pic := Pic.FileNew ("rp_pstun.bmp") % Reverse Punch stun

	    Purple.picStat := 0

    end case

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    case Green.picStat of

	label 0 :

	label 1 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_idle.bmp") % Green idle

	    Green.picStat := 0

	label - 1 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_idle.bmp") % Reverse green idle

	    Green.picStat := 0

	label 2 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_run1.bmp") % Green moving

	    Green.picStat := 0

	label - 2 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_run1.bmp") % Reverse Green moving

	    Green.picStat := 0

	label 3 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_run2.bmp") % Green runnning

	    Green.picStat := 0

	label - 3 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_run2.bmp") % Reverse Green running

	    Green.picStat := 0

	label 4 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_punch.bmp") % Green punching

	    Green.picStat := 0

	label - 4 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_punch.bmp") % Reverse green punching

	    Green.picStat := 0

	label 5 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_kick.bmp") % Green kicking

	    Green.picStat := 0

	label - 5 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_kick.bmp") % Reverse green kicking

	    Green.picStat := 0

	label 6 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_jump.bmp") % Green jumping

	    Green.picStat := 0

	label - 6 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_jump.bmp") % reverse green jumping

	    Green.picStat := 0

	label 7 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_stun.bmp") % Green stunned

	    Green.picStat := 0

	label - 7 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_stun.bmp") % reverse green stunned

	    Green.picStat := 0

	label 8 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("g_pstun.bmp") % Green punch stun

	    Green.picStat := 0

	label - 8 :

	    Pic.Free (Green.pic)

	    Green.pic := Pic.FileNew ("rg_pstun.bmp") % Green punchstun reverse

	    Green.picStat := 0

    end case

    case mapID of

	label 0 :

	    Pic.Free (map)

	    map := Pic.FileNew ("map1.bmp")

	label 1 :

	    Pic.Free (map)

	    map := Pic.FileNew ("map2.bmp")

	label 2 :

	    Pic.Free (map)

	    map := Pic.FileNew ("map3.bmp")

    end case

end drawPics

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure checkDeath % Checks for character Death

    var font : int := Font.New ("sans serif:36:bold")

    if Purple.health <= 0 then

	Purple.health := 0

	Green.score += 1

	if Green.score < 2 then

	    resetVars

	else

	    cls

	    Font.Draw ("Green Wins!", (maxx div 2 - 100), (maxy div 2 - 18), font, green) % Draws win screen if green wins game

	    View.Update

	    delay (1000)

	end if

    end if

    if Green.health <= 0 then

	Green.health := 0

	Purple.score += 1

	if Purple.score < 2 then

	    resetVars

	else

	    cls

	    Font.Draw ("Purple Wins!", (maxx div 2 - 100), (maxy div 2 - 18), font, purple) % Draws win screen if purple wins game

	    View.Update

	    delay (1000)

	end if

    end if

end checkDeath

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

process useAI % Adds single-player AI character

    if Green.x1 < Purple.x2 then % All lines from here on are used for AI movement

	Green.Right := true

    end if

    if Green.x2 > Purple.x1 then

	Green.Right := false

    end if

    if (Green.x1 - Purple.x2) >= 10 & not Green.stunned then

	isLeft := true

    end if

    if (Green.x2 - Purple.x1) <= -10 & not Green.stunned then

	isRight := true

    end if

    if (Green.y2 - Purple.y1) <= 20 & not Green.stunned then

	isUp := true

    end if

    if ((Green.x2 + 12 >= Purple.x1 & Green.x2 + 12 <= Purple.x2)| (Green.x1 - 12 >= Purple.x1 & Green.x1 - 12 <= Purple.x2)) & ((Green.y1 + 50 >= Purple.y1 & Green.y1 + 50 <= Purple.y2)| (Green.y1 +
	    60 >= Purple.y2 & Green.y1 + 50 <=
	    Purple.y2)) & (not isLeft & not isRight) then % This checks if purple can be hit with a kick

	if getTimePassed (lastKick) >= kickCool & Rand.Int (1, 4) = 1 & not Green.stunned then % Green has a 25% chance of using a kick attack when possible

	    if not Green.kicking then

		Green.kicking := true

		lastKick := Time.Elapsed

		fork kick (Green.ID)

	    end if

	end if

    end if

    if ((Green.x2 + 7 >= Purple.x1 & Green.x2 + 7 <= Purple.x2)| (Green.x1 - 7 <= Purple.x1 & Green.x1 - 7 >= Purple.x2)) & ((Green.y1 + 100 >= Purple.y1 & Green.y1 + 100 <= Purple.y2)| (Green.y1 +
	    110 >= Purple.y2 & Green.y1 + 100 <=
	    Purple.y2)) & (not isLeft & not isRight) then % This checks if purple can be hit with a punch

	if getTimePassed (lastPunch) >= punchCool & Rand.Int (1, 3) = 1 & not Green.stunned then % Green has a 33.3% chance of using a punch attack when possible

	    if not Green.punching & not Green.kicking then

		Green.punching := true

		lastPunch := Time.Elapsed

		fork punch (Green.ID)

	    end if

	end if

    end if

end useAI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure startFight % Starts and ends the fights based on scores

    loop

	exit when Purple.score >= 2| Green.score >= 2

	if usingAI then

	    fork useAI

	end if

	checkDeath     %\

	getInput       %  \
	collision      %   \
	movement       %    \

	drawForm       %      > THIS IS THE ACTUAL PROGRAM

	animatePurple  %     /
	animateGreen   %    /

	drawPics       %  /

	clearVar       %/

	delay (5)

    end loop

end startFight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

procedure opening         % Used to find out which mode the user selects, as well as which map was chosen

    var mouseX, mouseY, pressed : int

    var menu : int := Pic.FileNew ("menu1.bmp") % Creates the menu at the beginning
    var but1 : int := Pic.FileNew ("button1.bmp") % Used for singleplayer selection
    var but2 : int := Pic.FileNew ("button2.bmp") % Used for multiplayer selection

    loop

	cls

	Mouse.Where (mouseX, mouseY, pressed)

	Pic.Draw (menu, 0, 0, picMerge)

	if mouseX >= 739 & mouseX <= 1148 & mouseY >= 476 & mouseY <= 603 then % When user selects singleplayer mode

	    Pic.Draw (but1, 739, 476, picCopy)

	    if pressed = 1 then

		usingAI := true

		exit

	    end if

	end if

	if mouseX >= 739 & mouseX <= 1148 & mouseY >= 226 & mouseY <= 357 then % When user selects multiplayer mode

	    Pic.Draw (but2, 739, 226, picCopy)

	    if pressed = 1 then

		exit

	    end if

	end if

	View.Update

    end loop

    Pic.Free (menu)
    Pic.Free (but1)
    Pic.Free (but2)

end opening

procedure chooseMap % Chooses the map based on user click placements

    var mouseX, mouseY, pressed : int

    var menu : int := Pic.FileNew ("menu2.bmp") % Creates map menu for use after mode selection
    var but1 : int := Pic.FileNew ("chooseMap1.bmp") % Used for "Classic" map choice
    var but2 : int := Pic.FileNew ("chooseMap2.bmp") % Used for "City" map choice
    var but3 : int := Pic.FileNew ("chooseMap3.bmp") % Used for "Forest" map choice

    cls

    Pic.Draw (menu, 0, 0, picMerge)

    View.Update

    delay (100)

    loop

	cls

	Mouse.Where (mouseX, mouseY, pressed)

	Pic.Draw (menu, 0, 0, picMerge)

	if mouseX >= 787 & mouseX <= 1114 & mouseY >= 534 & mouseY <= 701 then % Chooses "Classic" map type

	    Pic.Draw (but1, 762, 521, picCopy)

	    if pressed = 1 then

		mapID := 0

		exit

	    end if

	end if

	if mouseX >= 787 & mouseX <= 1114 & mouseY <= 461 & mouseY >= 294 then % Chooses "City" map type

	    Pic.Draw (but2, 762, 281, picCopy)

	    if pressed = 1 then

		mapID := 1

		exit

	    end if

	end if

	if mouseX >= 787 & mouseX <= 1114 & mouseY <= 207 & mouseY >= 34 then % Chooses "Forest" map type

	    Pic.Draw (but3, 762, 21, picCopy)

	    if pressed = 1 then

		mapID := 2

		exit

	    end if

	end if

	View.Update

    end loop

    Pic.Free (menu)

    Pic.Free (but1)
    Pic.Free (but2)
    Pic.Free (but3)

end chooseMap

procedure controls

    var control : int := Pic.FileNew ("controls1.bmp") % Explains singleplayer controls

    cls

    if not usingAI then

	control := Pic.FileNew ("controls2.bmp") % Explain multiplayer controls

    end if

    Pic.Draw (control, 0, 0,
	picCopy)

    View.Update

    delay (7000)

end controls

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

loop % Used to start a multiplayer game

    usingAI := false
    
	Music.PlayFileLoop ("openingTheme.mp3")

    opening % Opening screen

    chooseMap % User's preferential map

    controls % Control screen explaining user controls
    
    resetVars % Resets playing field to original position

    resetScore % Resets score back to original value

    startFight % Starts the program

    delay (5000)

end loop

