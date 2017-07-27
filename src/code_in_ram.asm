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
        ;ld (hl), C_DIRSETARGS/256 : inc hl  ; Set high address of routine  XXX may be badly assembled by vasm
        ld (hl), C_DIRSETARGS >> 8 : inc hl  ; Set high address of routine
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
        ;ld (hl), C_READDIR/256 : inc hl ; may be badly assembled by vasm
        ld (hl), C_READDIR >> 8 : inc hl
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



autocomplete_search_completion_on_dirnames_m4
    ; Activate M4 ROM
    
    ; TODO move this code in normal memory ? (I guess once really in ROM, the selection of another ROM will make crash everything)
    ld  c, M4_ROM_NB; TODO programmatically select rom number (already found at init of the prog)
    call FIRMWARE.KL_ROM_SELECT
    push bc ; Backup rom configuration 


.configure_filtering_for_search

        push hl
            call m4_set_dir_filter_from_token ; function in RAM
        pop hl
        jp autocomplete_search_completion_on_filenames_or_dirnames_m4




autocomplete_search_completion_on_filenames_m4
    ; Activate M4 ROM
    
    ; TODO move this code in normal memory ? (I guess once really in ROM, the selection of another ROM will make crash everything)
    ld  c, M4_ROM_NB; TODO programmatically select rom number (already found at init of the prog)
    call FIRMWARE.KL_ROM_SELECT
    push bc ; Backup rom configuration 

.configure_filtering_for_search

        push hl
            call m4_set_file_filter_from_token ; function in RAM
        pop hl

autocomplete_search_completion_on_filenames_or_dirnames_m4


        ld de, (autocomplete.next_filename_address)
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
        ld a, (hl) : cp '>' : jr z, .is_dir
.is_file
        jr .continue
.is_dir
        inc hl: dec a ; Remove >
.continue

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
            ld b, 4 ; we do not care of file size ! so copy only extension
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


        ld (autocomplete.next_filename_address), de

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



;;
; XXX Attention, to work the memory must be appropiratly selected
bndsh_copy_current_rom_rsx_table_in_ram
        ; Select the ROM of interest
        push de

            ld c, a ; backup of a in c (not modified after)
            call FIRMWARE.KL_CURR_SELECTION 
            push af
                

                ; select memory of interest
                call FIRMWARE.KL_ROM_SELECT

                ; copy rsx names in workng memory
                ld  hl, (0xC004)
                ld de, temp.rsx_names
                ld bc, 256
                ldir

            pop af
            ld c, a
            call FIRMWARE.KL_ROM_SELECT

            ld hl, temp.rsx_names
        pop de


    ret




;;
; Check if, for this RSX, there is already an internal command with the same name
; INPUT:
; - de = string to compare to
; OUTPUT:
; - HL is inchanged
; - Z if command present
bndsh_command_exists

    BREAKPOINT_WINAPE

    ld hl, interpreter_command_list
.loop_full
        ld de, interpreter.command_name_buffer
        ; Read the ptr name
        ld c, (hl) : inc hl : ld b, (hl) 


        ; Quit if this is the end
        ld a, b
        or c
        jr z, .end_of_loop_no_match


    if 0
        ld a, (bc)
        ex de, hl :  cp (hl) : ex de, hl

        jr z, .need_to_test
        jr .no_need_to_test
    endif

.need_to_test
;        ; HL: list of commands
;        ; DE: string to compare to
;        ; BC: current string
;
        push hl 
            ld h, b : ld l, c
            call string_compare_ram
        pop hl
        jr z, .end_of_loop_match

.no_need_to_test
        ld de, command - 1 ; alrady moved of one byte
        add hl, de

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

    ld a, (hl) : ;call string_char_to_upper
    call string_char_is_eof_ram
    jr z, .str1_empty

.str1_not_empty
    ld c, a
    ld a, (de)
    ;: call string_char_to_upper :  
    call string_char_is_eof_ram : jr z, .not_equal
.str1_not_empty_and_str2_not_empty
    cp c : jr nz, .not_equal

    inc de : inc hl
    jr .loop

.str1_empty
    ld a, (de) 
    ;: call string_char_to_upper : 
    call string_char_is_eof_ram
    jr z, .equal
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


