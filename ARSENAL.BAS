DECLARE SUB Victory ()
DECLARE SUB DoGame ()
DECLARE SUB LoadWeapons (which AS INTEGER)
DECLARE SUB LoadSettings ()
DECLARE SUB scrolltext (text$, r%, c%, colour%)
DECLARE SUB DoTitle ()
DECLARE SUB DisplayStats ()
DECLARE SUB Destruction ()
DECLARE SUB Init ()
DECLARE SUB CheckCollisions ()
DECLARE SUB EnemyControl ()
DECLARE SUB EnemyGraphics ()
DECLARE SUB EnemyBullets ()
DECLARE SUB PlayerBullets ()
DECLARE SUB PlayerControl ()
DECLARE SUB PlayerGraphics ()

CONST FALSE = 0, TRUE = 1, EXPLODING = 2, NORMAL = 3

CONST MISSILE = 1, HOMER = 2, NUKE = 3, KNIFE = 4, CHAINGUN = 5
CONST TWIN = 6, WAVE = 7, BARRIER = 8, SPLITTER = 9

CONST IDPLAYER = 1, IDENEMY = 2

CONST delay! = 5           ' increase to slow game down
CONST showIntro% = FALSE    ' set to FALSE to bypass intro

TYPE weapon
   id AS INTEGER
   handle AS STRING * 20
   power AS INTEGER
   vertspd AS SINGLE
   plevel AS INTEGER
   elevel AS INTEGER
   dx AS INTEGER
   dy AS INTEGER
   accel AS SINGLE
   initspd AS SINGLE
   hpmax AS INTEGER
   maxbulletsloaded AS INTEGER
   aifirerate AS INTEGER
   colour AS INTEGER
END TYPE

TYPE obj
   x AS INTEGER
   y AS INTEGER
   dx AS INTEGER
   dy AS INTEGER
   xi AS INTEGER
   yi AS INTEGER
   xprev AS INTEGER
   yprev AS INTEGER
   hp AS INTEGER
   hpmax AS INTEGER
   spd AS SINGLE
   status AS INTEGER
   direction AS INTEGER
   counter AS INTEGER
   expcounter AS INTEGER
   curweapon AS weapon
END TYPE

TYPE rect
   left AS INTEGER
   right AS INTEGER
   top AS INTEGER
   bottom AS INTEGER
   delta AS INTEGER
END TYPE

DIM SHARED player AS obj, enemy AS obj
DIM SHARED playerbullet(1 TO 20) AS obj
DIM SHARED enemybullet(1 TO 20) AS obj
DIM SHARED weaponlist(1 TO 9) AS weapon
DIM SHARED PlayerBulletsLoaded%
DIM SHARED EnemyBulletsLoaded%
DIM SHARED xmax%, ymax%, xrightThreshold%, xleftThreshold%

CALL DoTitle
CALL Init
DO
   CALL LoadSettings
   CALL DisplayStats
   CALL DoGame
LOOP

SUB CheckCollisions
   DIM r1 AS rect, r2 AS rect

   FOR i% = 1 TO UBOUND(playerbullet)
      IF playerbullet(i%).status = TRUE THEN
         FOR j% = 1 TO UBOUND(enemybullet)
            IF enemybullet(j%).status = TRUE THEN
               r1.right = playerbullet(i%).x
               r1.top = playerbullet(i%).y
               r1.bottom = playerbullet(i%).y + player.curweapon.dy
               r2.left = enemybullet(j%).x - enemy.curweapon.dx
               r2.top = enemybullet(j%).y
               r2.bottom = enemybullet(j%).y + enemy.curweapon.dy
               IF playerbullet(i%).x - playerbullet(i%).xprev < player.curweapon.dx THEN r1.delta = player.curweapon.dx ELSE r1.delta = playerbullet(i%).x - playerbullet(i%).xprev
               IF enemybullet(j%).xprev - enemybullet(j%).x < enemy.curweapon.dx THEN r2.delta = enemy.curweapon.dx ELSE r2.delta = enemybullet(j%).xprev - enemybullet(j%).x
               r1.left = r1.right - r1.delta
               r2.right = r2.left + r2.delta
               IF NOT ((r1.left > r2.right) OR (r2.left > r1.right) OR (r1.top > r2.bottom) OR (r2.top > r1.bottom)) THEN
                  IF (player.curweapon.id = NUKE) OR (player.curweapon.id = BARRIER) THEN
                     playerbullet(i%).hp = playerbullet(i%).hp - enemy.curweapon.power
                     IF playerbullet(i%).hp <= 0 THEN
                        LINE (playerbullet(i%).x, playerbullet(i%).y)-(playerbullet(i%).x + player.curweapon.dx, playerbullet(i%).y + player.curweapon.dy), 0, BF
                        playerbullet(i%).status = EXPLODING
                        playerbullet(i%).expcounter = 40
                     END IF
                  ELSE
                     IF player.curweapon.id <> KNIFE THEN
                        LINE (playerbullet(i%).x, playerbullet(i%).y)-(playerbullet(i%).x + player.curweapon.dx, playerbullet(i%).y + player.curweapon.dy), 0, BF
                        playerbullet(i%).status = EXPLODING
                        playerbullet(i%).expcounter = 10
                     END IF
                  END IF
                    
                  IF (enemy.curweapon.id = NUKE) OR (enemy.curweapon.id = BARRIER) THEN
                     enemybullet(j%).hp = enemybullet(j%).hp - player.curweapon.power
                     IF enemybullet(j%).hp <= 0 THEN
                        LINE (enemybullet(j%).x, enemybullet(j%).y)-(enemybullet(j%).x + enemy.curweapon.dx, enemybullet(j%).y + enemy.curweapon.dy), 0, BF
                        enemybullet(j%).status = EXPLODING
                        enemybullet(j%).expcounter = 40
                     END IF
                  ELSE
                     IF enemy.curweapon.id <> KNIFE THEN
                        LINE (enemybullet(j%).x, enemybullet(j%).y)-(enemybullet(j%).x + enemy.curweapon.dx, enemybullet(j%).y + enemy.curweapon.dy), 0, BF
                        enemybullet(j%).status = EXPLODING
                        enemybullet(j%).expcounter = 10
                     END IF
                  END IF
               END IF
            END IF
         NEXT j%
        
         IF enemy.status <> EXPLODING THEN
            r1.right = playerbullet(i%).x
            r1.top = playerbullet(i%).y
            r1.bottom = playerbullet(i%).y + player.curweapon.dy
            IF playerbullet(i%).x - playerbullet(i%).xprev < player.curweapon.dx THEN r1.delta = player.curweapon.dx ELSE r1.delta = playerbullet(i%).x - playerbullet(i%).xprev
            r1.left = r1.right - r1.delta
            r2.left = enemy.x - enemy.dx
            r2.right = enemy.x
            r2.top = enemy.y
            r2.bottom = enemy.y + enemy.dy
           
            IF NOT ((r1.left > r2.right) OR (r2.left > r1.right) OR (r1.top > r2.bottom) OR (r2.top > r1.bottom)) THEN
               LINE (playerbullet(i%).x, playerbullet(i%).y)-(playerbullet(i%).x + player.curweapon.dx, playerbullet(i%).y + player.curweapon.dy), 0, BF
               playerbullet(i%).status = EXPLODING
               IF player.curweapon.id = NUKE THEN playerbullet(i%).expcounter = 40 ELSE playerbullet(i%).expcounter = 10
               enemy.status = EXPLODING
               enemy.expcounter = 20
               enemy.hp = enemy.hp - player.curweapon.power
               IF enemy.hp < 0 THEN enemy.hp = 0
               CALL DisplayStats
            END IF
         END IF
      END IF
   NEXT i%

   FOR i% = 1 TO UBOUND(enemybullet)
      IF enemybullet(i%).status = TRUE AND player.status <> EXPLODING THEN
         r1.right = player.x
         r1.top = player.y
         r1.bottom = player.y + player.dy
         r1.left = player.x - player.dx
        
         r2.left = enemybullet(i%).x - enemy.curweapon.dx
         r2.top = enemybullet(i%).y
         r2.bottom = enemybullet(i%).y + enemy.curweapon.dy
         IF enemybullet(i%).xprev - enemybullet(i%).x < enemy.curweapon.dx THEN r2.delta = enemy.curweapon.dx ELSE r2.delta = enemybullet(i%).xprev - enemybullet(i%).x
         r2.right = r2.left + r2.delta
         IF NOT ((r1.left > r2.right) OR (r2.left > r1.right) OR (r1.top > r2.bottom) OR (r2.top > r1.bottom)) THEN
            LINE (enemybullet(i%).x, enemybullet(i%).y)-(enemybullet(i%).x + enemy.curweapon.dx, enemybullet(i%).y + enemy.curweapon.dy), 0, BF
            enemybullet(i%).status = EXPLODING
            IF enemy.curweapon.id = NUKE THEN enemybullet(i%).expcounter = 40 ELSE enemybullet(i%).expcounter = 10
            player.status = EXPLODING
            player.expcounter = 20
            player.hp = player.hp - enemy.curweapon.power
            IF player.hp < 0 THEN player.hp = 0
            CALL DisplayStats
         END IF
      END IF
   NEXT i%

