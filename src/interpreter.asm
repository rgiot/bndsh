;;
; Basic interpreter for bndsh.
;
; @author Romain Giot
; @date june 2017
; @licence GPL



    struct command
name dw 0
help dw 0
routine dw 0
    endstruct

;;
; Input
;  - HL: string to parse
interpreter_manage_input
  xor a: ld (interpreter.did_nothing), a

 if BNDSH_ROM
  ld (line_editor.text_buffer_ptr), hl
 endif

    ; Ensure we really start at the right position
    call string_move_until_first_nonspace_char


    ; Leave if we have nothing more to do
    ld a, (hl) : call string_char_is_eof : ret z ; nothing types
    cp '|' : ret z  ; user wants an RSX

    ld a, 1: ld (interpreter.did_nothing), a




    ; Copy the first word in order to analyze it
    ; HL is already at the right position
    ld de, interpreter.command_name_buffer
    call string_copy_word
    inc de : xor a : ld (de), a ; Add eof Is is needed ?



    ; move until first argument and save its address
    ld a, (hl)
    call string_char_is_eof
    jr z, .no_more_things
      call string_move_until_first_nonspace_char
.no_more_things

    ld (interpreter.next_token_ptr), hl

    ; put string in uppercase
    ld hl, interpreter.command_name_buffer
    call string_string_to_upper

    ld hl, interpreter.command_name_buffer
    call alias_treat_command_name

interpreter_search_and_launch_routine

    ld hl, interpreter_command_list
.loop
        push hl

        ; HL : command list

        ; Read the address name of the current command
        ld c, (hl) : inc hl
        ld b, (hl)


        ; Check if it is the end
        ld a, b
        cp c
        jr z, .end

        ; if no, check if we match the current routine

        ; Need to do the comparison with HL and DE
        ld h, b
        ld l, c
        ld de, interpreter.command_name_buffer
        call string_compare
        jr z, .match


        ; Jump to next command database
        pop hl
        ld de, command
        add hl, de


    jr .loop

.end
    ;; Routine never found
     pop hl ; retreive save value
    jp interpreter_command_not_found

.match

    pop hl ; retreive buffer address
    ld de, command.routine
    add hl, de

    ld e, (hl) : inc hl : ld d, (hl)
    ex de, hl

    jp (hl) ; execute the command





interpreter_command_not_found
.check_if_rsx_exists
  ; Copy word in upper case



  ld hl, interpreter.command_name_buffer
  ld de, interpreter.next_token_buffer
.upper_loop
    ld a, (hl)
    call string_char_is_eof : jr z, .end_upper_loop
    call string_char_is_space : jr z, .end_upper_loop
    call string_char_to_upper
    ld (de), a
    inc hl
    inc de
  jr .upper_loop
.end_upper_loop

  ; Set last RSX char value
  ex de, hl
  dec hl ; By definition there is at least one char
  ld a, (hl) : add 0x80 : ld (hl), a




  ; Check if RSX exists
  ld hl, interpreter.next_token_buffer
  call FIRMWARE.KL_FIND_COMMAND
  jp nc, .try_to_cd

  ; Call the RSX
  push bc : push hl
  ; Retreive the arguments

  if BNDSH_ROM
   ld hl, (line_editor.text_buffer_ptr)
  else
    ld hl, line_editor.text_buffer
  endif

  call string_move_until_null_or_space_char
  call string_move_until_first_nonspace_char
  ld (interpreter.next_token_ptr), hl
  ld a, (hl) : call string_char_is_eof : jr z, .end_of_arguments

; Attention, here we assume the variables are all strings

;; the parameter buffer:
;; - 2 bytes per parameter:
;;   integer constant: the constant
;;   integer variable: address of 2-byte integer variable
;;   string: address of string descriptor block (size + pointer)
;;   real: address of 5-byte real number

;; - parameters are stored in reverse order (last parameter is first
;; in the buffer, first parameter is last in the buffer)
 ld ix, interpreter.parameter_buffer

