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
key_up equ 0xf0
key_down equ 0xf1
key_return equ 0x0d
key_eot equ  0x04
key_tab equ 0x09


line_editor_init
    ld a, screen.cpc_mode
    call FIRMWARE.SCR_SET_MODE



    ld hl, startup_data.text : call display_print_string
    call line_editor_clear_buffers
    ld a, 2 : ld (line_editor.cursor_ypos), a

    ret

line_editor_clear_buffers
    call history_save_current_context ; For performance reasons, I think it is better to save history here and not before launching a command that may never return

    ld a, -1
    ld (history.current), a

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


    cp key_backspace : jp z, .backspace
    cp key_left : jp z, .key_left
    cp key_right : jp z, .key_right
    cp key_del : jp z, .key_del
    cp key_return : jp z, .key_return
    cp key_up : jp z, .history_previous
    cp key_down : jp z, .history_next
    cp key_tab : jp z, .autocomplete
 ;   cp key_eot: jp interpreter_command_exit.routine ; XXX for an unknown reason, does not work

    jp .insert_char


.autocomplete

.autocomplete_copy_word_of_interest_in_buffer

; XXX Take into account no input

    ; Compute the address of the last char
    ld hl, line_editor.text_buffer
    ld de, (line_editor.cursor_xpos) : ld d, 0
    ld b, e
    dec e ; it seems it is the space here
    add hl, de
    ld (line_editor.autocomplete_stop), hl

    ; Compute the address of the first char
    call string_go_to_beginning_of_current_word
    ld (line_editor.autocomplete_start), hl

    ; Get the size of the string
    ld hl, (line_editor.autocomplete_stop)
    ld de, (line_editor.autocomplete_start)
    or a
    sbc hl, de
    inc hl
    ld (line_editor.autocomplete_word_size), hl

    ; Copy the word to the appropriate buffer
    ld b, h : ld c, l                       ; BC = Size of string
    ex de, hl                               ; HL = Start of the string
    ld de, interpreter.command_name_buffer  ; DE = bufferto write
    ldir
    xor a : ld (de), a

    call autocomplete_reset_buffers 
    call autocomplete_search_completions

    call autocomplete_get_number_of_completions
    or a : jr z, .autocomplete_no_completion
    cp 1 : jr z, .autocomplete_insert_completion

    jp autocomplete_print_completions ; TODO add something to clear the completions previously displayed

.autocomplete_no_completion
    ld a, 7
    call display_print_char
    ret

.autocomplete_insert_completion



    ; scroll the buffer content
    ld a, (line_editor.autocomplete_word_size) : push af
    call autocomplete_get_unique_completion : call string_size : pop bc 
    
    ; A=size of the string to insert
    ; B=size of the prefix
    sub b : ld b, a
    ; A = size of the thing to copy; Value is verified

    
    BREAKPOINT_WINAPE
    
    ld hl, line_editor.text_buffer
    ld a, (line_editor.current_width) : inc a
    ld d, 0
    ld e, a
    add hl, de 
    ; HL = source of the thing to copy

    ex de, hl
    ; DE = source of the thing to copy
    ld h, 0 : ld l, b ; width of the thing to copy
    add hl, de
    ex de, hl

    ; HL = source of the thing to copy
    ; DE = destination


    ld a, (line_editor.cursor_xpos) : ld c, a
    ld a, (line_editor.current_width)
    sub c 
    add b : ld c, a
    ld b, 0
    lddr



    ; Fix the cursor positionning
    ld de , (line_editor.autocomplete_word_size),
    ld a, (line_editor.cursor_xpos) : sub e : ld (line_editor.cursor_xpos), a
    ld a, (line_editor.current_width) : sub e : ld (line_editor.current_width), a


    ; finally insert the content
    call autocomplete_get_unique_completion
    ld de, (line_editor.autocomplete_start)


        
    ; TODO manage the fact we can go over the buffer line
.autocomplete_insert_completion_loop
        ld a, (hl)
        or a : ret z

        ldi
        ld a, (line_editor.cursor_xpos) : inc a : ld (line_editor.cursor_xpos), a
        ld a, (line_editor.current_width) : inc a : ld (line_editor.current_width), a
        jr .autocomplete_insert_completion_loop

.history_previous
    call history_select_previous
    call line_editor_display_line
    ret

.history_next
    call history_select_next
    call line_editor_display_line
    ret

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

    ld a, (interpreter.did_nothing)
    or a : jr nz, .interpreter_acted

.interpreter_did_nothing

    ret
.interpreter_acted
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
    cp c : jp z, .play_sound_and_leave
    inc a
    ld (line_editor.cursor_xpos), a
    ret

.backspace
    ld a, (line_editor.cursor_xpos)
    or a : jp z, .play_sound_and_leave
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
    push hl : push de : push af

    ; HL=address to squeeze
    ; D=0
    ; E=position of cursor

    ld a, (line_editor.current_width)
    cp e
    jr z, .insert_char_no_scroll


.insert_char_scroll
    ;; Scroll text content
    sub e

    ; TODO add secuirty ?

    ; scroll the buffer
    push hl
        ld b, 0 : ld c, a
        add hl, bc
        ld d, h: ld e, l : inc de
        inc bc: inc bc
        lddr
    pop hl

    pop af : pop de : pop hl

    ; Write the char in the buffer
    ld (hl), a

    ; if we are here it is because there is buffer used after, so we can move safely
    inc e : ld a, e
    ld (line_editor.cursor_xpos), a


    ; however the string still grows of one char
    ld a, (line_editor.current_width) : inc a : ld (line_editor.current_width), a
    ld e, a : ld d, 0
    ld hl, line_editor.text_buffer
    add hl, de
    jp .insert_char_no_scroll_put_guard


.insert_char_no_scroll

    pop af : pop de : pop hl
    ; Write the char in the buffer
    ld (hl), a

    inc hl
    call .insert_char_no_scroll_put_guard


    ; Increment buffer position
    inc e
    ld a, line_editor.max_width
    cp e
    ret z  ; no increment when arrived at the very end
    ld a, e
    ld (line_editor.cursor_xpos), a


    ld a, (line_editor.current_width) : inc a : ld (line_editor.current_width), a
    ret
.insert_char_no_scroll_put_guard
    ; The space for the next char
    ld a, ' '
    ld (hl), a

    ; End the end of string
    inc hl
    xor a
    ld (hl), a
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
    ld a, (line_editor.cursor_ypos)
    cp  25 : jr nc, .last_line
    inc a
    jr .set_row
.last_line
  ld a, 24 : ld  (line_editor.cursor_ypos), a
    ld a, 26
    call FIRMWARE.TXT_SET_ROW
    ld a, 13
    call display_print_char
    ld a, 25
.set_row
    call FIRMWARE.TXT_SET_ROW


    ld a, '$' : call FIRMWARE.TXT_WR_CHAR
 ;   ld a, ' ' : call FIRMWARE.TXT_WR_CHAR


    ld hl, line_editor.text_buffer
    ld b, 0; position number
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
        jr z, .clear_end_of_line

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


    ; XXX For performance reasons it would be nice to activate that ONLY when using history
.clear_end_of_line
    ; B = number of printed chars
    ld a, screen.width
    sub b
    ret c

    call display_line_fill_blank





    ret
.is_inverted db 0

line_editor_main_loop


    call line_editor_display_line
    call line_editor_get_key
    jp nc, line_editor_main_loop

    call line_editor_treat_key


    jp line_editor_main_loop
