;;
; Data content for bndsh
; All this stuff is in extra RAM not ROM



key_backspace equ 0x7f
key_del equ 0x10
key_left equ 0xf2
key_right equ 0xf3
key_ctrl_left equ 0xfa
key_ctrl_right equ 0xfb
key_up equ 0xf0
key_down equ 0xf1
key_return equ 0x0d
key_eot equ  0x04
key_tab equ 0x09



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




system
.m4rom db 0xff
.pdosrom db 0xff

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
.refresh_line db 0
.visible_width equ screen.width
.max_width equ 40 ; Max width that can be larger than screen
    assert line_editor.max_width <= screen.width, "[ERROR] Need to code the fact that a line is larger than the screen"
.cursor_xpos db 0 ; XXX is it necessary ?
.cursor_ypos db 0 ; Change with screen scrolling ; XXX is it necessary ?

.copy_cursor_position
.copy_cursor_xpos db 0 ; XXX is it necessary ?
.copy_cursor_ypos db 0 ; Change with screen scrolling ; XXX is it necessary ?

.insert_mode db 0 ; XXX Use 0xb1114 ?


.check_cursor db 1
.autocomplete_start dw 0    ; Start address (in text buffer) of the word for the autocompletion
.autocomplete_stop dw 0    ;  Stop address (in text buffer) of the word for the autocompletion
.autocomplete_word_size dw 0 ; XXX byte is needed
; XXX current widht MUST be before text_buffer in order to STRICTLY have the same structure than the history
.history_pointer
 if BNDSH_EXEC
.current_width db 0
.text_buffer defs .max_width + 2
 endif


interpreter
.max_command_name equ line_editor.max_width
.did_nothing db 0
.command_name_buffer defs .max_command_name
.next_token_ptr dw .command_name_buffer ; Address to the next token in the parsing (typically 1st argument)
.next_token_buffer defs .max_command_name
.param_string1 defs 3
.parameter_buffer defs 2*1

history
.size equ 8 ; XXX ATTENTION must be a power of two
.current db 0
.delta db 0
.buffer1
    defs 256
.buffer2
    defs 256
.buffer3
    defs 256
.buffer4
    defs 256
.buffer5
    defs 256
.buffer6
    defs 256
.buffer7
    defs 256
.buffer8
    defs 256





m4_buffer
    defs 50 ; XXX find its real size

roms_name
.m4 db "M4 BOAR", "D"+0x80, 0
.pdos db "PDO", "S"+0x80, 0

autocomplete
.nb_commands db 0
.commands_ptr_buffer defs 256 ; XXX cmpute its size based on the number of available commands

rsx_names
    defs 512

file_names
