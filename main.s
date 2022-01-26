global _start

default rel

section .text

_start:
	pop rdi
	cmp rdi, 2
	jne usage

	mov rdi, QWORD [rsp + 8]
	mov bl, 0
	call parse_spaces.entry
	call parse
	test bl, bl
	je .format
	mov rax, rdi
	sub rax, QWORD [rsp + 8]

.format:
	mov BYTE [rsp - 1], 10
	lea rsi, [rsp - 1]
	mov rcx, 10
.loop:
	mov rdx, 0
	div rcx
	add rdx, '0'
	sub rsi, 1
	mov BYTE [rsi], dl
	test rax, rax
	jne .loop

	test bl, bl
	je .print
	sub rsi, ERR.len
	mov rcx, ERR.len
.copy:
	sub rcx, 1
	mov al, BYTE [ERR + rcx]
	mov BYTE [rsi + rcx], al
	test rcx, rcx
	jne .copy

.print:
	mov rdi, 1
	mov rdx, rsp
	sub rdx, rsi
	mov rax, 1
	syscall

	mov rdi, 0
	; fallthrough

exit:
	mov rax, 60
	syscall

parse:
	call parse_expr
	test bl, bl
	jne .ret
	cmp BYTE [rdi], 0
	setne bl
.ret:
	ret

parse_expr:
	call parse_term
	test bl, bl
	jne .error
.loop:
	mov dl, BYTE [rdi]
	cmp dl, '+'
	je .add
	cmp dl, '-'
	je .sub
	ret

.add:
	call parse_spaces.skip
	push rax
	call parse_term
	pop rdx
	test bl, bl
	jne .error
	add rax, rdx
	jmp .loop

.sub:
	call parse_spaces.skip
	push rax
	call parse_term
	pop rdx
	test bl, bl
	jne .error
	sub rdx, rax
	mov rax, rdx
	jmp .loop

.error:
	mov bl, 1
	ret

parse_term:
	call parse_atom
	test bl, bl
	jne .error

.loop:
	mov dl, BYTE [rdi]
	cmp dl, '*'
	je .mul
	cmp dl, '/'
	je .div
	ret

.mul:
	call parse_spaces.skip
	push rax
	call parse_atom
	pop rdx
	test bl, bl
	jne .error
	mul rdx
	jmp .loop

.div:
	call parse_spaces.skip
	push rax
	call parse_atom
	pop rcx
	test bl, bl
	jne .error
	mov rdx, 0
	div rcx
	jmp .loop

.error:
	mov bl, 1
	ret

parse_atom:
	mov dl, BYTE [rdi]
	cmp dl, '('
	je .par

	sub dl, '0'
	cmp dl, 10
	jb .int

.error:
	mov bl, 1
	ret

.int:
	movzx rax, dl
	add rdi, 1
.loop:
	mov dl, BYTE [rdi]
	sub dl, '0'
	cmp dl, 10
	jae parse_spaces.entry
	imul rax, 10
	movzx rdx, dl
	add rax, rdx
	add rdi, 1
	jmp .loop

.par:
	call parse_spaces.skip
	call parse_expr
	test bl, bl
	jne .error
	cmp BYTE [rdi], ')'
	jne .error
	jmp parse_spaces.skip

parse_spaces:
.skip:
	add rdi, 1
.entry:
	cmp BYTE [rdi], ' '
	je .skip
	ret

usage:
	mov rdi, 2
	lea rsi, [USAGE]
	mov rdx, USAGE.len
	mov rax, 1
	syscall

	mov rdi, 1
	jmp exit

section .rodata

USAGE: db "Usage: ./main <expr>", 10
.len:  equ $ - USAGE

ERR:   db "Parse error at "
.len:  equ $ - ERR
