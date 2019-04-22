.model small
.stack 100h
.data

bad_params_message db "Bad cmd arguments", '$'
bad_source_file_message db "Cannot open file", '$'
file_not_found_message db "File not found", '$'
error_closing_file_message db "Cannot close file", '$'
error_read_file_text_message db "Error reading from file", '$'
file_is_empty_message db "File is empty", '$' 
result_message db "Number of lines with a length more than specified : ", '$'

space_char equ 32
new_line_char equ 13
return_char equ 10
tabulation equ 9
endl_char equ 0

max_size equ 126 
cmd_size db ?
cmd_text db max_size + 2 dup(0)
sourse_path db max_size + 2 dup(0) 
              
temp_length dw 0     
source_id dw 0
min_length dw 10 
lines_counter dw 0
buffer db max_size + 2 dup(0) 

.code
 
 
macro exit_app
   mov ax,4C00h
   int 21h  
endm
             
      
macro show_str out_str
	push ax
	push dx
	
	mov ah, 9h
	mov dx, offset out_str
	int 21h          
	
	mov dl, 10    
	mov ah, 2h
	int 21h      
	
	mov dl, 13    
	mov ah, 2h
	int 21h    
	
	pop dx
	pop ax
endm    
     
     
 
macro is_empty_line text_line, marker  
	push si
	
	mov si, offset text_line
	call strlen
	
	pop si
	cmp ax, 0    
	je marker 
endm
         
     
     
macro read_cmd
    xor ch, ch
	mov cl, ds:[80h] ; number of symbols in cmd          		
	mov cmd_size, cl ; 		
	mov si, 81h      ; adress of arguments 
	mov di, offset cmd_text 
	rep movsb   ;get symbols from cmd with adress to DI from SI
endm
  
  
  
      
print_result proc
    pusha           
    
    mov cx, 10         
    xor di, di 
            
    or ax, ax           
    jns conversion      
    push ax             
    mov dx, '-'         
    mov ah, 2           
    int 21h             
    pop ax              
                        
    neg ax                   
    
    
conversion:       
    xor dx, dx
    div cx              
    add dl, '0'         
    inc di
    push dx              
    or ax, ax
    jnz conversion 
 
    
show:
    pop dx              
    mov ah, 2           
    int 21h
    dec di              
    jnz show   
    
    popa
    ret    
endp
  
            
read_from_cmd proc
	push bx 
	push cx
	push dx 
	
	mov cl, cmd_size
	xor ch, ch
	mov si, offset cmd_text
	mov di, offset buffer                
	call rewrite_word                    
	
next_word:    
	mov di, offset sourse_path
	call rewrite_word
	is_empty_line sourse_path, bad_cmd        
	
	mov di, offset buffer
	call rewrite_word
	is_empty_line buffer, cmd_is_good         
	
bad_cmd:
	show_str bad_params_message
	mov ax, 1
	jmp endproc                   
	
cmd_is_good:
	mov ax, 0                       
	
endproc:    

	pop dx
	pop cx
	pop bx
	cmp ax, 0                          
	jne end_main
	ret	
endp
            
               
strlen proc
	push bx
	push si  
	
	xor ax, ax 
start_calculation:
	mov bl, ds:[si] 
	cmp bl, endl_char
	je end_calculation 
	
	inc si
	inc ax        
	jmp start_calculation
	
end_calculation:
	pop si 
	pop bx
	ret
endp
      
      
      
rewrite_word proc
	push ax
	push cx
	push di        
	
loop_parse_word:
	mov al, ds:[si]            
	cmp al, space_char        
	je is_stopped_char
	cmp al, new_line_char
	je is_stopped_char
	cmp al, tabulation
	je is_stopped_char
	cmp al, return_char
	je is_stopped_char
	cmp al, endl_char
	je is_stopped_char
	mov es:[di], al
	inc di
	inc si
	loop loop_parse_word 
	
