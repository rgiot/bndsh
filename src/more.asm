;;
; Simple dumb ascii file viewer (same as in ST?)
;
; @author Romain Giot
; @date june 2017
; @licence GPL




;;
; INPUT:
; - HL: pointer to the string of the filename
more_view_file
  
        ld de, 0x170 ; put string name in the input buffer of basic ...
        call string_copy_word
        xor a
        ld (de), a

        ld hl, 0x170
        call string_size
        ld b, a


        ld hl, 0x170 ; get name from basic buffer
        ld de, 0x7fff- 2048 ; XXX TODO change this buffer position
        call FIRMWARE.CAS_IN_OPEN
        jr nc, .file_error

        ;; cas_in_open returns:
        ;; if file was opened successfully:
        ;; - carry is true 
        ;; - HL contains address of the file's AMSDOS header
        ;; - DE contains the load address of the file (from the header)
        ;; - BC contains the length of the file (from the file header)
        ;; - A contains the file type (2 for binary files)

.read_loop

      call FIRMWARE.CAS_IN_CHAR
      jr nc, .eof

.not_eof
      call FIRMWARE.TXT_OUTPUT

      call FIRMWARE.KM_READ_CHAR
      jr nc, .read_loop
      cp 0xfc : jr z, .eof
      cp ' '  : jr z, .space_pause
      jr .read_loop


.eof
    call FIRMWARE.CAS_IN_CLOSE
    ret

.file_error
  ld hl, interpreter_messages.read_error
  call display_print_string
  ret


.space_pause
      call FIRMWARE.KM_READ_CHAR
      jr nc, .space_pause
      cp ' '  : jr z, .read_loop
      jr .space_pause
