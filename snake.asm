left equ 0
top equ 2
row equ 22
col equ 79
right equ left + col
bottom equ top + row

DATASEG
  ;static variable         
  startmsg db "Welcome to the SNAKE GAME!",13,10
            db "Use the following control:",13,10
            db "   a = left",13,10
            db "   d = right", 13,10
            db "   w = up",13,10
            db "   s = down",13,10
            db "   q = quit",13,10
            db "Press any key to continue...$"
  ingamemsg db "      SNAKE GAME ascii version",0

  quitmsg db "Thanks for playing! hope you enjoyed",0
  gameovermsg db "OOPS!! your snake died! ", 0
  scoremsg db "Score: ",0

  ;dynamic variable
  head db '^',10,10
  body db '*',10,11, 45 DUP(0)
  ;score = segmentcount - 1
  segmentcount db 1
  ; position of the fruit
  fruitactive db 1
  fruitx db 8
  fruity db 8
  gameover db 0
  quit db 0
  ; speed of the snake, higher means slower   
  delaytime db 5

  ; initial values of variables
  init_head db '^', 10, 10
  init_body db '*', 10, 11, 45 DUP(0)
  init_segmentcount db 1
  init_fruitactive db 0
  init_fruitx db 8
  init_fruity db 8
  init_gameover db 0
  init_quit db 0
  init_delaytime db 5

CODESEG
proc playSnake
	mov ax, @data
	mov ds, ax 

	mov ax, 0b800H
	mov es, ax

	;clear screen
	mov ax, 0003H
	int 10H
	
	lea dx, [startmsg]
	mov ah, 09H
	int 21h
	
    ; wait for character press
	mov ah, 07h
	int 21h

	mov ax, 0003H
	int 10H
    call printbox      
    
  mainloop: 
    call snakeDelay             
    lea bx, [ingamemsg]
    mov dx, 00
    call writestringat
    call shiftsnake
    cmp [gameover],1
    je gameover_mainloop
    
    call keyboardfunctions
    cmp [quit], 1
    je quitpressed_mainloop
    call fruitgeneration
    call draw
    
    ;TODO: check gameover and quit
    
    jmp mainloop
    
  gameover_mainloop: 
    mov ax, 0003H
	  int 10H
    mov [delaytime], 100
    mov dx, 0000H
    lea bx, [gameovermsg]
    call writestringat
    ; wait for key pressed
    mov  ah, 7
    int  21h   
    jmp quit_mainloop    
    
  quitpressed_mainloop:
    mov ax, 0003H
	  int 10H    
    mov [delaytime], 100
    mov dx, 0000H
    lea bx, [quitmsg]
    call writestringat
    call snakeDelay    
    jmp quit_mainloop    

  quit_mainloop:
    ; reset the variable of the game
    call resetSnakeVar
    ;first clear screen
    mov ax, 0003H
    int 10h    
    ret

proc snakeDelay
    ;this procedure uses 1A interrupt, more info can be found on   
    ;http://www.computing.dcu.ie/~ray/teaching/CA296/notes/8086_bios_and_dos_interrupts.html
    mov ah, 00
    int 1Ah
    mov bx, dx
    
jmp_delay:
    int 1Ah
    sub dx, bx
    ;there are about 18 ticks in a second, 10 ticks are about enough
    cmp dl, [delaytime]                                                      
    jl jmp_delay
    ret
endp snakeDelay
   
proc fruitgeneration
    mov ch, [fruity]
    mov cl, [fruitx]
  regenerate:
    
    cmp [fruitactive], 1
    je ret_fruitactive
    mov ah, 00
    int 1Ah
    ;dx contains the ticks
    push dx
    mov ax, dx
    xor dx, dx
    xor bh, bh
    mov bl, row
    dec bl
    div bx
    mov [fruity], dl
    inc [fruity]
    
    
    pop ax
    mov bl, col
    dec dl
    xor bh, bh
    xor dx, dx
    div bx
    mov [fruitx], dl
    inc [fruitx]
    
    cmp [fruitx], cl
    jne nevermind
    cmp [fruity], ch
    jne nevermind
    jmp regenerate
                 
nevermind:
    mov al, [fruitx]
    ror al,1
    jc regenerate
    
    
    add [fruity], top
    add [fruitx], left 
    
    mov dh, [fruity]
    mov dl, [fruitx]
    call readcharat
    cmp bl, '*'
    je regenerate
    cmp bl, '^'
    je regenerate
    cmp bl, '<'
    je regenerate
    cmp bl, '>'
    je regenerate
    cmp bl, 'v'
    je regenerate    
    
  ret_fruitactive:
    ret
