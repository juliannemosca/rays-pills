	!cpu 6502
	!to "rays-pills.prg",cbm
	!sl "rays-pills-labels"

	; colors
	col_orange	= $08
	col_black	= $00
	col_purple	= $04
	col_pink	= $0a
	col_white	= $01

	col_blue	= $06
	col_light_blue = $0e

	; border limits
	border_left		= $18
	border_right 	= $40
	border_top		= $32

	sp_pos_top		= $47
	sp_pos_bottom	= $cf ;$da

	sp0_title_pos_x = $60
	sp1_title_pos_x = $e8
	spx_title_pos_y = $74

	; dir. values
	dir_l_to_r = $00
	dir_r_to_l = $01

	; misc
	backgr_color_reg_0 	= $d021
	border_color_reg 	= $d020

	;head_dir			= $c304
	;pill_dir			= $c305
	;pill_launched		= $c306
	;delay_counter		= $c307
	;delay_counter_times	= $c308
	;score				= $c309
	;pills_left			= $c30a
	
	;save_a				= $c30c
	;save_y				= $c30d
	;save_x				= $c30e

	printch_zp			= $fb
	printch_screen		= $c30f
	printch_char		= $c30b

	delay_counter_until			= $ff
	delay_counter_times_until	= $01
	max_num_pills				= $0a

	; sprite addrs
	sprite0_ptr = $07f8
	sprite1_ptr = $07f9
	enable		= $d015
	color0		= $d027
	color1		= $d028
	sp0x		= $d000
	sp0y		= $d001
	sp1x		= $d002
	sp1y		= $d003
	msbx		= $d010
	collision	= $d01e

	; kernal funcs
	clear_screen	= $e544

;------------------------------
; loader for BASIC:
;------------------------------

	*= $0801

	!8 $0d,$08,$d9,$07,$9e,$20
	;!8 $34,$39,$31,$35,$32 ; 49152 ($c000)
	;!8 $39,$32,$33,$37 ; 9237 ($2415)
	!8 $33,$32,$38,$38 ; 3288 ($0cd8)
	!8 $00,$00,$00

end_loader
;------------------------------

head_dir			!8	0; = $c304
pill_dir			!8	0; = $c305
pill_launched		!8	0; = $c306
delay_counter		!8	0; = $c307
delay_counter_times	!8	0; = $c308
score				!8	0; = $c309
pills_left			!8	0; = $c30a
	
save_a				!8	0; = $c30c
save_y				!8	0; = $c30d
save_x				!8	0; = $c30e

digits		!8	48,48,48,0
tb1sub		!8	100,10,1
zerofl		!8	0

;------------------------------
; graphics data:
;------------------------------

	;*= $2000
	*=	$0880

head_data
	!8	0,126,0
	!8	3,255,192
	!8	7,255,224
	!8	31,255,248
	!8	30,59,216
	!8	60,157,188
	!8	121,206,126
	!8	120,142,126
	!8	252,29,191
	!8	254,59,223
	!8	255,255,255
	!8	252,255,191
	!8	252,0,31
	!8	124,15,30
	!8	126,52,190
	!8	63,34,124
	!8	31,242,120
	!8	31,242,120
	!8	7,240,240
	!8	3,251,192
	!8	0,126,0

	;*= $2040
	*= $08c0
pill_data
	!8	0,0,0
	!8	0,0,0
	!8	0,0,0
	!8	0,0,0
	!8	0,60,0
	!8	0,126,0
	!8	0,255,0
	!8	0,255,0
	!8	0,255,0
	!8	0,255,0
	!8	0,255,0
	!8	0,195,0
	!8	0,195,0
	!8	0,195,0
	!8	0,195,0
	!8	0,102,0
	!8	0,60,0
	!8	0,0,0
	!8	0,0,0
	!8	0,0,0
	!8	0,0,0

	;*= $2080
	*= $0900

str_rays_pills_title 	!scr "ray's pills", 0
str_rays_pills_title_2 	!scr "press  spacebar to start", 0
str_score_line			!scr "score:    ", 0
str_pills_left			!scr "pills left:    ", 0
str_game_over			!scr "game  over", 0
str_game_over_score		!scr "your score was    out of    ", 0
str_game_over_loose		!scr "you must do better!!!", 0
str_game_over_win		!scr "you won! enjoy your victory!!", 0
str_play_again			!scr "do you want to play again? (y/n)", 0

;------------------------------
; macros:
;------------------------------

