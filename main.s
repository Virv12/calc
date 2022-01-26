global _start

default rel

section .text

_start:
	pop rdi
	cmp rdi, 2
	jne usage

	mov rdi, QWORD [rsp + 8]
	call parse_spaces.entry
	call parse_expr

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

parse_expr:

parse_term:

parse_atom:
	mov dl, BYTE [rdi]
	sub dl, '0'
	cmp dl, 10
	jae .error
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

.error:
	ud2

parse_spaces:
.loop:
	add rdi, 1
.entry:
	cmp BYTE [rdi], ' '
	je .loop
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
