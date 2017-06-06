;;
; Basic display routine bndsh.
;
; To be reaplaced by faster ones later
; @author Romain Giot
; @date june 2017
; @licence GPL



display_print_char
        push hl : call FIRMWARE.TXT_OUTPUT: pop hl
        ret


display_print_string
.loop
        ld a, (hl)
        or a : ret z

        call display_print_char

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