endp fruitgeneration


proc dispdigit
    add dl, '0'
    mov ah, 02H
    int 21H
    ret
endp dispdigit
   
proc dispnum
  test ax,ax
  jz retz
  xor dx, dx
  ;ax contains the number to be displayed
  ;bx must contain 10
  mov bx,10
  div bx
  ;dispnum ax first.
  push dx
  call dispnum  
  pop dx
  call dispdigit
  ret
retz:
  mov ah, 02  
  ret    
endp dispnum

;sets the cursor position, ax and bx used, dh=row, dl = column
;preserves other registers
proc setcursorpos
  mov ah, 02H
  push bx
  mov bh,0
  int 10h
  pop bx
  ret
endp setcursorpos

proc draw
  lea bx, [scoremsg]
  mov dx, 0109
  call writestringat
  
  
  add dx, 7
  call setcursorpos
  mov al, [segmentcount]
  dec al
  xor ah, ah
  call dispnum

  lea si, [head]
  draw_loop:
    mov bl, [ds:si]
    test bl, bl
    jz out_draw
    mov dx, [ds:si+1]
    call writecharat
    add si,3   
    jmp draw_loop 

  out_draw:
    mov bl, 'F'
    mov dh, [fruity]
    mov dl, [fruitx]
    call writecharat
    mov [fruitactive], 1
    ret
endp draw

;dl contains the ascii character if keypressed, else dl contains 0
;uses dx and ax, preserves other registers
proc readchar
  mov ah, 01H
  int 16H
  jnz keybdpressed
  xor dl, dl
  ret
keybdpressed:
  ;extract the keystroke from the buffer
  mov ah, 00H
  int 16H
  mov dl,al
  ret
endp readchar           

proc keyboardfunctions
  call readchar
  cmp dl, 0
  je next_14
  
  ;so a key was pressed, which key was pressed then solti?
  cmp dl, 'w'
  jne next_11
  cmp [head], 'v'
  je next_14
  mov [head], '^'
  ret
  next_11:
    cmp dl, 's'
    jne next_12
    cmp [head], '^'
    je next_14
    mov [head], 'v'
    ret
  next_12:
    cmp dl, 'a'
    jne next_13
    cmp [head], '>'
    je next_14
    mov [head], '<'
    ret
  next_13:
    cmp dl, 'd'
    jne next_14
    cmp [head], '<'
    je next_14
    mov [head],'>'
  next_14:    
    cmp dl, 'q'
    je quit_keyboardfunctions
    ret    
  quit_keyboardfunctions:   
    ;conditions for quitting in here please  
    inc [quit]
    ret  
endp keyboardfunctions             
                    
                    
proc shiftsnake  
  mov bx, offset head
  
  ;determine the where should the head go solti?
  ;preserve the head
  xor ax, ax
  mov al, [bx]
  push ax
  inc bx
  mov ax, [bx]
  inc bx    
  inc bx
  xor cx, cx
  l:      
    mov si, [bx]
    test si, [bx]
    jz outside
    inc cx     
    inc bx
    mov dx,[bx]
    mov [bx], ax
    mov ax,dx
    inc bx
    inc bx
    jmp l
    
  outside:    
    ;hopefully, the snake will be shifted, i.e. moved.
    ;now shift the head in its proper direction and then clear the last segment. 
    ;But don't clear the last segment if the snake has eaten the fruit
    pop ax
    ;al contains the snake head direction
    
    push dx
    ;dx now consists the coordinates of the last segment, we can use this to clear it
    
    lea bx, [head]
    inc bx
    mov dx, [bx]
    
    cmp al, '<'
    jne next_1
    dec dl
    dec dl
    jmp done_checking_the_head

  next_1:
    cmp al, '>'
    jne next_2                
    inc dl 
    inc dl
    jmp done_checking_the_head
    
  next_2:
    cmp al, '^'
    jne next_3 
    dec dh               
    jmp done_checking_the_head
    
  next_3:
    ;must be 'v'
    inc dh
    
  done_checking_the_head:    
    mov [bx],dx
    ;dx contains the new position of the head, now check whats in that position   
    call readcharat ;dx
    ;bl contains the result
    
    cmp bl, 'F'
    je i_ate_fruit
    
    ;if fruit was not eaten, then clear the last segment, 
    ;it will be cleared where?
    mov cx, dx
    pop dx 
    cmp bl, '*'    ;the snake bit itself, gameover
    je game_over
    mov bl, 0
    call writecharat
    mov dx, cx
    ;check whether the snake is within the boundary
    cmp dh, top
    je game_over
    cmp dh, bottom
    je game_over
    cmp dl,left
    je game_over
    cmp dl, right
    je game_over
    ;balance the stack, number of segment and the coordinate of the last segment
    ret
  game_over:
    inc [gameover]
    ret
  i_ate_fruit:    
    ; add a new segment then
    mov al, [segmentcount]
    xor ah, ah

    lea bx, [body]
    mov cx, 3
    mul cx
    
    pop dx
    add bx, ax
    ; mov byte ptr ds:[bx], '*'
    mov [bx+1], dx
    inc [segmentcount ]
    mov dh, [fruity]
    mov dl, [fruitx]
    mov bl, 0
    call writecharat
    mov [fruitactive], 0   
    ret 