.has_one_arg

 ; Build the string parameter
 ld hl, (interpreter.next_token_ptr) : call string_word_size : ld (interpreter.param_string1), a
 ld hl, (interpreter.next_token_ptr) : ld (interpreter.param_string1+1), hl

  call string_move_until_null_or_space_char
  call string_move_until_first_nonspace_char
  ld (interpreter.next_token_ptr), hl

 ld a, (hl) : or a
 ld a, 1
 jr z, .set_one_arg

.has_two_args



 ld hl, (interpreter.next_token_ptr) : call string_word_size : ld (interpreter.param_string2), a
 ld hl, (interpreter.next_token_ptr) : ld (interpreter.param_string2+1), hl

 ld a, (hl) : or a
 ld a, 2
 jr z, .set_two_args
 

 jp $ ; XXX Code 3 args

.set_two_args
 ld hl, interpreter.param_string2
 ld (ix+0), l
 ld (ix+1), h
 ld hl, interpreter.param_string1
 ld (ix+2), l
 ld (ix+3), h
 jr .end_of_arguments



.set_one_arg
 ld hl, interpreter.param_string1
 ; Store the string bloc address
 ld (ix+0), l
 ld (ix+1), h


.end_of_arguments
  pop hl: pop bc
  call FIRMWARE.KL_FAR_PCHL

  ret


;; this is not a command, not an rsx, it is maybe a folder
.try_to_cd




    call m4_available : jp nz, .try_to_run
    jp ram_cd_from_interpreter


;;
; Uses the system to load and run the program
.try_to_run
        ; initial code to load an application
        ; Get string size

        ld a, 0xc9: ld (0xbb5a), a ; disable print


        ; Load file
        ; HL=filename
        ; B=filenamesize
        ld hl, interpreter.command_name_buffer 
        ld de, 0x170 ; put string name in the input buffer of basic ...
        call string_copy_word
        xor a
        ld (de), a

        if BNDSH_ROM
           call bndsh_select_normal_memory
        endif

        ld hl, 0x170
        call string_size
        ld b, a


        ld hl, 0x170 ; get name from basic buffer
        ld de, 0xc000
        call FIRMWARE.CAS_IN_OPEN
        jr nc, .did_nothing ; Jump if file note opened




    ;; cas_in_open returns:
    ;; if file was opened successfully:
    ;; - carry is true 
    ;; - HL contains address of the file's AMSDOS header
    ;; - DE contains the load address of the file (from the header)
    ;; - BC contains the length of the file (from the file header)
    ;; - A contains the file type (2 for binary files)

        push hl
            ex de, hl
            call FIRMWARE.CAS_IN_DIRECT
            jr nc, .read_error
            call FIRMWARE.CAS_IN_CLOSE
        pop hl


        ld a, 0xcf: ld (0xbb5a), a ; enable print




        ld de, 26 : or a : add hl, de
        ld e, (hl) : inc hl : ld d, (hl)
        ex de, hl
        ld c, 0xff
        call FIRMWARE.MC_START_PROGRAM


        
        if BNDSH_ROM
            ; go back to normal memory if des not work
            call bndsh_select_extra_memory
        endif

.did_nothing

        xor a : ld (interpreter.did_nothing), a
        ld a, 0xcf: ld (0xbb5a), a ; enable print

  if BNDSH_EXEC

     ld hl, interpreter_messages : call display_print_string
     ld hl, interpreter.command_name_buffer : call display_print_string
  endif
     ret

.read_error
     ld hl, interpreter_messages.read_error : call display_print_string
    ret

interpreter_command_list
    command interpreter_command_basic.name, interpreter_command_basic.help, interpreter_command_basic.routine
;    command interpreter_command_cat.name, interpreter_command_cat.help, interpreter_command_cat.routine  ; XXX No need to create a CAT command, we have the BASIC one 
    command interpreter_command_clear.name, interpreter_command_clear.help, interpreter_command_clear.routine
