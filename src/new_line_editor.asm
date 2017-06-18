;;
; Rewrite of the line editor to have something which looks more like the BASIC's one
; (so code is mainly copied from it)


new_line_editor_mode_insert equ 0
new_line_editor_mode_erase equ 1

;;
; Permanents registers :
;  - HL = buffer pointer
;  - B = position in buffer
;  - C = width



; OS Mapping
; - b116 copy cursor position copy_cursor_xpos, ypos
; - b114 ???
; - b115 insert/overwrite 

;;
; Manage the line and leave only when Enter is pressed
new_line_editor
    push bc : push de : push hl
        call new_line_editor_init_copy_cursor



    ; Manage string
    ld bc,0x00ff ; position in buffer / width


    ld a, (hl)

    push hl
.initial_string_not_finished
    inc c ; count number of char
    ld a, (hl) : inc hl  ; Get current char
    or a : jr nz, .initial_string_not_finished
.set_up_input_mode
    ld (line_editor.insert_mode), a
    pop hl

    call new_line_editor_display_initial_string



.wait_key
    push bc : push hl
        call    new_line_edit_read_key
    pop hl : pop bc

    call    new_line_edit_treat_key         ; process key

    jr      nc, .wait_key         ; (-$0c)

    push    af
       call    new_line_editor_manage_cursor_display.remove
    pop     af



    pop hl : pop de : pop bc
    cp      0xfc    ; Break ?
    ret


; 2c48
new_line_edit_treat_key
    BREAKPOINT_WINAPE
    push    hl
    ld      hl, new_line_edit_key_table
    ld      e,a
    ld      a,b
    or      c
    ld      a,e
    jr      nz,.continue ; (+$0b)

    cp      key_up              ;
    jr      c,  .continue; (+$07)
    cp      $f4
    jr      nc, .continue         ; (+$03)

;; cursor keys ?
    ld      hl, new_line_edit_key_table2

;;--------------------------------------------------------------------
.continue
    ld      d,(hl) ; get number of elements
    inc     hl
    push    hl
.loop
    inc     hl
    inc     hl
    cp      (hl)    ; check if current element matches key pressed
    inc     hl
    jr      z, .match          ; (+$04)
    dec     d
    jr      nz, .loop        ; (-$09)
    ex      (sp),hl     ; put n hl the adress of the first elem of the table (fallback routine)
.match
    pop     af
    ld      a,(hl)
    inc     hl
    ld      h,(hl)
    ld      l,a
    ld      a,e
    ex      (sp),hl ; put the routine address on the table
    ret      ; and jump on it


;; keys for editing an existing line
;2c72 
new_line_edit_key_table
    defb &13
    defw new_line_edit_any_key_pressed
    defb &fc                                ; ESC key
    defw &2cd0                              
    defb &ef
    defw &2cce
    defb &0d                                ; RETURN key
    defw &2cf2
    defb &f0                                ; up cursor key
    defw &2d3c
    defb &f1                                ; down cursor key
    defw &2d0a
    defb &f2                                ; left cursor key
    defw new_line_edit_left_cursor_key_pressed
    defb &f3                                ; right cursor key
    defw &2d02
    defb &f8                                ; CTRL key + up cursor key
    defw &2d4f
    defb &f9                                ; CTRL key + down cursor key
    defw &2d1d
    defb &fa                                ; CTRL key + left cursor key
    defw &2d45
    defb &fb                                ; CTRL key + right cursor key
    defw &2d14
    defb &f4                                ; SHIFT key + up cursor key
    defw &2e21
    defb &f5                                ; SHIFT key + down cursor key
    defw &2e26
    defb &f6                                ; SHIFT key + left cursor key
    defw &2e1c
    defb &f7                                ; SHIFT key + right cursor key
    defw &2e17                              
    defb &e0                                ; COPY key
    defw &2e65
    defb &7f                                ; ESC key
    defw &2dc3
    defb &10                                ; CLR key
    defw &2dcd
    defb &e1                                ; CTRL key+TAB key (toggle insert/overwrite)
    defw &2d81
