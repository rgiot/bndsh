    org 0x4000

    call line_editor_init
    jp line_editor_main_loop
    

    include "lib/debug.asm"
    include "lib/system.asm"
    include "line_editor.asm"
    include "interpreter.asm"
    include "display.asm"
    include "string.asm"
    include "data.asm"
