;;
; Krusty/Benediciton
; June 2017
; Code that cannot be executed in ROM and in thus copied in extra RAM



ram_cd_from_interpreter

    ld  c, M4_ROM_NB ; TODO remove that
    call FIRMWARE.KL_ROM_SELECT
    push bc ; Backup rom configuration 


    if 1
        ; Compute the size of the command to send
        ld hl, interpreter.command_name_buffer
        call string_size_ram
        add 2 + 1

        ld hl, m4_buffer
        ld (hl), a : inc hl                 ; Set size of the parameters                 
        ld (hl), C_DIRSETARGS%256 : inc hl  ; Set low address of routine
        ld (hl), C_DIRSETARGS/256 : inc hl  ; Set high address of routine
        ex de, hl
            ld hl, interpreter.command_name_buffer
            call string_copy_word_ram
        ex de,hl
        ld (hl), 0 : inc hl  
        ld hl, m4_buffer
        call m4_send_command

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
        ld a, (hl)  ; Get response size 
        cp 2 : jp z, .cd_error
        
        ld de, 3 : add hl, de
       ; push hl
       ;     ld a, (hl)
       ;     call display_print_char_ram
       ; pop hl
        ld a ,(hl) : cp '>'
        jr nz, .cd_error

   endif


    ; Go in directory (works)
    ld hl, interpreter.command_name_buffer
    call string_size_ram
    add 2 + 1

    ld hl, m4_buffer
    ld (hl), a : inc hl                 ; Set size of the parameters                 
    ld (hl), C_CD%256 : inc hl  ; Set low address of routine
    ld (hl), C_CD/256 : inc hl  ; Set high address of routine
    ex de, hl
        ld hl, interpreter.command_name_buffer
        call string_copy_word_ram
    ex de, hl
    ld (hl), 0
    ld hl, m4_buffer
    call m4_send_command


    ; Get memory address of result
    ld hl, (0xFF02)
    inc hl  : inc hl  : inc hl 
    ld a, (hl)
    cp 0xff
    jr z, .cd_error

.cd_successfull
    pop bc
    call FIRMWARE.KL_ROM_DESELECT 
    ret

.cd_error
    pop bc
    call FIRMWARE.KL_ROM_DESELECT 
    jp interpreter_command_not_found.try_to_run





autocomplete_search_completion_on_filenames_m4
    ; Activate M4 ROM
    
    ; TODO move this code in normal memory ? (I guess once really in ROM, the selection of another ROM will make crash everything)
    ld  c, M4_ROM_NB; TODO programmatically select rom number (already found at init of the prog)
    call FIRMWARE.KL_ROM_SELECT
    push bc ; Backup rom configuration 

    xor a : ld (autocomplete.nb_commands),a 

.configure_filtering_for_search

        call m4_set_dir_filter_from_token ; function in RAM




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
       call FIRMWARE.KL_ROM_DESELECT ; is restore needed ?
    pop hl

    ret





;;
; Input: 
; DE: ROm name
bndsh_get_rom_number
    ; Save current state of the ROM
    xor a
    push de : call FIRMWARE.KL_ROM_SELECT : pop de
    push bc

    xor a
.loop_over_rom
    push af

        ; Select the ROM of interest
        ld c, a
        push de : call FIRMWARE.KL_ROM_SELECT : pop de

        ; Get rom name
        ld  hl,(0xC004)
        push de : call string_is_prefix_ram : pop de
        jr z,.found 
    pop af
    inc a


    cp 32
   jr nz, .loop_over_rom

.not_found
    ld a, 0xff
.continue
    ; Restore the previous state of the ROM
    pop bc
    push af : call FIRMWARE.KL_ROM_DESELECT : pop af
    ret

.found
    pop af
    jr .continue



;;;
; ATTENTION as this code is in extra RAM and other ROMs are activated, this function MUST NOT call code of the ROM
; TODO this is a very sill way to retreive RSX names. I'm sure there are somewhere in memory !
bndsh_get_rsx_names

    ; Save current state of the ROM
    xor a
    call FIRMWARE.KL_CURR_SELECTION 
    ld c, a :  push bc

    xor a
    ld de, rsx_names
.loop_over_rom
    push af

        ; Select the ROM of interest
        ld c, a
        push de
            call FIRMWARE.KL_ROM_SELECT
      ;      ld a, '.' : call FIRMWARE.TXT_WR_CHAR
        pop de


        ; Get rom name
        ld  hl,(0xC004)
        ld a, (hl) : or a : jp z, .test_next_rom
        ld a, (hl) : cp 'A' : jp c, .test_next_rom

         push hl: push de:call display_print_string2_ram: ld a, 10: call 0xbb5a: ld a,13:call 0xbb5a :pop de: pop hl
        call .eat_string

.loop_over_rsx



   ;         push hl: push de: ld a, '*' : call FIRMWARE.TXT_WR_CHAR : pop de: pop hl

            ld a, (hl)
            or a : jr z, .end_loop_over_rsx             ; End of table
            bit 7, a : jr nz, .loop_over_rsx_forget     ; Unprintable string
            cp 'A' : jr c, .test_next_rom               ; Memory error ?

                push hl

                    push hl: push de:call display_print_string2_ram: pop de: pop hl

                    push de
                        ld de, interpreter.command_name_buffer
                        call  .copy_name_in_buffer
                        call bndsh_rsx_exists
                        call nz, bndsh_command_exists 
                    pop de
                pop hl
                jr z, .loop_over_rsx_forget
                
                push hl
                    ld hl, interpreter.command_name_buffer
                    call string_copy_word_ram : inc de
                pop hl
            