;    command interpreter_command_cd.name, interpreter_command_cd.name
    command interpreter_command_crtc.name, interpreter_command_crtc.help, interpreter_command_crtc.routine
    command interpreter_command_exit.name, interpreter_command_exit.help, interpreter_command_exit.routine
    command interpreter_command_help.name, interpreter_command_help.help, interpreter_command_help.routine
    command interpreter_command_history.name, interpreter_command_history.help, interpreter_command_history.routine
    command interpreter_command_keys.name, interpreter_command_keys.help, interpreter_command_keys.routine
    command interpreter_command_ls.name, interpreter_command_ls.help, interpreter_command_ls.routine
    command interpreter_command_more.name, interpreter_command_more.help, interpreter_command_more.routine
    command interpreter_command_mv.name, interpreter_command_mv.help, interpreter_command_mv.routine
    command interpreter_command_pwd.name, interpreter_command_pwd.help, interpreter_command_pwd.routine
    command interpreter_command_rom.name, interpreter_command_rom.help, interpreter_command_rom.routine
    command 0, 0




interpreter_command_more
.name string "MORE"
.help string "Display the content of an ASCII file on screen. ESC quit the viewing. SPACE pause the viewing."
.routine
  ld hl, (interpreter.next_token_ptr)
  call more_view_file
  ret



interpreter_command_basic
.name string "BASIC"
.help string "Sends the command to the BASIC interpreter (disambiguity purpose)"
.routine

  ; Get buffer address
  if BNDSH_ROM
   ld hl, (line_editor.text_buffer_ptr)
  endif
  if BNDSH_EXEC
   ld hl, line_editor.text_buffer
  endif

  push hl

  ; compute the next position
  call string_move_until_first_nonspace_char
  call string_move_until_null_or_space_char

  pop de

  ; copy to remove basic keyword
  ld bc, 256
  ldir

  ; inform that nothing has been executed
  xor a : ld (interpreter.did_nothing), a
  ret

interpreter_command_help
.nbArgs equ 0
.name  string "HELP"
.help string "Display the help of each known command\r\nUsage\r\n help\r\n help COMMAND"
.routine

    ; Chose a different method depending on the token
    ld hl, (interpreter.next_token_ptr)
    ld a, (hl)
    call string_char_is_eof
    jr z, .display_full_list

.display_one_token

    ; copy the word of interest in the appropriate buffer
    ld hl, (interpreter.next_token_ptr)
    ld de, interpreter.next_token_buffer
    call string_copy_word
    xor a : ld (de), a

    ld hl, interpreter_command_list
.loop_token

    ; Get the next command name
    ld e, (hl)
    inc hl
    ld d, (hl)

    ; Quit if this is the end of the buffer
    ld a, d
    or e
    jr z, .help_not_displayed

    push hl

        ex de, hl

        push hl ; Store ptr to command name
            ld de, interpreter.next_token_buffer
            call string_compare
        pop hl

        jr nz, .end_display


        ; Move in the right place
      pop hl
      ld de, command.help-1
      add hl, de
      ld e, (hl) : inc hl : ld d, (hl) : ex de, hl
      call display_print_string
      ld a, 10 : call display_print_char
      jr .help_displayed

.end_display

    pop hl ; consumme latesest word
    ld de, command - 1
    add hl, de

    jr .loop_token

.help_not_displayed
    ld hl, interpreter_messages.command_not_found
    call display_print_string
    ld hl, interpreter.next_token_buffer
    call display_print_string

    ret

.help_displayed

    ret

.display_full_list

    call FIRMWARE.TXT_INVERSE
    ld hl, interpreter_messages.internal_commands : call display_print_string
    call FIRMWARE.TXT_INVERSE

    ld hl, interpreter_command_list
