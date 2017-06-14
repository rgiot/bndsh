 ;;
; Basic interpreter for bndsh.
;
; @author Romain Giot
; @date june 2017
; @licence GPL



 
    include "lib/debug.asm"

M4_ROM_NB equ 6 ; TODO remove that for a final version

config_enable_sound equ 1





bndsh_startup
    ld a, screen.cpc_mode
    call FIRMWARE.SCR_SET_MODE


    ld hl, startup_data.text : call display_print_string
    
    call m4_available : jr nz, .no_m4
    ld hl, startup_data.m4 : call display_print_string
.no_m4

    call pdos_available : jr nz, .no_pdos
    ld hl, startup_data.pdos : call display_print_string
.no_pdos
    ret






startup_data
.text    string  "Benediction Shell v0.1a      (june 2017)"
.m4      string  "                            M4 detected."
.pdos    string  " (do not still work)   Parados detected."


    include "lib/system.asm"
    include "lib/CRTC_detection.asm" ; XXX Attention may not be ROM friendly

    include "line_editor.asm"
    include "interpreter.asm"
    include "display.asm"
    include "string.asm"
    include "history.asm"
    include "autocomplete.asm"



    if BNDSH_EXEC
        include "m4.asm"
        include "code_in_ram.asm"
        include "data.asm"
    endif

    if BNDSH_ROM
bndsh_rom_data_start
        rorg BNDSH_DATA_LOCATION
            include "m4.asm"
            include "code_in_ram.asm"
            include "data.asm"
        rend
bndsh_rom_data_stop
    endif
