DATASEG
gameover_flap db "Game over",13,10
              db "Your score is: $"
exit_inst db 13,10,"Press any key to exit$"
score_0 db 0
score_1 db 0
bird_x db 2  ; bird starting x position
bird_y db 10 ; bird starting y position
pipe_x db 79
pipe_y db 0
cursor_x db 24
cursor_y db 79

CODESEG
proc playFlappy
  game_loop:
    cmp [pipe_x], 0
    ja pipe_x_gt_zero

    ; set pipe_x to the right most
    mov [pipe_x], 79

    ; increment score by 1
    inc [score_0]
    cmp [score_0], 9       
    jbe dont_icrement_tens
    ; if ones place is >= 9
    ; increment decimal by one
    ; so number jump from 9 
    ; to 1,0 [score_1, score_0]  
    mov [score_0], 0
    inc [score_1]

  dont_icrement_tens:
    cmp [pipe_y], 5
    jb pipe_y_gt_5
    mov [pipe_y], 0
    jmp pipe_x_gt_zero

  pipe_y_gt_5:
    inc [pipe_y]
                
  pipe_x_gt_zero:  
    ; move pipe position by 1 unit horizontally left
    dec [pipe_x]

  check_key:
    ; sleep for 250ms (250000 microseconds -> 3D090h)
    mov cx, 03h
    mov dx, 05150h
    mov ah, 86h
    int 15h
    ; check if any data is in keyboard buffer
    mov ah, 0Bh
    int 21h
    cmp al, 0h   
    je is_new_key_false

  is_new_key_true:
    ; if there is some data in keyboard buffer
    ; get keystroke and save ASCII character in AL, AH = scan code
    mov ah, 0
    int 16h
    ; check if esc is pressed
    cmp ah, 01h
    jne not_exit
    jmp game_over_flap
    not_exit:
    ; move bird position by 1 unit verically up
    sub [bird_y], 2
    ; flush keyboard buffer
    mov ah, 0Ch
    int 21h

  is_new_key_false:
    ; move bird position by 1 unit verically down
    inc [bird_y]

  check_collision:
    ; collision with ground
    mov ah, 23
    mov bh, [bird_y]                       
    cmp ah, bh 
    jb game_over_flap
    ; ja game_over_flap
    ; check if bird is between pipes
    mov ah, [pipe_x]
    mov bh, [bird_x]                       
    cmp ah, bh 
    jne render
    mov ah, [bird_y]
    mov bh, [pipe_y]
    add bh, 4
    cmp ah, bh
    je render
    inc bh
    cmp ah, bh
    je render
    sub bh, 2                       
    cmp ah, bh
    je render

  game_over_flap:
    ; reset bird fly
    mov al, 10
    mov [bird_y], al
    ; clear screen
    mov ax, 3
    int 10h
    ; print string
    mov dx, offset gameover_flap
    mov ah, 9
    int 21h
    ; print score
    mov ah, 06h
    mov dl, [score_1]
    add dl, '0'
    int 21h
    mov dl, [score_0]
    add dl, '0'
    int 21h
    ; reset score
    mov al, 0
    mov [score_0], al
    mov [score_1], al

    mov dx, offset exit_inst
    mov ah, 9
    int 21h
    ; wait for character press
    mov ah, 07h
    int 21h
    ret

  render:
    ; draw grass bottom
    mov dl, 10
    mov ah, 06h
    int 21h
    mov dl, 13
    int 21h
    mov cx, 79 ; grass length buttom
    mov dl, '='
    draw_grass_bottom:
    int 21h
    loop draw_grass_bottom
    ; write new line
    mov dl, 10
    mov ah, 06h
    int 21h
    mov dl, 13
    int 21h
    ; print score
    mov dl, [score_1]
    add dl, '0'
    mov ah, 06h
    int 21h
    mov dl, [score_0]
    add dl, '0'
    int 21h
    ; set cursor at x=dl=0, y=dh=0
    mov dl, 00h
    mov dh, 00h
    mov ah, 2h
    mov bh, 0
    int 10h
    ; draw grass top
    mov cx, 79 ; grass length top
    mov dl, '='
    draw_grass_top:
    int 21h
    loop draw_grass_top
    mov dh, 00h
    int 10h
    ; outer loop (y-axis)
    mov [cursor_y], 0
    render_y:
    inc [cursor_y]
    ; write new line
    mov dl, 10
    mov ah, 06h
    int 21h
    mov dl, 13
    int 21h
    ; inner loop (x-axis)
    mov [cursor_x], 0

  render_x:
    inc [cursor_x]
    
    render_bird:
    mov ah, [cursor_x]
    mov bh, [bird_x]                       
    cmp ah, bh 
    jne render_pipe
    mov ah, [cursor_y]
    mov bh, [bird_y]                       
    cmp ah, bh 
    jne render_pipe
    mov dl, '>'
    mov ah, 06h
    int 21h
    jmp render_x_end
    
    render_pipe:
    mov ah, [cursor_x]
    mov bh, [pipe_x]				
    cmp ah, bh 
    jne render_3
    mov ah, [cursor_y]
    mov bh, [pipe_y]
add bh, 4
    cmp ah, bh
    je render_3
    inc bh                       
    cmp ah, bh
    je render_3
    sub bh, 2                       
    cmp ah, bh
    je render_3
    mov dl, 'I'
    mov ah, 06h
    int 21h
    jmp render_x_end
    
    ; render empty space
    render_3:
    mov dl, ' '
    mov ah, 06h
    int 21h
    jmp render_x_end
      
  render_x_end:    
    cmp [cursor_x], 79
    jb render_x

  render_y_end:
    cmp [cursor_y], 22 ; lenth of the game
    jb render_y
    ; repeat game loop
    jmp game_loop
    jmp game_over_flap

endp playFlappy