;;
; June 2017
; Dumb copy/paste of OS disassembly by Kevin Thacker


input_txt_unknwown_var1_ptr equ 0xb114
input_txt_mode_ptr          equ line_editor.insert_mode
input_txt_copy_cursor_x_ptr equ line_editor.copy_cursor_xpos
input_txt_copy_cursor_y_ptr equ line_editor.copy_cursor_ypos

;;========================================================================================
;; EDIT
;; HL = address of buffer

new_line_editor
input_txt_2c02  push    bc
input_txt_2c03  push    de
input_txt_2c04  push    hl
input_txt_2c05  call    input_txt_reset_copy_cursor            ; reset relative cursor pos
input_txt_2c08  ld      bc,0x00ff         
; B = position in edit buffer
; C = number of characters remaining in buffer

;; if there is a number at the start of the line then skip it
input_txt_2c0b  ld      a,(hl)
input_txt_2c0c  cp      0x30              ; '0'
input_txt_2c0e  jr      c,input_txt_2c17          ; (+0x07)
input_txt_2c10  cp      0x3a              ; '9'+1
input_txt_2c12  call    c,input_txt_2c42
input_txt_2c15  jr      c,input_txt_2c0b          

;;--------------------------------------------------------------------
;; all other characters
input_txt_2c17  ld      a,b
input_txt_2c18  or      a
;; zero flag set if start of buffer, zero flag clear if not start of buffer

input_txt_2c19  ld      a,(hl)
input_txt_2c1a  call    nz,input_txt_2c42

input_txt_2c1d  push    hl
input_txt_2c1e  inc     c
input_txt_2c1f  ld      a,(hl)
input_txt_2c20  inc     hl
input_txt_2c21  or      a
input_txt_2c22  jr      nz,input_txt_2c1e         ; (-0x06)

input_txt_2c24  ld      (input_txt_mode_ptr),a        ; insert/overwrite mode
input_txt_2c27  pop     hl
input_txt_2c28  call    input_txt_2ee4


input_txt_2c2b  push    bc
input_txt_2c2c  push    hl
input_txt_2c2d  call    input_txt_2f56
input_txt_2c30  pop     hl
input_txt_2c31  pop     bc
input_txt_2c32  call    input_txt_2c48            ; process key
input_txt_2c35  jr      nc,input_txt_2c2b         ; (-0x0c)

input_txt_2c37  push    af
input_txt_2c38  call    input_txt_2e4f
input_txt_2c3b  pop     af
input_txt_2c3c  pop     hl
input_txt_2c3d  pop     de
input_txt_2c3e  pop     bc
input_txt_2c3f  cp      0xfc
input_txt_2c41  ret     

;;--------------------------------------------------------------------
;; used to skip characters in input buffer

input_txt_2c42  inc     c
input_txt_2c43  inc     b        ; increment pos
input_txt_2c44  inc     hl       ; increment position in buffer
input_txt_2c45  jp      input_txt_2f25

;;--------------------------------------------------------------------

input_txt_2c48  
input_txt_treat_key                
                push    hl
input_txt_2c49  ld      hl, key_table1 ;input_txt_2c72
input_txt_2c4c  ld      e,a
input_txt_2c4d  ld      a,b
input_txt_2c4e  or      c
input_txt_2c4f  ld      a,e
input_txt_2c50  jr      nz,input_txt_2c5d         ; (+0x0b)

input_txt_2c52  cp      0xf0              ;
input_txt_2c54  jr      c,input_txt_2c5d          ; (+0x07)

input_txt_2c56  cp      0xf4
input_txt_2c58  jr      nc,input_txt_2c5d         ; (+0x03)

;; cursor keys
input_txt_2c5a  ld      hl,input_txt_2cae

;;--------------------------------------------------------------------

input_txt_2c5d  ld      d,(hl)
input_txt_2c5e  inc     hl
input_txt_2c5f  push    hl
input_txt_2c60  inc     hl
input_txt_2c61  inc     hl
input_txt_2c62  cp      (hl)
input_txt_2c63  inc     hl
input_txt_2c64  jr      z,input_txt_2c6a          ; (+0x04)
input_txt_2c66  dec     d
input_txt_2c67  jr      nz,input_txt_2c60         ; (-0x09)
input_txt_2c69  ex      (sp),hl
input_txt_2c6a  pop     af
input_txt_2c6b  ld      a,(hl)
input_txt_2c6c  inc     hl
input_txt_2c6d  ld      h,(hl)
input_txt_2c6e  ld      l,a
input_txt_2c6f  ld      a,e
input_txt_2c70  ex      (sp),hl
input_txt_2c71  ret     