END SUB

SUB Destruction

IF player.hp > enemy.hp THEN
   FOR r% = 1 TO xmax% + 150 STEP 6
      PCOPY 0, 1
      CIRCLE (enemy.x + enemy.dx / 2, enemy.y + enemy.dy / 2), r%, 9, , , .15
      CIRCLE (enemy.x + enemy.dx / 2, enemy.y + enemy.dy / 2), ABS(r% - 6), 0, , , .15
   NEXT r%
  
   CLS
   CALL DisplayStats

   LOCATE 3, 1
   COLOR 4
   PRINT "Player wins"
ELSE
   FOR r% = 1 TO xmax% + 150 STEP 6
      PCOPY 0, 1
      CIRCLE (player.x + player.dx / 2, player.y + player.dy / 2), r%, 14, , , .15
      CIRCLE (player.x + player.dx / 2, player.y + player.dy / 2), ABS(r% - 6), 0, , , .15
   NEXT r%
 
   CLS
   CALL DisplayStats

   LOCATE 3, 66
   COLOR 5
   PRINT "Computer wins"
END IF

LOCATE 23, 1
COLOR 14
PRINT "Hit [ENTER] to player again, [ESC] to exit"
PCOPY 0, 1
DO
   DO: any$ = INKEY$: LOOP WHILE any$ = ""
   IF any$ = CHR$(27) THEN SYSTEM
   IF any$ = CHR$(13) THEN EXIT DO
LOOP

IF player.hp > enemy.hp THEN
   CALL Victory
END IF

END SUB

SUB DisplayStats

   COLOR 4
   LOCATE 1, 1
   PRINT STRING$(80, " ")

   LOCATE 1, 1
   PRINT "HP: "; RTRIM$(STR$(player.hp)); "/"; LTRIM$(STR$(player.hpmax))
   LOCATE 1, 20
   PRINT "["; RTRIM$(LTRIM$(player.curweapon.handle)); "-"; RTRIM$(LTRIM$(STR$(player.curweapon.plevel))); "]"

   COLOR 9
   LOCATE 1, 50
   PRINT "["; RTRIM$(LTRIM$(enemy.curweapon.handle)); "-"; RTRIM$(LTRIM$(STR$(enemy.curweapon.elevel))); "]"
   LOCATE 1, 66
   PRINT "HP: "; RTRIM$(STR$(enemy.hp)); "/"; LTRIM$(STR$(enemy.hpmax))

   VIEW SCREEN (0, 8)-(xmax%, ymax%)
END SUB

SUB DoGame
DO
   FOR t! = 1 TO delay!: NEXT t!
   CALL CheckCollisions

   CALL PlayerControl
   CALL EnemyControl
  
   CALL PlayerGraphics
   CALL EnemyGraphics

   CALL PlayerBullets
   CALL EnemyBullets

   PCOPY 0, 1

   IF player.hp <= 0 OR enemy.hp <= 0 THEN EXIT DO
LOOP

CALL Destruction

END SUB

SUB DoTitle

   SCREEN 12
   WINDOW SCREEN (0, 0)-(100, 100)
      xmax% = PMAP(100, 0)
      ymax% = PMAP(100, 1)
   WINDOW

   ' Threshold for splitter
   xrightThreshold% = xmax% * .6
   xleftThreshold% = xmax% * .4

   FOR i% = 1 TO 30
      LINE (i% * (xmax% / 30), 1)-(xmax%, i% * (ymax% / 30)), 4
      LINE (1, i% * ymax% / 30)-(i% * xmax% / 30, ymax%), 4
   NEXT i%

   PALETTE 8, 1

   title$ = "s8bm90,250 r10u30r5f30 u30r20d20l20f10r15 r20u15l20u15r20br5 nr20d15nr20d15r25 u30r5f30r5u30br5 nd30r5f30br5 nu30r20"
   DRAW "c8"
   DRAW title$
 
   FOR x% = 90 TO 540
      FOR y% = 190 TO 250
         IF POINT(x%, y%) = 8 THEN PSET (x%, y%), 15
      NEXT y%
   NEXT x%

   title$ = "s2 bm450,280 u15nu15r20d15nl20br5bu15 f15ng15e15bu15br20 nd30r20d30nl20bu10bl5f10 br5u30r20d10nl20bu10br5 r20g30"
   DRAW "c8"
   DRAW title$

   FOR x% = 450 TO 590
      FOR y% = 260 TO 290
         IF POINT(x%, y%) = 8 THEN PSET (x%, y%), 9
      NEXT y%
   NEXT x%

   DO: LOOP WHILE INKEY$ = ""
  
