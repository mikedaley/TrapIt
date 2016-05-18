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



; -----------------------------------------------------------------------------
; MAIN CODE
; -----------------------------------------------------------------------------

                org     0x8000

            ; -----------------------------------------------------------------------------
            ; Init the bitmap screen and attributes
init
                ld      hl, dynamicVariables
                ld      (hl), 0                                     ; Reset win count
                inc     hl
                ld      (hl), 0                                     ; Reset trap count

start
                ld      hl, BITMAP_SCRN_ADDR       
                ld      de, BITMAP_SCRN_ADDR + 1
                ld      bc, BITMAP_SCRN_SIZE + ATTR_SCRN_SIZE       ; Bitmap screen size + attributes size
                ld      (hl), l                                     ; L = 0 so use that to clear
                ldir                                                ; 13 bytes

            ; -----------------------------------------------------------------------------
            ; Draw playing court
                ld      a, 20                                    
                ld      hl, ATTR_SCRN_ADDR + (3 * 32) + 1
drawCourt
                push    hl
                pop     de
                inc     de
                ld      bc, ATTR_ROW_SIZE - 2
                ld      (hl), SCRN_COLOUR
                ldir
                ld      c, 3
                add     hl, bc
                dec     a  
                jr      nz, drawCourt                               ; 21 bytes

            ; -----------------------------------------------------------------------------
            ; Draw the win bar 
                ld      a, (dynamicVariables)
                cp      0
                jr      z, mainLoop                

                ld      hl, ATTR_SCRN_ADDR + (1 * 32) + 1
                ld      de, ATTR_SCRN_ADDR + (1 * 32) + 2
                ld      c, a
                ld      (hl), GREEN * PAPER + WHITE
                ldir

                push    hl                              ; Place an initial value on the stack
                                                        ; to be used later when see if the ball has got trapped
mainLoop                                                          

            ; -----------------------------------------------------------------------------
            ; Player movement
                ld      bc, 0xdffe
                in      a, (c)

                ld      hl, playerVector

_checkRight                                             ; Move player right
                rra
                jr      c, _checkLeft
                ld      (hl), 0x01
                inc     hl
                ld      (hl), 0x00
                jr      _movePlayer

_checkLeft                                              ; Move player left
                rra
                jr      c, _checkUp
                ld      (hl), 0xff
                inc     hl
                ld      (hl), 0xff
                jr      _movePlayer

_checkUp                                                ; Move player up
                ld      bc, 0xfbfe
                in      a, (c)
                rra
                jr      c, _checkDown
                ld      (hl), 0xe0
                inc     hl
                ld      (hl), 0xff
                jr      _movePlayer

_checkDown                                              ; Move player down
                inc     b 
                inc     b
                in      a, (c)
                rra
                jr      c, _checkEnter
                ld      (hl), 0x20
                inc     hl
                ld      (hl), 0x00

_checkEnter
                ld      bc, 0xbffe
                in      a, (c)
                rra
                jr      c, _movePlayer
                jp      init

_movePlayer
                ld      hl, (playerAddr)
                ld      (hl), BORDER_COLOUR
                ld      de, (playerVector)
                add     hl, de
                ld      a, BORDER_COLOUR                            
                cp      (hl)         
                jr      z, _drawplayer            
                ld      (playerAddr), hl
                
            ; -----------------------------------------------------------------------------
            ; Draw player 
_drawplayer
                ld      hl, (playerAddr)
                ld      (hl), PLAYER_COLOUR

            ; -----------------------------------------------------------------------------
            ; Move the balls
_moveBall
                ld      de, xVector
                ld      bc, (xVector)
                call    updateBallWithVector
                ld      de, yVector
                ld      bc, (yVector)
                call    updateBallWithVector

            ; -----------------------------------------------------------------------------
            ; Draw ball
_drawBall
                ld      hl, (ballAddr)
                ld      (hl), BALL_COLOUR

                halt 
                halt

            ; -----------------------------------------------------------------------------
            ; Erase ball
_eraseBall
                ld      (hl), SCRN_COLOUR

            ; -----------------------------------------------------------------------------
            ; Has the ball been trapped    
                pop     de                                      ; Get the previous position 
                push    hl                                      ; Save the current position 
                or      1
                sbc     hl, de
                jp      z, _trapped
                ld      hl, dynamicVariables + 1
                ld      (hl), 0
                jp      mainLoop

_trapped
                ld      hl, dynamicVariables + 1
                inc     (hl)
                ld      a, (hl)
                cp      2
                jp      nz, mainLoop

                ld      hl, dynamicVariables
                inc     (hl)

                jp      start                                    ; Loop

; -----------------------------------------------------------------------------
; Update the balls position based on the vector provided
;
; DE = vector address
; BC = vector value
; -----------------------------------------------------------------------------
updateBallWithVector
                ld      hl, (ballAddr)
                add     hl, bc
                ld      a, BORDER_COLOUR
                cp      (hl)
                jr      nz, _saveBallPos

                ld      hl, 0
                sbc     hl, bc
                
                ex      de, hl
                
                ld      (hl), e
                inc     hl
                ld      (hl), d

                ret
_saveBallPos     
                ld      (ballAddr), hl
                ret

; -----------------------------------------------------------------------------
; Variables
; -----------------------------------------------------------------------------
; courtAddr       dw      ATTR_COURT_START

playerAddr      dw      ATTR_SCRN_ADDR + (12 * 32) + 16
playerVector    dw      UP_CELL

ballAddr        dw      ATTR_SCRN_ADDR + (12 * 32) + 16
xVector         dw      LEFT_CELL
yVector         dw      DOWN_CELL

dynamicVariables

                END init