!macro reset_pill_sprite {

	ldx		#dir_r_to_l
	stx		pill_dir

	ldx		#border_right
	stx		sp1x

	ldx		#sp_pos_bottom
	stx		sp1y

	ldx		#$00
	stx		pill_launched
}

!macro output_string .outstr, .chmem, .colmem {

	; string output loop:
	ldx 	#0
	jmp		.__output_string_loop_a

.__output_string_loop_b

	; output character:
	sta		.chmem,x
	lda		#col_white
	sta		.colmem,x

	inx		; advance pointer

.__output_string_loop_a

	lda 	.outstr,x					; get character
	bne 	.__output_string_loop_b 	; check if last
}

!macro output_num .scrmemlo, .scrmemhi, .offset, .numcharaddr {

	ldx		#.scrmemlo
	stx		printch_zp
	ldx		#.scrmemhi
	stx		printch_zp + 1

	ldx		#.offset ; offset from above screen memory location
	stx		printch_screen
	lda		.numcharaddr
	jsr		bytasc
}

!macro show_score {
	+output_string str_score_line, $079a, $db9a
	+output_num $9a, $07, $07, score
}

!macro show_pills_left {
	+output_string str_pills_left, $07b1, $dbb1
	+output_num $b1, $07, $0c, pills_left
}

;------------------------------
; check keyboard input subr.:
;
; sets Y if spacebar is pressed
; sets X if 'Y' is pressed
; un-sets A (A = 0) if 'N' is pressed
;------------------------------

check_keyboard_input

	pra 	= $dc00	; port A cia
	prb 	= $dc01	; port B cia
	ddra 	= $dc02	; port A data direction reg.
	ddrb 	= $dc03	; port B data direction reg.

	; set port A to output
	lda 	#%11111111 
	sta 	ddra             

	; set port B to input
	lda 	#%00000000
	sta 	ddrb             

	; check for spacebar:
	;
	lda 	#%01111111 ; space key is in row 7
	sta 	pra

	lda 	prb
	and 	#%00010000 ; check for space key in col 4 
	beq		__cki_spacebar_key_pressed
	ldy		#$00
	jmp		__cki_check_y_key

__cki_spacebar_key_pressed
	ldy		#$ff

__cki_check_y_key
	; check for 'Y':
	;
	lda 	#%11110111 ; 'y' key is in row 3
	sta 	pra

	lda 	prb
	and 	#%00000010 ; check for 'y' key in col 1 
	beq		__cki_y_key_pressed
	ldx		#$00
	jmp		__cki_check_n_key

__cki_y_key_pressed
	ldx		#$ff

__cki_check_n_key
	; check for 'N':
	;
	lda 	#%11101111 ; 'n' key is in row 4
	sta 	pra

	lda 	prb
	and 	#%10000000 ; check for 'n' key in col 7
	beq		__cki_n_key_pressed
	lda		#$ff
	jmp		__cki_end

__cki_n_key_pressed
	lda		#$00

__cki_end
	rts

;------------------------------
; printch.:
;
; this subr. outputs the character stored in printch_char
; to the screen memory location stored in printch_zp and
; printch_zp + 1, plus an offset specified in printch_screen.
;
;
;------------------------------

printch

	col_mem_offset = $d400

	sty		save_y
	stx		save_x

	ldy		printch_screen

	; write char to screen memory
	lda		printch_char
	sta		(printch_zp),y

	; calculate color offset and save in zero page
	lda		printch_zp
	ldx		printch_zp + 1
	clc
	adc		#<col_mem_offset
	sta		printch_zp+2
	txa
	adc		#>col_mem_offset
	sta		printch_zp+3

	; write to color memory
	lda		#col_white
	sta		(printch_zp+2),y

	; increment position for next character
	iny
	sty		printch_screen

	ldy		save_y
	ldx		save_x

	rts

;------------------------------
; bytasc subr.:
;------------------------------

bytasc

	ldx		#48

	stx		digits
	stx		digits+1
	stx		digits+2
	ldy		#0			; as an index
	sty		zerofl		; initialize zerofl
.nmloop
	ldx		digits,y	; load with ASCII counter for a particular
						; digit's place
	beq		.done		; if we've reached the last digit's place, go
						; print the number
	sec
.sublop
	sbc		tb1sub,y	; substract corresponding table value from .A
	inx					; increment ASCII counter for a particular
						; digit's place
	bcs		.sublop		; if .A is still zero or above
	adc		tb1sub,y	; we substracted one time too many, so add
						; subtrahend back to .A
	dex					; since one time too many
	pha					; temporarily save .A
	txa
	sta		digits,y	; store respective digit to place-holder table
	pla					; restire .A
	iny					; for next digit's place
	bne 	.nmloop		; branch always