SCREEN 8

   RANDOMIZE TIMER
   WINDOW SCREEN (0, 0)-(100, 100)
      xmax% = PMAP(100, 0)
      ymax% = PMAP(100, 1)
   WINDOW

   IF showIntro% = TRUE THEN
      scrolltext "Welcome to the Arsenal databank", 1, 1, 2
      LOCATE 2, 1: COLOR 2: PRINT "Login: "
      LOCATE 2, 8: COLOR 9: INPUT "", userlogin$
      LOCATE 3, 1: COLOR 2: PRINT "Password: "
         x% = 11
         COLOR 9
         DO
            DO: any$ = INKEY$: LOOP WHILE any$ = ""
            IF any$ = CHR$(13) THEN EXIT DO
            LOCATE 3, x%
            PRINT "."
            x% = x% + 1
            IF x% > 40 THEN EXIT DO
         LOOP
      LOCATE 4, 1: COLOR 2: PRINT "Verifying..."
      LOCATE 5, 1: COLOR 2: PRINT "Access granted"
      outmsg$ = "Welcome to the system " + userlogin$
      scrolltext outmsg$, 7, 1, 2
      scrolltext "INCOMMING MESSAGE FROM COMMAND - SET PRIORITY 1", 8, 1, 2
      outmsg$ = "Agent " + userlogin$ + ", Kurali craft have been detected in sector alpha!"
      scrolltext outmsg$, 10, 1, 4
      scrolltext "Engage and destroy all enemy craft.  Kurali have destroyed Terran headquarters", 11, 1, 4
      scrolltext "leaving you as our sole countermeasures.  Act immediately, as there may not be", 12, 1, 4
      scrolltext "much mo^D", 13, 1, 4
      scrolltext "<EOF received from client>", 14, 1, 2

      COLOR 2: LOCATE 16, 1: PRINT "% "
      scrolltext "execute arsenal", 16, 3, 9
      scrolltext "You have security clearence. ", 17, 1, 2
      scrolltext "Are you sure you wish to launch Arsenal? [yn] ", 18, 1, 2
      scrolltext "y", 18, 47, 9
      scrolltext "[Hit any key to execute]", 20, 1, 2

      DO: LOOP WHILE INKEY$ = ""
   END IF
  
   VIEW SCREEN (0, 8)-(xmax%, ymax%)

END SUB

SUB EnemyBullets
   FOR i% = 1 TO UBOUND(enemybullet)
      IF enemybullet(i%).status = TRUE THEN
         LINE (enemybullet(i%).x, enemybullet(i%).y)-(enemybullet(i%).x + enemy.curweapon.dx, enemybullet(i%).y + enemy.curweapon.dy), 0, BF
         enemybullet(i%).spd = enemybullet(i%).spd + enemy.curweapon.accel
         IF enemybullet(i%).x < 0 THEN
            enemybullet(i%).status = FALSE
            EnemyBulletsLoaded% = EnemyBulletsLoaded% - 1
         ELSE
            enemybullet(i%).xprev = enemybullet(i%).x
            enemybullet(i%).yprev = enemybullet(i%).y
            enemybullet(i%).x = enemybullet(i%).x - enemybullet(i%).spd
            IF enemy.curweapon.id = HOMER THEN
               IF enemybullet(i%).y > player.y THEN enemybullet(i%).direction = 8
               IF enemybullet(i%).y < player.y THEN enemybullet(i%).direction = 2
               IF enemybullet(i%).direction = 2 THEN enemybullet(i%).y = enemybullet(i%).y + enemy.curweapon.vertspd
               IF enemybullet(i%).direction = 8 THEN enemybullet(i%).y = enemybullet(i%).y - enemy.curweapon.vertspd
            END IF
            IF enemy.curweapon.id = WAVE THEN
               enemybullet(i%).y = enemybullet(i%).yi - 20 * SIN(((enemybullet(i%).x - enemybullet(i%).xi) / 50))
            END IF
            IF enemy.curweapon.id = SPLITTER THEN
               IF (enemybullet(i%).x < xleftThreshold%) THEN
                  IF enemybullet(i%).direction = 2 THEN enemybullet(i%).y = enemybullet(i%).y + enemy.curweapon.vertspd
                  IF enemybullet(i%).direction = 8 THEN enemybullet(i%).y = enemybullet(i%).y - enemy.curweapon.vertspd
               END IF
            END IF
            LINE (enemybullet(i%).x, enemybullet(i%).y)-(enemybullet(i%).x + enemy.curweapon.dx, enemybullet(i%).y + enemy.curweapon.dy), enemy.curweapon.colour, BF
         END IF
      ELSEIF enemybullet(i%).status = EXPLODING THEN
         CIRCLE (enemybullet(i%).x + enemy.curweapon.dx / 2, enemybullet(i%).y + enemy.curweapon.dy / 2), enemybullet(i%).expcounter * 2, 0
         enemybullet(i%).expcounter = enemybullet(i%).expcounter - 1
         IF enemybullet(i%).expcounter > 0 THEN
            enemybullet(i%).x = enemybullet(i%).x + enemybullet(i%).spd
            CIRCLE (enemybullet(i%).x + enemy.curweapon.dx / 2, enemybullet(i%).y + enemy.curweapon.dy / 2), enemybullet(i%).expcounter * 2, enemy.curweapon.colour
         ELSE
            enemybullet(i%).status = FALSE
            EnemyBulletsLoaded% = EnemyBulletsLoaded% - 1
         END IF
      END IF
   NEXT i%
END SUB

