BNDSH_ROM equ 1
BNDSH_EXEC equ 0

BNDSH_DUMMY_MEMORY_LIMIT equ 0x9000     ; TODO do not use this limit ; compute it and uses as less memory as possible
    
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
    ; TOTALLY stupid; most of these things of WASTE ....
    ld hl, bndsh_rom_data_start
    ld de, BNDSH_DUMMY_MEMORY_LIMIT
    ld bc, bndsh_rom_data_stop - bndsh_rom_data_start
    ldir

    assert (bndsh_rom_data_stop - bndsh_rom_data_start) < (0xa700- 0x9000)

    call bndsh_get_rsx_names  ; XXX Reimplement it does not work for the ROM
    call bndsh_startup ; XXX Reimplement it does not work for the ROM



    call line_editor_init
    jp line_editor_main_loop

    ret
   


    include bndsh.asm

