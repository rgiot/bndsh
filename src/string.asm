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
; Input: 
; HL: buffer to modify
string_string_to_upper
  ld a, (hl)
  or a
  ret z
  
  call string_char_to_upper
  ld (hl), a
  inc hl
  jr string_string_to_upper



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


;;
; Comput ethe size of the current string
string_size
  ld b, 0
.loop
  ld a, (hl)
  call string_char_is_eof: jr z, .end
 ; call string_char_is_space: jr z, .end ; for a word not a string !
  inc hl
  inc b
  jr .loop
.end
  ld a, b
  ret



;;
; Compute the size of the current word
string_word_size
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
; Case INSENSITIVE string comparison
; Input
;  - HL:  string 1
;  - DE: stirng 2
; Output
;  - Zero flag set when equal
string_compare
.loop

    ld a, (hl) : call string_char_to_upper
    call string_char_is_eof
    jr z, .str1_empty

.str1_not_empty
    ld c, a
    ld a, (de) : call string_char_to_upper :  call string_char_is_eof : jr z, .not_equal
.str1_not_empty_and_str2_not_empty
    cp c : jr nz, .not_equal

    inc de : inc hl
    jr .loop

.str1_empty
    ld a, (de) : call string_char_to_upper : call string_char_is_eof : jr z, .equal
    jr .not_equal

.equal
    cp a; Z=1
    ret

.not_equal
    or 1; Z=0
    ret













;;
; Case insensitive
; Input:
; - HL: complete string
; - DE: smallest string
; Check if DE is a previx of HL
; Output
;  - Zero flag set when DE is a prefix of hl
string_is_prefix
.loop

    ld a, (hl) : call string_char_to_upper
    call string_char_is_eof
    jr z, .complete_empty

.complete_not_empty
    ld c, a
    ld a, (de) : call string_char_to_upper : call string_char_is_eof : jr z, .is_prefix
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


;;
; check if first string is before the second
; INPUT:
;  - HL: string 1
;  - DE: string 2
string_compare_signed
.loop

    ld a, (hl) : call string_char_to_upper
    call string_char_is_eof
    jr z, .str1_empty

.str1_not_empty
    ld c, a
    ld a, (de) : call string_char_to_upper :  call string_char_is_eof : jr nz, .str1_not_empty_and_str2_not_empty
.str1_not_empty_str2_empty
    or 1 : scf    ; A > B Z=0 C=0
    ret 

.str1_not_empty_and_str2_not_empty
    cp c 
    ret nz; Z=0 C depends on the comparison

    inc de : inc hl ; go for a next loop
    jr .loop

.str1_empty
    ld c, a
    ld a, (de) : call string_char_to_upper :  call string_char_is_eof : ret z ; A = B Z=1 C=? XXX ensure C=0


    ; by definition string 1 is smaller than string 2
    or 1 : scf : ccf ; A<B Z=0, C=1
    ret

;;
; Sort a buffer of pointer of strings based on the value of this string
; Input:
;  HL= buffer of pointer of strings (ends with nullptr)
gnome_sort
  ld e, (hl) : inc hl : ld d, (hl) : dec hl
  ld a, e : or d : ret z ; The buffer is empty

  jr .increment_pos
.loop
  push hl
    ; HL = pos
    dec hl : dec hl
    ; HL = pos-1
    ld c, (hl) : inc hl : ld b, (hl) : inc hl
    ld e, (hl) : inc hl : ld d, (hl)
    ld h, b: ld l, c
    ; HL = pos -1
    ; DE = pos

    call string_compare_signed
  pop hl
  
  jr z, .increment_pos
  jr c, .swap

.increment_pos
  ; We are at next position
  inc hl : inc hl
  ld e, (hl) : inc hl : ld d, (hl) : dec hl ; read position to be sure we are not out
  ld a, e : or d : ret z ; This is the end of the buffer
  jr .loop

.swap
  BREAKPOINT_WINAPE
  ld d, h : ld e, l
  dec hl : dec hl


  ; DE = low pos
  ; HL = low pos-1

  ; swap low byte address
  ld a, (de) : ld c, a
  ld b, (hl)
  ld (hl), c
  ld a, b : ld (de), a

  ; swap high byte address
  inc hl : inc de
  ld a, (de) : ld c, a
  ld b, (hl)
  ld (hl), c
  ld a, b : ld (de), a
  
  ; DE = high pos
  ; HL = high pos-1

  dec hl

  ; HL = low pos-1
  jr .loop
  ret