.done
	ldy		#255		; as index in the number
.prtlop
	iny					; start with first digit
	lda		digits,y
	beq		.out		; if we're at the end of the table, leave routine
	ldx		zerofl		; check zerofl to see if a nonzero digit
						; has been printed
	bne		.print		; if so, go print the digit
	cmp		#48			; check for leading zeros
	beq		.prtlop		; if leading zero occurs, get the next digit
	sta		zerofl		; store nonzero digit
.print
	sta		printch_char	; print each digit
	jsr		printch

	jmp		.prtlop		; and go to next place
.out
	lda		zerofl		; determine if the number is 000
	bne		.exit		; if not, then return
	lda		#48			; print a zero

	sta		printch_char
	jsr		printch
.exit
	rts					; we're finished

;------------------------------
; screen initialization:
;------------------------------

init_screen

	jsr		clear_screen
	ldx		#col_black
	stx		backgr_color_reg_0
	ldx		#col_purple
	stx		border_color_reg

	rts

;------------------------------
; title screen:
;------------------------------

title_screen

	+output_string str_rays_pills_title, $0576, $d976
	+output_string str_rays_pills_title_2, $0778, $db78

	ldx		#$00
	stx		msbx

	ldx		#sp0_title_pos_x
	stx		sp0x

	ldx		#spx_title_pos_y
	stx		sp0y

	ldx		#sp1_title_pos_x
	stx		sp1x

	ldx		#spx_title_pos_y
	stx		sp1y

__title_screen_wait
	; now wait for user input
	jsr		check_keyboard_input
	cpy		#$00
	beq		__title_screen_wait

 	; and wait until key is not pressed anymore
__title_screen_wait_2
 	jsr		check_keyboard_input
	cpy		#$00
	bne		__title_screen_wait_2

	jsr		clear_screen
	rts

;------------------------------
; MUSIC routines and data
;------------------------------

	irqvec	= 788				; ($0314) vector to IRQ interrupt routine
	irq_kernal_isr = $ea31		; kernal's interrupt service routine
								; (59953), 64101 on the 128

	frelo1	= 54272				; starting address for the SID chip
	frehi1	= 54273				; voice 1 high frequency
	vcreg1	= 54276				; voice 1 control register
	atdcy1	= 54277				; voice 1 attack/decay
	surel1	= 54278				; voice 1 sustain/release
	sigvol	= 54296				; SID chip volume register

;=======================================
; intmus_reset: reset the irq vector to its default
;   and clear the SID chip
;=======================================
intmus_reset
	sei
	lda		#<irq_kernal_isr
	sta		irqvec
	lda		#>irq_kernal_isr
	sta		irqvec + 1
	jsr		sidclr
	cli
	rts

;=======================================
; intmus:
;
;   set up an IRQ interrupt to play
; background music
;=======================================
intmus	

	sei							; disable IRQ interrupts to change	
								; the vector
	lda		#<music_main		; store the low byte of the IRQ wedge
	sta		irqvec				;
	lda		#>music_main		; and the high byte
	sta		irqvec + 1	
	lda		#0
	sta		notenm				; set pointer to first note in table	
	jsr		sidclr				; clear the SID chip
	lda		#15					; set the volume to maximum
	sta		sigvol
	lda		#$1a				; set attack/decay
	sta		atdcy1
	lda		#1
	sta		durate				; initialize duration counter for first pass	
	cli							; with vector changed, reenable IRQ
								; interrupts
	rts

;=======================================
; music_main:
;
;   the interrupt handler routine we installed
; with `intmus`. this is what actually plays
; the music
;=======================================
music_main
	dec		durate				; see if current note has finished playing
	bne		exit				; if not, allow it to finish
	ldx		notenm				; index to `notes`
	lda		ndurtb,x			; get the note's duration from a table
	asl							; multiply by 8 so each note lasts eight times
								; longer
	asl
	asl	
	sta		durate				; and store it into the counter
	lda		notes,x				; get index for `freqtb`
	asl							; double it since `freqtb` contains two-byte 
								; addresses
	tax							; to index `freqtb`
	lda		freqtb,x			; get low byte of note's frequency
	sta		frelo1				; store it in voice 1
	lda		freqtb+1,x			; get high byte of note's frequency
	sta		frehi1				; store it in voice 1
	lda		#%00100000			; ungate sawtooth waveform
	sta		vcreg1
	lda		#%00100001			; gate waveform
	sta		vcreg1
	inc		notenm				; increase note counter
	lda		notenm
	cmp		#nmnote				; determine if all notes have played
	bcc		exit				; if not, then continue
	lda		#0
	sta		notenm				; if yes, start again with first note
