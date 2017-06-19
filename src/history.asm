; TODO use a circular buffer instead of copying everything !!!!




history_init
  call history_reset_delta
  ld (history.current), a

  xor a
  ld hl, history_jump_table
  ld b, history.size
.loop

    ld e, (hl) : inc hl
    ld d, (hl) : inc hl

    ld (de), a
  djnz .loop
  ret


history_print
  xor a
.loop 
  push af
    call history_get_buffer
    call display_print_string
    call display_crlf
  pop af
  inc a
  cp history.size
  jp nz, .loop
  ret

;;
; Reset the delta 
; Must be called at each new buffer line input
history_reset_delta
  xor a
  ld (history.delta), a
  ret


;;
; Input
;  A = relative buffer number
; Modified
;  DE
; Output
; HL = buffer address for the current configuration
history_get_buffer
  ; Compute the absolute position
  ld hl, history.current
  add (hl)
  and history.size- 1

  ; Get the ptr to the buffer
  add a
  ld d, 0
  ld e, a
  ld hl, history_jump_table
  add hl, de

  ; Read the buffer address from the table
  ld e, (hl)
  inc hl
  ld d, (hl)
  ex de, hl

  ret
  

;;
; Input
; - HL: source buffer
; Modified
; - HL, AF, BC, DE
history_save_current_context
  push hl
    ; Rotate the history buffer of one step
    ld a, (history.current)
    inc a
    and history.size- 1
    ld (history.current), a

    ; Get the buffer address
    xor a
    call history_get_buffer
    ex de, hl

  pop hl
  ; ... copy now ...
;;
; Input
;  - HL: source buffer
;  - DE: destination buffer
history_copy_buffer
    ld a, (hl)
    ldi
    or a
  jr nz, history_copy_buffer
  ret



;;
; Input
; HL=buffer where to copy paste string
history_select_previous
  push hl
    ld a, (history.delta) 
    dec a
    and history.size-1
    ld (history.delta), a

    inc a
    and history.size-1
    call history_get_buffer
  pop de

  jr history_copy_buffer


;;
; Input
; HL=buffer where to copy paste string
history_select_next
  push hl
    ld a, (history.delta) 
    inc a
    and history.size-1
    ld (history.delta), a

    dec a
    and history.size-1
    call history_get_buffer
  pop de

  jr history_copy_buffer


;; TODO do not use thes huge tables / things should be done programmatically
history_jump_table
.table0
    dw history.buffer1
    dw history.buffer2
    dw history.buffer3
    dw history.buffer4
    dw history.buffer5
    dw history.buffer6
    dw history.buffer7
    dw history.buffer8



