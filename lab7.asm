	.model tiny
	.code
	.186
	org 100h
	
	jmp start
	

getProgramPath proc
	push ax
	push bx
	push cx
	push dx
	
	mov error, 0
	xor cx, cx
	mov cl, es:[80h]           ;PSP(program segment prefix) загрузка размер
	cmp cl, 0
	je invalidCommandLine
	mov di, 82h                ;значение командной строки
	lea si, programPath        ;в si будет находиться адрес, по которому лежит переменная
getSymbols:
	mov al, es:[di]
	cmp al, 0Dh                ;проверяем на конец командную строку 
	je FirstParamEnded
	cmp al, ' '                ;(21.06)
	je theSecondParam
	mov [si], al
	inc di
	inc si
	jmp getSymbols
   
invalidCommandLine:
    mov error, 1
    jmp getFilenameExit   
   
FirstParamEnded:
	cmp isSecondSpace, 0        ;проверяем, внесли ли мы все аргументы(21.06)
	je invalidCommandLine		;если нет
	jmp getFilenameExit
								    ;inc si
								    ;mov byte ptr [si], 0        ;заносим 0 в конец(ASCIZ-строка)
	
theSecondParam:
	cmp isSecondSpace, 0
	je setNewParam
	jmp invalidCommandLine
	
setNewParam:
	inc di
	mov isSecondSpace, 1        ;проверка на второй параметр
	inc si
	mov byte ptr [si], 0        ;заносим 0 в конец(ASCIZ-строка)(имя программы)
	lea si, string
	xor ax, ax
	
setTheNumber:
	mov al, es:[di]
	cmp al, 0Dh
	je checkTheLastArgument
	cmp al, ' '
	je invalidCommandLine
	mov [si], al
	inc di
	inc si
	inc length
	cmp length, 4
	je invalidCommandLine
	jmp setTheNumber
	
checkTheLastArgument:
	cmp length, 0
	je invalidCommandLine
	
getFilenameExit:	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
getProgramPath endp
	
	
atoi	proc
;==== ds:si - string address ===  
    	push bx
    	push cx
    	push dx
    	push si  
 
    	xor bx, bx
    	xor dx, dx 
    	mov error, 0
    	
getNumberLength:
        xor cx, cx
        mov di, offset length
        mov cl, [di] 
        cmp cl, 0
        je invalidInput      	
convert:	
        xor ax, ax
    	lodsb
        cmp al, '-'	
    	je invalidInput	
        cmp al, '9'
    	jnbe invalidInput    
    	cmp al, '0'    
    	jb invalidInput   
    	sub ax, '0'	
    	shl dx, 1	
    	add ax, dx
    	shl dx, 2	
    	add dx, ax  
    	cmp dx, MAX_NUMBER
    	jg invalidInput 
    	cmp dx, 0
    	je invalidInput
loop convert
        jmp exit

invalidInput:
        mov error, 1
exit:   
        mov ax, dx 
        mov N_times, al             
    	pop si
    	pop dx 
    	pop cx
    	pop bx
	    
	    ret 
atoi	endp 
	
start:           
    
	call getProgramPath     
	cmp error, 1
	je invalidCommandLineArgs
	    
    mov si, offset string          
    call atoi  
    
    cmp error, 1
    jne loadProgram
    
    mov ah, 09h
    mov dx, offset invalidNumberMessage
    int 21h
    
    jmp start    
    
loadProgram:
	              
	mov ah, 09h
    mov dx, offset newLine
    int 21h                
	              
	mov sp, programLength + 100h + 200h            ;перемещение стека на 200h после конца программы
	
	mov ah, 4Ah                                    ;изминение размера блока памяти(урезание)
	
	stackShift = programLength + 100h + 200h       ;мы добавляем кусок для стека нашей новой программы
	mov bx, stackShift shr 4 + 1     ;засовываем новый размер программы в 16-байтных параграфах
	int 21h 
	
	
	; exec parameter block ( load and run )
	mov ax, cs                      ;код-сегмент нашей программы (сегмент кода - страница памяти исполняемой в данный момент программы)
	mov word ptr EPB + 4, ax		; cmd segment
	mov word ptr EPB + 8, ax		; fcb1 segment
	mov word ptr EPB + 0Ch, ax		; fcb2 segment
	
	xor cx, cx
	mov cl, N_times

runProgram:
	mov ssSeg, ss     ;стековый сеегмент
	mov spSeg, sp     ;стек-поинтер текущей программы
	
	mov ax, 4B00h     ;функция запуска программы
	mov dx, offset programPath
	mov bx, offset EPB
	int 21h
	jc errorDuringLoadingProgram
	mov ss, cs:ssSeg   ;
	mov sp, cs:spSeg   ;
	loop runProgram
	
	
    jmp exitStart
 
errorDuringLoadingProgram:
    mov ah, 09h
    mov dx, offset error4Bh
    int 21h
    jmp exitStart 
 
invalidCommandLineArgs:
    mov ah, 09h
    mov dx, offset invalidCmdArgs
    int 21h
        
exitStart:
	
	int 20h
	

newLine         db      10, 13, '$' 
invalidNumberMessage    db      'Invalid input: not correct number!', 10, 13, '$' 
invalidCmdArgs          db      'Invalid command line input', 10, 13, '$' 
error4Bh                db      'Error has happened during loading/running program.', 10, 13, 'Check your program path and try again', '$'        
error           db      0
ssSeg			dw		0			; переменные для стековых регистров(хранение)
spSeg			dw		0
userInput    	EQU $                             ; Buffer for string
				maxLength db 4                    ; Maximum characters buffer can hold
				length 	  db 0                    ; Number of characters actually read,
				string    db 4 dup ('$')          ; Actual characters read, including the final carriage return (0Dh)
N_times			db		0	
programPath		db		30 dup('$')
EPB		dw		0000
		dw 		offset commandLine, 0
		dw 		005Ch, 0, 006Ch, 0
commandLine		db		125
commandText		db 		122 dup(?)
				db		'0Dh'
MAX_NUMBER		equ		255
programLength	equ		$ - start      ;размер занимаемой программы
isSecondSpace dw 0
end start