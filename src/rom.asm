BNDSH_ROM equ 1
BNDSH_EXEC equ 0

BNDSH_DUMMY_MEMORY_LIMIT    equ 0x9000     ; TODO do not use this limit ; compute it and uses as less memory as possible (BTW now data is in extra RAM, it si not usefull)
BNDSH_DATA_LOCATION         equ 0x4000
BNDSH_EXTRA_BANK_SELECTION   equ %11111111  ; Extra memory is in last page of last bank accessible in 0x4000
BNDSH_CPC_BANK_SELECTION     equ 0xc0

    
                org 0xc000

ROM
.type               db 0x01 ; Background 0x80 for foreground (maybe the best choice ?)
.version            db 0x00, 0x00, 0x01
.command_table_ptr  dw bndsh_rom_command_table
.execution_table  
    jp bndsh_init_rom
    jp cpcget_search_rsx
    jp cpcget_download_dsk

bndsh_rom_command_table
    defb 'BNDSH RO', 0x80+'M'
    defb 'DSKSEARC', 0x80+'H'
    defb 'DSKGE', 0x80+'T'
    defb 0


;;
; Only AF can be modified
; Input:
; - HL: higher memory available TODO take it into account
; Output:
; - HL : last memory byte used  TODO put a real vlaue
bndsh_init_rom
    push de : push bc
    ; Rom takes only the space of its command
    ld de, 10 + 1 ; space for the far call
    and a
    sbc hl, de ; get space for the autocmd

    push hl

; XXX it seems firmware does not work here ...
; XXX this routine must be buggy
; Test clavier de la ligne
; dont le numéro est dans D
; D doit contenir une valeur de 0 à 9
;
  ld d, 8
        ld bc,&f40e  ; Valeur 14 sur le port A
        out (c),c
        ld bc,&f6c0  ; C'est un registre
        out (c),c    ; BDIR=1, BC1=1
        ld bc,&f600  ; Validation
        out (c),c
        ld bc,&f792  ; Port A en entrée
        out (c),c
        ld a,d       ; A=ligne clavier
        or %01000000 ; BDIR=0, BC1=1
        ld b,&f6
        out (c),a
        ld b,&f4     ; Lecture du port A
        in a,(c)     ; A=Reg 14 du PSG
        ld bc,&f782  ; Port A en sortie
        out (c),c
        ld bc,&f600  ; Validation
        out (c),c
; Et A contient la ligne
        bit 2, a
        jr z, .leave_init

.no_key_pressed

        call bndsh_select_extra_memory


            ; copy other things in extra memory
            ld hl, bndsh_rom_data_start
            ld de, BNDSH_DATA_LOCATION
            ld bc, bndsh_rom_data_stop - bndsh_rom_data_start
            ldir



            ld de, roms_name.m4 : call bndsh_get_rom_number : ld (system.m4rom), a
            cp 0xff : jr nz, .init_stuff
            ld de, roms_name.pdos : call bndsh_get_rom_number : ld (system.pdosrom), a
            cp 0xff : jr nz, .init_stuff

.init_stuff
            call bndsh_get_rsx_names  ; XXX  This stuff is in the extra memory
            call bndsh_startup ; XXX Reimplement it does not work for the ROM



            call line_editor_init
            call history_init

    pop hl 
    push hl ; retreive address
            inc hl
            call input_txt_replace_firmware


            call bndsh_select_normal_memory

.leave_init
    pop hl ; retreive memory after space removal
    pop bc : pop de
    SCF
    ret


;;
; Input:
; IX: parameters in reverse order (none I think)
; A: number of parameters
; IY: memory zone provided (I guess in our case it is always BNDSH_DUMMY_MEMORY_LIMIT)
; C: rom number
bndsh_select_memory

  ; TODO backup the user choice of memory selection

    ret
   



bndsh_select_extra_memory
    ld bc, 0x7f00 + BNDSH_EXTRA_BANK_SELECTION
    out (c), c
    ret

bndsh_select_normal_memory
    ld bc, 0x7f00 + BNDSH_CPC_BANK_SELECTION
    out (c), c
    ret

    include bndsh.asm


