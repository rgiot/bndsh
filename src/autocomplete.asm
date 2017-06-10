autocomplete_reset_buffers
    ld hl, 0
    ld (autocomplete.commands_ptr_buffer), hl
    ret

autocomplete_search_completions
    call autocomplete_search_completions_on_commands
    ; XXX TODO Add other completions (RSX, filename)
    ret


autocomplete_search_completions_on_commands

    ld hl, interpreter_command_list             ; Buffer of commands to search
    ld de, autocomplete.commands_ptr_buffer     ; Buffer to fill with the pointers to the corresponding strings
.loop
        push hl : push de

            ; Get pointer value
            ld e, (hl) : inc hl : ld d, (hl)

            ; Leave if end of buffer is reached
            ld a, e : or d
            jr z, .end_of_table
    
            ex de, hl
            ld de, interpreter.command_name_buffer
            call string_is_prefix               ; HL=command to compare with, DE=keyword typed by the user
        pop de: pop hl  ; does not affect z flag

        jr nz, .end_of_loop

.is_prefix

        ; DE = buffer to fill with
        ; HL = Buffer of commands

        ; Save the address of the ptr
        ld c, (hl) : inc hl : ld b, (hl) : dec hl ; XXX Optimize that to not read again the value ...

        ; DE = buffer to fill with
        ; HL = Buffer of commands
        ; BC = Command value
        ex de, hl
            ld (hl), c
            inc hl
            ld (hl), b
            inc hl
        ex de, hl
    
.end_of_loop

        ; Move of one setp in the command list
        ld bc, command
        add hl, bc
    jr .loop


.end_of_table
    pop de: pop hl

    ex de, hl
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    ret



autocomplete_print_completions

    ld hl,  autocomplete.commands_ptr_buffer
.loop
        ; Get the addres of the string
        ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl

        ; Leave if empty
        ld a, e : or d
        jr z, .end_of_table

        push hl
            ex de, hl
            call display_print_string

            ld a, ' ' : call display_print_char
        pop hl
    jr .loop

.end_of_table

.clear_end_of_line
    call FIRMWARE.TXT_GET_CURSOR
    ld a, screen.width
    sub l
    ret c

    call display_line_fill_blank

    ret