;; keys for editing an existing line
key_table1
input_txt_2c72 
    defb &14 ; +1 for tab
 ;   defw input_txt_2d8a
    defw input_txt_insert_char
    defb &fc                                ; ESC key
    defw input_txt_2cd0                              
    defb &ef
    defw input_txt_2cce
    defb &0d                                ; RETURN key
;    defw input_txt_2cf2
    defw input_txt_key_return
    defb &f0                                ; up cursor key
    defw input_txt_2d3c
    defb &f1                                ; down cursor key
    defw input_txt_2d0a
    defb &f2                                ; left cursor key
    defw input_txt_2d34
    defb &f3                                ; right cursor key
    defw input_txt_2d02
    defb &f8                                ; CTRL key + up cursor key
    defw input_txt_2d4f
    defb &f9                                ; CTRL key + down cursor key
    defw input_txt_2d1d
    defb &fa                                ; CTRL key + left cursor key
    defw input_txt_2d45
    defb &fb                                ; CTRL key + right cursor key
    defw input_txt_2d14
    defb &f4                                ; SHIFT key + up cursor key
    defw input_txt_2e21
    defb &f5                                ; SHIFT key + down cursor key
    defw input_txt_2e26
    defb &f6                                ; SHIFT key + left cursor key
    defw input_txt_2e1c
    defb &f7                                ; SHIFT key + right cursor key
    defw input_txt_2e17                              
    defb &e0                                ; COPY key
    defw input_txt_2e65
    defb &7f                                ; ESC key
    defw input_txt_2dc3
    defb &10                                ; CLR key
    defw input_txt_2dcd
    defb &e1                                ; CTRL key+TAB key (toggle insert/overwrite)
    defw input_txt_2d81
    defb key_tab                            ; TAB key (additional key code for BNDSH)
    defw input_txt_tab
;;--------------------------------------------------------------------

;; keys for 
input_txt_2cae
    defb &04
    defw input_txt_2cfe                              ; Sound bleeper
    defb &f0                                ; up cursor key
    defw input_txt_2cbd                              ; Move cursor up a line
    defb &f1                                ; down cursor key
    defw input_txt_2cc1                              ; Move cursor down a line
    defb &f2                                ; left cursor key
    defw input_txt_2cc9                              ; Move cursor back one character
    defb &f3                                ; right cursor key
    defw input_txt_2cc5                              ; Move cursor forward one character

;;--------------------------------------------------------------------
;; up cursor key pressed
input_txt_2cbd  ld      a,0x0b            ; VT (Move cursor up a line)
input_txt_2cbf  jr      input_txt_2ccb            ; 

;;--------------------------------------------------------------------
;; down cursor key pressed
input_txt_2cc1  ld      a,0x0a            ; LF (Move cursor down a line)
input_txt_2cc3  jr      input_txt_2ccb           

;;--------------------------------------------------------------------
;; right cursor key pressed
input_txt_2cc5  ld      a,0x09            ; TAB (Move cursor forward one character)
input_txt_2cc7  jr      input_txt_2ccb            ; 

;;--------------------------------------------------------------------
;; left cursor key pressed
input_txt_2cc9  ld      a,0x08            ; BS (Move character back one character)

;;--------------------------------------------------------------------

input_txt_2ccb  call    FIRMWARE.TXT_OUTPUT            ; TXT OUTPUT

;;--------------------------------------------------------------------
input_txt_2cce  or      a
input_txt_2ccf  ret     

;;--------------------------------------------------------------------

input_txt_2cd0  call    input_txt_2cf2            ; display message
input_txt_2cd3  push    af
input_txt_2cd4  ld      hl,input_txt_2cea         ; "*Break*"
input_txt_2cd7  call    input_txt_2cf2            ; display message

input_txt_2cda  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2cdd  dec     h
input_txt_2cde  jr      z,input_txt_2ce8          

;; go to next line
input_txt_2ce0  ld      a,0x0d            ; CR (Move cursor to left edge of window on current line)
input_txt_2ce2  call    FIRMWARE.TXT_OUTPUT            ; TXT OUTPUT
input_txt_2ce5  call    input_txt_2cc1            ; Move cursor down a line

input_txt_2ce8  pop     af
input_txt_2ce9  ret     

;;--------------------------------------------------------------------
input_txt_2cea 
    defb "*Break*",0