SUB EnemyControl
   DIM maxbulletsloaded%
  
   IF INT(RND * 20) + 1 = 1 THEN
      IF enemy.direction = 8 THEN enemy.direction = 2 ELSE enemy.direction = 8
   END IF
   IF INT(RND * enemy.curweapon.aifirerate) + 1 = 1 THEN
      IF enemy.curweapon.id = SPLITTER OR enemy.curweapon.id = BARRIER OR enemy.curweapon.id = NUKE OR enemy.curweapon.id = KNIFE THEN maxbulletsloaded% = enemy.curweapon.maxbulletsloaded ELSE maxbulletsloaded% = UBOUND(enemybullet)
      IF enemy.curweapon.id = TWIN THEN
         IF EnemyBulletsLoaded% < maxbulletsloaded% THEN
            EnemyBulletsLoaded% = EnemyBulletsLoaded% + 1
            FOR i% = 1 TO UBOUND(enemybullet)
               IF enemybullet(i%).status = FALSE THEN EXIT FOR
            NEXT i%
            enemybullet(i%).status = TRUE
            enemybullet(i%).x = enemy.x + enemy.dx
            enemybullet(i%).y = enemy.y + enemy.dy * 2
            enemybullet(i%).spd = enemy.curweapon.initspd
         END IF
         IF EnemyBulletsLoaded% < maxbulletsloaded% THEN
            EnemyBulletsLoaded% = EnemyBulletsLoaded% + 1
            FOR i% = 1 TO UBOUND(enemybullet)
               IF enemybullet(i%).status = FALSE THEN EXIT FOR
            NEXT i%
            enemybullet(i%).status = TRUE
            enemybullet(i%).x = enemy.x + enemy.dx
            enemybullet(i%).y = enemy.y - enemy.dy * 2
            enemybullet(i%).spd = enemy.curweapon.initspd
         END IF
      ELSEIF enemy.curweapon.id = SPLITTER THEN
         IF EnemyBulletsLoaded% + 2 < maxbulletsloaded% THEN
            FOR i% = 1 TO 3
               IF EnemyBulletsLoaded% < maxbulletsloaded% THEN
                  EnemyBulletsLoaded% = EnemyBulletsLoaded% + 1
                  FOR j% = 1 TO UBOUND(enemybullet)
                     IF enemybullet(j%).status = FALSE THEN EXIT FOR
                  NEXT j%
                  enemybullet(j%).status = TRUE
                  enemybullet(j%).x = enemy.x + enemy.dx + 1
                  enemybullet(j%).y = enemy.y + enemy.dy / 2 - 1 - enemy.curweapon.dy / 2
                  enemybullet(j%).yi = enemybullet(j%).y
                  enemybullet(j%).xi = enemybullet(j%).x
                  enemybullet(j%).spd = enemy.curweapon.initspd
                  IF i% = 1 THEN enemybullet(j%).direction = 2
                  IF i% = 2 THEN enemybullet(j%).direction = 8
                  IF i% = 3 THEN enemybullet(j%).direction = 4
               END IF
            NEXT i%
         END IF
      ELSE
         IF EnemyBulletsLoaded% < maxbulletsloaded% THEN
            EnemyBulletsLoaded% = EnemyBulletsLoaded% + 1
            FOR i% = 1 TO UBOUND(enemybullet)
               IF enemybullet(i%).status = FALSE THEN EXIT FOR
            NEXT i%
            enemybullet(i%).status = TRUE
            enemybullet(i%).x = enemy.x - enemy.curweapon.dx - 1
            enemybullet(i%).y = enemy.y + enemy.dy / 2 - (enemy.curweapon.dy / 2)
            enemybullet(i%).xi = enemybullet(i%).x
            enemybullet(i%).yi = enemybullet(i%).y
            enemybullet(i%).spd = enemy.curweapon.initspd
            IF enemy.curweapon.id = NUKE OR enemy.curweapon.id = BARRIER THEN enemybullet(i%).hp = enemy.curweapon.hpmax
         END IF
      END IF
   END IF

END SUB

SUB EnemyGraphics
   IF enemy.status = EXPLODING THEN
      CIRCLE (enemy.x + enemy.dx / 2, enemy.y + enemy.dy / 2), enemy.expcounter * 2, 0
   END IF
  
   LINE (enemy.x, enemy.y)-(enemy.x + enemy.dx, enemy.y + enemy.dy), 0, BF
   SELECT CASE enemy.direction
   CASE 8:
      IF enemy.y - enemy.spd < 20 THEN
         enemy.y = 20
         enemy.direction = 2
      ELSE
         enemy.y = enemy.y - enemy.spd
      END IF
   CASE 2:
      IF enemy.y + enemy.spd > ymax% - enemy.dy THEN
         enemy.y = ymax% - enemy.dy
         enemy.direction = 8
      ELSE
         enemy.y = enemy.y + enemy.spd
      END IF
   END SELECT
   LINE (enemy.x, enemy.y)-(enemy.x + enemy.dx, enemy.y + enemy.dy), 1, BF

   IF enemy.status = EXPLODING THEN
      CIRCLE (enemy.x + enemy.dx / 2, enemy.y + enemy.dy / 2), enemy.expcounter * 2, 0
      enemy.expcounter = enemy.expcounter - 1
      IF enemy.expcounter <= 0 THEN enemy.status = NORMAL
      CIRCLE (enemy.x + enemy.dx / 2, enemy.y + enemy.dy / 2), enemy.expcounter * 2, 9
   END IF

END SUB

SUB Init

   player.curweapon.plevel = 1
   enemy.curweapon.elevel = 1

   FOR i% = 1 TO UBOUND(weaponlist)
      weaponlist(i%).plevel = 1
      weaponlist(i%).elevel = 1
   NEXT i%
         
   player.x = 30
   player.y = ymax% / 2
   player.hp = 50
   player.hpmax = 50
   player.spd = 3
   player.dx = 14
   player.dy = 6
   player.status = NORMAL

   enemy.x = xmax% - 40
   enemy.y = ymax% / 2
   enemy.hp = 100
   enemy.hpmax = 100
   enemy.spd = 3
   enemy.dx = 14
   enemy.dy = 6
   enemy.status = NORMAL

END SUB

