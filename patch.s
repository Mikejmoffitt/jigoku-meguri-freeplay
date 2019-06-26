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

CreditCount = $37B6

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

; Uncomment to draw the license text faster for the Japan region.
;	ORG	$018D24
;	move.w	#1, -(sp)

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
	ORG	$008408
	jmp	continue_hook_2

; Credit count drawing is conditional
	ORG	$008500
	jmp	draw_credit_count

; Insert Coin drawing is conditional
	ORG	$00859A
	jmp	draw_insert_coin

; New routines ---------------------------------------------
	ORG	ROM_FREE
	ALIGN	16
	dc.b	"BONZE FREE V1.1 "
	dc.b	"Jigoku Meguri / "
	dc.b	"Bonze Adventure "
	dc.b	"Free Play patch "
	dc.b	"       by       "
	dc.b	"Michael Moffitt "
	dc.b	" mikejmoffitt@  "
	dc.b	" gmail.com      "
	dc.b	"----------------"
	dc.b	"Use DIPSW B #8  "
	dc.b	"to enable free  "
	dc.b	"play mode. With "
	dc.b	"the switch off, "
	dc.b	"it will act as  "
	dc.b	"normal.         "
	dc.b	"----------------"
	dc.b	"Revision History"
	dc.b	"                "
	dc.b	"V1.1 -----------"
	dc.b	"Fixed critical  "
	dc.b	"error that made "
	dc.b	"the contents of "
	dc.b	"a0 get corrupt  "
	dc.b	"during attract. "
	dc.b	"                "
	dc.b	"V1.0 -----------"
	dc.b	"Initial release."

FreePlayText:
	dc.b	10, "FREE PLAY ", 0

PressStartText:
	dc.b	11, "PRESS START", 0

	ALIGN	2

; The credit count is drawn on the Press Start and Continue screens. In Free
; Play, the Press Start screen is skipped, so this only applies to the
; Continue prompt.
draw_credit_count:
	FREEPLAY
	; Draw our new "Free Play" text.
	lea	(FreePlayText).l, a1 ; Pointer to pascal-style string.
	jmp	($008506).l ; Resume normal drawing.
/	POST
	lea	($008512).l, a1 ; "CREDIT" string.
	jmp	($008506).l ; Resume drawing.

; This replaces the Insert Coin text shown on the Press Start and Attract Demo
; screens. Since the start screen is skipped in Free Play, it only applies to
; the attract sequence.
draw_insert_coin:
	FREEPLAY
	; Draw our new "Press Start" text.
	lea	(PressStartText).l, a1 ; Pointer to pascal-style string.
	lea	($C04722).l, a0 ; Destination in text layout VRAM.
	jmp	($0085BA).l ; Resume normal drawing.

/	POST
	; Check coinage settings to see if the cost is >1 coin.
	btst	#5, $B7D(a5)
	beq	.multiple_required
	btst	#7, $B7D(a5)
	beq	.multiple_required
	; If only one credit is required, draw "Insert Coin".
	jmp	($0085AA).l
.multiple_required:
	; Draw a prompt to insert coins.
	jmp	($0085C2).l

; In Free Play, this skips the subtraction of a credit once a game has begun.
continue_hook_2:
	FREEPLAY
	clr.w	CreditCount(a5)  ; Clear credit count.
	bra	post_subtract

/	POST
	subq.w	#1,CreditCount(a5)  ; Subtract 1 from the credit count.

post_subtract:
	jsr	draw_credit_count
	jmp	($008410).l

; In Free Play, the coin check
continue_hook_1:
	FREEPLAY
	jmp	$0083E8
/	POST
	tst.w	CreditCount(a5)  ; Credits in?
	beq	.no_coins
	jmp	$0083E8  ; If so, proceed to check for a button press.

.no_coins:
	rts

p2_start:
	bset	#1, $C0E(a5) ; Set P2 flag
	; Fallthrough.
p1_start:
	jsr	($00E10C).l ; Run fadeout
	; Fallthrough.
credits_in:
	jmp	($007C28).l
	
; This check originally triggered a jump to the Press Start screen if credits
; were in the machine. It now checks if start is pressed, sets the P2 flag if
; appropriate, and then proceeds to the (now mostly skipped) start screen.
coin_in_check:
	FREEPLAY
	clr.w	CreditCount(a5)  ; Clear credit count.
	bclr	#1, $C0E(a5)  ; Clear P2 flag
	move.b	($800007).l, d0  ; Read start buttons.
	btst	#6, d0  ; P1 start?
	beq	p1_start
	btst	#5, d0  ; P2 start?
	beq	p2_start
	jmp	($007C16).l

/	POST
	tst.w	CreditCount(a5)  ; Check if credits are inserted.
	bne.s	credits_in
	jmp	($007C16).l

; The Press Start screen is mostly skipped in Free Play. Variables that are
; cleared explicitly before setting up the screen are still cleared, and the
; layer clears and fade-in routine still run.
press_start_screen:
	FREEPLAY
	; Clear out some vars that it normally clears
	clr.w	CreditCount(a5) ; Clear credit count.
	move.w	#$90, $C1C(a5)
	move.w	#$A0, $C1E(a5)
	clr.w	$C0C(a5)
	clr.w	$C0A(a5)
	clr.w	$15D4(a5)
	clr.w	$C30(a5)
	move.w	#$20, $161E(a5)
	jsr	($00E776).l

	jmp	($007D32).l
/	POST
	jsr	($00973E).l	; Draw the "Press Start" prompt
	jmp	($007C4E).l	; Resume normalcy

; We've got a lot of empty ROM to mess about with.
	ALIGN	16
	dc.b	"                "
	dc.b	"    0     0     "
	dc.b	"     0   0      "
	dc.b	"    0000000     "
	dc.b	"   00 000 00    "
	dc.b	"  00000000000   "
	dc.b	"  0 0000000 0   "
	dc.b	"  0 0     0 0   "
	dc.b	"     00 00      "
	dc.b	"                "
	dc.b	"     Taito,     "
	dc.b	"Even though you "
	dc.b	"seem to hate us,"
	dc.b	" we still       "
	dc.b	"     love you   "
	dc.b	"                "
	dc.b	"    0     0     "
	dc.b	"  0  0   0  0   "
	dc.b	"  0 0000000 0   "
	dc.b	"  000 000 000   "
	dc.b	"  00000000000   "
	dc.b	"   000000000    "
	dc.b	"    0     0     "
	dc.b	"   0       0    "
	dc.b	"                "
