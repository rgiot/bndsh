;;
; Basic interpreter for bndsh.
;
; @author Romain Giot
; @date june 2017
; @licence GPL



    struct command
.name dw 0
.nbArgs db 0
.routine dw 0
    endstruct

;;
; Input
;  - HL: string to parse
interpreter_manage_input
    BREAKPOINT_WINAPE
    ; Ensure we really start at the right position
    call string_move_until_first_nonspace_char  
    
    ; Leave if we have nothing more to do
    ld a, (hl) : call string_char_is_eof : ret z              
    
    ; Copy the first word in order to analyze it
    ; HL is already at the right position
    ld de, interpreter.command_name_buffer 
    call string_copy_word

    
    call interpreter_command_not_found
    ret


interpreter_command_not_found
    ld hl, interpreter_messages : call display_print_string
    ld hl, interpreter.command_name_buffer : call display_print_string
    ret


interpreter_command_list
    command interpreter_command_cat.name, interpreter_command_cat.nbArgs, interpreter_command_cat.routine
    dw 0


interpreter_command_cat
.nbArgs equ 0
.name  string "cat"
.routine
    ld a, '?' : call 0xbb5d
    ret
    



interpreter_messages
    string 'command not found: '

