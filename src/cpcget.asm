;;
; Krusty/Benediction
; June 2017
; Fast made tentative to download stuff on CPCrulez platform

; Rappel
; 1. IX Contient la liste des paramètres (IX+&00),(IX+&01) contient l'adresse ou la valeur du dernier paramètre, (IX+&02),(IX+&03) l'adresse de l'avant dernier etc...
; 2. A contient le nombre de paramètres
; 3. IY contient l'adresse mémoire du début de la zone réservée à la ROM en RAM.
; 4. C contient le numéro de la ROM (0..7)

cpcget_search_rsx
  BREAKPOINT_WINAPE
  cp 1 : ret nz ; Leave if not right amount of paramters TODO really display an error

  ld hl, rsx_name.httpmem
  call FIRMWARE.KL_FIND_COMMAND
  ret nc 

.get_list
  push hl : push bc


    ; Build the query string
    ld hl, cpcget_rom_data.search_query
    call cpcget_build_url

.location equ 0x7000
.max_size equ 0x1000

    ld ix, interpreter.parameter_buffer
    ld (ix+0), .max_size%256
    ld (ix+1), .max_size/256
    ld (ix+2), .location%256
    ld (ix+3), .location/256
    ld (ix+4), interpreter.param_string1%256
    ld (ix+5), interpreter.param_string1/256

  pop bc: pop hl

  ld a, 3
  call FIRMWARE.KL_FAR_PCHL


.display_list
  ret


cpcget_download_dsk
  cp 1 : ret nz ; Leave if not right amount of paramters TODO really display an error

  ld hl, rsx_name.httpget
  call FIRMWARE.KL_FIND_COMMAND
  ret nc 

.get_list
  push hl : push bc


    ; Build the query string
    ld hl, cpcget_rom_data.download_query
    call cpcget_build_url


.location equ 0x7000
.max_size equ 0x1000

    ld ix, interpreter.parameter_buffer
    ld (ix+0), interpreter.param_string1%256
    ld (ix+1), interpreter.param_string1/256

  pop bc: pop hl

  ld a, 1
  call FIRMWARE.KL_FAR_PCHL


.display_list
  ret



cpcget_build_url
    ld de, cpcget.query_buffer
    call string_copy_word

    ld l, (ix+0)
    ld h, (ix+1)
    call string_copy_firmware_string


    ld hl, cpcget.query_buffer 
    call display_print_string


    ld hl, cpcget.query_buffer  
    ld (interpreter.param_string1+1), hl
    call string_word_size
    ld (interpreter.param_string1+0), a


  ret

cpcget_rom_data
.search_query string "benediction.cpcscene.net/brige.php?q="
.download_query string "benediction.cpcscene.net/brige.php?d="
