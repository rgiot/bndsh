;;
; Basic string manipualtion for bndsh.
; Will need lots of improvment later.
;
; @author Romain Giot
; @date june 2017
; @licence GPL




;;;
; Input;
; A: a char
; Output
; A: the char in uppercase
string_char_to_upper
  ;cp 'A' : ret c ; not needed
  cp 'a'-1 : ret c
  cp 'z'+1 : ret nc

  add -( 'a' - 'A')

  ret






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


string_move_until_first_space_char
.loop
    ld a, (hl)
    call string_char_is_space: ret z
    inc hl
    jr .loop

string_move_until_null_char
.loop
    ld a, (hl)
    call string_char_is_eof: ret z
    inc hl
    jr .loop


string_move_until_null_or_space_char
.loop
        ld a, (hl)
        call string_char_is_eof: ret z
        call string_char_is_space: ret z
        inc hl
        jr .loop


string_size
  ld b, 0
.loop
  ld a, (hl)
  call string_char_is_eof: jr z, .end
  call string_char_is_space: jr z, .end
  inc hl
  inc b
  jr .loop
.end
  ld a, b
  ret


;;
; Move HL ptr to the beginning of the current word
; Input:
; - HL: ptr to the current char of the string
; - B: number of chars in the string
; Output:
; - HL: ptr to the beginning of the word
string_go_to_beginning_of_current_word
    ld a, (hl)
    call string_char_is_space: ret z; We are not even in one word


.loop
    ld a, 1 : cp b
    ret z   ; we cannot make more test, the string has a size of one

    dec b : dec hl

    ld a, (hl)
    call string_char_is_space : jr z, .is_space

.is_not_space
    jr .loop

.is_space
    ; By construction, we know whe can increment the pointer
    ; Move to the next char which IS a char
    inc hl
    ret
;;
; Input
;  - HL:  string 1
;  - DE: stirng 2
; Output
;  - Zero flag set when equal
string_compare
.loop

    ld a, (hl)
    call string_char_is_eof
    jr z, .str1_empty

.str1_not_empty
    ld c, a
    ld a, (de) : call string_char_is_eof : jr z, .not_equal
.str1_not_empty_and_str2_not_empty
    cp c : jr nz, .not_equal

    inc de : inc hl
    jr .loop

.str1_empty
    ld a, (de) : call string_char_is_eof : jr z, .equal
    jr .not_equal

.equal
    cp a; Z=1
    ret

.not_equal
    or 1; Z=0
    ret








;;
; Input:
; - HL: complete string
; - DE: smallest string
; Check if DE is a previx of HL
; Output
;  - Zero flag set when DE is a prefix of hl
string_is_prefix
.loop

    ld a, (hl)
    call string_char_is_eof
    jr z, .complete_empty

.complete_not_empty
    ld c, a
    ld a, (de) : call string_char_is_eof : jr z, .is_prefix
.complete_not_empty_and_prefix_not_empty
    cp c : jr nz, .is_not_prefix

    inc de : inc hl
    jr .loop

.complete_empty
   ; ld a, (de) : call string_char_is_eof : jr z, .is_prefix
    jr .is_not_prefix

.is_prefix
    cp a; Z=1
    ret

.is_not_prefix
    or 1; Z=0
    ret