;;--------------------------------------------------------------------
;; display 0 terminated string
input_txt_key_return
input_txt_2cf2  push af
input_txt_2cf3  ld      a,(hl)           ; get character
input_txt_2cf4  inc     hl
input_txt_2cf5  or      a                ; end of string marker?
input_txt_2cf6  call    nz,input_txt_2f25         ; display character
input_txt_2cf9  jr      nz,input_txt_2cf3         ; loop for next character


    pop af : cp key_return
    jr nz, input_txt_2cfc   

    push af

    ; Launch execution
    ld hl, line_editor.text_buffer
    call interpreter_manage_input

    ld a, (interpreter.did_nothing)
    or a : jr z, .interpreter_did_nothing

.interpreter_acted
    ; Properly set cursor
    ld a, key_return : call FIRMWARE.TXT_OUTPUT
    ld a, key_return : call FIRMWARE.TXT_OUTPUT

.interpreter_did_nothing
input_txt_2cfb  pop     af
input_txt_2cfc  scf     
input_txt_2cfd  ret     

;;===========================================================================
input_txt_2cfe  ld      a,0x07            ; BEL (Sound bleeper)
input_txt_2d00  jr      input_txt_2ccb

;;===========================================================================
;; right cursor key pressed
input_txt_2d02  ld      d,0x01
input_txt_2d04  call    input_txt_2d1e
input_txt_2d07  jr      z,input_txt_2cfe          ; (-0x0b)
input_txt_2d09  ret     

;;===========================================================================
;; down cursor key pressed

input_txt_2d0a  call    input_txt_2d73
input_txt_2d0d  ld      a,c
input_txt_2d0e  sub     b
input_txt_2d0f  cp      d
input_txt_2d10  jr      c,input_txt_2cfe          ; (-0x14)
input_txt_2d12  jr      input_txt_2d1e            ; (+0x0a)

;;--------------------------------------------------------------------
;; CTRL key + right cursor key pressed
;; 
;; go to end of current line
input_txt_2d14  call    input_txt_2d73
input_txt_2d17  ld      a,d
input_txt_2d18  sub     e
input_txt_2d19  ret     z

input_txt_2d1a  ld      d,a
input_txt_2d1b  jr      input_txt_2d1e            ; (+0x01)

;;--------------------------------------------------------------------
;; CTRL key + down cursor key pressed
;;
;; go to end of text 

input_txt_2d1d  ld      d,c

;;--------------------------------------------------------------------

input_txt_2d1e  ld      a,b
input_txt_2d1f  cp      c
input_txt_2d20  ret     z

input_txt_2d21  push    de
input_txt_2d22  call    input_txt_2ecd
input_txt_2d25  ld      a,(hl)
input_txt_2d26  call    nc,input_txt_2f25
input_txt_2d29  inc     b
input_txt_2d2a  inc     hl
input_txt_2d2b  call    nc,input_txt_2ee4
input_txt_2d2e  pop     de
input_txt_2d2f  dec     d
input_txt_2d30  jr      nz,input_txt_2d1e         ; (-0x14)
input_txt_2d32  jr      input_txt_2d70            ; (+0x3c)

;;===========================================================================
;; left cursor key pressed
input_txt_2d34  ld      d,0x01
input_txt_2d36  call    input_txt_2d50
input_txt_2d39  jr      z,input_txt_2cfe          ; (-0x3d)
input_txt_2d3b  ret     


;;===========================================================================
;; up cursor key pressed
input_txt_2d3c  call    input_txt_2d73
input_txt_2d3f  ld      a,b
input_txt_2d40  cp      d
input_txt_2d41  jr      c,input_txt_2cfe          ; (-0x45)
input_txt_2d43  jr      input_txt_2d50            ; (+0x0b)


;;===========================================================================
;; CTRL key + left cursor key pressed
;;
;; go to start of current line

input_txt_2d45  call    input_txt_2d73
input_txt_2d48  ld      a,e
input_txt_2d49  sub     0x01
input_txt_2d4b  ret     z

input_txt_2d4c  ld      d,a
input_txt_2d4d  jr      input_txt_2d50            ; (+0x01)

;;===========================================================================
;; CTRL key + up cursor key pressed

;; go to start of text

input_txt_2d4f  ld      d,c

input_txt_2d50  ld      a,b
input_txt_2d51  or      a
input_txt_2d52  ret     z

input_txt_2d53  call    input_txt_2ec7
input_txt_2d56  jr      nc,input_txt_2d5f         ; (+0x07)
input_txt_2d58  dec     b
input_txt_2d59  dec     hl
input_txt_2d5a  dec     d
input_txt_2d5b  jr      nz,input_txt_2d50         ; (-0x0d)
input_txt_2d5d  jr      input_txt_2d70            ; (+0x11)

