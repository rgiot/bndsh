
    org 0x8000

BNDSH_ROM equ 0
BNDSH_EXEC equ 1

    include lib/debug.asm
    



start

        ld de, roms_name.m4 : call bndsh_get_rom_number : ld (system.m4rom), a
        cp 0xff : jr nz, .init_stuff
        ld de, roms_name.pdos : call bndsh_get_rom_number : ld (system.pdosrom), a
        cp 0xff : jr nz, .init_stuff
        
        ; fallback
        ld a, 7

.init_stuff
        ld c, a
        ; sauvegarde lecteur/face courante
        ld hl,(&BE7D)
        ld a,(hl)
        push hl
        push af
        ; initialise la ROM7
        ld hl,&ABFF
        ld de,&0040
        call &BCCE
        ; on reprend sur le même lecteur/face
        pop af
        pop hl
        ld (hl),a



    call bndsh_get_rsx_names
    call bndsh_startup

    call line_editor_init
    call history_init
    jp line_editor_main_loop

    include bndsh.asm

