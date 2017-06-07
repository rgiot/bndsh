;;
; Basic interpreter for bndsh.
;
; @author Romain Giot
; @date june 2017
; @licence GPL



    struct command
name dw 0
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

    
    ; Searhc and launch routine
    call interpreter_search_and_launch_routine

    ret



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
    ld de, 2 ;command.routine
    add hl, de

    ld e, (hl) : inc hl : ld d, (hl)
    ex de, hl

    jp (hl) ; execute the command


    


interpreter_command_not_found
    ld hl, interpreter_messages : call display_print_string
    ld hl, interpreter.command_name_buffer : call display_print_string
    ret


interpreter_command_list
    command interpreter_command_cat.name, interpreter_command_cat.routine
    command interpreter_command_clear.name, interpreter_command_clear.routine
    command interpreter_command_crtc.name, interpreter_command_crtc.routine
    command interpreter_command_exit.name, interpreter_command_exit.routine
    command interpreter_command_ls.name, interpreter_command_ls.routine
    command interpreter_command_help.name, interpreter_command_help.routine
    command 0, 0



interpreter_command_help
.nbArgs equ 0
.name  string "help"
.routine

    ld hl, interpreter_command_list

.loop

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

    jr .loop



    ret



interpreter_command_cat
.nbArgs equ 0
.name  string "cat"
.routine
    ld hl, rsx_name.dir
    call FIRMWARE.KL_FIND_COMMAND
    jr nc, interpreter_rsx_not_found ; Should never append
    call FIRMWARE.KL_FAR_PCHL
    ret

interpreter_command_ls
.nbArgs equ 0
.name  string "ls"
.routine
    ld hl, rsx_name.ls
    call FIRMWARE.KL_FIND_COMMAND
    jr nc, interpreter_rsx_not_found ; Should never append
    call FIRMWARE.KL_FAR_PCHL
    ret





interpreter_rsx_not_found
    ld hl, interpreter_messages.rsx_not_found
    call display_print_string
    ld hl, rsx_name.dir
    call display_print_rsx_name; XXX Call a display_print_rsx_name
    ret


interpreter_command_clear
.nbArgs equ 0
.name string "clear"
.routine
    ;call FIRMWARE.SCR_CLEAR
    jp line_editor_init ; XXX Optimize
    

interpreter_command_crtc
.nbArgs equ 0
.name string "crtc"
.routine
    call TestCRTC
    add '0'
    call display_print_char
    ret



interpreter_command_exit
.nbArgs equ 0
.name string "exit"
.routine
    call 0

interpreter_messages
.command_not_found
    string 'command not found: '
.rsx_not_found
    string 'rsx not found: '

