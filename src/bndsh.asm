    org 0x8000


config_enable_sound equ 1

        ; sauvegarde lecteur/face courante
        ld hl,(&BE7D)
        ld a,(hl)
        push hl
        push af
        ; initialise la ROM7
        ld hl,&ABFF
        ld de,&0040
        ld c,&06 ; XXX found the rom position automatically
        call &BCCE
        ; on reprend sur le même lecteur/face
        pop af
        pop hl
        ld (hl),a




    call line_editor_init

    jp line_editor_main_loop

startup_data
.text    string  "Benediction Shell v0.1 (june 2017)"


    include "lib/debug.asm"
    include "lib/system.asm"
    include "lib/CRTC_detection.asm" ; XXX Attention may not be ROM friendly

    include "line_editor.asm"
    include "interpreter.asm"
    include "display.asm"
    include "string.asm"
    include "history.asm"
    include "autocomplete.asm"


    include "data.asm"
