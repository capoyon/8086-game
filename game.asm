IDEAL
MODEL small
STACK 100h
P386

CODESEG
include "menu.asm"
include "snake.asm"
include "flappy.asm"

start:
	mov  ax, @data
	mov  ds, ax
	call printMainMenu
	mov ax, 4c00h
	int 21h
END start