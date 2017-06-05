;;
; Data content for bndsh
;



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
.cursor_xpos db 0
.cursor_ypos db 0 ; Change with screen scrolling
.check_cursor db 1
.text_buffer defs .visible_width + 2


interpreter
.max_command_name equ 256
.command_name_buffer defs .max_command_name
