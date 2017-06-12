autocomplete_reset_buffers
    ld hl, 0
    ld (autocomplete.commands_ptr_buffer), hl
    ret

autocomplete_search_completions
    call autocomplete_search_completion_on_filenames
    call autocomplete_search_completions_on_commands
    call autocomplete_search_completions_on_rsx
    ; XXX TODO Add other completions (RSX, filename)
    ret


autocomplete_search_completion_on_filenames
    ; Activate M4 ROM
    ; TODO programmatically select rom number (already found at init of the prog)
    ; TODO move this code in normal memory ? (I guess once really in ROM, the selection of another ROM will make crash everything)
    ld  c, 6
    call FIRMWARE.KL_ROM_SELECT
    push bc ; Backup rom configuration 

    xor a : ld (autocomplete.nb_commands),a 

.configure_filtering_for_search
    ld hl, m4_buffer
    ld (hl), 3 : inc hl                  ; No args for the moment, uses null string ; XXX Really use argument with filtering !
    ld (hl), C_DIRSETARGS%256 : inc hl
    ld (hl), C_DIRSETARGS/256 : inc hl
    ld (hl), 0
    ld hl, m4_buffer : call m4_send_command



        ld de, file_names ; the buffer that will contains ALL the filenames
        ld hl, autocomplete.commands_ptr_buffer  ; Buffer to add the pointer of filenames
.loop
        push de : push hl
        ; HL : autocomplete buffer
        ; DE = filenames buffer

        ; Ask to read a next filename
        ld hl, m4_buffer
        ld (hl), 2 : inc hl
        ld (hl), C_READDIR%256 : inc hl
        ld (hl), C_READDIR/256 : inc hl
        ld hl, m4_buffer 
        call m4_send_command

        ; Get memory address of result
        ld hl, (0xFF02)

        ; HL = buffer to read
        ld a, (hl) : inc hl ; Get response size 
        cp 2 : jr z, .end_of_dir


        ; Remove 2 first things ; no idea what it is ..
        inc hl : dec a : inc hl : dec a

        ; Copy string out of ROM to the main memory
        ld a, (hl) : cp '>' : jr nz, .is_file
.is_dir
        inc hl: dec a ; Remove >
.is_file

        pop de : pop bc
        ; DE = autocomplete buffer
        ; BC = filenames buffer
        ; HL = m4 buffer

        ; store the pointer of file name
        ex de, hl

        ; HL = autocomplete buffer
        ; BC = filenames buffer
        ; DE = m4 buffer
            ld (hl), c : inc hl
            ld (hl), b : inc hl

        ex de, hl

        ; DE = autocomplete buffer
        ; BC = filenames buffer
        ; HL = m4 buffer

        push de 
        ld d, b : ld e, c

        ; DE = filenames_buffer
        ; BC = filenames buffer
        ; HL = m4 buffer


        ld b, a
.fname_copy_loop
            ld a, (hl)
            cp ' ' : jr z, .do_no_copy_char
            cp '.' : jr nz, .copy_char
.is_dot
            ld b, 3 ; we do not care of file size ! so copy only extension
.copy_char
            ld (de), a
            inc de
.do_no_copy_char
            inc hl
        djnz .fname_copy_loop

        ; remove . if last char
        dec de
        ld a, (de) : cp '.' : jr z, .add_null_byte
        inc de
.add_null_byte
        ; ensure the end is ok
        xor a : ld (de), a : inc de



        pop hl


        ld a, (autocomplete.nb_commands) : inc a : ld (autocomplete.nb_commands),a 
    jr .loop
    

.end_of_dir

        pop hl : pop de
    xor a 
    ld (hl), a : inc hl : ld (hl), a

    ; restore initial configuration
    pop bc
    push hl
       call FIRMWARE.KL_ROM_SELECT ; is restore needed ?
    pop hl

    ret

    



autocomplete_search_completions_on_commands

    ; XXX hl already feed up
    dec hl ; 0 pointer
    ex de, hl
 ;   ld hl, interpreter_command_list             ; Buffer of commands to search
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
