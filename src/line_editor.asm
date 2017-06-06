;;
; Line editor code for bndsh.
; Txt size is always 1 at minimum with last char to space
;
; Current version uses system calls.
; When the tool will be really used, all these system calls will have to be replaced by fast routines
;
; @author Romain Giot
; @date june 2017
; @licence GPL


key_backspace equ 0x7f
key_del equ 0x10
key_left equ 0xf2
key_right equ 0xf3
key_return equ 0x0d
key_eot equ  0x04


line_editor_init
    ld a, screen.cpc_mode
    call FIRMWARE.SCR_SET_MODE


    call line_editor_clear_buffers
    ret

line_editor_clear_buffers
    xor a
    ld (line_editor.text_buffer + 1 ), a

    ld a, ' '
    ld (line_editor.text_buffer), a


    xor a
    ld (line_editor.cursor_xpos), a
    ld (line_editor.current_width), a
    ret


line_editor_get_key
    jp FIRMWARE.KM_WAIT_CHAR


;;
; Input
;  - A: key char
line_editor_treat_key


    cp key_backspace : jr z, .backspace
    cp key_left : jr z, .key_left
    cp key_right : jr z, .key_right
    cp key_del : jr z, .key_del
    cp key_return : jr z, .key_return
 ;   cp key_eot: jp interpreter_command_exit.routine ; XXX for an unknown reason, does not work

    jp .insert_char




.key_return

    call line_editor_display_line_without_cursor

    ; Move cursor to next line
    ld a, 1 : call FIRMWARE.TXT_SET_COLUMN
    ld a, (line_editor.cursor_ypos) : inc a : inc a : call FIRMWARE.TXT_SET_ROW

    ; Launch execution
    ld hl, line_editor.text_buffer
    call interpreter_manage_input

    ; clear the buffer
    call line_editor_clear_buffers

    ; Properly set cursor
    ld a, key_return : call FIRMWARE.TXT_OUTPUT
    ld a, key_return : call FIRMWARE.TXT_OUTPUT
    call FIRMWARE.TXT_GET_CURSOR
    ld a, l : dec a : inc a : ld (line_editor.cursor_ypos), a
    ret



.key_left
    ld a, (line_editor.cursor_xpos)
    or a : jp z, .play_sound_and_leave
    dec a
    ld (line_editor.cursor_xpos), a
    ret



.key_right
    ld a, (line_editor.current_width): ld c, a
    ld a, (line_editor.cursor_xpos)
    cp c : ret z
    inc a
    ld (line_editor.cursor_xpos), a
    ret

.backspace
    ld a, (line_editor.cursor_xpos)
    or a : ret z
    dec a
    ld (line_editor.cursor_xpos), a
    ld a, (line_editor.current_width) : dec a : ld (line_editor.current_width), a

.shift_left ; XXX Also called by key_del
    ; TODO optimize this memory move far less memory is supposed to be moved
    ld de, (line_editor.cursor_xpos) : ld d, 0
    ld hl, line_editor.text_buffer
    add hl, de

    push hl
    pop de

    inc hl

    ld bc, line_editor.max_width
    ldir
    ret


.key_del
    jr .shift_left
    

.insert_char
    ;; Compute the buffer address
    ld hl, line_editor.text_buffer
    ld de, (line_editor.cursor_xpos) : ld d, 0
    add hl, de

    ; Write the char in the buffer
    ld (hl), a
    
    ; The space for the next char
    inc hl
    ld a, ' '
    ld (hl), a

    ; End the end of string
    inc hl
    xor a
    ld (hl), a


    ; Increment buffer position
    inc e
    ld a, line_editor.max_width
    cp e
    ret z  ; no increment when arrived at the very end
    ld a, e
    ld (line_editor.cursor_xpos), a


    ld a, (line_editor.current_width) : inc a : ld (line_editor.current_width), a
    ret

.play_sound_and_leave
    if config_enable_sound
       ld a, 7 : call display_print_char
    endif
    ret

line_editor_display_line_without_cursor
    xor a : ld (line_editor.check_cursor), a
    call line_editor_display_line
    ld a, 1 :ld (line_editor.check_cursor), a 
    ret


;; TODO Use display_print_string
;; TODO Build a transformed string instead of doing the transformation realtime
line_editor_display_line

    ld a, 1 : call FIRMWARE.TXT_SET_COLUMN 
    ld a, (line_editor.cursor_ypos) : inc a : call FIRMWARE.TXT_SET_ROW


    ld a, '$' : call FIRMWARE.TXT_WR_CHAR
    ld a, ' ' : call FIRMWARE.TXT_WR_CHAR

    
    ld hl, line_editor.text_buffer
    ld b, 0
    ld a, (line_editor.cursor_xpos) : ld c, a
.display_loop

        xor a : ld (.is_inverted), a

        ld a, (line_editor.check_cursor)
        or a
        jr z, .not_cursor

        ; In verse at cursor pos
        ld a, c : cp b : jr nz, .not_cursor
        push hl: call FIRMWARE.TXT_INVERSE : pop hl
        ld a, 1 : ld (.is_inverted), a
 ;       call FIRMWARE.TXT_PLACE_CURSOR
.not_cursor

        ld a, (hl)
        or a
        ret z

        push hl : push bc
        call display_print_char
        pop bc : pop hl


        ; restore at cursor pos
         ld a,(.is_inverted): or a : jr z, .not_cursor2
        push hl: call FIRMWARE.TXT_INVERSE : pop hl
.not_cursor2

        inc hl
        inc b
        jr .display_loop



    ret
.is_inverted db 0

line_editor_main_loop


    call line_editor_display_line
    call line_editor_get_key
    jp nc, line_editor_main_loop

    call line_editor_treat_key


    jp line_editor_main_loop
