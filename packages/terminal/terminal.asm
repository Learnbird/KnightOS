.nolist
#include "kernel.inc"
#include "applib.inc"
#include "stdio.inc"
#include "terminal.lang"
bufferSize .equ 256 ; For reading input
leftMargin .equ 2
commandChar .equ '$'
cursorChar .equ '_'
.list
    .db 0b00000010, 50
.org 0
    jr start
    .db 'K'
    .db 0b00000010
    .db lang_description, 0
start:
    call getLcdLock
    call getKeypadLock

    call allocScreenBuffer
    
    ; Load dependencies
    kld(de, applibPath)
    call loadLibrary
    kld(de, stdioPath)
    call loadLibrary
    
    kld(hl, windowTitle)
    xor a
    applib(drawWindow)
    
    ; Set default character set
    ld a, charSetLowercase
    applib(setCharSet)
    
    call flushKeys
    
    ld bc, bufferSize
    call malloc
    
    ld de, leftMargin << 8 | 8
    
idleLoop: ; Run when there is no attached program
    call memSeekToStart
    ; Draw out the command character
    ld a, commandChar
    kcall(term_printChar)
    
    ; Clear out old input
    xor a \ call memset
    push de
        push ix \ pop de
        kld(hl, binPath)
        ld bc, 5
        ldir
        push de \ pop ix
    pop de
    
    kcall(term_readString)
    
    ; Handle empty string
    ld a, (ix)
    or a \ jr z, idleLoop
    
    ; Special case for "exit" command
    push de
        push ix \ pop hl
        kld(de, exitStr)
        call compareStrings
    pop de
    ret z
    
    ; Interpret given string
    kcall(parseInput)
    jr z, idleLoop
    
    ; Display error
    kld(hl, commandNotFoundStr)
    kcall(term_printString)
    
    jr idleLoop
    
#include "parser.asm"
#include "routines.asm"
   
windowTitle:
    .db lang_windowTitle, 0
applibPath:
    .db "/lib/applib", 0
stdioPath:
    .db "/lib/stdio", 0
exitStr:
    .db "exit", 0
commandNotFoundStr:
    .db lang_commandNotFound, 0
binPath:
    .db "/bin/"