;;===========================================================================
input_txt_2d5f  ld      a,b
input_txt_2d60  or      a
input_txt_2d61  jr      z,input_txt_2d6d          ; (+0x0a)
input_txt_2d63  dec     b
input_txt_2d64  dec     hl
input_txt_2d65  push    de
input_txt_2d66  call    input_txt_2ea2
input_txt_2d69  pop     de
input_txt_2d6a  dec     d
input_txt_2d6b  jr      nz,input_txt_2d5f         ; (-0x0e)
input_txt_2d6d  call    input_txt_2ee4
input_txt_2d70  or      0xff
input_txt_2d72  ret     

;;--------------------------------------------------------------------
input_txt_2d73  push    hl
input_txt_2d74  call    FIRMWARE.TXT_GET_WINDOW            ; TXT GET WINDOW
input_txt_2d77  ld      a,d
input_txt_2d78  sub     h
input_txt_2d79  inc     a
input_txt_2d7a  ld      d,a
input_txt_2d7b  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2d7e  ld      e,h
input_txt_2d7f  pop     hl
input_txt_2d80  ret     
;;--------------------------------------------------------------------
;; CTRL key + TAB key
;; 
;; toggle insert/overwrite mode
input_txt_2d81  ld      a,(input_txt_mode_ptr)        ; insert/overwrite mode
input_txt_2d84  cpl     
input_txt_2d85  ld      (input_txt_mode_ptr),a
input_txt_2d88  or      a
input_txt_2d89  ret     

;;--------------------------------------------------------------------

input_txt_insert_char   or      a
input_txt_2d8a  or      a
input_txt_2d8b  ret     z

input_txt_2d8c  ld      e,a
input_txt_2d8d  ld      a,(input_txt_mode_ptr)        ; insert/overwrite mode
input_txt_2d90  or      a
input_txt_2d91  ld      a,c
input_txt_2d92  jr      z,input_txt_2d9f          ; (+0x0b)
input_txt_2d94  cp      b
input_txt_2d95  jr      z,input_txt_2d9f          ; (+0x08)
input_txt_2d97  ld      (hl),e
input_txt_2d98  inc     hl
input_txt_2d99  inc     b
input_txt_2d9a  or      a
input_txt_2d9b  ld      a,e
input_txt_2d9c  jp      input_txt_2f25

input_txt_2d9f  cp      0xff
input_txt_2da1  jp      z,input_txt_2cfe
input_txt_2da4  xor     a
input_txt_2da5  ld      (input_txt_unknwown_var1_ptr),a
input_txt_2da8  call    input_txt_2d9b
input_txt_2dab  inc     c
input_txt_2dac  push    hl
input_txt_2dad  ld      a,(hl)
input_txt_2dae  ld      (hl),e
input_txt_2daf  ld      e,a
input_txt_2db0  inc     hl
input_txt_2db1  or      a
input_txt_2db2  jr      nz,input_txt_2dad         ; (-0x07)
input_txt_2db4  ld      (hl),a
input_txt_2db5  pop     hl
input_txt_2db6  inc     b
input_txt_2db7  inc     hl
input_txt_2db8  call    input_txt_2ee4
input_txt_2dbb  ld      a,(input_txt_unknwown_var1_ptr)
input_txt_2dbe  or      a
input_txt_2dbf  call    nz,input_txt_2ea2
input_txt_2dc2  ret     

;; ESC key pressed
input_txt_2dc3  ld      a,b
input_txt_2dc4  or      a
input_txt_2dc5  call    nz,input_txt_2ec7
input_txt_2dc8  jp      nc,input_txt_2cfe
input_txt_2dcb  dec     b
input_txt_2dcc  dec     hl

;; CLR key pressed
input_txt_2dcd  ld      a,b
input_txt_2dce  cp      c
input_txt_2dcf  jp      z,input_txt_2cfe
input_txt_2dd2  push    hl
input_txt_2dd3  inc     hl
input_txt_2dd4  ld      a,(hl)
input_txt_2dd5  dec     hl
input_txt_2dd6  ld      (hl),a
input_txt_2dd7  inc     hl
input_txt_2dd8  or      a
input_txt_2dd9  jr      nz,input_txt_2dd3         ; (-0x08)
input_txt_2ddb  dec     hl
input_txt_2ddc  ld      (hl),0x20
input_txt_2dde  ld      (input_txt_unknwown_var1_ptr),a
input_txt_2de1  ex      (sp),hl
input_txt_2de2  call    input_txt_2ee4
input_txt_2de5  ex      (sp),hl
input_txt_2de6  ld      (hl),0x00
input_txt_2de8  pop     hl
input_txt_2de9  dec     c
input_txt_2dea  ld      a,(input_txt_unknwown_var1_ptr)
input_txt_2ded  or      a
input_txt_2dee  call    nz,input_txt_2ea6
input_txt_2df1  ret     