exit
	jmp		irq_kernal_isr		; exit through normal IRQ interrupt handler

;============================

notes

	; indexes
	mn_0	= 0
	mn_D2	= 1
	mn_A2	= 2
	mn_C3	= 3
	mn_D3	= 4
	mn_E3	= 5
	mn_F3	= 6
	mn_G3	= 7
	mn_A3	= 8
	mn_Bb3	= 9
	mn_C4	= 10
	mn_D4	= 11


	; table of note indexes

	!8		mn_D3, mn_E3
	!8		mn_F3, mn_E3, mn_D3, mn_D3, mn_E3
	!8		mn_F3, mn_A3, mn_E3, mn_F3, mn_D3, mn_D3, mn_E3
	!8		mn_F3, mn_E3, mn_D3, mn_D3, mn_E3
	!8		mn_F3, mn_A3, mn_E3, mn_F3, mn_D3, mn_0

	!8		mn_A3, mn_A3, mn_A3, mn_Bb3, mn_A3, mn_G3, mn_E3, mn_F3
	!8		mn_G3, mn_G3, mn_G3, mn_A3 , mn_G3, mn_F3, mn_D3, mn_E3
	!8		mn_F3, mn_F3, mn_F3, mn_G3 , mn_F3, mn_E3, mn_D3, mn_E3
	!8		mn_F3, mn_E3, mn_E3, mn_D3 , mn_0

	!8		mn_A3, mn_A3, mn_F3, mn_G3, mn_G3, mn_E3, mn_D3, mn_C3
	!8		mn_F3, mn_A3, mn_C4, mn_D4, mn_C4, mn_D4, mn_C4, mn_A3,mn_G3
	!8		mn_A3, mn_A3, mn_F3, mn_G3, mn_A3, mn_G3, mn_E3, mn_D3,mn_C3
	!8		mn_F3, mn_A3, mn_F3, mn_G3, mn_A3, mn_F3, mn_0,  mn_A3

	!8		mn_D2, mn_0 , mn_A2, mn_0 , mn_D2, mn_0 , mn_A2, mn_0
	!8		mn_D2, mn_0 , mn_A2, mn_0 , mn_D2, mn_0 , mn_A2, mn_0
	!8		mn_D2, mn_0 , mn_A2, mn_0 , mn_D2, mn_0 , mn_A2, mn_0
	!8		mn_D2, mn_0 , mn_A2, mn_0

	; number of notes
	nmnote	= * - notes

ndurtb
	; table of note durations
	!8		2,2,4,4,4,2,2,2,2,2,2,4
	!8		2,2,4,4,4,2,2,2,2,2,2,4,4
	!8		2,2,2,2,2,2,2,2
	!8		2,2,2,2,2,2,2,2
	!8		2,2,2,2,2,2,2,2
	!8		4,2,2,4,4
	!8		8,6,2,4,3,1,4,4
	!8		4,4,4,4,4,4,2,2,4
	!8		8,6,2,3,1,2,2,4,4
	!8		4,2,2,4,4,8,4,4
	!8		1,1,1,1,1,1,1,1
	!8		1,1,1,1,1,1,1,1
	!8		1,1,1,1,1,1,1,1
	!8		1,1,1,1

freqtb
	; table of two-byte frequency values
	;	-  d2    a2    c3    d3    e3    f3    g3    a3    Bb3   c4    d4
	!wo 0, 1204, 1804, 2145, 2408, 2703, 2864, 3215, 3608, 3823, 4291, 4817

durate
	; duration counter
	!8		0
notenm
	; note number counter
	!8		0

;------------------------------
; other sound effects:
;------------------------------

sound_miss
	sound_miss_jifflo	= 162	; low byte of jiffy clock
	sound_miss_njiffies = 2		; n of jiffies for delay

	jsr		sidclr				; clear the SID chip
	lda		#15					; set volume
	sta		sigvol
	lda		#$0c				; set attack/decay
	sta		atdcy1
	lda		#$18				; set sustain/release
	sta		surel1
	lda		#0					; set voice 1 low frequency
	sta		frelo1
	lda		#24					; set voice 1 high frequency
	sta		frehi1
	lda		#%10000001			; select noise waveform and gate sound
	sta		vcreg1
	lda		#sound_miss_njiffies; cause delay of n jiffies
	adc		sound_miss_jifflo	; add current jiffy reading
