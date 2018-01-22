;;
; Basic display routine bndsh.
;
; To be reaplaced by faster ones later
; @author Romain Giot
; @date june 2017
; @licence GPL



    if DEBUG_MODE
display_print_debug

    push hl
        ld hl, debug_string
        call display_print_string
    pop hl
    call display_print_string
    call display_crlf
    ret
    endif


;;
; Input
; DE: 16 bits number
display_hexadecimal_16bits_number
    ld a, d
    push de
        call display_hexadecimal_8bits_number
    pop de

    ld a, e
    push de
        call display_hexadecimal_8bits_number
    pop de
    ret

;;
; Input
; - A: 8 bits number to display
display_hexadecimal_8bits_number

    push af
        repeat 4
            sra a
        endrepeat
        call .treat_digit
    pop af


    call .treat_digit
    ret

.treat_digit
        and %1111
        cp 10
        jr nc, .is_letter
.is_digit
            add '0'
            call display_print_char
            ret
.is_letter
            add 'A' - 10
            call display_print_char
            ret


        


display_crlf
    ld a, 10 : call FIRMWARE.TXT_OUTPUT
    ld a, 13 : call FIRMWARE.TXT_OUTPUT
    ret


display_print_char
        res 7, a
        push hl : call FIRMWARE.TXT_OUTPUT: pop hl
        ret

;;
; Attention remove bit 7 of char
display_print_string
.loop
        ld a, (hl)
        or a : ret z

        call display_print_char

        inc hl

    jr .loop


display_print_string_256
.loop
        ld a, (hl)
        or a : ret z

        push hl : call FIRMWARE.TXT_OUTPUT: pop hl

        inc hl

    jr .loop



display_print_firmware_string
  ld b, (hl) : inc hl
.loop
  push bc
    ld a, (hl) : inc hl
    push hl
      call FIRMWARE.TXT_OUTPUT
    pop hl
  pop bc
  djnz .loop
  ret


display_print_string2
.loop
        ld a, (hl)

        call display_print_char

        ld a, (hl)
        bit 7, a : ret nz

        inc hl

    jr .loop






display_print_rsx_name
.loop
        ld a, (hl)
        bit 7, a
        jr nz, .latest

        call display_print_char

        inc hl

    jr .loop

.latest
    res 7, a
    call display_print_char
    ret



display_line_fill_blank
    ld b, a
.clear_loop
        ld a, ' '
        push bc
            call display_print_char
        pop bc
        djnz .clear_loop
    ret
