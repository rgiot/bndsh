;;
; Data content for bndsh
;

; TODO properly manage these data buffers to reduce their impact in memory
;
;  - size reduction
;  - buffer reuse
;  - buffers inside extra memory
;  - buffers inside the ROM (the CPC-wifi allows that) - Maybe conditional assembly would allow that for M4 compatibility and sisallow that for other usage

; RSX names have to be in main memory
rsx_name
.dir db "DI", "R"+0x80
.ls db "L", "S"+0x80
.getpath db "GETPAT", "H"+0x80
.era db "ER", "A"+0x80

screen
.cpc_mode equ 1
    if .cpc_mode == 1
.width equ 40
    endif
    if .cpc_mode == 2
.width equ 80
    endif
    if .cpc_mode == 0
        assert 0, "[ERROR] unsoorted mode"
    endif
.crtc_base equ 0x3000
.screen_base equ 0xc000


line_editor
.visible_width equ screen.width
.max_width equ 40
    assert line_editor.max_width <= screen.width, "[ERROR] Need to code the fact that a line is larger than the screen"
.cursor_xpos db 0 ; XXX is it necessary ?
.cursor_ypos db 0 ; Change with screen scrolling ; XXX is it necessary ?
.check_cursor db 1
.autocomplete_start dw 0    ; Start address (in text buffer) of the word for the autocompletion
.autocomplete_stop dw 0    ;  Stop address (in text buffer) of the word for the autocompletion
.autocomplete_word_size dw 0 ; XXX byte is needed
; XXX current widht MUST be before text_buffer in order to STRICTLY have the same structure than the history
.history_pointer
.current_width db 0
.text_buffer defs .max_width + 2


interpreter
.max_command_name equ 256
.did_nothing db 0
.command_name_buffer defs .max_command_name
.next_token_ptr dw .command_name_buffer ; Address to the next token in the parsing (typically 1st argument)
.next_token_buffer defs .max_command_name
.param_string1 defs 3
.parameter_buffer defs 2*1

history
.size equ 5
.current db 0
.buffer1
    db 0 ; Size
    defs line_editor.max_width + 2 ; data
.buffer2
    db 0
    defs line_editor.max_width + 2
.buffer3
    db 0
    defs line_editor.max_width + 2
.buffer4
    db 0
    defs line_editor.max_width + 2
.buffer5
    db 0
    defs line_editor.max_width + 2


autocomplete
.nb_commands db 0
.commands_ptr_buffer defs 256 ; XXX cmpute its size based on the number of available commands

rsx_names
