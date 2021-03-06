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
    ld (autocomplete.nb_commands), a

    ld de, file_names
    ld (autocomplete.next_filename_address), de
    dec hl : call autocomplete_search_completion_on_dirnames
    dec hl : call autocomplete_search_completion_on_filenames
    call autocomplete_search_completions_on_commands
    call autocomplete_search_completions_on_rsx
  ;  call autocomplete_search_completions_on_aliases ; XXX Deactivated because currently buggy :(


    ld hl, autocomplete.commands_ptr_buffer 
    call gnome_sort

    ret

autocomplete_search_completion_on_filenames
    call m4_available
    jp z, autocomplete_search_completion_on_filenames_m4 ;; ram
    jr autocomplete_search_completion_on_dirnames.no_m4
    
autocomplete_search_completion_on_dirnames
    call m4_available
    jp z, autocomplete_search_completion_on_dirnames_m4 ;; ram
.no_m4
 ;   ld hl, autocomplete.commands_ptr_buffer 
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



autocomplete_search_completions_on_aliases

  dec hl
  ex de, hl
  ld hl, alias_table
.loop

  ; HL = pointr in the table of aliases
  ; DE = pointer on the buffer to feed

  ld c, (hl) : inc hl
  ld b, (hl) : inc hl
  inc hl : inc hl
  ld a, b: cp c : jr z, autocomplete_search_completions_on_rsx.buffer_filled ; XXX the code would be the same, so better to not lost space

  ; BC = address of the string to test
  push hl : push de : push bc
    ld h, b : ld l, c
    call string_is_prefix
  pop bc : pop de : pop hl

  jr nz, .loop ; current string is not a prefix

.is_prefix
    ; Add the string
    ex de, hl
        ld (hl), c
        inc hl
        ld (hl), b
        inc hl
    ex de, hl
        
    ld a, (autocomplete.nb_commands) : inc a : ld (autocomplete.nb_commands),a 
    jr .loop

; XXX Attention, here I assume the routine is called JUST AFTER autocomplete_search_completions_on_commands and HL is around the end of the buffer
; XXX Speed up procedure by using trees are something like that
autocomplete_search_completions_on_rsx
    dec hl ; 0 pointer
    ex de, hl
    ld hl, rsx_names
.loop
    ; HL = pointer on the rsx names
    ; DE = pointer on the buffer to feed
    
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

    ex de, hl
    ret






autocomplete_print_completions
    ; XXX Check if it is really needed (or add the number of line to manage the 256 chars)
    ld a, 10 : call 0xbb5a
    ld a, 13 : call 0xbb5a
 ;   ld a, ' ' : call 0xbb5a



    ; Erase previous completion if any
    ld a, (line_editor.autocomplete_done)
    or a
    call nz, autocomplete_erase_completion

    call FIRMWARE.TXT_GET_CURSOR
    ld (line_editor.autocomplete_before_cursor_pos), hl
    ld (line_editor.autocomplete_before_roll_count), a




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

  ;  call display_line_fill_blank; XXX really needed ?


    call FIRMWARE.TXT_GET_CURSOR
    ld (line_editor.autocomplete_after_cursor_pos), hl
    ld (line_editor.autocomplete_after_roll_count), a

    ld a, 1
    ld (line_editor.autocomplete_done), a
    ret

;;
; Assume the complete as already be done on time
; XXX Need to work properly when completion has never been used
; TODO Manage the case where a scroll occured
autocomplete_erase_completion

    BREAKPOINT_WINAPE

    ; Erase nothing if completion has not been done
    ld hl, (line_editor.autocomplete_start )
    ld a, h
    or l
    ret z


    call FIRMWARE.TXT_GET_CURSOR
    push hl : push af



; screen MUST NOT ROLL I doubt the current implementation guarantes that

.set_cursor_at_beginning
        ld hl, (line_editor.autocomplete_before_cursor_pos)
        push hl : call FIRMWARE.TXT_SET_CURSOR : pop hl


.clear_loop
        ld a, 'X' : call FIRMWARE.TXT_OUTPUT
        call FIRMWARE.TXT_GET_CURSOR
        inc h
        call FIRMWARE.TXT_VALIDATE

        push hl
            ld de, (line_editor.autocomplete_after_cursor_pos)
            or a
            sbc hl, de
            ex de ,hl
        pop hl

        ld a, d
        or e
        jr nz, .clear_loop
        


    ld a, 1
    ld (line_editor.autocomplete_done), a

    pop af : pop hl
    call FIRMWARE.TXT_SET_CURSOR


autocomplete_get_number_of_completions
    ; XXX add the count of the other types
    ld a, (autocomplete.nb_commands)
    ret


autocomplete_get_unique_completion
    ; XXX take into account the other types of completions
    ld hl, (autocomplete.commands_ptr_buffer)
    ret


;;
; Compute the longest common string in order to automatically insert it
autocomplete_get_longest_common_string
  xor a : ld (autocomplete.longest_common_string), a


  ; Leave if there is no completion
  ld a, (autocomplete.nb_commands) : or a : ret  z
  push af

    ; Copy the very first string to the appropriate buffer
    ld hl, autocomplete.commands_ptr_buffer
    ld e, (hl) : inc hl
    ld d, (hl) 
    ex de, hl
    ld de, autocomplete.longest_common_string
    call string_copy_word


    ; Go at the second position in the buffer of autocompletion proposals
    ld hl, autocomplete.commands_ptr_buffer
    inc hl : inc hl

  pop af
  dec a
  ret: or a : ret z

   ;A = number of remaining strings
.loop
    push af

      ; Get the pointer of the current string
      ld c, (hl) : inc hl
      ld b, (hl) : inc hl

      ; Update the longest common substring
      push hl
        ld l, c : ld h, b
        ld de, autocomplete.longest_common_string
        call string_update_longest_common_prefix
      pop hl

      ; No need to lost more time if the string is empty
      ld de, autocomplete.longest_common_string
      ld a, (de)
      or a : jr z, .leave
      
    pop af
    dec a 
    or a : jr nz, .loop
    ret


.leave
  pop af

  ret

