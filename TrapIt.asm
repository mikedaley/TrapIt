; -----------------------------------------------------------------------------
; Name:     TRAPIT
; Author:   Mike Daley
; Started:  12th May 2016
; Finished: 
;
; The idea of the game is to move the red player square around the screen leaving a
; trail of black squares. The player and the ball are unable to move through black
; squares. The player must trap the ball so that it cannot move. When the ball cannot
; move any more the players green progress bar at the top of the screen is increased
; and the level is reset.
;
; If the player gets into a position where they are stuck and cannot trap the ball then
; pressing the Enter key will reset the level, loosing all their progress :) The aim of
; the game is to get the progress bar as long as possilbe.
;
; To move the player the Q, A, O, P keys are used and Enter resets the level.
; 
; Remember to be careful as the ball will pass through the players red square which can
; cause the ball to escape from the player just when you think you have it trapped.
;
; This game is very easy to play but hard to master :o)
;
; This is an entry for the 256 byte game challenge on the Z80 Assembly programming
; on the ZX Spectrum Facebook Group https://www.facebook.com/groups/z80asm/
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; CONSTANTS
; -----------------------------------------------------------------------------
BITMAP_SCRN_ADDR        equ             0x4000
BITMAP_SCRN_SIZE        equ             0x1800
ATTR_SCRN_ADDR          equ             0x5800
ATTR_SCRN_SIZE          equ             0x300
ATTR_ROW_SIZE           equ             0x1f

BLACK                   equ             0x00
BLUE                    equ             0x01
RED                     equ             0x02
MAGENTA                 equ             0x03
GREEN                   equ             0x04
CYAN                    equ             0x05
YELLOW                  equ             0x06
WHITE                   equ             0x07
PAPER                   equ             0x08                        ; Multiply with inks to get paper colour
BRIGHT                  equ             0x40
FLASH                   equ             0x80                        ; e.g. ATTR = BLACK * PAPER + CYAN + BRIGHT

PLAYER_COLOUR           equ             RED * PAPER + BRIGHT
BALL_COLOUR             equ             BLUE * PAPER + WHITE
SCRN_COLOUR             equ             YELLOW * PAPER + BLACK
BORDER_COLOUR           equ             BLACK * PAPER               ; Must be Black on Black as that is what the attr memory is initialised too

UP_CELL                 equ             0xffe0                      ; - 32
DOWN_CELL               equ             0x0020                      ; + 32
LEFT_CELL               equ             0xffff                      ; -1 
RIGHT_CELL              equ             0x0001                      ; + 1

MAX_TRAPPED_COUNT       equ             0x02                        ; Numer of frames the ball has been unable to move. If the trapped
                                                                    ; count reaches this number then the ball is trapped and the level ends

DYN_VAR_LEVELS_COMPLETE equ             0x00                        ; Stores the number of consecutive levels completed
DYN_VAR_TRAPPED_COUNT   equ             0x01                        ; Stores how many frames the ball has not been able to move

; -----------------------------------------------------------------------------
; MAIN CODE
; -----------------------------------------------------------------------------

                org     0x8000

; -----------------------------------------------------------------------------
; Initialiase the level complete and trapped variables
; -----------------------------------------------------------------------------
init
                ld      hl, dynamicVariables + DYN_VAR_LEVELS_COMPLETE
                ld      (hl), 0                                     ; Reset win count
                inc     hl
                ld      (hl), 0                                     ; Reset trap count

; -----------------------------------------------------------------------------
; Initiaise the screen by clearing the bitmap screen and attributes. Everything
; is set to 0 which is why the border colour used in the game is black to save
; some bytes ;o)
; -----------------------------------------------------------------------------
start
                ld      hl, BITMAP_SCRN_ADDR       
                ld      de, BITMAP_SCRN_ADDR + 1
                ld      bc, BITMAP_SCRN_SIZE + ATTR_SCRN_SIZE       ; Bitmap screen size + attributes size
                ld      (hl), l                                     ; L = 0 so use that to clear
                ldir                                                ; 13 bytes