SUB LoadSettings

   IF INT(RND) + 1 = 1 THEN enemy.direction = 8 ELSE enemy.direction = 2

   player.hp = player.hpmax
   player.x = 30
   player.y = ymax% / 2
   player.status = NORMAL
 
   enemy.hp = enemy.hpmax
   enemy.x = xmax% - 40
   enemy.y = ymax% / 2
   enemy.status = NORMAL

   PlayerBulletsLoaded% = 0
   EnemyBulletsLoaded% = 0

   SCREEN 8, , 0, 0

   LoadWeapons IDPLAYER
   LoadWeapons IDENEMY

   sel% = INT(RND * UBOUND(weaponlist) + 1)
   enemy.curweapon = weaponlist(sel%)
   LoadWeapons IDENEMY
   enemy.curweapon = weaponlist(sel%)

   VIEW SCREEN (0, 0)-(xmax%, ymax%)
   CLS
   scrolltext "A R S E N A L", 1, 1, 2
   scrolltext "Terran craft", 3, 1, 11
   outmsg$ = "HP: " + STR$(player.hp)
   scrolltext outmsg$, 4, 1, 2
   outmsg$ = "Speed: " + STR$(player.spd)
   scrolltext outmsg$, 5, 1, 2
  
   scrolltext "Kulari craft", 3, 40, 11
   outmsg$ = "HP: " + STR$(enemy.hp)
   scrolltext outmsg$, 4, 40, 9
   outmsg$ = "Speed: " + STR$(enemy.spd)
   scrolltext outmsg$, 5, 40, 9
   outmsg$ = "Weapon: " + RTRIM$(enemy.curweapon.handle) + " [" + LTRIM$(STR$(enemy.curweapon.elevel)) + "]"
   scrolltext outmsg$, 7, 40, 9

   scrolltext "Make a weapon selection", 7, 1, 2
   y% = 1
      FOR i% = 1 TO UBOUND(weaponlist)
         IF y% = i% THEN
            LOCATE 7 + i%, 1: COLOR 14: PRINT "- "
         ELSE
            LOCATE 7 + i%, 1: PRINT "  "
         END IF
         LOCATE 7 + i%, 3: COLOR 2: PRINT RTRIM$(weaponlist(i%).handle); " ["; LTRIM$(RTRIM$(STR$(weaponlist(i%).plevel))); "]"
      NEXT i%
     
   DO
      SELECT CASE INKEY$
      CASE CHR$(0) + CHR$(72)
         y% = y% - 1
         IF y% < 1 THEN y% = UBOUND(weaponlist)
         FOR i% = 1 TO UBOUND(weaponlist)
            IF y% = i% THEN
               LOCATE 7 + i%, 1: COLOR 14: PRINT "- "
            ELSE
               LOCATE 7 + i%, 1: PRINT "  "
            END IF
            LOCATE 7 + i%, 3: COLOR 2: PRINT RTRIM$(weaponlist(i%).handle); " ["; LTRIM$(RTRIM$(STR$(weaponlist(i%).plevel))); "]"
         NEXT i%
      CASE CHR$(0) + CHR$(80)
         y% = y% + 1
         IF y% > UBOUND(weaponlist) THEN y% = 1
         FOR i% = 1 TO UBOUND(weaponlist)
            IF y% = i% THEN
               LOCATE 7 + i%, 1: COLOR 14: PRINT "- "
            ELSE
               LOCATE 7 + i%, 1: PRINT "  "
            END IF
            LOCATE 7 + i%, 3: COLOR 2: PRINT RTRIM$(weaponlist(i%).handle); " ["; LTRIM$(RTRIM$(STR$(weaponlist(i%).plevel))); "]"
         NEXT i%
      CASE CHR$(13)
         EXIT DO
      END SELECT
   LOOP

   player.curweapon = weaponlist(y%)
   LoadWeapons IDPLAYER
   player.curweapon = weaponlist(y%)

   outmsg$ = RTRIM$(player.curweapon.handle) + " selected.  Hit [ENTER] to enage Kulari craft"
   scrolltext outmsg$, 7 + i% + 1, 1, 2
   DO: LOOP WHILE INKEY$ <> CHR$(13)

   ' Load constant parameters for bullet arrays
   FOR i% = 1 TO UBOUND(playerbullet)
      playerbullet(i%).status = FALSE
      playerbullet(i%).direction = 6
      IF player.curweapon.id = NUKE THEN playerbullet(i%).hp = player.curweapon.hpmax
   NEXT i%
   FOR i% = 1 TO UBOUND(enemybullet)
      enemybullet(i%).status = FALSE
      enemybullet(i%).direction = 4
      IF enemy.curweapon.id = NUKE THEN enemybullet(i%).hp = enemy.curweapon.hpmax
   NEXT i%

   CLS
   SCREEN 8, , 0, 1

END SUB

