FIRMWARE

.GRA_SET_PEN        equ 0xBBDE
.GRA_TEST_ABSOLUTE  equ 0xBBF0
.GRA_PLOT_ABSOLUTE  equ 0xBBEA 

.SCR_SET_MODE       equ 0xBC0E
.SCR_SET_INK        equ 0xBC32
.SCR_SET_BORDER     equ 0xbc38
.SCR_SET_FLASHING   equ 0xbc3e
.SCR_CLEAR          equ 0xbc14

.SCR_GET_MODE       equ 0xBC11
.SCR_GET_INK        equ 0xBC35
.SCR_GET_BORDER     equ 0xBC3B
.SCR_GET_FLASHING   equ 0xBC41
.SCR_GET_LOCATION   equ 0xBC0B

.TXT_OUTPUT         equ 0xbb5a
.TXT_WR_CHAR        equ 0xbb5d
.TXT_SET_CURSOR     equ 0xbb75
.TXT_SET_COLUMN     equ 0xBB6F
.TXT_SET_ROW        equ 0xBB72
.TXT_INVERSE        equ 0xbb9c
.TXT_SET_BACK       equ 0xbb9f
.TXT_PLACE_CURSOR   equ 0xbb8a
.TXT_REMOVE_CURSOR  equ 0xbb8d
.TXT_GET_CURSOR     equ 0xBB78 

.KM_WAIT_CHAR       equ 0xbb06
.KM_READ_CHAR       equ 0xbb09

.KL_ROM_SELECT  equ 0xB90F
.KL_L_ROM_ENABLE EQU 0XB906
.KL_L_ROM_DISABLE EQU 0XB909
.KL_U_ROM_DISABLE EQU 0XB903
.KL_FIND_COMMAND equ 0xbcd4
.KL_FAR_PCHL equ 0x001B 


.CAS_IN_OPEN equ &bc77
.CAS_IN_CLOSE equ &bc7a
.CAS_IN_DIRECT  equ &bc83

.MC_START_PROGRAM equ 0xbd16

    macro KILL_SYSTEM   
        ld hl, 0xc9fb
        ld (0x38), hl
    endm
