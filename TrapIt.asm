; -----------------------------------------------------------------------------
; TRAPIT - Mike Daley
;
; Started:  12th May 2016
; Finished: 
;
; The idea of this game is to freeze sections of the playing area by drawing a
; vertical or horizontal line which devides the screen. If the ball hits the
; line which it is being drawn then the player looses a life.
;
; To win the game you need to either freeze 75%+ of the playing area, or trap
; the ball in a frozen area.
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

ATTR_COURT_START        equ             ATTR_SCRN_ADDR + (3 * 32) + 1
ATTR_COURT_ROWS         equ             0x16

ATTR_ROW_24_ADDR        equ             0x5ae0
ATTR_SIDE_BORDER_ADDR   equ             0x583f

COLUMNS                 equ             0x20
ROWS                    equ             0x18

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
BORDER_COLOUR           equ             BLACK * PAPER

SCRN_TOP_CELL           equ             0x00
SCRN_BOTTOM_CELL        equ             0x18
SCRN_LEFT_CELL          equ             0x00
SCRN_RIGHT_CELL         equ             0x20

UP_CELL                 equ             0xffe0
DOWN_CELL               equ             0x0020
LEFT_CELL               equ             0xffff
RIGHT_CELL              equ             0x0001               

LEVELS_COMPLETE_ADDR    equ             0x7daa
FROZEN_COUNT_ADDR       equ             0x7dab

; -----------------------------------------------------------------------------
; MAIN CODE
; -----------------------------------------------------------------------------

                org     0x8000

            ; -----------------------------------------------------------------------------
            ; Init the bitmap screen and attributes
init
                ld      hl, LEVELS_COMPLETE_ADDR
                ld      (hl), 0                                     ; Reset win count
                inc     hl
                ld      (hl), 0                                     ; Reset frozen count

start

                ld      hl, BITMAP_SCRN_ADDR       
                ld      de, BITMAP_SCRN_ADDR + 1
                ld      bc, BITMAP_SCRN_SIZE + ATTR_SCRN_SIZE       ; Bitmap screen size + attributes size
                ld      (hl), l                                     ; L = 0 so use that to clear
                ldir                                                ; 13 bytes

            ; -----------------------------------------------------------------------------
            ; Draw playing court
                ld      a, 20                                    
                ld      hl, ATTR_COURT_START
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
                ld      a, (LEVELS_COMPLETE_ADDR)
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
                ld      hl, FROZEN_COUNT_ADDR
                ld      (hl), 0
                jp      mainLoop

_trapped
                ld      hl, FROZEN_COUNT_ADDR
                inc     (hl)
                ld      a, (hl)
                cp      2
                jp      nz, mainLoop

                ld      hl, LEVELS_COMPLETE_ADDR
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

                END init