SUB LoadWeapons (which AS INTEGER)

   weaponlist(MISSILE).id = MISSILE
   IF which = 1 THEN
      IF player.curweapon.id = MISSILE THEN
         weaponlist(MISSILE).plevel = player.curweapon.plevel
      END IF
      weaponlist(MISSILE).power = player.curweapon.plevel + 4
      weaponlist(MISSILE).accel = (player.curweapon.plevel + 3) / 10
   ELSE
      IF enemy.curweapon.id = MISSILE THEN
         weaponlist(MISSILE).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(MISSILE).power = enemy.curweapon.elevel + 4
      weaponlist(MISSILE).accel = (enemy.curweapon.elevel + 3) / 10
   END IF
   weaponlist(MISSILE).handle = "Missile"
   weaponlist(MISSILE).dx = 20
   weaponlist(MISSILE).dy = 2
   weaponlist(MISSILE).initspd = .4
   weaponlist(MISSILE).aifirerate = 4
   weaponlist(MISSILE).colour = 14

   weaponlist(HOMER).id = HOMER
   IF which = 1 THEN
      IF player.curweapon.id = HOMER THEN
         weaponlist(HOMER).plevel = player.curweapon.plevel
      END IF
      weaponlist(HOMER).power = player.curweapon.plevel + 2
      weaponlist(HOMER).vertspd = 1 + (player.curweapon.plevel / 10)
      weaponlist(HOMER).accel = player.curweapon.plevel / 10
   ELSE
      IF enemy.curweapon.id = HOMER THEN
         weaponlist(HOMER).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(HOMER).accel = enemy.curweapon.elevel / 10
      weaponlist(HOMER).power = enemy.curweapon.elevel + 2
      weaponlist(HOMER).vertspd = 1 + (enemy.curweapon.elevel / 10)
   END IF
   weaponlist(HOMER).handle = "Homer"
   weaponlist(HOMER).dx = 5
   weaponlist(HOMER).dy = 2
   weaponlist(HOMER).initspd = .4
   weaponlist(HOMER).aifirerate = 4
   weaponlist(HOMER).colour = 1

   weaponlist(NUKE).id = NUKE
   IF which = 1 THEN
      IF player.curweapon.id = NUKE THEN
         weaponlist(NUKE).plevel = player.curweapon.plevel
      END IF
      weaponlist(NUKE).power = player.curweapon.plevel * 2 + 10
      weaponlist(NUKE).accel = (player.curweapon.plevel) / 10
      weaponlist(NUKE).hpmax = 20 + (player.curweapon.plevel * 2)
      weaponlist(NUKE).maxbulletsloaded = player.curweapon.plevel + 4
   ELSE
      IF enemy.curweapon.id = NUKE THEN
         weaponlist(NUKE).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(NUKE).power = enemy.curweapon.elevel * 5 + 3
      weaponlist(NUKE).accel = (enemy.curweapon.elevel) / 10
      weaponlist(NUKE).hpmax = 20 + (enemy.curweapon.elevel * 2)
      weaponlist(NUKE).maxbulletsloaded = enemy.curweapon.elevel + 4
   END IF
   weaponlist(NUKE).handle = "Nuke"
   weaponlist(NUKE).dx = 40
   weaponlist(NUKE).dy = 4
   weaponlist(NUKE).initspd = 4
      IF weaponlist(NUKE).maxbulletsloaded > UBOUND(playerbullet) THEN weaponlist(NUKE).maxbulletsloaded = UBOUND(playerbullet)
   weaponlist(NUKE).aifirerate = 10
   weaponlist(NUKE).colour = 6

   weaponlist(KNIFE).id = KNIFE
   IF which = 1 THEN
      IF player.curweapon.id = KNIFE THEN
         weaponlist(KNIFE).plevel = player.curweapon.plevel
      END IF
      weaponlist(KNIFE).power = player.curweapon.plevel + 1
      weaponlist(KNIFE).accel = (player.curweapon.plevel) / 5
      weaponlist(KNIFE).maxbulletsloaded = player.curweapon.plevel + 3
   ELSE
      IF enemy.curweapon.id = KNIFE THEN
         weaponlist(KNIFE).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(KNIFE).power = enemy.curweapon.elevel + 1
      weaponlist(KNIFE).accel = (enemy.curweapon.elevel) / 5
      weaponlist(KNIFE).maxbulletsloaded = enemy.curweapon.elevel + 3
   END IF
   weaponlist(KNIFE).handle = "Knife"
   weaponlist(KNIFE).dx = 15
   weaponlist(KNIFE).dy = 1
   weaponlist(KNIFE).initspd = 20
   weaponlist(KNIFE).aifirerate = 6
   weaponlist(KNIFE).colour = 8

   weaponlist(CHAINGUN).id = CHAINGUN
   IF which = 1 THEN
      IF player.curweapon.id = CHAINGUN THEN
         weaponlist(CHAINGUN).plevel = player.curweapon.plevel
      END IF
      weaponlist(CHAINGUN).power = player.curweapon.plevel + 2
      weaponlist(CHAINGUN).accel = (player.curweapon.plevel + 3) / 10
   ELSE
      IF enemy.curweapon.id = CHAINGUN THEN
         weaponlist(CHAINGUN).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(CHAINGUN).power = enemy.curweapon.elevel + 2
      weaponlist(CHAINGUN).accel = (enemy.curweapon.elevel + 3) / 10
   END IF
   weaponlist(CHAINGUN).handle = "Chain gun"
   weaponlist(CHAINGUN).dx = 20
   weaponlist(CHAINGUN).dy = 1
   weaponlist(CHAINGUN).initspd = 8
   weaponlist(CHAINGUN).aifirerate = 1
   weaponlist(CHAINGUN).colour = 15

   weaponlist(TWIN).id = TWIN
   IF which = 1 THEN
      IF player.curweapon.id = TWIN THEN
         weaponlist(TWIN).plevel = player.curweapon.plevel
      END IF
      weaponlist(TWIN).power = player.curweapon.plevel + 3
      weaponlist(TWIN).accel = (player.curweapon.plevel + 3) / 10
   ELSE
      IF enemy.curweapon.id = TWIN THEN
         weaponlist(TWIN).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(TWIN).power = enemy.curweapon.elevel + 3
      weaponlist(TWIN).accel = (enemy.curweapon.elevel + 3) / 10
   END IF
   weaponlist(TWIN).handle = "Twin"
   weaponlist(TWIN).dx = 25
   weaponlist(TWIN).dy = 1
   weaponlist(TWIN).initspd = 4
   weaponlist(TWIN).aifirerate = 4
   weaponlist(TWIN).colour = 2

   weaponlist(WAVE).id = WAVE
   IF which = 1 THEN
      IF player.curweapon.id = WAVE THEN
         weaponlist(WAVE).plevel = player.curweapon.plevel
      END IF
      weaponlist(WAVE).power = player.curweapon.plevel + 5
      weaponlist(WAVE).accel = 0
   ELSE
      IF enemy.curweapon.id = WAVE THEN
         weaponlist(WAVE).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(WAVE).power = enemy.curweapon.elevel + 5
      weaponlist(WAVE).accel = 0
   END IF
   weaponlist(WAVE).handle = "Wave"
   weaponlist(WAVE).dx = 10
   weaponlist(WAVE).dy = 2
   weaponlist(WAVE).initspd = 14
   weaponlist(WAVE).aifirerate = 10
   weaponlist(WAVE).colour = 12

   weaponlist(BARRIER).id = BARRIER
   IF which = 1 THEN
      IF player.curweapon.id = BARRIER THEN
         weaponlist(BARRIER).plevel = player.curweapon.plevel
         weaponlist(BARRIER).hpmax = 40 + (player.curweapon.plevel * 2)
         weaponlist(BARRIER).maxbulletsloaded = player.curweapon.plevel / 5 + 4
         weaponlist(BARRIER).power = player.curweapon.plevel + 2
      END IF
   ELSE
      IF enemy.curweapon.id = BARRIER THEN
         weaponlist(BARRIER).elevel = enemy.curweapon.elevel
         weaponlist(BARRIER).power = enemy.curweapon.elevel + 2
         weaponlist(BARRIER).hpmax = 40 + (enemy.curweapon.elevel * 2)
         weaponlist(BARRIER).maxbulletsloaded = enemy.curweapon.elevel / 5 + 4
      END IF
   END IF
   weaponlist(BARRIER).handle = "Barrier"
   weaponlist(BARRIER).dx = 4
   weaponlist(BARRIER).dy = 40
   weaponlist(BARRIER).initspd = 4
   weaponlist(BARRIER).accel = .1
      IF weaponlist(BARRIER).maxbulletsloaded > UBOUND(playerbullet) THEN weaponlist(BARRIER).maxbulletsloaded = UBOUND(playerbullet)
   weaponlist(BARRIER).aifirerate = 8
   weaponlist(BARRIER).colour = 9

   weaponlist(SPLITTER).id = SPLITTER
   IF which = 1 THEN
      IF player.curweapon.id = SPLITTER THEN
         weaponlist(SPLITTER).plevel = player.curweapon.plevel
      END IF
      weaponlist(SPLITTER).power = player.curweapon.plevel + 4
      weaponlist(SPLITTER).accel = (player.curweapon.plevel + 3) / 10
   ELSE
      IF enemy.curweapon.id = SPLITTER THEN
         weaponlist(SPLITTER).elevel = enemy.curweapon.elevel
      END IF
      weaponlist(SPLITTER).power = enemy.curweapon.elevel + 4
      weaponlist(SPLITTER).accel = (enemy.curweapon.elevel + 3) / 10
   END IF
   weaponlist(SPLITTER).vertspd = 6
   weaponlist(SPLITTER).maxbulletsloaded = 18
   weaponlist(SPLITTER).handle = "Splitter"
   weaponlist(SPLITTER).dx = 20
   weaponlist(SPLITTER).dy = 2
   weaponlist(SPLITTER).initspd = 15
   weaponlist(SPLITTER).aifirerate = 4
   weaponlist(SPLITTER).colour = 4