;;--------------------------------------------------------------------
;; initialise relative copy cursor position to origin
input_txt_reset_copy_cursor 
input_txt_2df2  xor     a
input_txt_2df3  ld      (input_txt_copy_cursor_x_ptr),a
input_txt_2df6  ld      (input_txt_copy_cursor_y_ptr),a
input_txt_2df9  ret     

;;--------------------------------------------------------------------
;; compare copy cursor relative position
;; HL = cursor position
input_txt_2dfa  ld      de,(input_txt_copy_cursor_x_ptr)
input_txt_2dfe  ld      a,h
input_txt_2dff  xor     d
input_txt_2e00  ret     nz
input_txt_2e01  ld      a,l
input_txt_2e02  xor     e
input_txt_2e03  ret     nz
input_txt_2e04  scf     
input_txt_2e05  ret     
;;--------------------------------------------------------------------

input_txt_2e06  ld      c,a
input_txt_2e07  call    input_txt_2ec1            ; get copy cursor position
input_txt_2e0a  ret     z                ; quit if not active

;; adjust y position
input_txt_2e0b  ld      a,l
input_txt_2e0c  add     a,c
input_txt_2e0d  ld      l,a

;; validate new position
input_txt_2e0e  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE
input_txt_2e11  jr      nc,input_txt_reset_copy_cursor         ; reset relative cursor pos

;; set cursor position
input_txt_2e13  ld      (input_txt_copy_cursor_x_ptr),hl
input_txt_2e16  ret     

;;--------------------------------------------------------------------
;; SHIFT key + left cursor key
;; 
;; move copy cursor left
input_txt_2e17  ld      de,0x0100
input_txt_2e1a  jr      input_txt_2e29            ; (+0x0d)
;;--------------------------------------------------------------------
;; SHIFT key + right cursor pressed
;; 
;; move copy cursor right
input_txt_2e1c  ld      de,0xff00
input_txt_2e1f  jr      input_txt_2e29            ; (+0x08)
;;--------------------------------------------------------------------
;; SHIFT key + up cursor pressed
;;
;; move copy cursor up
input_txt_2e21  ld      de,0x00ff
input_txt_2e24  jr      input_txt_2e29            ; (+0x03)
;;--------------------------------------------------------------------
;; SHIFT key + left cursor pressed
;;
;; move copy cursor down
input_txt_2e26  ld      de,0x0001

;;--------------------------------------------------------------------
;; D = column increment
;; E = row increment
input_txt_2e29  push    bc
input_txt_2e2a  push    hl
input_txt_2e2b  call    input_txt_2ec1            ; get copy cursor position

;; get cursor position
input_txt_2e2e  call    z,FIRMWARE.TXT_GET_CURSOR          ; TXT GET CURSOR

;; adjust cursor position

;; adjust column
input_txt_2e31  ld      a,h
input_txt_2e32  add     a,d
input_txt_2e33  ld      h,a

;; adjust row
input_txt_2e34  ld      a,l
input_txt_2e35  add     a,e
input_txt_2e36  ld      l,a
;; validate the position
input_txt_2e37  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE
input_txt_2e3a  jr      nc,input_txt_2e47         ; position invalid?

;; position is valid

input_txt_2e3c  push    hl
input_txt_2e3d  call    input_txt_2e4f
input_txt_2e40  pop     hl

;; store new position
input_txt_2e41  ld      (input_txt_copy_cursor_x_ptr),hl

input_txt_2e44  call    input_txt_2e4a

;;----------------

input_txt_2e47  pop     hl
input_txt_2e48  pop     bc
input_txt_2e49  ret     

;;--------------------------------------------------------------------

input_txt_2e4a  ld      de,FIRMWARE.TXT_PLACE_CURSOR         ; TXT PLACE CURSOR/TXT REMOVE CURSOR
input_txt_2e4d  jr      input_txt_2e52            

;;--------------------------------------------------------------------
input_txt_2e4f  ld      de,FIRMWARE.TXT_PLACE_CURSOR         ; TXT PLACE CURSOR/TXT REMOVE CURSOR

