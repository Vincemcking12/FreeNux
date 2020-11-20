org 0x7C00   ; add 0x7C00 to label addresses
bits 16      ; tell the assembler we want 16 bit code

  mov ax, 0  ; set up segments
  mov ds, ax
  mov es, ax
  mov ss, ax     ; setup stack
  mov bx, 0x8000
  mov sp, 0x7C00 ; stack grows downwards from 0x7C00
 
user_set:
  ;bios struff
  ;call clear_screen 
  mov si , login  ;ask for user log in 
  call print_string
  
  mov di , buffer
  call get_string
  
  mov si ,buffer
  mov di ,root 
  call strcmp
  jc welc
  
  mov si, error 
  call _print_red
  jmp user_set
  
welc: 
  call clear_screen 
  mov si, welcome
  call print_string

mainloop:
  mov si, prompt
  call print_string

  mov di, buffer
  call get_string

  mov si, buffer
  cmp byte [si], 0  ; blank line?
  je mainloop       ; yes, ignore it

  mov si, buffer
  mov di, cmd_hello  ; "hello" command
  call strcmp
  jc .helloworld

  mov si, buffer
  mov di, cmd_help  ; "help" command
  call strcmp
  jc .help
 
  mov si, buffer 
  mov di, cmd_clear ;clear command 
  call strcmp 
  jc .clear
  
  mov si,badcommand
  call print_string 
  jmp mainloop  

.clear:
   call clear_screen
   jmp mainloop 
   
.helloworld:
  mov si, msg_helloworld
  call print_string

  jmp mainloop

.help:
  mov si, msg_help
  call print_string

  jmp mainloop

welcome db 'FREENUX - OS BY VINCENT!', 0x0D, 0x0A, 0
msg_helloworld db 'Hello World!', 0x0D, 0x0A, 0
badcommand db 'Bad command entered.', 0x0D, 0x0A, 0
prompt db '>', 0

msg_help db 'FREENUX HELP' , 0x0D , 0x0A  ,'visit: www.freenux.com for commands' , 0x0D ,0x0A , 0
login  db 'Username:' , 0
root db 'root' ,0
error db 'wrong login info' , 0x0D , 0x0A , 0

;os commands
cmd_hello db 'hello', 0
cmd_clear db 'clear' , 0
cmd_help db 'help', 0
cmd_about db 'about' , 0

buffer times 64 db 0

; ================
; calls start here
; ================


_print_red:
    mov bl,2
    mov ah, 0x0E

.repeat_next_char:
    lodsb
    cmp al, 0
    je .done_print
    int 0x10
    jmp .repeat_next_char

.done_print:
    ret

clear_screen:
    mov al, 2
    mov ah , 0 
    int 0x10
    ret

print_string:
 
  lodsb        ; grab a byte from SI

  or al, al  ; logical or AL by itself
  jz .done   ; if the result is zero, get out

  mov ah, 0x0E
  int 0x10      ; otherwise, print out the character!

  jmp print_string

.done:
  ret

get_string:
  xor cl, cl

.loop:
  mov ah, 0
  int 0x16   ; wait for keypress

  cmp al, 0x08    ; backspace pressed?
  je .backspace   ; yes, handle it

  cmp al, 0x0D  ; enter pressed?
  je .done      ; yes, we're done

  cmp cl, 0x3F  ; 63 chars inputted?
  je .loop      ; yes, only let in backspace and enter

  mov ah, 0x0E
  int 0x10      ; print out character

  stosb  ; put character in buffer
  inc cl
  jmp .loop

.backspace:
  cmp cl, 0	; beginning of string?
  je .loop	; yes, ignore the key

  dec di
  mov byte [di], 0	; delete character
  dec cl		; decrement counter as well

  mov ah, 0x0E
  mov al, 0x08
  int 10h		; backspace on the screen

  mov al, ' '
  int 10h		; blank character out

  mov al, 0x08
  int 10h		; backspace again

  jmp .loop	; go to the main loop

.done:
  mov al, 0	; null terminator
  stosb

  mov ah, 0x0E
  mov al, 0x0D
  int 0x10
  mov al, 0x0A
  int 0x10		; newline

  ret

strcmp:
.loop:
  mov al, [si]   ; grab a byte from SI
  mov bl, [di]   ; grab a byte from DI
  cmp al, bl     ; are they equal?
  jne .notequal  ; nope, we're done.

  cmp al, 0  ; are both bytes (they were equal before) null?
  je .done   ; yes, we're done.

  inc di     ; increment DI
  inc si     ; increment SI
  jmp .loop  ; loop!

.notequal:
  clc  ; not equal, clear the carry flag
  ret

.done: 	
  stc  ; equal, set the carry flag
  ret

  times 510-($-$$) db 0
  dw 0AA55h ; some BIOSes require this 