sound_miss_delay
	cmp		sound_miss_jifflo	; and wait for n jiffies to elapse
	bne		sound_miss_delay
	lda		#%10000000			; ungate sound
	sta		vcreg1
	rts

;------------------------------

; sound hit

sound_hit_jifflo	= 162				; low byte of jiffy clock (todo: same for all)
sound_hit_njiffies 	= 2 ;120			; n of jiffies for delay
sound_hit_repeat 	= 6
sound_hit_ntimes	!8 0

sound_hit
	ldx		#$00
	stx		sound_hit_ntimes

sound_hit_loop
	jsr		sidclr
	lda		#15
	sta		sigvol
	lda		#$00
	sta		atdcy1
	lda		#$f0
	sta		surel1
	lda		#132
	sta		frelo1
	lda		#125
	sta		frehi1
	lda		#%00010001
	sta		vcreg1
	lda		#sound_hit_njiffies
	adc		sound_hit_jifflo
sound_hit_delay
	cmp		sound_hit_jifflo
	bne		sound_hit_delay
	lda		#%00010000
	sta		vcreg1

; wait
	lda		#sound_hit_njiffies
	adc		sound_hit_jifflo
sound_hit_loop_wait
	cmp		sound_hit_jifflo
	bne		sound_hit_loop_wait

	ldx		sound_hit_ntimes
	cpx		#sound_hit_repeat
	beq		sound_hit_end
	inx
	stx		sound_hit_ntimes
	jmp		sound_hit_loop

sound_hit_end
	rts

;------------------------------
; sid clear routine:
;------------------------------
sidclr							; clear the SID chip
	lda		#0					; fill with zeros
	ldy		#24					; as the offset from frelo1
sidlop
	sta		frelo1,y			; store zero in each SID chip address
	dey							; for next lower address
	bpl		sidlop				; fill 25 bytes
	rts							; we're done

;------------------------------
; end of MUSIC routines and data
;------------------------------

;------------------------------
; program start:
;------------------------------

	;*= $c000

;------------------------------
; main:
;------------------------------

main

	jsr		init_screen

	; initialize sprite pointers
	;
	lda		#$22;#$80 ; this is addr. 0x2000 div by 64 (8192 / 64) = 128 (0x80) 
	sta		sprite0_ptr

	lda		#$23;#$81 
	sta		sprite1_ptr

	; set up sprites
	lda		#3
	sta		enable

	lda		#col_orange
	sta		color0

	lda		#col_pink
	sta		color1

	; title screen
	;
	jsr		intmus
	jsr		title_screen
	jsr		intmus_reset

	; initialize score and number of pills
	ldx		#$00
	stx		score
	ldx		#max_num_pills
	stx		pills_left

	+show_score
	+show_pills_left


	; set initial sprite locations for game to start
	ldx		#$02
	stx		msbx

	ldx		#dir_l_to_r
	stx		head_dir

	ldx		#border_left
	stx		sp0x

	ldx		#sp_pos_top
	stx		sp0y

	+reset_pill_sprite

__main_silly_wait					;
 	jsr		check_keyboard_input	; this is here due to some stupid bug
	cpy		#$00					; related to debouncing the keys, but
	bne		__main_silly_wait		; i don't wanna fix it now so... ;-P

__main_loop

	; reset delay counter
	ldx		#0
	stx		delay_counter
	stx		delay_counter_times

;------------------------------
; head movement:
;------------------------------

	ldx		sp0x
	cpx		#$ff
	bne		__main_move_head_no_msb
	lda		msbx
	eor		#$01
	sta		msbx
	
__main_move_head_no_msb
	ldy		head_dir
	cpy		#dir_l_to_r
	beq		__main_move_head_l_to_r

	;move r to l
	dex

	; check to see if we hit the left border
	lda		msbx
	and		#$01
	cmp		#$01
	beq		__main_move_head_end
	cpx		#border_left
	bne		__main_move_head_end
	ldy		#dir_l_to_r
	sty		head_dir

	jmp		__main_move_head_end

__main_move_head_l_to_r
	inx

	; check to see if we hit the right border
	lda		msbx
	and		#$01
	cmp		#$00
	beq		__main_move_head_end
	cpx		#border_right
	bne		__main_move_head_end
	ldy		#dir_r_to_l
	sty		head_dir