;;--------------------------------------------------------------------
input_txt_2e52  call    input_txt_2ec1            ; get copy cursor position
input_txt_2e55  ret     z

input_txt_2e56  push    hl
input_txt_2e57  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2e5a  ex      (sp),hl
input_txt_2e5b  call    FIRMWARE.TXT_SET_CURSOR            ; TXT SET CURSOR
input_txt_2e5e  call    FIRMWARE.PCDE_INSTRUCTION            ; LOW: PCDE INSTRUCTION
input_txt_2e61  pop     hl
input_txt_2e62  jp      FIRMWARE.TXT_SET_CURSOR            ; TXT SET CURSOR
;;--------------------------------------------------------------------
;; COPY key pressed
input_txt_2e65  push    bc
input_txt_2e66  push    hl
input_txt_2e67  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2e6a  ex      de,hl
input_txt_2e6b  call    input_txt_2ec1
input_txt_2e6e  jr      nz,input_txt_2e7c         ; perform copy
input_txt_2e70  ld      a,b
input_txt_2e71  or      c
input_txt_2e72  jr      nz,input_txt_2e9a         ; (+0x26)
input_txt_2e74  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2e77  ld      (input_txt_copy_cursor_x_ptr),hl
input_txt_2e7a  jr      input_txt_2e82            ; (+0x06)

;;--------------------------------------------------------------------

input_txt_2e7c  call    FIRMWARE.TXT_SET_CURSOR            ; TXT SET CURSOR
input_txt_2e7f  call    FIRMWARE.TXT_PLACE_CURSOR            ; TXT PLACE CURSOR/TXT REMOVE CURSOR

input_txt_2e82  call    FIRMWARE.TXT_RD_CHAR            ; TXT RD CHAR
input_txt_2e85  push    af
input_txt_2e86  ex      de,hl
input_txt_2e87  call    FIRMWARE.TXT_SET_CURSOR            ; TXT SET CURSOR
input_txt_2e8a  ld      hl,(input_txt_copy_cursor_x_ptr)
input_txt_2e8d  inc     h
input_txt_2e8e  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE
input_txt_2e91  jr      nc,input_txt_2e96         ; (+0x03)
input_txt_2e93  ld      (input_txt_copy_cursor_x_ptr),hl
input_txt_2e96  call    input_txt_2e4a
input_txt_2e99  pop     af
input_txt_2e9a  pop     hl
input_txt_2e9b  pop     bc
input_txt_2e9c  jp      c,input_txt_2d8a
input_txt_2e9f  jp      input_txt_2cfe

;;--------------------------------------------------------------------

input_txt_2ea2  ld      d,0x01
input_txt_2ea4  jr      input_txt_2ea8            ; (+0x02)

;;--------------------------------------------------------------------

input_txt_2ea6  ld      d,0xff
;;--------------------------------------------------------------------
input_txt_2ea8  push    bc
input_txt_2ea9  push    hl
input_txt_2eaa  push    de
input_txt_2eab  call    input_txt_2e4f
input_txt_2eae  pop     de
input_txt_2eaf  call    input_txt_2ec1
input_txt_2eb2  jr      z,input_txt_2ebd          ; (+0x09)
input_txt_2eb4  ld      a,h
input_txt_2eb5  add     a,d
input_txt_2eb6  ld      h,a
input_txt_2eb7  call    input_txt_2e0e
input_txt_2eba  call    input_txt_2e4a
input_txt_2ebd  pop     hl
input_txt_2ebe  pop     bc
input_txt_2ebf  or      a
input_txt_2ec0  ret     

;;--------------------------------------------------------------------
;; get copy cursor position
;; this is relative to the actual cursor pos
;;
;; zero flag set if cursor is not active
input_txt_2ec1  ld      hl,(input_txt_copy_cursor_x_ptr)
input_txt_2ec4  ld      a,h
input_txt_2ec5  or      l
input_txt_2ec6  ret  

;;--------------------------------------------------------------------
;; try to move cursor left?
input_txt_2ec7  push    de
input_txt_2ec8  ld      de,0xff08
input_txt_2ecb  jr      input_txt_2ed1            ; (+0x04)

;;--------------------------------------------------------------------
;; try to move cursor right?
input_txt_2ecd  push    de
input_txt_2ece  ld      de,0x0109
;;--------------------------------------------------------------------
;; D = column increment
;; E = character to plot
input_txt_2ed1  push    bc
input_txt_2ed2  push    hl

;; get current cursor position
input_txt_2ed3  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR

;; adjust cursor position
input_txt_2ed6  ld      a,d              ; column increment
input_txt_2ed7  add     a,h              ; add on column
input_txt_2ed8  ld      h,a              ; final column

