interpreter_command_autocomplete

.nbArgs equ 0
.name  string "AUTOCOMPLETE" 
.help string "For debug purpose only. Display what the autocomplete system would provide for the provided argument."
.routine


    ld hl, (interpreter.next_token_ptr) 
    ld de, interpreter.command_name_buffer 

    call string_copy_word

    call autocomplete_search_completions

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

    ret