__main_move_head_end
	stx		sp0x

;------------------------------
; pill movement:
;------------------------------

	lda		pill_launched
	beq		__main_move_pill_not_launched
	jmp		__main_move_pill_launched

__main_move_pill_not_launched

	ldx		sp1x
	cpx		#$ff
	bne		__main_move_pill_no_msb
	lda		msbx
	eor		#$02
	sta		msbx

__main_move_pill_no_msb
	ldy		pill_dir
	cpy		#dir_l_to_r
	beq		__main_move_pill_l_to_r

	;move r to l
	dex

	; check to see if we hit the left border
	lda		msbx
	and		#$02
	cmp		#$02
	beq		__main_move_pill_end
	cpx		#border_left
	bne		__main_move_pill_end
	ldy		#dir_l_to_r
	sty		pill_dir

	jmp		__main_move_pill_end

__main_move_pill_l_to_r
	inx

	; check to see if we hit the right border
	lda		msbx
	and		#$02
	cmp		#$00
	beq		__main_move_pill_end
	cpx		#border_right
	bne		__main_move_pill_end
	ldy		#dir_r_to_l
	sty		pill_dir

__main_move_pill_end
	stx		sp1x
	jmp		__main_check_keyboard_input

;------------------------------
; pill (launched) movement:
;------------------------------

__main_move_pill_launched

	ldx		sp1y
	cpx		#border_top
	beq		__main_move_pill_launched_completed_miss

	dex
	stx		sp1y

	lda		collision
	and		#$03
	beq		__main_move_pill_launched_continue

	; it's a hit! count the score
	ldx		score
	inx
	stx		score
	+show_score

	jsr		sound_hit

	jmp		__main_move_pill_launched_completed

__main_move_pill_launched_continue

	jmp		__main_wait

__main_move_pill_launched_completed_miss
	jsr		sound_miss

__main_move_pill_launched_completed

	lda		msbx
	and		#$01
	sta		msbx

	+reset_pill_sprite

	lda		collision	; read again to make sure it's cleared out
						; before going back to the main_loop

	; check if it was the last pill, then it's game over
	lda		pills_left
	beq		__main_game_over

	jmp		__main_wait

;------------------------------
; main-check keyboard input
;------------------------------

__main_check_keyboard_input

	jsr		check_keyboard_input
	cpy		#$00
	beq		__main_wait
	ldx		#$ff
	stx		pill_launched
	ldx		pills_left
	dex
	stx		pills_left
	+show_pills_left

;------------------------------
; wait:
;------------------------------
__main_wait

	ldx		delay_counter_times
	cpx		#delay_counter_times_until
	beq		__main_end

	ldx		delay_counter
	inx
	stx		delay_counter
	cpx		#delay_counter_until
	bne		__main_wait

	ldx		#$00
	stx		delay_counter
	ldx		delay_counter_times
	inx
	stx		delay_counter_times
	jmp		__main_wait

__main_end
	jmp		__main_loop

__main_game_over

	lda		#0
	sta		enable

	+output_string str_game_over, $0576, $d976
	+output_string str_game_over_score, $05be, $d9be

	+output_num $be, $05, $0f, score
	ldx		#max_num_pills
	stx		pills_left
	+output_num $be, $05, $19, pills_left

	ldx		score
	cpx		#max_num_pills
	beq		__main_game_over_win

	+output_string str_game_over_loose, $05e9, $d9e9

	jmp		__main_game_over_play_again

__main_game_over_win
	+output_string str_game_over_win, $05e5, $d9e5

__main_game_over_play_again
	+output_string str_play_again, $0684, $da84


__main_game_over_wait
	; now wait for user input
	jsr		check_keyboard_input
	beq		__main_game_over_end_game
	cpx		#$ff
	beq		__main_game_over_new_game

	jmp		__main_game_over_wait


__main_game_over_new_game

	jmp		main

__main_game_over_end_game

	; and wait until key is not read in anymore
	jsr		check_keyboard_input
	beq		__main_game_over_end_game;__main_game_over_end_game_wait
	jmp		__main_game_over_end_game_deinit

__main_game_over_end_game_wait
	jmp		__main_game_over_end_game

__main_game_over_end_game_deinit

	lda		#0
	sta		$c6 ; clear NDX

	jsr		clear_screen
	ldx		#col_blue
	stx		backgr_color_reg_0
	ldx		#col_light_blue
	stx		border_color_reg	

;------------------------------
; program end
;------------------------------
	rts

