;;
; Basic display routine bndsh.
;
; To be reaplaced by faster ones later
; @author Romain Giot
; @date june 2017
; @licence GPL



display_print_char
        res 7, a
        push hl : call FIRMWARE.TXT_OUTPUT: pop hl
        ret


display_print_string
.loop
        ld a, (hl)
        or a : ret z

        call display_print_char

        inc hl

    jr .loop



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
