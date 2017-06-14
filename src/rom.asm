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
    jp bndsh_launch

bndsh_rom_command_table
    defb 'BNDSH RO', 0x80+'M'
    defb 'BNDS', 0x80+'H'
    defb 0


;;
; Only AF can be modified
; Input:
; - HL: higher memory available TODO take it into account
; Output:
; - HL : last memory byte used  TODO put a real vlaue
bndsh_init_rom
    ld hl, BNDSH_DUMMY_MEMORY_LIMIT
    SCF
    ret


;;
; Input:
; IX: parameters in reverse order (none I think)
; A: number of parameters
; IY: memory zone provided (I guess in our case it is always BNDSH_DUMMY_MEMORY_LIMIT)
; C: rom number
bndsh_launch
    ; Select extra memory
    call bndsh_select_extra_memory

    ; TOTALLY stupid; most of these things of WASTE ....
    ld hl, bndsh_rom_data_start
    ld de, BNDSH_DATA_LOCATION
    ld bc, bndsh_rom_data_stop - bndsh_rom_data_start
    ldir

    assert (bndsh_rom_data_stop - bndsh_rom_data_start) < (0xa700- 0x9000)


    ld de, roms_name.m4 : call bndsh_get_rom_number : ld (system.m4rom), a
    cp 0xff : jr nz, .init_stuff
    ld de, roms_name.pdos : call bndsh_get_rom_number : ld (system.pdosrom), a
    cp 0xff : jr nz, .init_stuff

.init_stuff
    call bndsh_get_rsx_names  ; XXX  This stuff is in the extra memory
    call bndsh_startup ; XXX Reimplement it does not work for the ROM



    call line_editor_init
    jp line_editor_main_loop

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


