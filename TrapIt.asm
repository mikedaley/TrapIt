; ----------------------------------------------------------------------------------------------------------------------------------------------------------
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
; This is an entry for the 256byte game challenge on the Z80 Assembly programming
; on the ZX Spectrum Facebook Group https://www.facebook.com/groups/z80asm/
; ----------------------------------------------------------------------------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------------------------------------------------------------------------
; CONSTANTS
; ----------------------------------------------------------------------------------------------------------------------------------------------------------

BITMAP_SCRN_ADDR        equ             16384
BITMAP_SCRN_SIZE        equ             6144
ATTR_SCRN_ADDR          equ             22528
ATTR_SCRN_SIZE          equ             768
COLUMNS                 equ             32
ROWS                    equ             24

BLACK                   equ             0
BLUE                    equ             1
RED                     equ             2
MAGENTA                 equ             3
GREEN                   equ             4
CYAN                    equ             5
YELLOW                  equ             6
WHITE                   equ             7
PAPER                   equ             8               ; Multiply with inks to get paper colour
BRIGHT                  equ             64
FLASH                   equ             128             ; e.g. ATTR = BLACK * PAPER + CYAN + BRIGHT

BALL_COLOUR             equ             BLUE * PAPER + BRIGHT
SCRN_COLOUR             equ             BLACK * PAPER + WHITE
FREEZE_COLOUR           equ             GREEN * PAPER + BLACK

SCRN_TOP_CELL           equ             1
SCRN_BOTTOM_CELL        equ             23
SCRN_LEFT_CELL          equ             1
SCRN_RIGHT_CELL         equ             31

MAX_FREEZE_COUNT        equ             576             ; 75% of 768 screen cells
; ----------------------------------------------------------------------------------------------------------------------------------------------------------

                org     32768

start
                ld      a, MAGENTA                      ; Set the border to black
                out     (254), a

                ld      hl, BITMAP_SCRN_ADDR            ; Clear the screen file
                ld      de, BITMAP_SCRN_ADDR + 1
                ld      bc, BITMAP_SCRN_SIZE
                ld      a, 0
                ld      (hl), a
                ldir
                ld      bc, ATTR_SCRN_SIZE              ; Set the initial attribute values
                ld      a, SCRN_COLOUR
                ld      (hl), a
                ldir

                ld      de, 0x050c
                call    getAttrAddr
                push    hl
                pop     de
                inc     de
                ld      a, FREEZE_COLOUR
                ld      (hl), a 
                ld      bc, 25
                ldir

mainLoop
                ; Move ball
                ld      a, (ballYPos)
                ld      b, a
                ld      a, (yDir)
                add     a, b
                ld      (ballYPos), a

                cp      SCRN_TOP_CELL
                jp      c, _bounceY
                cp      SCRN_BOTTOM_CELL
                jp      nc, _bounceY
                jp      nz, _checkXPos      
_bounceY
                ld      a, (yDir)
                neg
                ld      (yDir), a

_checkXPos
                ld      a, (ballXPos)
                ld      b, a
                ld      a, (xDir)
                add     a, b
                ld      (ballXPos), a

                cp      SCRN_LEFT_CELL
                jp      c, _bounceX
                cp      SCRN_RIGHT_CELL
                jp      nc, _bounceX
                jp      nz, _drawBall      
_bounceX
                ld      a, (xDir)
                neg
                ld      (xDir), a


_drawBall       ; Draw ball
                ld      de, (ballYPos)
                call    getAttrAddr
                ld      (hl), BALL_COLOUR

                ; Screen sync
                halt
                halt
                halt
                halt

                ; Erase ball
                ld      (hl), SCRN_COLOUR

                jp      mainLoop                        ; Loop

                    
; ----------------------------------------------------------------------------------------------------------------------------------------------------------
; Convert a cell x, y location into an attribute screen address
; 
; Entry Registers:
;   DE = Cell X, Cell Y
; Used Registers:
;   B, C, D, E, H, L
; Returned Registers:
;   HL = Attribute address
; ----------------------------------------------------------------------------------------------------------------------------------------------------------
getAttrAddr
                ld      l, e                        ; Get the cell Y pos
                ld      h, 0 

                add     hl, hl                      ; Multiply the Y position by 32
                add     hl, hl
                add     hl, hl
                add     hl, hl
                add     hl, hl

                ld      c, d                        ; Get the cell X pos
                ld      b, 0
                add     hl, bc                      

                ld      de, ATTR_SCRN_ADDR 
                add     hl, de

                ret

; ----------------------------------------------------------------------------------------------------------------------------------------------------------
; Variables
; ----------------------------------------------------------------------------------------------------------------------------------------------------------
ballYPos        db      12
ballXPos        db      16 
yDir            db      1         
xDir            db      1


                END start