.loop_over_rsx_forget

            call .eat_string
            jr .loop_over_rsx
.end_loop_over_rsx
.test_next_rom
    pop af : inc a


    cp 32
   jr nz, .loop_over_rom
.end_loop_over_rom

    
    ; Restore the previous state of the ROM
    pop bc : push de : call FIRMWARE.KL_ROM_SELECT : pop de
    xor a
    ld (de), a
    inc de
    ld (de), a

    ret

.eat_string
    ld a, (hl)
    inc hl
    bit 7, a
    ret nz
    jr .eat_string
    

.copy_name_in_buffer
    ld a, (hl) : res 7, a : ld (de), a  ; Copy char without bit 7
    ld a, (hl) : inc hl : inc de        ; Read again char
    bit 7, a : jr nz, .end_of_copy                    ; Leave when the word is written
    jr .copy_name_in_buffer
.end_of_copy
    xor a
    ld (de), a
    inc de
    ret



bndsh_rsx_exists

    ld hl, rsx_names
    ld de, interpreter.command_name_buffer
.loop
    ; HL = pointer on the rsx names
    
    ; Stop search if we are reading the latest string
    ld a, (hl) : or a : jr z, .buffer_read

    ; Check if we have a same
    push de: push hl
        ld de, interpreter.command_name_buffer
        call string_compare_ram
    pop hl: pop de

    jr nz, .is_not_same


.is_same
    ; Add the string
    cp a
    ret

.is_not_same
        ; move to the end of string
        ld  a, (hl) : inc hl
        or a
        jr z, .loop
    jr .is_not_same

.buffer_read
    or 1
    ret




;;
; Check if, for this RSX, there is already an internal command with the same name
; INPUT:
; - HL = string to compare to
; OUTPUT:
; - HL is inchanged
; - Z if command present
bndsh_command_exists


    ld de, interpreter.command_name_buffer
    ld hl, interpreter_command_list
.loop_full
        ; Read the ptr name
        ld c, (hl) : inc hl : ld b, (hl)


        ; Quit if this is the end
        ld a, b
        or c
        jr z, .end_of_loop_no_match


;        ; HL: list of commands
;        ; DE: string to compare to
;        ; BC: current string
;
        push hl : push de
            ld h, b : ld l, c
            call string_compare_ram
        pop de : pop hl
        jr z, .end_of_loop_match

        ld de, command - 1
        add hl, de
        ld de, interpreter.command_name_buffer

    jr .loop_full

.end_of_loop_no_match
    or 1
    ret

.end_of_loop_match
    cp a
    ret


;;; XXX very bad code here XXX
;;; XXX Duplicated code XXX
;;; XXX Find a way to remove this ugly thing or at least generate it programmaticaly XXX

;;
; Input
;  - HL:  string 1
;  - DE: stirng 2
; Output
;  - Zero flag set when equal
string_compare_ram
.loop

    ld a, (hl)
    call string_char_is_eof_ram
    jr z, .str1_empty

.str1_not_empty
    ld c, a
    ld a, (de) : call string_char_is_eof_ram : jr z, .not_equal
.str1_not_empty_and_str2_not_empty
    cp c : jr nz, .not_equal

    inc de : inc hl
    jr .loop

.str1_empty
    ld a, (de) : call string_char_is_eof_ram : jr z, .equal
    jr .not_equal

.equal
    cp a; Z=1
    ret

.not_equal
    or 1; Z=0
    ret



;;
; Input
; - A char vlaue
; Output
; - Flag Z if char is a space
string_char_is_space_ram
    cp ' '
    ret

string_char_is_eof_ram
    or a
    ret


;;
; Input
;  - HL: input string whith one or several words
;  - DE: output buffer with a size allowing to copy the first word
; Output
;  - HL: moved until first space or end of string
;  - DE: address of the null terminated string
; Modified
;  - A, BC
; Limitation: no overflow test
string_copy_word_ram
.loop
    ld a, (hl)
    call string_char_is_space_ram : jr z, .end
    call string_char_is_eof_ram : jr z, .end

    ; Here we are sure the string is not finished
    ldi
    jr .loop



.end
    xor a
    ld (de), a
    ret


;;
; Input:
; - HL: complete string
; - DE: smallest string
; Check if DE is a previx of HL
; Output
;  - Zero flag set when DE is a prefix of hl
string_is_prefix_ram
.loop

    ld a, (hl)
    call string_char_is_eof_ram
    jr z, .complete_empty

.complete_not_empty
    ld c, a
    ld a, (de) : call string_char_is_eof_ram : jr z, .is_prefix
.complete_not_empty_and_prefix_not_empty
    cp c : jr nz, .is_not_prefix

    inc de : inc hl
    jr .loop

.complete_empty
   ; ld a, (de) : call string_char_is_eof : jr z, .is_prefix
    jr .is_not_prefix

.is_prefix
    cp a; Z=1
    ret

.is_not_prefix
    or 1; Z=0
    ret



display_print_string2_ram
.loop
        ld a, (hl)

        push hl
        call FIRMWARE.TXT_WR_CHAR
        pop hl

        ld a, (hl)
        bit 7, a : ret nz

        inc hl

    jr .loop




string_size_ram
  ld b, 0
.loop
  ld a, (hl)
  call string_char_is_eof_ram: jr z, .end
;  call string_char_is_space_ram: jr z, .end ; XXX this is an error here !!
  inc hl
  inc b
  jr .loop
.end
  ld a, b
  ret


