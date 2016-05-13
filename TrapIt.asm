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

ATTR_PLAY_ZONE_START    equ             0x5821
ATTR_PLAY_ZONE_ROWS     equ             0x17

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

BAT_COLOUR              equ             BLUE * PAPER + BRIGHT
BALL_COLOUR             equ             RED * PAPER + WHITE
SCRN_COLOUR             equ             WHITE * PAPER + BLACK
BORDER_COLOUR           equ             BLACK * PAPER + BRIGHT

SCRN_TOP_CELL           equ             0x00
SCRN_BOTTOM_CELL        equ             0x18
SCRN_LEFT_CELL          equ             0x00
SCRN_RIGHT_CELL         equ             0x20

UP_CELL                 equ             0xffe0
DOWN_CELL               equ             0x20
LEFT_CELL               equ             0xffff
RIGHT_CELL              equ             0x01               

; -----------------------------------------------------------------------------
; MAIN CODE
; -----------------------------------------------------------------------------

                org     0x8000

start
                ld      hl, BITMAP_SCRN_ADDR                        ; Clear the screen file & Attributes
                ld      de, BITMAP_SCRN_ADDR + 1
                ld      bc, BITMAP_SCRN_SIZE                        ; Bitmap screen size + attributes size
                ld      (hl), l                                     ; L = 0 so use that to clear
                ldir

                ld      (hl), BORDER_COLOUR                         ; Draw the top border using bright black background
                ld      bc, ATTR_ROW_SIZE + 1
                ldir

                ld      hl, ATTR_ROW_24_ADDR                        ; Draw bottom border
                ld      de, ATTR_ROW_24_ADDR + 1                
                ld      bc, ATTR_ROW_SIZE
                ld      (hl), BORDER_COLOUR
                ldir

                ld      b, 23                                       ; Draw side borders
                ld      hl, ATTR_SIDE_BORDER_ADDR
                ld      de, 0x1f
drawSides   
                ld      (hl), BORDER_COLOUR
                inc     hl
                ld      (hl), BORDER_COLOUR
                add     hl, de
                djnz    drawSides

mainLoop                                                            ; Main game loop
                
                ld      hl, (ballAddr)
                ld      de, (xVector)
                add     hl, de
                ld      a, BORDER_COLOUR
                cp      (hl)
                jp      nz, _updateXVector
                

_updateXVector
                ld      (ballAddr), hl

                ld      hl, (ballAddr)
                ld      (hl), BALL_COLOUR

                halt 

                ld      hl, (ballAddr)
                ld      (hl), SCRN_COLOUR

                jp      mainLoop                                    ; Loop

ballAddr        dw      ATTR_SCRN_ADDR + (12 * 32) + 16
xVector         dw      LEFT_CELL
yVector         dw      DOWN_CELL

                END start