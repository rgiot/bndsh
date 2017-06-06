; TODO use a circular buffer instead of copying everything !!!!

history_save_current_context

    ld hl, history.buffer4
    ld de, history.buffer5
    call history_copy_buffer

    ld hl, history.buffer3
    ld de, history.buffer4
    call history_copy_buffer

    ld hl, history.buffer2
    ld de, history.buffer3
    call history_copy_buffer

    ld hl, history.buffer1
    ld de, history.buffer2
    call history_copy_buffer

    ld hl, line_editor.history_pointer
    ld de, history.buffer1
    call history_copy_buffer

    ret


history_select_previous
    ld a, (history.current)
    inc a
    cp history.size
    jr nz, .no_ovf
    dec a
.no_ovf
    ld (history.current), a

    jr history_select_current

history_select_next
    ld a, (history.current)
    dec a
    cp 0xff
    jr nz, .no_ovf
    inc a
.no_ovf
    ld (history.current), a

history_select_current
    ld hl, .table
    add a
    ld d, 0 : ld e, a
    add hl, de
    ld e, (hl) : inc hl : ld d, (hl)
    ex de, hl

    ld de, line_editor.history_pointer
    call  history_copy_buffer

    ret

.table
    dw history.buffer1
    dw history.buffer2
    dw history.buffer3
    dw history.buffer4
    dw history.buffer5



;;
; Input
;  - HL: source buffer
;  - DE: destination buffer
history_copy_buffer
    ldi     ; Copy buffer size
    dec de : ld a, (de) : inc de ; Get size
    or a : ret z ; do nothing if size is 0

    inc a: inc a ; ensure there is the space for the 2 special bytes of the end

    ld b, 0  : ld c, a
    ldir
    ret


