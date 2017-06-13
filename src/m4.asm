
DATAPORT                        equ 0xFE00
ACKPORT                     equ 0xFC00

C_OPEN                      equ 0x4301
C_READ                      equ 0x4302
C_WRITE                     equ 0x4303
C_CLOSE                     equ 0x4304
C_SEEK                      equ 0x4305
C_READDIR                       equ 0x4306
C_EOF                       equ 0x4307
C_CD                            equ 0x4308
C_FREE                          equ 0x4309
C_FTELL                     equ 0x430A
C_READSECTOR                    equ 0x430B
C_WRITESECTOR                   equ 0x430C
C_FORMATTRACK                   equ 0x430D
C_ERASEFILE                 equ 0x430E
C_RENAME                        equ 0x430F
C_MAKEDIR                       equ 0x4310
C_FSIZE                     equ 0x4311
C_READ2                     equ 0x4312
C_GETPATH                       equ 0x4313
C_SDREAD                        equ 0x4314
C_SDWRITE                       equ 0x4315
C_FSTAT                     equ 0x4316  
C_HTTPGET                       equ 0x4320
C_SETNETWORK                    equ 0x4321
C_M4OFF                     equ 0x4322
C_NETSTAT                       equ 0x4323
C_TIME                      equ 0x4324
C_DIRSETARGS                    equ 0x4325
C_VERSION                       equ 0x4326
C_UPGRADE                       equ 0x4327
C_HTTPGETMEM                    equ 0x4328
C_COPYBUF                       equ 0x4329
C_COPYFILE                  equ 0x432A
C_ROMSUPDATE                    equ 0x432B
C_ROMLIST                       equ 0x432C
C_CMDRBTRUN                 equ 0x432D


C_NETSOCKET                 equ 0x4331
C_NETCONNECT                    equ 0x4332
C_NETCLOSE                  equ 0x4333
C_NETSEND                       equ 0x4334
C_NETRECV                       equ 0x4335
C_NETHOSTIP                 equ 0x4336
C_NETRSSI                       equ 0x4337
C_NETBIND                       equ 0x4338
C_NETLISTEN                 equ 0x4339
C_NETACCEPT                 equ 0x433A
C_GETNETWORK                    equ 0x433B
C_WIFIPOW                       equ 0x433C

C_ROMCP                     equ 0x43FC
C_ROMWRITE                  equ 0x43FD
C_CONFIG                        equ 0x43FE

C_WRITE_COC equ 0x4343




pdos_available
    ld a, (system.pdosrom)
    jr m4_available.test_rom



m4_available
    ld a, (system.m4rom)
.test_rom
    cp 0xff
    jr z, .absent
.present
    cp a
    ret
.absent
    or 1
    ret

m4_send_command
            ld  bc,DATAPORT             ; FE data out port
            ld  d,(hl)                      ; size
            inc d
sendloop        inc b
            outi
            dec d
            jr  nz, sendloop
            
            ; tell M4 that command has been send
        
            ld  bc,ACKPORT
            out (c),c
            ret
            
m4_send_command_iy
            push    iy
            pop hl
            ld  bc,DATAPORT ;0xFE00         ; FE data out port
            ld  a,(hl)                      ; size
            inc a
sendloop_iy
            inc b
            outi
            dec a
            jr  nz, sendloop_iy
            
            ; tell M4 that command has been send
        
            ld  bc,#ACKPORT
            out (c),c
            ret




m4_set_dir_filter_from_token
    if 1


        ; Compute the size of the command to send
        ld hl, interpreter.command_name_buffer
        call string_size
.min_size equ 2 + 1 + 1  ; arguments + * + 0 
        add .min_size


        ld hl, m4_buffer
        ld (hl), a : inc hl                 ; Set size of the parameters                 
        ld (hl), C_DIRSETARGS%256 : inc hl  ; Set low address of routine
        ld (hl), C_DIRSETARGS/256 : inc hl  ; Set high address of routine
     ;   ld (hl), 0x25 : inc hl
     ;   ld (hl), 0x43 : inc hl

        cp .min_size
        jp z, .no_proposal
            ex de, hl
                ld hl, interpreter.command_name_buffer
                call string_copy_word
            ex de,hl
          ;  dec hl                              ; go one char before the end of string
.no_proposal
        ld (hl), '*' : inc hl               ; Set wildcard
        ld (hl), 0 : inc hl               ; Set wildcard
    else

        ; Display directory starting with m
        ld hl, m4_buffer
        ld (hl), 5 : inc hl                 ; Set size of the parameters                 
        ld (hl), 0x25 : inc hl
        ld (hl), 0x43 : inc hl
        ld (hl), 'T'  : inc hl
        ld (hl), '*'  : inc hl
        ld (hl), 0

    endif


        ld hl, m4_buffer: call m4_send_command
        ret