is_stopped_char:
	mov al, endl_char
	mov es:[di], al
	inc si  
	
	pop di
	pop cx
	pop ax
	ret
endp
          
          
     
                                                  
open_file proc
	push bx
	push dx 
	
	mov ah, 3Dh	; 3d - open existing file;	
	mov al,00h	; 00 - for only reading
	mov dx, offset sourse_path        ;filename
	int 21h                       
	jb bad_open	                               ; If cf = 1 then cannot open file
	
	mov source_id, ax	                        ; ax - file id 
	mov ax, 0			 
	jmp end_open		 
	
bad_open:
	show_str bad_source_file_message
	cmp ax, 02h                                 ; 2h - cannot find file
	jne error_found
	show_str file_not_found_message
	jmp error_found    
	
error_found:
	mov ax, 1         
	
end_open:
	pop dx
	pop bx    
	
	cmp ax, 0
	jne end_main
	ret
endp
          
                                        
macro read_and_check_file
	call read_from_file
	mov bx, ax                   
	mov buffer[bx], endl_char         ; last symbol - endl;
	cmp ax, 0                         ; 0 byte
	je finish_processing            
	
	mov si, offset buffer
	mov di, offset buffer
	mov cx, ax					  
	xor dx, dx                    
endm    
          
          

read_from_file proc
	push bx
	push cx
	push dx                        
	
	mov ah, 3Fh                       ; 3f - read from file            
	mov bx, source_id                 ; id of file 
	mov cx, max_size                  ; max byte for reading
	mov dx, offset buffer             ; adress of buffer
	int 21h
	jnb good_read					      ; cf = 0 -> OK
	show_str error_read_file_text_message ; fiasko
	mov ax, 0                      
	
good_read:                                ; ax - number of bytes readed from file
	pop dx
	pop cx
	pop bx
	ret
endp
           
           
           
           
           
           
           
           
file_handling proc
	pusha               
	read_and_check_file	        
	mov temp_length, 0
	cmp ds:[si], endl_char                ; ds:[si] next symbol in file      
	jne loop_processing           
	
	show_str file_is_empty_message
	jmp end_main               
	
loop_processing:                   
    mov al, ds:[si]            
    cmp al, new_line_char
    jne no_new_line
    
    mov dx, min_length               
    cmp temp_length, dx
    jl no_increment
    
    inc lines_counter
no_increment:
    mov temp_length, 0                  
    
no_new_line:
    inc temp_length
    cmp al, endl_char            
    je read_again                
    
    inc si                            
	jmp loop_processing       
	
read_again:      ; to read new line in file
	read_and_check_file
	jmp loop_processing          
	
finish_processing:
	popa
	
	mov dx, min_length               
    cmp temp_length, dx
    jl no_increment_2
    
    inc lines_counter
    
no_increment_2:  

	push ax
	
	mov ax, lines_counter                   
	jo end_main 
	jc end_main
	pop ax
	ret
endp    
                
                
                
close_file proc
	push bx
	push cx  
	
	xor cx, cx
	mov ah, 3Eh   ; 3e - close file    
	mov bx, source_id   
	int 21h
	jnb good_close	; if c=0 - OK	   
	
	show_str error_closing_file_message
	inc cx 	
			
good_close:
	mov ax, cx 		
	pop cx
	pop bx 
	
	cmp ax, 0
	jne end_main
	ret
endm
    
 
 
    
    
start:
	mov ax, @data
	mov es, ax
	read_cmd            
	mov ds, ax
	
	call read_from_cmd				
    call open_file 
	call file_handling
	call close_file			
		
				     
    mov ah, 9h                      
	mov dx, offset result_message
	int 21h                     
	
	mov ax, lines_counter     
    call print_result 
    
    mov dl, 10    
	mov ah, 2h
	int 21h    
	          
	mov dl, 13     
	mov ah, 2h
	int 21h  
	 
	
end_main:
	exit_app 

end start

