autocomplete_reset_buffers
    ld hl, 0
    ld (autocomplete.commands_ptr_buffer), hl
    ret

autocomplete_search_completions
    ld hl, autocomplete.commands_ptr_buffer 
    xor a
    ld (hl), a
    inc hl
    ld (hl), a

    call autocomplete_search_completion_on_filenames
    call autocomplete_search_completions_on_commands
    call autocomplete_search_completions_on_rsx
    ret

autocomplete_search_completion_on_filenames
    call m4_available
    jp z, autocomplete_search_completion_on_filenames_m4 ;; ram
.no_m4
    ld hl, autocomplete.commands_ptr_buffer 
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    ret


    



autocomplete_search_completions_on_commands

    ; XXX hl already feed up
    dec hl ; 0 pointer
    ex de, hl
    ld hl, interpreter_command_list             ; Buffer of commands to search
  ;  ld de, autocomplete.commands_ptr_buffer     ; Buffer to fill with the pointers to the corresponding strings
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
    
        ld a, (autocomplete.nb_commands) : inc a : ld (autocomplete.nb_commands),a 
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






; XXX Attention, here I assume the routine is called JUST AFTER autocomplete_search_completions_on_commands and HL is around the end of the buffer
; XXX Speed up procedure by using trees are something like that
autocomplete_search_completions_on_rsx
    dec hl ; 0 pointer
    ex de, hl
    ld hl, rsx_names
.loop
    ; HL = pointer on the rsx names
    ; DE = pointer on the buffer to feel
    
    ; Stop search if we are reading the latest string
    ld a, (hl) : or a : jr z, .buffer_filled

    ; Check if we have a prefix
    push de: push hl
        ld de, interpreter.command_name_buffer
        call string_is_prefix
    pop hl: pop de

    jr nz, .is_not_prefix


.is_prefix
    ; Add the string
    ex de, hl
        ld (hl), e
        inc hl
        ld (hl), d
        inc hl
    ex de, hl
        
    ld a, (autocomplete.nb_commands) : inc a : ld (autocomplete.nb_commands),a 

.is_not_prefix
        ; move to the end of string
        ld  a, (hl) : inc hl
        or a
        jr z, .loop
    jr .is_not_prefix

.buffer_filled
    xor a
    ld (de), a
    inc de
    ld (de), a

    ret






autocomplete_print_completions
    ld a, 10 : call 0xbb5a
    ld a, 13 : call 0xbb5a
    ld a, ' ' : call 0xbb5a

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
            BREAKPOINT_WINAPE

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

autocomplete_get_number_of_completions
    ; XXX add the count of the other types
    ld a, (autocomplete.nb_commands)
    ret


autocomplete_get_unique_completion
    ; XXX take into account the other types of completions
    ld hl, (autocomplete.commands_ptr_buffer)
    ret
