.model tiny

.code
 org 100h
 
  start:

;   |     |                       |
;max| len |  T     E     X     T  | 0DH $
;   |     |                       |

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ввод строк~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mov dx, offset message
mov ah, 09h
int 21h

mov ah, 0Ah
mov dx, offset instr
int 21h 

mov dx, offset message2
mov ah, 09h
int 21h
 
mov ah, 0Ah
mov dx, offset str2
int 21h

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~алгоритм~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FindAgain:
	 mov di, offset str2[2]
	 lea si,  instr[2]
     mov sp, si
     mov newWordPosition, si
COMPARE:
	 mov bx, di
	 mov di, offset endSymbol
	 cmpsb
	 je newString
	 dec si
	 mov di, offset spaceSymbol
	 cmpsb                                  ;сравнивает с пробелом
	 je Space
	 dec si
	 mov di, bx
	 cmpsb                                  ;сравнивает символы строки
	 jne NotEqual
	 jmp COMPARE

NotEqual:
	 mov ax, si
	 mov bx, di
	 mov si, di
	 mov di, offset endSymbol
	 cmpsb                                  ;проверка на конец подстроки
	je DeleteWord
CompareAgain:
	 mov si, ax
	 lea di, str2[2]
	 jmp COMPARE
	 
Space:
	 mov ax, si
	 mov di, bx
	 inc di
	 mov si, di
	 mov di, offset endSymbol
	 cmpsb
	 je DeleteWord
	 mov si, ax
	 mov newWordPosition, si
	 lea di, str2[2]
	 jmp COMPARE
	  
DeleteWord:
	  
	  mov si, newWordPosition
	  xor cx, cx
Word:
CheckForTheLastWord:
	  inc si
	  inc cx
	  mov di, offset EndSymbol
	  cmpsb
      je WordMove
      sub si, 2
	  mov di, offset spaceSymbol
CheckForLengthOfTheWordBySpace:
	  cmpsb
	  jne Word
WordMove:
	  mov di, newWordPosition
	  add newWordPosition, cx
	  mov si, newWordPosition
	  mov ax, si
	  mov bx, di
countBites:
	  inc cx
	  mov di, offset endSymbol
	  cmpsb
	  jne countBites
	  mov si, ax
	  mov di, bx
	  rep movsb	
	  jmp FindAgain
newString:
	  mov di, bx
	  mov si, di
	  mov di, offset EndSymbol
	  cmpsb 
	  je DeleteWord	  
	  mov ah, 02h
	  mov dl, 0Ah
	  int 21h
	  mov ah, 02h
	  mov dl, 0Dh
	  int 21h
	  mov si, sp
	  mov dx, si
	  mov ah, 09h
	  int 21h
		  
int 20h
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~variables~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

message db 'Please, enter string:', 0Ah, 0Dh,'$'
message2 db 0Ah, 0Dh, 'Enter substring:', 0Ah, 0Dh, '$'
instr db 254 DUP (36), '$'
str2 db 254 DUP (36), '$'
spaceSymbol db ' ', 0Ah, 0Dh, '$'
endSymbol db '$', 0Ah, 0Dh, '$'
newWordPosition dw 0
substringOffset db 0


end start