END SUB

SUB PlayerBullets
   FOR i% = 1 TO UBOUND(playerbullet)
      IF playerbullet(i%).status = TRUE THEN
         LINE (playerbullet(i%).x, playerbullet(i%).y)-(playerbullet(i%).x + player.curweapon.dx, playerbullet(i%).y + player.curweapon.dy), 0, BF
         playerbullet(i%).spd = playerbullet(i%).spd + player.curweapon.accel
         IF playerbullet(i%).x + player.curweapon.dx > xmax% THEN
            playerbullet(i%).status = FALSE
            PlayerBulletsLoaded% = PlayerBulletsLoaded% - 1
         ELSE
            playerbullet(i%).xprev = playerbullet(i%).x
            playerbullet(i%).yprev = playerbullet(i%).y
            playerbullet(i%).x = playerbullet(i%).x + playerbullet(i%).spd
            IF player.curweapon.id = HOMER THEN
               IF playerbullet(i%).y > enemy.y THEN playerbullet(i%).direction = 8
               IF playerbullet(i%).y < enemy.y THEN playerbullet(i%).direction = 2
               IF playerbullet(i%).direction = 2 THEN playerbullet(i%).y = playerbullet(i%).y + player.curweapon.vertspd
               IF playerbullet(i%).direction = 8 THEN playerbullet(i%).y = playerbullet(i%).y - player.curweapon.vertspd
            END IF
            IF player.curweapon.id = WAVE THEN
               playerbullet(i%).y = playerbullet(i%).yi - 20 * SIN(((playerbullet(i%).x - playerbullet(i%).xi) / 50))
            END IF
            IF player.curweapon.id = SPLITTER THEN
               IF (playerbullet(i%).x > xrightThreshold%) THEN
                  IF playerbullet(i%).direction = 2 THEN playerbullet(i%).y = playerbullet(i%).y + player.curweapon.vertspd
                  IF playerbullet(i%).direction = 8 THEN playerbullet(i%).y = playerbullet(i%).y - player.curweapon.vertspd
               END IF
            END IF
            LINE (playerbullet(i%).x, playerbullet(i%).y)-(playerbullet(i%).x + player.curweapon.dx, playerbullet(i%).y + player.curweapon.dy), player.curweapon.colour, BF
         END IF
      ELSEIF playerbullet(i%).status = EXPLODING THEN
         CIRCLE (playerbullet(i%).x + player.curweapon.dx / 2, playerbullet(i%).y + player.curweapon.dy / 2), playerbullet(i%).expcounter * 2, 0
         playerbullet(i%).expcounter = playerbullet(i%).expcounter - 1
         IF playerbullet(i%).expcounter > 0 THEN
            playerbullet(i%).x = playerbullet(i%).x - playerbullet(i%).spd
            CIRCLE (playerbullet(i%).x + player.curweapon.dx / 2, playerbullet(i%).y + player.curweapon.dy / 2), playerbullet(i%).expcounter * 2, player.curweapon.colour
         ELSE
            playerbullet(i%).status = FALSE
            PlayerBulletsLoaded% = PlayerBulletsLoaded% - 1
         END IF
      END IF
   NEXT i%
END SUB

SUB PlayerControl
   DIM maxbulletsloaded%
   STATIC switch%

   SELECT CASE INKEY$
   CASE CHR$(0) + CHR$(72)
      player.direction = 8
   CASE CHR$(0) + CHR$(75)
      player.direction = 4
   CASE CHR$(0) + CHR$(77)
      player.direction = 6
   CASE CHR$(0) + CHR$(80)
      player.direction = 2
   CASE CHR$(27)
      SYSTEM
   CASE "f"
      IF player.curweapon.id <> CHAINGUN THEN
         IF player.curweapon.id = SPLITTER OR player.curweapon.id = BARRIER OR player.curweapon.id = NUKE OR player.curweapon.id = KNIFE THEN maxbulletsloaded% = player.curweapon.maxbulletsloaded ELSE maxbulletsloaded% = UBOUND(playerbullet)
         IF player.curweapon.id = TWIN THEN
            IF PlayerBulletsLoaded% < maxbulletsloaded% THEN
               PlayerBulletsLoaded% = PlayerBulletsLoaded% + 1
               FOR i% = 1 TO UBOUND(playerbullet)
                  IF playerbullet(i%).status = FALSE THEN EXIT FOR
               NEXT i%
               playerbullet(i%).status = TRUE
               playerbullet(i%).x = player.x - player.dx
               playerbullet(i%).y = player.y - player.dy * 2
               playerbullet(i%).spd = player.curweapon.initspd
            END IF
            IF PlayerBulletsLoaded% < maxbulletsloaded% THEN
               PlayerBulletsLoaded% = PlayerBulletsLoaded% + 1
               FOR i% = 1 TO UBOUND(playerbullet)
                  IF playerbullet(i%).status = FALSE THEN EXIT FOR
               NEXT i%
               playerbullet(i%).status = TRUE
               playerbullet(i%).x = player.x - player.dx
               playerbullet(i%).y = player.y + player.dy * 2
               playerbullet(i%).spd = player.curweapon.initspd
            END IF
         ELSEIF player.curweapon.id = SPLITTER THEN
            IF PlayerBulletsLoaded% + 2 < maxbulletsloaded% THEN
               FOR i% = 1 TO 3
                  IF PlayerBulletsLoaded% < maxbulletsloaded% THEN
                     PlayerBulletsLoaded% = PlayerBulletsLoaded% + 1
                     FOR j% = 1 TO UBOUND(playerbullet)
                        IF playerbullet(j%).status = FALSE THEN EXIT FOR
                     NEXT j%
                     playerbullet(j%).status = TRUE
                     playerbullet(j%).x = player.x + player.dx + 1
                     playerbullet(j%).y = player.y + player.dy / 2 - 1 - player.curweapon.dy / 2
                     playerbullet(j%).yi = playerbullet(j%).y
                     playerbullet(j%).xi = playerbullet(j%).x
                     playerbullet(j%).spd = player.curweapon.initspd
                     IF i% = 1 THEN playerbullet(j%).direction = 6
                     IF i% = 2 THEN playerbullet(j%).direction = 8
                     IF i% = 3 THEN playerbullet(j%).direction = 2
                  END IF
               NEXT i%
            END IF
         ELSE
            IF PlayerBulletsLoaded% < maxbulletsloaded% THEN
               PlayerBulletsLoaded% = PlayerBulletsLoaded% + 1
               FOR i% = 1 TO UBOUND(playerbullet)
                  IF playerbullet(i%).status = FALSE THEN EXIT FOR
               NEXT i%
               playerbullet(i%).status = TRUE
               playerbullet(i%).x = player.x + player.dx + 1
               playerbullet(i%).y = player.y + player.dy / 2 - 1 - player.curweapon.dy / 2
               playerbullet(i%).yi = playerbullet(i%).y
               playerbullet(i%).xi = playerbullet(i%).x
               playerbullet(i%).spd = player.curweapon.initspd
               IF player.curweapon.id = NUKE OR player.curweapon.id = BARRIER THEN playerbullet(i%).hp = player.curweapon.hpmax
            END IF
         END IF
      END IF
   END SELECT

   IF switch% = 0 THEN
      IF player.curweapon.id = CHAINGUN THEN
         IF PlayerBulletsLoaded% < UBOUND(playerbullet) THEN
            PlayerBulletsLoaded% = PlayerBulletsLoaded% + 1
            FOR i% = 1 TO UBOUND(playerbullet)
               IF playerbullet(i%).status = FALSE THEN EXIT FOR
            NEXT i%
            playerbullet(i%).status = TRUE
            playerbullet(i%).x = player.x + player.dx + 1
            playerbullet(i%).y = player.y + player.dy / 2 - 1
            playerbullet(i%).spd = player.curweapon.initspd
         END IF
      END IF
   END IF
          
   switch% = NOT switch%

