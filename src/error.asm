wrong_number_of_arguments
    push hl : push bc
        ld hl, error_messages.wrong_number_of_arguments
        call display_print_string
    pop bc : pop hl
    ret


error_messages
.wrong_number_of_arguments string "Wrong number of arguments"
    