;2cae:
new_line_edit_key_table2
    defb &04
    defw new_line_edit_bel                  ; Sound bleeper
    defb &f0                                ; up cursor key
    defw new_line_edit_move_cursor.up       ; Move cursor up a line
    defb &f1                                ; down cursor key
    defw new_line_edit_move_cursor.down     ; Move cursor down a line
    defb &f2                                ; left cursor key
    defw new_line_edit_move_cursor.left     ; Move cursor back one character
    defb &f3                                ; right cursor key
    defw new_line_edit_move_cursor.right    ; Move cursor forward one character

;;--------------------------------------------------------------------
;; up cursor key pressed
new_line_edit_move_cursor
.up
    ld      a,0x0b          ; VT (Move cursor up a line)
    jr      .done            ; 

;;--------------------------------------------------------------------
;; down cursor key pressed
.down
    ld      a,0x0a          ; LF (Move cursor down a line)
    jr      .done           

;;--------------------------------------------------------------------
;; right cursor key pressed
.right
    ld      a,0x09          ; TAB (Move cursor forward one character)
    jr      .done            ; 

;;--------------------------------------------------------------------
;; left cursor key pressed
.left
    ld      a,0x08          ; BS (Move character back one character)

;;--------------------------------------------------------------------
; 2ccb
.done
    call    FIRMWARE.TXT_OUTPUT         ; TXT OUTPUT

;;--------------------------------------------------------------------
    or      a
    ret     

;;===========================================================================
; 2cfe
new_line_edit_bel
    ld      a, 0x07         ; BEL (Sound bleeper)
    jr      new_line_edit_move_cursor.done




;; left cursor key pressed
new_line_edit_left_cursor_key_pressed
; 2d34
    ld      d,0x01
    call    new_line_edit_ctrl_up_cursor_key_pressed.loop
    jr      z, new_line_edit_bel
    ret     






; CTRL key + up cursor key pressed
;; go to start of text
new_line_edit_ctrl_up_cursor_key_pressed
; 2d4f
    ld      d,c
.loop
; 2d50
    ld      a,b

new_line_edit_manage_cursor_move
    or      a
    ret     z

    call    new_line_editor_try_left_cursor_move
    jr      nc, .unable_to_move_left         ; (+$07)
    dec     b
    dec     hl
    dec     d
    jr      nz, new_line_edit_ctrl_up_cursor_key_pressed.loop         
    jr      .leave           

;;===========================================================================
.unable_to_move_left
    ld      a,b
    or      a
    jr      z, .before_display         
    dec     b
    dec     hl
    push    de
    call    unknown_2ea2
    pop     de
    dec     d
    jr      nz, new_line_edit_manage_cursor_move. unable_to_move_left 
.before_display
    call    new_line_editor_display_initial_string
.leave
    or      0xff
    ret  

;2d8a
new_line_edit_any_key_pressed
    or a
    ret z

    ld e, a
    ld a, (line_editor.insert_mode)
    or      a
    ld      a,c
    jr      z, .insert_mode
    cp      b
    jr      z, .insert_mode

.replace_mode
    ld      (hl),e ; replace current char by this one
    inc     hl
    inc     b 
    or      a
.go_print
    ld      a,e
    jp      new_line_edit_print_on_screen_char

.insert_mode
    cp      0xff
    jp      z, new_line_edit_bel     ; we are at the end of the screen
    xor     a
    ld      (0xb114),a ; XXX 
    call    .go_print
    inc     c
    push    hl
.buffer_loop_move
    ld      a,(hl)
    ld      (hl),e
    ld      e,a
    inc     hl
    or      a
    jr      nz, .buffer_loop_move
    ld      (hl),a
    pop     hl
    inc     b
    inc     hl
.update_screen_after_move
    call    new_line_editor_display_initial_string
    ld      a,(0xb114)
    or      a
    call    nz, unknown_2ea2
    ret   


; 2ea2
unknown_2ea2
.v1
    ld      d,0x01
    jr      .go
.v2

;;--------------------------------------------------------------------

    ld      d,0xff
;;--------------------------------------------------------------------
.go
    push    bc
    push    hl
    push    de
    call    new_line_editor_manage_cursor_display.remove
    pop     de
    call    new_line_editor_get_copy_cursor_position
    jr      z, .continue
    ld      a,h
    add     a,d
    ld      h,a
    call   new_line_editor_adjust_copy_cursor_position.validate 
    call   new_line_editor_manage_cursor_display.insert
