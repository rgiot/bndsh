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

    ; Ensure we really start at the right position
    call string_move_until_first_nonspace_char

    ; Leave if we have nothing more to do
    ld a, (hl) : call string_char_is_eof : ret z

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
    ld hl, interpreter_messages : call display_print_string
    ld hl, interpreter.command_name_buffer : call display_print_string
    ret


interpreter_command_list
    command interpreter_command_cat.name, interpreter_command_cat.help, interpreter_command_cat.routine
    command interpreter_command_clear.name, interpreter_command_clear.help, interpreter_command_clear.routine
;    command interpreter_command_cd.name, interpreter_command_cd.name
    command interpreter_command_crtc.name, interpreter_command_crtc.help, interpreter_command_crtc.routine
    command interpreter_command_exit.name, interpreter_command_exit.help, interpreter_command_exit.routine
    command interpreter_command_help.name, interpreter_command_help.help, interpreter_command_help.routine
    command interpreter_command_ls.name, interpreter_command_ls.help, interpreter_command_ls.routine
    command interpreter_command_pwd.name, interpreter_command_pwd.help, interpreter_command_pwd.routine
    command 0, 0



interpreter_command_help
.nbArgs equ 0
.name  string "help"
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

          BREAKPOINT_WINAPE

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

    ld hl, interpreter_command_list
.loop_full

    ld e, (hl)
    inc hl
    ld d, (hl)

    ; Quit if this is the end
    ld a, d
    or e
    ret z

    push hl
        ex de, hl
        call display_print_string

        ld a, ' '
        call display_print_char
    pop hl

    ld de, command - 1
    add hl, de

    jr .loop_full



    ret






interpreter_rsx_not_found
    ld hl, interpreter_messages.rsx_not_found
    call display_print_string
    ld hl, rsx_name.dir
    call display_print_rsx_name; XXX Call a display_print_rsx_name
    ret


interpreter_command_cat
.nbArgs equ 0
.name  string "cat"
.help string "Display catalog (though |dir)."
.routine
    ld hl, rsx_name.dir
    call FIRMWARE.KL_FIND_COMMAND
    jr nc, interpreter_rsx_not_found ; Should never append
    call FIRMWARE.KL_FAR_PCHL
    ret

interpreter_command_ls
.nbArgs equ 0
.name  string "ls"
.help string "Display catalog (though |ls)."
.routine
    ld hl, rsx_name.ls
    call FIRMWARE.KL_FIND_COMMAND
    jr nc, interpreter_rsx_not_found ; Should never append
    call FIRMWARE.KL_FAR_PCHL
    ret





interpreter_command_clear
.nbArgs equ 0
.name string "clear"
.help string "Clear the screen."
.routine
    ;call FIRMWARE.SCR_CLEAR
    jp line_editor_init ; XXX Optimize


interpreter_command_crtc
.nbArgs equ 0
.name string "crtc"
.help string "Print CRTC number."
.routine
    call TestCRTC
    add '0'
    call display_print_char
    ret



interpreter_command_exit
.nbArgs equ 0
.name string "exit"
.help string "Go back to basic."
.routine
    call 0



interpreter_command_pwd
.nbArgs equ 0
.name string "pwd"
.help string "Display the current directory"
.routine
    ld hl, rsx_name.getpath
    call FIRMWARE.KL_FIND_COMMAND
    jp nc, interpreter_rsx_not_found
    ld a, 255
    ld de, interpreter.command_name_buffer ; place to write the result
    call FIRMWARE.KL_FAR_PCHL
    ld hl, interpreter.command_name_buffer
    call display_print_string
    ret

interpreter_messages
.command_not_found
    string 'command not found: '
.rsx_not_found
    string 'rsx not found: '