.loop_full

    ld e, (hl)
    inc hl
    ld d, (hl)

    ; Quit if this is the end
    ld a, d
    or e
    jr z, .display_rsx

    push hl
        ex de, hl
        call display_print_string

        ld a, ' '
        call display_print_char
    pop hl

    ld de, command - 1
    add hl, de

    jr .loop_full



.display_rsx

   call display_crlf
   call FIRMWARE.TXT_INVERSE
   ld hl, interpreter_messages.rsx: call display_print_string
   call FIRMWARE.TXT_INVERSE

    ld hl, rsx_names
.loop_rsx
    ld a, (hl) : or a : jr z, .display_aliases

    ld a,' ' : call display_print_char
    call display_print_string
    inc hl

    jr .loop_rsx



.display_aliases
    call display_crlf
    call FIRMWARE.TXT_INVERSE
    ld hl, interpreter_messages.aliases: call display_print_string
    call FIRMWARE.TXT_INVERSE

    
    ld hl, alias_table
.loop_aliases

    ld e, (hl) : inc hl
    ld d, (hl) : inc hl

    ld a, e : or d : ret z

    ld a, " " : call display_print_char

    ex de, hl : call display_print_string : ex de, hl

    ld a, "/" : call display_print_char


    ld e, (hl) : inc hl
    ld d, (hl) : inc hl


    ex de, hl : call display_print_string : ex de, hl

    jr .loop_aliases
  ret




interpreter_rsx_not_found
    ld hl, interpreter_messages.rsx_not_found
    call display_print_string
    ld hl, rsx_name.dir
    call display_print_rsx_name; XXX Call a display_print_rsx_name
    ret


  if 0
interpreter_command_cat
.nbArgs equ 0
.name  string "CAT"
.help string "Display catalog (though |dir)."
.routine
;    call m4_available : jr .m4_version
;    
;    ld de, file_names
;    call FIRMWARE.CAS_CATALOG
;    ret
;
;.m4_version
    ld hl, rsx_name.dir
    call FIRMWARE.KL_FIND_COMMAND
    jr nc, interpreter_rsx_not_found ; Should never append
    call FIRMWARE.KL_FAR_PCHL
    ret

 endif


interpreter_command_mv
.name string 'MV'
.help string 'Rename a file. Attention parameter order is the opposite of |REN: MV SOURCE DESTINATION instead of |REN,"DESTINATION","SOURCE"'
.routine


  ld hl, rsx_name.ren
  call FIRMWARE.KL_FIND_COMMAND

  push hl: push bc

 ; TODO check the number of arguments to be sure there are no overflows

 ld ix, interpreter.parameter_buffer

 ; consumme first argument (source)
 ld hl, (interpreter.next_token_ptr) : call string_word_size : ld (interpreter.param_string1), a
 ld hl, (interpreter.next_token_ptr) : ld (interpreter.param_string1+1), hl

 ; Go until next argument
 call string_move_until_null_or_space_char
 call string_move_until_first_nonspace_char
 ld (interpreter.next_token_ptr), hl

 ; consumme second argument (destination)
 ld hl, (interpreter.next_token_ptr) : call string_word_size : ld (interpreter.param_string2), a
 ld hl, (interpreter.next_token_ptr) : ld (interpreter.param_string2+1), hl

 ; Fill the RSX call table
 ld hl, interpreter.param_string1
 ld (ix+0), l :  ld (ix+1), h

 ld hl, interpreter.param_string2
 ld (ix+2), l :  ld (ix+3), h

  pop bc : pop hl
  ld a, 2
  call FIRMWARE.KL_FAR_PCHL
  ret


interpreter_command_clear
.nbArgs equ 0
.name string "CLEAR"
.help string "Clear the screen."
.routine
    call FIRMWARE.TXT_CLEAR_WINDOW
    jp line_editor_init ; XXX Optimize


interpreter_command_crtc
.nbArgs equ 0
.name string "CRTC"
.help string "Print CRTC number."
.routine
    call TestCRTC
    add '0'
    call display_print_char
    ret