.continue
    pop     hl
    pop     bc
    or      a
    ret  





; 2f25
new_line_edit_print_on_screen_char

    push    af
    push    bc
    push    de
    push    hl
    ld      b,a
    call    FIRMWARE.TXT_GET_CURSOR         ; TXT GET CURSOR
    ld      c,a
    push    bc
    call    FIRMWARE.TXT_VALIDATE           ; TXT VALIDATE
    pop     bc
    call    c, new_line_editor_compare_copy_cursor_relative_position
    push    af
    call    c, new_line_editor_manage_cursor_display.remove
    ld      a,b
    push    bc
    call    FIRMWARE.TXT_WR_CHAR            ; TXT WR CHAR
    pop     bc
    call    FIRMWARE.TXT_GET_CURSOR         ; TXT GET CURSOR
    sub     c
    call    nz, new_line_editor_adjust_copy_cursor_position
    pop     af
    jr      nc,.restore_and_leave
    sbc     a,a
    ld      (0xb114),a ; XXX
    call    new_line_editor_manage_cursor_display.insert
.restore_and_leave
    pop     hl
    pop     de
    pop     bc
    pop     af
    ret  



;
;;;--------------------------------------------------------------------
;
;2cd0 cdf22c    call    $2cf2           ; display message
;2cd3 f5        push    af
;2cd4 21ea2c    ld      hl,$2cea            ; "*Break*"
;2cd7 cdf22c    call    $2cf2           ; display message
;
;2cda cd7c11    call    $117c           ; TXT GET CURSOR
;2cdd 25        dec     h
;2cde 2808      jr      z,$2ce8          
;
;;; go to next line
;2ce0 3e0d      ld      a,$0d           ; CR (Move cursor to left edge of window on current line)
;2ce2 cdfe13    call    $13fe           ; TXT OUTPUT
;2ce5 cdc12c    call    $2cc1           ; Move cursor down a line
;
;2ce8 f1        pop     af
;2ce9 c9        ret     
;
;;;--------------------------------------------------------------------
;2cea 
;defb "*Break*",0




; 2df2
new_line_editor_init_copy_cursor

; init cursor
    xor a
    ld (line_editor.copy_cursor_xpos), a
    ld (line_editor.copy_cursor_ypos), a
    ret




; 2dfa
new_line_editor_compare_copy_cursor_relative_position
    ld de, (line_editor.copy_cursor_position)
    ld a, h
    xor d
    ret nz

    ld a, l
    xor e
    ret nz

    scf
    ret




; 2ec1
; Get copy curosr position relativly to actual cursor position
; zero flag set if cursor inactive
new_line_editor_get_copy_cursor_position
    ld hl, (line_editor.copy_cursor_position)
    ld a, h
    or l
    ret


;; try to move cursor left?
new_line_editor_try_left_cursor_move
; 2ec7
    push    de
    ld      de, 0xff08
    jr       new_line_editor_try_right_cursor_move

;;--------------------------------------------------------------------
;; try to move cursor right?
new_line_editor_try_right_cursor_move
    push    de
    ld      de,0x0109

;;--------------------------------------------------------------------
;; D = column increment
;; E = character to plot
new_line_editor_try_cursor_horizontal_move
    push    bc
    push    hl

    ;; get current cursor position
    call   FIRMWARE.TXT_GET_CURSOR ; TXT GET CURSOR

    ;; adjust cursor position
    ld      a,d				; column increment
    add     a,h				; add on column
    ld      h,a				; final column

    ;; validate this new position
    call    FIRMWARE.TXT_VALIDATE			; TXT VALIDATE

    ;; if valid then output character, otherwise report error
    ld      a,e
    call    c, FIRMWARE.TXT_OUTPUT  ; TXT OUTPUT

    pop     hl
    pop     bc
    pop     de
    ret  





; 2e06
; this method is called when the screen is scroll after printing a chars
new_ligne_editor_adjust_copy_cursor_position
new_line_editor_adjust_copy_cursor_position
    ld      c,a
    call    new_line_editor_get_copy_cursor_position            ; get copy cursor position
    ret     z               ; quit if not active

    ;; adjust y position
    ld      a,l
    add     a,c
    ld      l,a

