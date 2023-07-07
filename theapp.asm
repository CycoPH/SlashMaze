* = $2000
	.bank
RTCLOK60 = $14 ; incremented every jiffy/frame.
SDLSTL = $0230 ; DLISTL
SDLSTH = $0231 ; DLISTH
CHBAS = $02F4 ; CHBASE
DL_LMS =     ~01000000 ; Enable Reload Memory Scan address for this graphics line
DL_TEXT_2 = $02 ; 1.5 Color, 40 Columns X 8 Scan lines, 40 bytes/line

COLOR2 =  $02C6 ; COLPF2 - Playfield 2 color

seed = $80
drawLeft = $84
drawRight = $86
lineNr = $88
XPos = $89

FROM = $8A
TO = $8C
SIZEL = $8E
SIZEH = $8F

Font:
	.BYTE 0,0,0,0,0,0,0,0
	.BYTE 255,254,253,250,245,234,213,170
	.BYTE 0,128,64,160,80,168,84,170
	.BYTE 85,171,87,175,95,191,127,255
	.BYTE 85,42,21,10,5,2,1,0
	.BYTE 0,0,0,0,0,0,0,0

DisplayList:
	.byte $70,$70,$70       	; 24 blank lines
	.byte DL_LMS|DL_TEXT_2, 	;
	.byte <Screen, >Screen
	.byte DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2
	.byte DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2,DL_TEXT_2
	.byte DL_TEXT_2,DL_TEXT_2,DL_TEXT_2
	.byte $41,<DisplayList,>DisplayList 	; JVB ends display list

POS: .byte 1,2
NEG: .byte 3,4


rand:   .byte $B5,$B5,$B4,$B4

	.local
WaitForVBI
	lda RTCLOK60
?wait
	cmp RTCLOK60
	beq ?wait
	rts

_rand:  clc
        lda     rand+0
        adc     #$B3
        sta     rand+0
        adc     rand+1
        sta     rand+1
        adc     rand+2
        sta     rand+2
        eor     rand+0
        and     #$7f            ; Suppress sign bit (make it positive)
        tax
        lda     rand+2
        adc     rand+3
        sta     rand+3
        eor     rand+1
        rts                     ; return bit (16-22,24-31) in (X,A)	

OneLine:
	lda #0
	sta XPos
nextOne:
	; top
	jsr _rand
	and #1
	tay
	lda POS,y
	ldy XPos
	sta (drawLeft),Y

	; bottom
	jsr _rand
	and #1
	tay
	lda NEG,y
	ldy XPos
	sta (drawRight),Y

	inc XPos

	; top
	jsr _rand
	and #1
	tay
	lda NEG,y
	ldy XPos
	sta (drawLeft),Y

	; bottom
	jsr _rand
	and #1
	tay
	lda POS,y
	ldy XPos
	sta (drawRight),Y

	inc XPos

	lda XPos
	cmp #40
	bne nextOne

	rts

MOVEDOWN LDY #0
         LDX SIZEH
         BEQ MD2
MD1      LDA (FROM),Y ; move a page at a time
         STA (TO),Y
         INY
         BNE MD1
         INC FROM+1
         INC TO+1
         DEX
         BNE MD1
MD2      LDX SIZEL
         BEQ MD4
MD3      LDA (FROM),Y ; move the remaining bytes
         STA (TO),Y
         INY
         DEX
         BNE MD3
MD4      RTS


BOOT_THIS:
	lda #>Font			; Font of the GUI
	sta CHBAS

	; Setup display list in shadow reg, VBI will activate it
	lda #<DisplayList
	sta SDLSTL
	lda #>DisplayList
	sta SDLSTL+1

	lda #0
	sta COLOR2

	jsr WaitForVBI

	lda #1
	sta seed
	sta seed+1
	lda #2
	sta seed+2
	sta seed+3

	lda #<[screen+22*40]
	sta drawLeft
	lda #>[screen+22*40]
	sta drawLeft+1

	lda #<[screen+23*40]
	sta drawRight
	lda #>[screen+23*40]
	sta drawRight+1

Restart:
	jsr OneLine

	lda #<screen
	sta TO
	lda #>screen
	sta TO+1

	lda #<[screen+80]
	sta FROM
	lda #>[screen+80]
	sta FROM+1

	lda #<960
	sta SIZEL
	lda #>960
	sta SIZEH

	ldx #10
WaitSomeMore:
	jsr WaitForVBI
	dex
	bne WaitSomeMore

	jsr MOVEDOWN


	jmp Restart

Screen:
	

	.bank
	* = $2e0 "Boot vector"
	.word BOOT_THIS	