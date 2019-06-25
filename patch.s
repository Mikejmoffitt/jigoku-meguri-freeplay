; Free Play
	CPU 68000
	PADDING OFF
	ORG		$000000
	BINCLUDE	"prg.orig"

RAM_BASE = $100000
WRAM_BASE = RAM_BASE + $C000
CREDIT_COUNT = RAM_BASE + $00F7B6

ROM_FREE = $000200

DSW1_LOC = RAM_BASE + $00CB7C
DSW2_LOC = RAM_BASE + $00CB7E

COINSW_LOC = RAM_BASE + $00F7C0


; Free play is DSW2_LOC & $80 == 0.
FREEPLAY_MASK = $0080

	ORG	$000000

; Macro for checking free play ----------------------------------------------
FREEPLAY macro
	move.l	d1, -(sp)
	move.w	(DSW2_LOC).l, d1
	andi.w	#FREEPLAY_MASK, d1
	beq	.freeplay_is_enabled
	bra	+ ; Jump to anonymous label in user code

.freeplay_is_enabled:
	move.l (sp)+, d1
	ENDM

POST macro
	move.l (sp)+, d1
	ENDM

; Non free play shit ----------------------------------

; Set the region.
; 0 - Japan
; 1 - World
; 2 - USA
	ORG	$03FFFE
	dc.w	$0000

; Disable checksum.
	ORG	$007504
	rts

; Free play shit --------------------------------------------

; Bypass credit check with start button check if applicable
	ORG	$007C10
	jmp	coin_in_check

; Bypass most of the Press Start screen
	ORG	$007C48
	jmp	press_start_screen

; Continue: Allow checking start buttons even with no coins.
	ORG	$0083E0
	jmp	continue_hook_1

; Continue: Don't subtract a credit without coins.
	ORG	$8408
	jmp	continue_hook_2

; Credit count drawing is conditional
	ORG	$008500
	jmp	draw_credit_count

; Insert Coin drawing is conditional
	ORG	$00859A
	jmp	draw_insert_coin

; New routines ---------------------------------------------
FreePlayText:
	dc.b	10, "FREE PLAY ", 0

PressStartText:
	dc.b	11, "PRESS START", 0

	ALIGN	2

draw_credit_count:
	FREEPLAY
	lea	(FreePlayText).l, a1
	jmp	($008506).l
/	POST
	lea	($008512).l, a1
	jmp	($008506).l

draw_insert_coin:
	FREEPLAY
	lea	(PressStartText).l, a1
	lea	($C04722).l, a0
	jmp	($0085BA).l

/	POST
	btst	#5, $B7D(a5)
	beq	.multiple_required
	btst	#7, $B7D(a5)
	beq	.multiple_required
	jmp	($0085AA).l
.multiple_required:
	jmp	($0085C2).l

continue_hook_2:
	FREEPLAY
	clr.w	$37B6(a0) ; Clear credit count.
	bra	post_subtract

/	POST
	subq.w	#1,$37B6(a5)

post_subtract:
	jsr	draw_credit_count
	jmp	($008410).l

continue_hook_1:
	FREEPLAY
	jmp	$0083E8
/	POST
	tst.w	$0037B6(a5)
	beq	.no_coins
	jmp	$0083E8

.no_coins:
	rts

press_start_screen:
	FREEPLAY
	; Clear out some vars that it normally clears
	clr.w	$37B6(a0) ; Clear credit count.
	move.w	#$90, $C1C(a5)
	move.w	#$A0, $C1E(a5)
	clr.w	$C0C(a5)
	clr.w	$C0A(a5)
	clr.w	$15D4(a5)
	clr.w	$C30(a5)
	move.w	#$20, $161E(a5)

	jmp	$007D32
/	POST
	jsr	($00973E).l	; Draw the "Press Start" prompt
	jmp	($007C4E).l	; Resume normalcy

p1_start:
	jsr	($00E10C).l ; Run fadeout
	bra	credits_in
p2_start:
	jsr	($00E10C).l ; Run fadeout
	bset	#1, $C0E(a5) ; Set P2 flag
credits_in:
	jmp	($007C28).l
coin_in_check:
	FREEPLAY
	clr.w	$37B6(a0) ; Clear credit count.
	bclr	#1, $C0E(a5) ; Clear P2 flag
	move.b	($800007).l, d0
	btst	#6, d0
	beq	p1_start
	btst	#5, d0
	beq	p2_start
	jmp	($007C16).l

/	POST
	tst.w	$37B6(a5)
	bne.s	credits_in
	jmp	($007C16).l
