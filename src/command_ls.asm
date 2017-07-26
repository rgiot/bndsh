interpreter_command_ls

.nbArgs equ 0
.name  string "LS" ; XXX LS
.help string "Display catalog (though |ls)."
.routine
    ;call m4_available : jp nz, interpreter_command_unaivailable

    BREAKPOINT_WINAPE


    ; Set size and address of string parameter 1
    ld hl, (interpreter.next_token_ptr) : call string_word_size : ld (interpreter.param_string1), a
    ld hl, (interpreter.next_token_ptr) : ld (interpreter.param_string1+1), hl

    or a : jr z, .no_argument


.with_argument
    ld hl, rsx_name.ls
    call FIRMWARE.KL_FIND_COMMAND
    jp nc, interpreter_rsx_not_found ; Should never append


     ld ix, interpreter.parameter_buffer
     ld de, interpreter.param_string1 
     ld (ix+0), e
     ld (ix+1), d
     ld a, 1
    call FIRMWARE.KL_FAR_PCHL
    ret

.no_argument
    ld hl, rsx_name.ls
    call FIRMWARE.KL_FIND_COMMAND
    jp nc, interpreter_rsx_not_found ; Should never append
    call FIRMWARE.KL_FAR_PCHL
    ret