endp shiftsnake
   
;Print the box for the snake
proc printbox
;Draw a box around
    mov dh, top
    mov dl, left
    mov cx, col
    mov bl, '*'
  l1:                 
    call writecharat
    inc dl
    loop l1
    
    mov cx, row
  l2:
    call writecharat
    inc dh
    loop l2
    
    mov cx, col
  l3:
    call writecharat
    dec dl
    loop l3

    mov cx, row     
  l4:
    call writecharat    
    dec dh 
    loop l4    
    
    ret
endp printbox
              
;dx contains row, col
;bl contains the character to write
;uses di. 
proc writecharat
  ;80x25
  push dx
  mov ax, dx
  and ax, 0FF00H
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  
  
  push bx
  mov bh, 160
  mul bh 
  pop bx
  and dx, 0FFH
  shl dx,1
  add ax, dx
  mov di, ax
  mov [es:di], bl
  pop dx
  ret    
endp writecharat  
            
            
;dx contains row,col
;returns the character at bl
;uses di
proc readcharat
  push dx
  mov ax, dx
  and ax, 0FF00H
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1    
  push bx
  mov bh, 160
  mul bh 
  pop bx
  and dx, 0FFH
  shl dx,1
  add ax, dx
  mov di, ax
  mov bl,[es:di]
  pop dx
  ret
endp readcharat        

;dx contains row, col
;bx contains the offset of the string
proc writestringat
  push dx
  mov ax, dx
  and ax, 0FF00H
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  shr ax,1
  
  push bx
  mov bh, 160
  mul bh
  
  pop bx
  and dx, 0FFH
  shl dx,1
  add ax, dx
  mov di, ax
  loop_writestringat:
    mov al, [bx]
    test al, al
    jz exit_writestringat
    mov [es:di], al
    inc di
    inc di
    inc bx
    jmp loop_writestringat
    
exit_writestringat:
    pop dx
    ret
endp writestringat
  
endp playSnake

; reset the variable value
proc resetSnakeVar
  mov al, [init_head]
  mov [head], al
  mov al, [init_head+1]
  mov [head+1], al
  mov al, [init_head+2]
  mov [head+2], al
  mov al, [init_body]
  mov [body], al
  mov al, [init_body+1]
  mov [body+1],al
  mov al, [init_body+2]
  mov [body+2],al
  mov al, [init_body +3]
  mov [body+3],al
  mov al, [init_body +4]
  mov [body+4],al
  mov al, [init_body +5]
  mov [body+5],al
  mov al, [init_body +6]
  mov [body+6],al
  mov al, [init_body +7]
  mov [body+7],al
  mov al, [init_body +8]
  mov [body+8],al
  mov al, [init_body +9]
  mov [body+9],al
  mov al, [init_body +10]
  mov [body+10],al
  mov al, [init_body +11]
  mov [body+11],al
  mov al, [init_segmentcount]
  mov [segmentcount], al
  mov al, [init_fruitactive]
  mov [fruitactive], al
  mov al, [init_fruitx]
  mov [fruitx], al
  mov al, [init_fruity]
  mov [fruity], al
  mov al, [init_gameover]
  mov [gameover], al
  mov al, [init_quit]
  mov [quit], al
  mov al, [init_delaytime]
  mov [delaytime], al

  ret
endp resetSnakeVar