;; validate this new position
input_txt_2ed9  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE

;; if valid then output character, otherwise report error
input_txt_2edc  ld      a,e
input_txt_2edd  call    c,FIRMWARE.TXT_OUTPUT          ; TXT OUTPUT

input_txt_2ee0  pop     hl
input_txt_2ee1  pop     bc
input_txt_2ee2  pop     de
input_txt_2ee3  ret     

;;--------------------------------------------------------------------
input_txt_2ee4  push    bc
input_txt_2ee5  push    hl
input_txt_2ee6  ex      de,hl
input_txt_2ee7  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2eea  ld      c,a
input_txt_2eeb  ex      de,hl
input_txt_2eec  ld      a,(hl)
input_txt_2eed  inc     hl
input_txt_2eee  or      a
input_txt_2eef  call    nz,input_txt_2f02
input_txt_2ef2  jr      nz,input_txt_2eec         ; (-0x08)
input_txt_2ef4  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2ef7  sub     c
input_txt_2ef8  ex      de,hl
input_txt_2ef9  add     a,l
input_txt_2efa  ld      l,a
input_txt_2efb  call    FIRMWARE.TXT_SET_CURSOR            ; TXT SET CURSOR
input_txt_2efe  pop     hl
input_txt_2eff  pop     bc
input_txt_2f00  or      a
input_txt_2f01  ret     

input_txt_2f02  push    af
input_txt_2f03  push    bc
input_txt_2f04  push    de
input_txt_2f05  push    hl
input_txt_2f06  ld      b,a
input_txt_2f07  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2f0a  sub     c
input_txt_2f0b  add     a,e
input_txt_2f0c  ld      e,a
input_txt_2f0d  ld      c,b
input_txt_2f0e  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE
input_txt_2f11  jr      c,input_txt_2f18          ; (+0x05)
input_txt_2f13  ld      a,b
input_txt_2f14  add     a,a
input_txt_2f15  inc     a
input_txt_2f16  add     a,e
input_txt_2f17  ld      e,a
input_txt_2f18  ex      de,hl
input_txt_2f19  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE
input_txt_2f1c  ld      a,c
input_txt_2f1d  call    c,input_txt_2f25
input_txt_2f20  pop     hl
input_txt_2f21  pop     de
input_txt_2f22  pop     bc
input_txt_2f23  pop     af
input_txt_2f24  ret     

input_txt_2f25  push    af
input_txt_2f26  push    bc
input_txt_2f27  push    de
input_txt_2f28  push    hl
input_txt_2f29  ld      b,a
input_txt_2f2a  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2f2d  ld      c,a
input_txt_2f2e  push    bc
input_txt_2f2f  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE
input_txt_2f32  pop     bc
input_txt_2f33  call    c,input_txt_2dfa
input_txt_2f36  push    af
input_txt_2f37  call    c,input_txt_2e4f
input_txt_2f3a  ld      a,b
input_txt_2f3b  push    bc
input_txt_2f3c  call    FIRMWARE.TXT_WR_CHAR            ; TXT WR CHAR
input_txt_2f3f  pop     bc
input_txt_2f40  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2f43  sub     c
input_txt_2f44  call    nz,input_txt_2e06
input_txt_2f47  pop     af
input_txt_2f48  jr      nc,input_txt_2f51         ; (+0x07)
input_txt_2f4a  sbc     a,a
input_txt_2f4b  ld      (input_txt_unknwown_var1_ptr),a
input_txt_2f4e  call    input_txt_2e4a
input_txt_2f51  pop     hl
input_txt_2f52  pop     de
input_txt_2f53  pop     bc
input_txt_2f54  pop     af
input_txt_2f55  ret     

input_txt_2f56  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2f59  ld      c,a
input_txt_2f5a  call    FIRMWARE.TXT_VALIDATE            ; TXT VALIDATE
input_txt_2f5d  call    input_txt_2dfa
input_txt_2f60  jp      c,FIRMWARE.KM_WAIT_CHAR          ; KM WAIT CHAR
input_txt_2f63  call    FIRMWARE.TXT_CUR_ON            ; TXT CUR ON
input_txt_2f66  call    FIRMWARE.TXT_GET_CURSOR            ; TXT GET CURSOR
input_txt_2f69  sub     c
input_txt_2f6a  call    nz,input_txt_2e06
input_txt_2f6d  call    FIRMWARE.KM_WAIT_CHAR            ; KM WAIT CHAR
input_txt_2f70  jp      FIRMWARE.TXT_CUR_OFF            ; TXT CUR OFF



