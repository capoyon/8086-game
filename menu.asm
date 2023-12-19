DATASEG
menu db 13,10,13,10,13,10,13,10,13,10
    db "                          Choose your game:",13,10
    db "                            [A]. Snake",13,10
    db "                            [B]. Flappy bird",13,10
    db "                          [ESC]. Exit",13,10,'$'

CODESEG
proc printMainMenu
    printmenu:
    call @@clearScreen
    ; hide blinking text cursor:
    mov ch, 32
    mov ah, 1
    int 10h
    ; print string
    mov dx, offset menu
    mov ah, 9
    int 21h

    @@getKey:
        xor ah, ah
        int 16h
        cmp ah, 1eh ; A key
        je @@playSnake
        cmp ah, 30h ; B key
        je @@playFlappy
        cmp ah, 1 ; Esc key
        je @@exitProgram
        ; invalid key, jump back to get another key
        jmp @@getKey

    @@playSnake:
        call playSnake
        jmp printmenu

    @@playFlappy:
        call playFlappy
        jmp printmenu

    @@exitProgram:
        call @@clearScreen
        mov  ax, 4c00h
        int  21h

    @@clearScreen:
        mov ax, 3
        int 10h
        ret
endp printMainMenu