interpreter_command_exit
.nbArgs equ 0
.name string "EXIT"
.help string "Go back to basic."
.routine
    call 0



interpreter_command_pwd
.nbArgs equ 0
.name string "PWD"
.help string "Display the current directory"
.routine
    call m4_available : jp nz, interpreter_command_unaivailable

    ld hl, rsx_name.getpath
    call FIRMWARE.KL_FIND_COMMAND
    jp nc, interpreter_rsx_not_found
    ld a, 255
    ld de, interpreter.command_name_buffer ; place to write the result
    call FIRMWARE.KL_FAR_PCHL
    ld hl, interpreter.command_name_buffer
    call display_print_string
    ret

interpreter_command_unaivailable
    ld hl, interpreter_messages.unavailable
    call display_print_string

    ld hl, interpreter.command_name_buffer
    call display_print_string
    ret


interpreter_command_history
.name string "HISTORY"
.help string "Display the 8 lines of history"
.routine
  call history_print
  ret


interpreter_command_rom
.name string "ROM"
.help string "Display the list of available ROMS\r\n (later will do more)"
; XXX i doubt this can work when the application is in a ROM
; XXX Add numbering of the roms
; XXX Add arguments to do something else than lisintg roms (upload, remove, rsx list)
.routine

    ; Save current state of the ROM
    xor a
    call FIRMWARE.KL_ROM_SELECT
    push bc

    xor a
.loop_over_rom
    push af

        ; Select the ROM of interest
        ld c, a
        call FIRMWARE.KL_ROM_SELECT
        ld a, 1 : call FIRMWARE.TXT_SET_COLUMN

        ; Get rom name
        ld  hl,(0xC004)
        call display_print_string2

        ld a, 20 : call FIRMWARE.TXT_SET_COLUMN
    pop af : inc a

    push af

        ; Select the ROM of interest
        ld c, a
        call FIRMWARE.KL_ROM_SELECT

        ; Get rom name
        ld  hl,(0xC004)
        call display_print_string2

        ld a, 10 : call 0xbb5a
        ld a, 13 : call 0xbb5a

        call FIRMWARE.KM_WAIT_CHAR
    pop af : inc a


    cp 32
   jr nz, .loop_over_rom

    
    ; Restore the previous state of the ROM
    pop bc : call FIRMWARE.KL_ROM_SELECT

    ret



interpreter_command_keys
.name string "KEYS"
.help string "Display the keys used by the line editor"
.routine
  ld hl, .description
  call display_print_string_256
  ret
.description
  db 0xf0,": move cursor to the left", 10, 13
	db 243,": move cursor to the right", 10, 13
	db "CONTROL+",242,": move cursor to the beginnig of the line", 10, 13
	db "CONTROL+:",243," move cursor to the end of the line", 10, 13
	db "CONTROL+",240,": move cursor to the beginnig of the text", 10, 13
	db "CONTROL+",241,": move cursor to the end of the text", 10, 13
	db "SHIFT+",242,": move copy cursor to the left", 10, 13
	db "SHIFT+",243,": move copy cursor to the right", 10, 13
	db "SHIFT+",240",: move copy cursor to the up", 10, 13
	db "SHIFT+",241,": move copy cursor to the dowa", 10, 13
	db "CONTROL+TAB: switch between insert/replace modes", 10, 13
	db "BREAK: break the input control flow", 10, 13
	db "ENTER: validate and execute the instruction of the line by the BASIC interpreter", 10, 13
  db 0

interpreter_messages
.command_not_found
    string 'command not found: '
.rsx_not_found
    string 'rsx not found: '
.press_key
    string 'press key to launch: '
.unavailable
    string 'command unavailable: '
.read_error
    string 'read error'
.internal_commands
    string "Internal commands: "
.rsx
    string "RSX:"
.aliases
    string "ALIASES:"


  include src/command_ls.asm