;;
; Manage the autocompletion stuff
; HL = pointer to the current position in the text
input_txt_tab
    push de : push af : push bc : push hl  ; XXX Check which one are really usefull


    BREAKPOINT_WINAPE
    ; Save current position
    ld (line_editor.autocomplete_stop), hl

    ; Compute the address of the first char of the current word
    ld a, b : or a ; test if string is empty
    jr z, .save_beginning

 ;   In any case go to previous char

    ld a, (hl) : or a; test if we are on the null char and that we have a
    dec hl ; go to previous char
    
    ld a, (hl) : cp ' '
    jr nz, .move_to_beginning
    ld hl, (line_editor.autocomplete_stop)
    jr .save_beginning
    ld (line_editor.autocomplete_stop), hl

.move_to_beginning
    call string_go_to_beginning_of_current_word ; XXX Need to check if we can go out
.save_beginning
    ld (line_editor.autocomplete_start), hl

    ; Get the size of the string
    ld hl, (line_editor.autocomplete_stop)
    ld de, (line_editor.autocomplete_start)
    or a
    sbc hl, de
    inc hl
    ld (line_editor.autocomplete_word_size), hl

    ; Copy the word to the appropriate buffer
    ld b, h : ld c, l                       ; BC = Size of string
    ex de, hl                               ; HL = Start of the string
    ld de, interpreter.command_name_buffer  ; DE = bufferto write
    ldir
    xor a : ld (de), a

    call autocomplete_reset_buffers 
    call autocomplete_search_completions

    call autocomplete_get_number_of_completions
    or a : jr z, .autocomplete_no_completion
    cp 1 : jr z, .autocomplete_insert_completion

.autocomplete_print_completion
    call FIRMWARE.TXT_GET_CURSOR
    push hl
        ; TODO Save scroll number to properly treat completions atthe end of the screen
        call .move_to_completion_place
        call autocomplete_print_completions ; TODO add something to clear the completions previously displayed
    pop hl
    call FIRMWARE.TXT_SET_CURSOR


.autocomplete_no_completion
    call FIRMWARE.TXT_GET_CURSOR
    push hl

    ld b, 40; XXX erase the right amount of completion (depend on the previous completion)
.autocomplete_no_completion_line_loop
        push bc : ld a, ' ' : call FIRMWARE.TXT_WR_CHAR : pop bc
        djnz .autocomplete_no_completion_line_loop
    pop hl
    call FIRMWARE.TXT_SET_CURSOR
    jr .exit

.autocomplete_insert_completion



    call autocomplete_get_unique_completion
    ex de, hl
    pop hl  ; we lost it and replace by the computed stuff

    ld hl, (line_editor.autocomplete_start)
    ; DE = source to copy
    ; HL = buffer position

    ; Skip the prefix
    dec de : dec hl
.autocomplete_insert_completion_skip_loop
    inc de: inc hl
    ld a, (de)
    cp (hl)
    jr z, .autocomplete_insert_completion_skip_loop ; XXX I'm sure it can bug as we do not test position in buffer



    ; BC = current string length
    pop bc
    ; insert the suffix
.autocomplete_insert_completion_loop

    ld a, (de) : inc de
    or a
    jr z, .autocomplete_insert_completion_end_loop
    push de
        call input_txt_insert_char
    pop de
    jr .autocomplete_insert_completion_loop
.autocomplete_insert_completion_end_loop
    
    
    pop af : pop de
    ret





.exit
    pop hl : pop bc :  pop af : pop de 
    ret

.move_to_completion_place
      call display_crlf ; TODO move to the end of the edit string before that (to not smash multi line edit)
    ret





line_editor_init
line_editor_clear_buffers
    call history_save_current_context ; For performance reasons, I think it is better to save history here and not before launching a command that may never return

    ld a, -1
    ld (history.current), a

    xor a
    ld (line_editor.text_buffer), a

    ld a, ' '
    ld (line_editor.text_buffer), a


    xor a
    ld (line_editor.cursor_xpos), a
    ld (line_editor.current_width), a
    ret


line_editor_main_loop


.loop


    ; TODO add a function for that
    ; TODO add sstuff to manage history    
    ld a, 10 : call 0xbb5a : ld a, 13: call 0xbb5a

    ld hl, line_editor.text_buffer
    xor a : ld (hl), a

    call new_line_editor ; XXX Use the appropriate firmware functin
    ld hl, line_editor.text_buffer
    call display_print_string


    jp .loop
