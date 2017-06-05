;;
; Basic string manipualtion for bndsh.
; Will need lots of improvment later.
;
; @author Romain Giot
; @date june 2017
; @licence GPL






;;
; Input:
; - HL: string (null pterminated)
; Ouptut :
;  - A: String size
; Modified:
;  B
; Limitation : 8 bits size...
string_size
    ld b, 0
.loop
    ld a, (hl)
    or a
    jr nz, .continue
.finished
    ld a, b
    ret
.continue
    inc b
    jr .loop



;;
; Input
; - A char vlaue
; Output
; - Flag Z if char is a space
string_char_is_space
    cp ' '
    ret

string_char_is_eof
    or a
    ret


;;
; Input
;  - HL: input string whith one or several words
;  - DE: output buffer with a size allowing to copy the first word
; Output
;  - HL: moved until first space or end of string
;  - DE: address of the null terminated string
; Modified
;  - A, BC
; Limitation: no overflow test
string_copy_word
    BREAKPOINT_WINAPE
.loop
    ld a, (hl)
    call string_char_is_space : jr z, .end
    call string_char_is_eof : jr z, .end

    ; Here we are sure the string is not finished
    ldi
    jr .loop



.end
    xor a
    ld (de), a
    ret


string_move_until_first_nonspace_char
.loop
    ld a, (hl)
    call string_char_is_space: ret nz
    inc hl
    jr .loop

