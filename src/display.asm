;;
; Basic display routine bndsh.
;
; To be reaplaced by faster ones later
; @author Romain Giot
; @date june 2017
; @licence GPL



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