; -----------------------------------------------------------------------------
; Draw playing area
; -----------------------------------------------------------------------------
drawPlayingArea
                ld      a, 20                                    
                ld      hl, ATTR_SCRN_ADDR + (3 * 32) + 1
drawRow
                push    hl
                pop     de
                inc     de
                ld      bc, ATTR_ROW_SIZE - 2
                ld      (hl), SCRN_COLOUR
                ldir
                ld      c, 3
                add     hl, bc
                dec     a  
                jr      nz, drawRow                                 ; 21 bytes

; -----------------------------------------------------------------------------
; Draw the progress bar
; -----------------------------------------------------------------------------
drawProgress
                ld      a, (dynamicVariables + DYN_VAR_LEVELS_COMPLETE) ; If the level count == 0...
                or      a                                           ; ...then don't draw the...
                jr      z, mainLoop                                 ; ...progress bar

                ld      hl, ATTR_SCRN_ADDR + (1 * 32) + 1           ; Point HL to the start of the progress bar       
drawProgressBlock
                ld      (hl), GREEN * PAPER + WHITE                 ; Paint the block
                inc     hl                                          ; Move to the right
                dec     a                                           ; Dec the level count
                jr      nz, drawProgressBlock                       ; If we are not at zero go again

                push    hl                                          ; Place an initial value on the stack
                                                                    ; to be used later when see if the ball has got trapped

; -----------------------------------------------------------------------------
; Main game loop
; -----------------------------------------------------------------------------
mainLoop                                                          

            ; -----------------------------------------------------------------------------
            ; Read the keyboard and update the players direction vector
                ld      bc, 0xdffe                                  ; Read keys YUIOP
                in      a, (c)          
            
                ld      hl, playerVector                            ; We will use HL in a few places so just load it once here
            
_checkRight                                                         ; Move player right
                rra         
                jr      c, _checkLeft                               ; If P was not pressed check O as we don't need to IN again
                ld      (hl), 0x01                                  ; P pressed so set the player vector to 0x0001
                inc     hl          
                ld      (hl), 0x00          
                jr      _movePlayer                                 ; Don't check for any more keys
            
_checkLeft                                                          ; Move player left
                rra         
                jr      c, _checkUp         
                ld      (hl), 0xff                                  ; O pressed so set the player vector to 0xffff
                inc     hl          
                ld      (hl), 0xff          
                jr      _movePlayer         
            
_checkUp                                                            ; Move player up
                ld      bc, 0xfbfe                                  ; Read keys QWERT
                in      a, (c)          
                rra         
                jr      c, _checkDown           
                ld      (hl), 0xe0                                  ; Q pressed so set the player vector to 0xfffe
                inc     hl          
                ld      (hl), 0xff          
                jr      _movePlayer         
            
_checkDown                                                          ; Move player down
                inc     b                                           ; INC B from 0xFB to 0xFD to read ASDFG
                inc     b           
                in      a, (c)          
                rra         
                jr      c, _checkEnter          
                ld      (hl), 0x20                                  ; A pressed so set the player vectory to 0x0020
                inc     hl          
                ld      (hl), 0x00          
            
_checkEnter         
                ld      bc, 0xbffe                                  ; Read keys HJKLEnter
                in      a, (c)          
                rra         
                jr      c, _movePlayer          
                jp      init                                        ; Player wants to reset to init the game

            ; -----------------------------------------------------------------------------
            ; Update the players position based on the current player vector
_movePlayer
                ld      hl, (playerAddr)                            ; Get the players location address             
                ld      (hl), BORDER_COLOUR                         ; Draw the border colour in the current location 
                ld      de, (playerVector)                          ; Get the players movement vector
                add     hl, de                                      ; Calculate the new player position address
                ld      a, BORDER_COLOUR                                         
                cp      (hl)                                        ; Compare the new location with the border colour...
                jr      z, _drawplayer                              ; ...and if it is a border block then don't save HL
                ld      (playerAddr), hl                            ; New position is not a border block so save the new position 
                
            ; -----------------------------------------------------------------------------
            ; Draw player 