END SUB

SUB PlayerGraphics
   IF player.status = EXPLODING THEN
      CIRCLE (player.x + player.dx / 2, player.y + player.dy / 2), player.expcounter * 2, 0
   END IF
  
   LINE (player.x, player.y)-(player.x + player.dx, player.y + player.dy), 0, BF
      SELECT CASE player.direction
         CASE 8
            IF player.y - player.spd < 20 THEN
               player.y = 20
            ELSE
               player.y = player.y - player.spd
            END IF
         CASE 4
            IF player.x - player.spd < 0 THEN
               player.x = 0
            ELSE
               player.x = player.x - player.spd
            END IF
         CASE 6
            IF player.x + player.spd > xmax% / 4 - player.dx THEN
               player.x = xmax% / 4 - player.dx
            ELSE
               player.x = player.x + player.spd
            END IF
         CASE 2
            IF player.y + player.spd > ymax% - player.dy THEN
               player.y = ymax% - player.dy
            ELSE
               player.y = player.y + player.spd
            END IF
      END SELECT
      LINE (player.x, player.y)-(player.x + player.dx, player.y + player.dy), 4, BF
     
      IF player.status = EXPLODING THEN
         player.expcounter = player.expcounter - 1
         IF player.expcounter <= 0 THEN player.status = NORMAL
         CIRCLE (player.x + player.dx / 2, player.y + player.dy / 2), player.expcounter * 2, 12
      END IF

END SUB

SUB scrolltext (text$, r%, c%, colour%)

   scrolldelay! = 300

   LOCATE r%, c%
   FOR i% = 1 TO LEN(text$)
      FOR t! = 1 TO scrolldelay!: NEXT t!
      COLOR colour%
      PRINT MID$(text$, i%, 1);
   NEXT i%
   PRINT

END SUB

SUB Victory

   CLS
   SCREEN 8, , 0, 0

   LOCATE 1, 1: COLOR 2
   PRINT "Select one of the following options"
   DIM choicelist$(1 TO 3)
      choicelist$(1) = "Upgrade " + RTRIM$(player.curweapon.handle) + " to level " + LTRIM$(STR$(player.curweapon.plevel + 1))
      choicelist$(2) = "Upgrade hull HP to " + LTRIM$(STR$(player.hpmax + 20))
      choicelist$(3) = "Upgrade speed to " + LTRIM$(STR$(player.spd + .5))

   y% = 1
   FOR i% = 1 TO UBOUND(choicelist$)
      IF y% = i% THEN
         LOCATE 3 + i%, 1: COLOR 14: PRINT "- "
      ELSE
         LOCATE 3 + i%, 1: PRINT "  "
      END IF
      LOCATE 3 + i%, 3: COLOR 2: PRINT choicelist$(i%)
   NEXT i%
    
   DO
      SELECT CASE INKEY$
      CASE CHR$(0) + CHR$(72)
         y% = y% - 1
         IF y% < 1 THEN y% = UBOUND(choicelist$)
         FOR i% = 1 TO UBOUND(choicelist$)
            IF y% = i% THEN
               LOCATE 3 + i%, 1: COLOR 14: PRINT "- "
            ELSE
               LOCATE 3 + i%, 1: PRINT "  "
            END IF
            LOCATE 3 + i%, 3: COLOR 2: PRINT choicelist$(i%)
         NEXT i%
      CASE CHR$(0) + CHR$(80)
         y% = y% + 1
         IF y% > UBOUND(choicelist$) THEN y% = 1
         FOR i% = 1 TO UBOUND(choicelist$)
            IF y% = i% THEN
               LOCATE 3 + i%, 1: COLOR 14: PRINT "- "
            ELSE
               LOCATE 3 + i%, 1: PRINT "  "
            END IF
            LOCATE 3 + i%, 3: COLOR 2: PRINT choicelist$(i%)
         NEXT i%
      CASE CHR$(13)
         EXIT DO
      END SELECT
   LOOP

   SELECT CASE y%
   CASE 1:
      player.curweapon.plevel = player.curweapon.plevel + 1
   CASE 2:
      player.hpmax = player.hpmax + 20
   CASE 3:
      player.spd = player.spd + .5
   END SELECT
 
   enemy.hpmax = enemy.hpmax + 10
   enemy.spd = enemy.spd + .1
   enemy.curweapon.elevel = enemy.curweapon.elevel + 2

END SUB

