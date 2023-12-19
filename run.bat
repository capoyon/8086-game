@echo off
tasm game.asm > err.txt
link game.obj;
del game.obj
game