.validate
    ;; validate new position
    call    FIRMWARE.TXT_VALIDATE           ; TXT VALIDATE
    jr      nc, new_line_editor_init_copy_cursor         ; reset relative cursor pos

    ;; set cursor position
    ld      (line_editor.copy_cursor_position),hl
    ret


new_line_editor_manage_cursor_display
; 2e4a
.place
.insert
    ld      de, FIRMWARE.TXT_PLACE_CURSOR           ; TXT PLACE CURSOR/TXT REMOVE CURSOR
    jr      .manage            
; 2e4f
.remove
    ;;--------------------------------------------------------------------
    ld      de, FIRMWARE.TXT_REMOVE_CURSOR          ; TXT PLACE CURSOR/TXT REMOVE CURSOR

    ;;--------------------------------------------------------------------
.manage
    call    new_line_editor_get_copy_cursor_position ; get copy cursor position
    ret     z

    push    hl
    call    FIRMWARE.TXT_GET_CURSOR
    ex      (sp),hl
    call    FIRMWARE.TXT_SET_CURSOR             ; TXT SET CURSOR
    call    FIRMWARE.PCDE_INSTRUCTION           ; LOW: PCDE INSTRUCTION
    pop     hl
    jp      FIRMWARE.TXT_SET_CURSOR












;;
;; ????
; 2ee4
new_line_editor_display_initial_string
    push bc: push hl
        ex de, hl
            call FIRMWARE.TXT_GET_CURSOR
            ld c, a     ; Roll count
        ex de, hl

.loop_over_string
        ld a, (hl) : inc hl
        or a
        call nz, .ask_to_print_char
        jr nz, .loop_over_string

        call FIRMWARE.TXT_GET_CURSOR
        sub c           ; Get Roll count difference

        ; move cursor on the very first line ?
        ex de, hl
        add a, l : ld l , a
        call FIRMWARE.TXT_SET_CURSOR


    pop hl: pop bc
    or a
    ret


.ask_to_print_char
    push af : push bc : push de : push hl
        ld b, a
        call FIRMWARE.TXT_GET_CURSOR
        sub c
        add a, e
        ld e, a
        ld c, b
        call FIRMWARE.TXT_VALIDATE
        jr c, .no_scroll_will_occur
        ld a, b
        add a, a
        inc a
        add a, e
        ld e, a
.no_scroll_will_occur
        ex de, hl
        call FIRMWARE.TXT_VALIDATE
        ld a, c
        call c, .do_print_char

    pop hl : pop de : pop bc : pop af
    ret


;2f25
.do_print_char
    push af : push bc : push de : push hl
    ld b, a
    call FIRMWARE.TXT_GET_CURSOR
    ld c, a
    push    bc
    call    FIRMWARE.TXT_VALIDATE
    pop     bc
    call    c, new_line_editor_compare_copy_cursor_relative_position
    push    af
    call    c, new_line_editor_manage_cursor_display.remove
    ld      a,b
    push    bc
    call    FIRMWARE.TXT_WR_CHAR
    pop     bc
    call    FIRMWARE.TXT_GET_CURSOR
    sub     c
    call    nz, new_ligne_editor_adjust_copy_cursor_position 
    pop     af
    jr      nc, .do_print_no_scroll  
    sbc     a,a
    ld      (0xb114),a ; XXX
    call    new_line_editor_manage_cursor_display.insert 
.do_print_no_scroll
    pop     hl
    pop     de
    pop     bc
    pop     af
    ret


; 2f56
new_line_edit_read_key
    call    FIRMWARE.TXT_GET_CURSOR 
    ld      c,a
    call    FIRMWARE.TXT_VALIDATE 
    call    new_line_editor_compare_copy_cursor_relative_position; XXX
    jp      c, FIRMWARE.KM_WAIT_CHAR

    call    FIRMWARE.TXT_CUR_ON
    call    FIRMWARE.TXT_GET_CURSOR
    sub     c
    call    nz, new_line_editor_get_copy_cursor_position
    call    FIRMWARE.KM_WAIT_CHAR
    jp      FIRMWARE.TXT_CUR_OFF