_drawplayer
                ld      hl, (playerAddr)                            ; Load the players position 
                ld      (hl), PLAYER_COLOUR                         ; and draw the player

            ; -----------------------------------------------------------------------------
            ; Move the ball
_moveBall
                ld      de, xVector                                 ; We need to pass a pointer to the vector...
                ld      bc, (xVector)                               ; ...and the actual vector into the ball update routine
                call    updateBallWithVector                        ; Update the ball with the x vector

                ld      de, yVector
                ld      bc, (yVector)
                call    updateBallWithVector            

            ; -----------------------------------------------------------------------------
            ; Draw ball
_drawBall
                ld      hl, (ballAddr)                              ; Draw the ball at the...
                ld      (hl), BALL_COLOUR                           ; ...current position 

            ; -----------------------------------------------------------------------------
            ; Sync screen and slow things down to 25 fps
                halt                                    
                halt

            ; -----------------------------------------------------------------------------
            ; Erase ball
_eraseBall
                ld      (hl), SCRN_COLOUR                           ; HL is already pointing to the balls location so erase it

            ; -----------------------------------------------------------------------------
            ; Has the ball been trapped    
                pop     de                                          ; Get the previous position 
                push    hl                                          ; Save the current position 
                or      1                                           ; Clear the carry flag
                sbc     hl, de                                      ; current pos - previous pos
                ld      hl, dynamicVariables + DYN_VAR_TRAPPED_COUNT; Do this now so we don't have to do it again in the
                                                                    ; _trapped branch :)
                jp      z, _trapped                                 ; If current pos == previous pos increment the trapped counter...
                ld      (hl), 0                                     ; ...else reset the trapped counter

                jp      mainLoop                                    ; Round we go again :)

_trapped
                inc     (hl)                                        ; Up the trapped count
                ld      a, (hl)                                     ; Check to see if the trapped count...
                cp      2                                           ; ... is equal to 2
                jp      nz, mainLoop

                dec     hl                                          ; Point HL at the level pointer address
                inc     (hl)                                        ; Inc the level complete counter

                jp      start                                       ; Loop

; -----------------------------------------------------------------------------
; Update the balls position based on the vector provided
;
; DE = vector address
; BC = vector value
; -----------------------------------------------------------------------------
updateBallWithVector
                ld      hl, (ballAddr)                              ; Get the balls current position address...
                add     hl, bc                                      ; ...and calculate the new position using the vector in BC
                cp      (hl)                                        ; A already holds the border colour at this point so see if..
                jr      nz, _saveBallPos                            ; ...the new position is a border block and is not save the new pos
    
                ld      hl, 0                                       ; The new position was a border block...
                sbc     hl, bc                                      ; ...so NEG the vector in BC
                    
                ex      de, hl                                      ; Need to save the new vector so switch DE and HL
                    
                ld      (hl), e                                     ; Save the new vector back into the vector addr
                inc     hl  
                ld      (hl), d 
    
                ret                                             
_saveBallPos        
                ld      (ballAddr), hl                              ; Save the new position in HL
                ret

; -----------------------------------------------------------------------------
; Variables
; -----------------------------------------------------------------------------
playerAddr      dw      ATTR_SCRN_ADDR + (12 * 32) + 16
playerVector    dw      UP_CELL

ballAddr        dw      ATTR_SCRN_ADDR + (12 * 32) + 16
xVector         dw      LEFT_CELL
yVector         dw      DOWN_CELL

dynamicVariables        ; Points to the address in memory where we will store some dynamic variables
                ; First byte is the Levels the count of levels completed
                ; Second byte is the # frames the ball has not been able to move

                END init








