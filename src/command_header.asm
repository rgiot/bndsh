interpreter_command_header

.nbArgs equ 0
.name  string "HEADER"
.help string "Display the header content of the file in argument"
.routine

        ld hl, (interpreter.next_token_ptr)
        ld de, 0x170 ; put string name in the input buffer of basic ...
        call string_copy_word
        xor a
        ld (de), a



        if BNDSH_ROM
           call bndsh_select_normal_memory
        endif

        ld hl, 0x170
        call string_size
        ld b, a
        ld de, 0xc000
        ld hl, 0x170
        call FIRMWARE.CAS_IN_OPEN
        jp nc, .did_nothing ; Jump if file not opened
.opened

        push hl
        if BNDSH_ROM
            ; go back to normal memory if des not work
            call bndsh_select_extra_memory
        endif
        pop hl


        push hl

; User
        push hl
            ld hl, header_strings.userNb : call display_print_string
        pop hl      
        ld a, (hl) : inc hl
        add '0'
        push hl 
            call display_print_char
            call display_crlf
        pop hl

; Filename
        push hl
            ld hl, header_strings.filename : call display_print_string
        pop hl
        ld b, 8
.fname_loop
        push bc
            ld a, (hl) : inc hl
            call display_print_char
        pop bc
        djnz .fname_loop
        
        ld a, '.' : call display_print_char

        ld b, 3
.ext_loop
        push bc
            ld a, (hl) : inc hl
            call display_print_char
        pop bc
        djnz .ext_loop
        
    call display_crlf

; file type


    ld de, 18 - 12
    add hl, de
    ld a, (hl) : inc hl
    
    push hl
        push af
            bit 0, a
            call z, .file_protected
            call nz, .file_not_protected
            call display_crlf


            ld hl, header_strings.type
            call display_print_string


        pop af
        and %1110
        cp %0000 : jr z, .is_basic
        cp %0010 : jr z, .is_binary
        cp %0100 : jr z, .is_screen
        cp %0110 : jr z, .is_ascii
.is_unknown
        ld hl, header_strings.is_unknown
        jr .end_of_type_treatment
.is_basic
        ld hl, header_strings.is_basic
        jr .end_of_type_treatment
.is_binary
        ld hl, header_strings.is_binary
        jr .end_of_type_treatment
.is_screen
        ld hl, header_strings.is_screen
        jr .end_of_type_treatment
.is_ascii
        ld hl, header_strings.is_ascii
        jr .end_of_type_treatment
.end_of_type_treatment
        call display_print_string



        call display_crlf
        ld hl, header_strings.loading_address
        call display_print_string
    pop hl

    inc hl
    inc hl

    ld e, (hl) : inc hl
    ld d, (hl) : inc hl
    push hl
        call display_hexadecimal_16bits_number
        call display_crlf
        ld hl, header_strings.file_size
        call display_print_string
    pop hl



    inc hl
    ld e, (hl) : inc hl
    ld d, (hl) : inc hl
    push hl
        call display_hexadecimal_16bits_number
        call display_crlf
        ld hl, header_strings.execution_address
        call display_print_string
    pop hl

    ld e, (hl) : inc hl
    ld d, (hl) : inc hl
    push hl
        call display_hexadecimal_16bits_number
        call display_crlf
        ld hl, header_strings.checksum
        call display_print_string
    pop hl

    ld b, 67-28
.delta_checksum
        inc hl
    djnz .delta_checksum

    ld e, (hl) : inc hl
    ld d, (hl) : inc hl
    call display_hexadecimal_16bits_number
    call display_crlf


    pop hl

    ld b, 178
.display_loop
        ld a, (hl)
        inc hl
        push hl : push bc
            call display_hexadecimal_8bits_number
            ld a, ' ' : call display_print_char
        pop bc : pop hl
        djnz .display_loop


    call FIRMWARE.CAS_IN_CLOSE

    ret

.did_nothing
    ld hl, error_messages.file_does_not_exist : call display_print_string
    ld hl, 0x170 : call display_print_string

        
        if BNDSH_ROM
            ; go back to normal memory if des not work
            call bndsh_select_extra_memory
        endif
    ret

.file_protected
    ld hl, header_strings.file_protected
    call display_print_string
    cp a
    ret


.file_not_protected
    ld hl, header_strings.file_not_protected
    call display_print_string
    ret


header_strings
.userNb string "User number: "
.filename string "Filename: "
.type string "File type: "
.file_protected string "File protected"
.file_not_protected string "File not protected"
.is_unknown string "Unknown"
.is_basic string "Basic"
.is_binary string "Binary"
.is_screen string "Screen image"
.is_ascii string "ASCII"
.file_size string "File size: 0x"
.loading_address string "Loading address: 0x"
.execution_address string "Execution address: 0x"
.checksum string "Checksum: 0x"

