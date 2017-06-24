;;
; Alias managment. An aliases allow to give other names to exisintg commands.
;
; @author Romain Giot
; @date june 2017
; @licence GPL


  struct alias
alias dw 0    ; Ptr to an alias
original dw 0 ; Pointer to the original name
  endstruct



;;
; Input:
;  - HL: pointer to the probable alias string
; Output:
; - Hl: pointer to the original string (or nullptr)
; - Carry is set when an alias is found
alias_word_is_alias

  ex de, hl
  ld hl, alias_table - 2
.loop

  inc hl : inc hl

  ; HL= table of alias
  ; DE= pointer to the string to test

  ld c, (hl) : inc hl
  ld b, (hl) : inc hl

  ; BC = pointer to the current alias

  ld a, b : or c
  jr z, .not_found


  push de ; store the beginning of the string
  push hl

    ld h, b : ld l, c
    call string_compare

  pop hl
  pop de

  jr nz, .loop


.found
  ld e, (hl) : inc hl : ld d, (hl)
  ex de, hl
  scf
  ret

.not_found
  ld hl, 0
  cp a
  ret


; Check if the word corresponds to an alias; if so, replace the word by the appropriate value
; Input:
; - HL: pointer to the word of interest

alias_treat_command_name
  BREAKPOINT_WINAPE

  ; Leave if the string is empty
  ld a, (hl): or a : ret z

  push hl ; save the address
    call alias_word_is_alias
  pop de

  ret nc ; no alias found

; We found an alias
.found

  call string_copy_word

  ret



alias_table
  alias alias_strings.mv, alias_strings.era
  alias alias_strings.h, alias_strings.help
  alias alias_strings.b, alias_strings.basic
  alias alias_strings.off, alias_strings.m4romoff
  alias 0, 0



alias_strings
.era string "ERA"
.mv string "MV"

.h string "H"
.help string "HELP"

.b string "B"
.basic string "BASIC"

.off string "OFF"
.m4romoff string "M4ROMOFF"
