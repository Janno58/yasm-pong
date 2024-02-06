bits 64

section .data
	title db 'Pong!', 0x00
	winWidth	dd 1024 
	winHeight	dd 768

	backgroundColor dd 0xFFFFFFFF
	rectangleColor  dd 0xFF000000
	ballColor	dd 0xFF0000FF
	
	scoreLeft dd 0 
	scoreRight dd 0

	ballX dd 250 
	ballY dd 250 
	ballVelX dd 2 
	ballVelY dd 0
	ballRadius dd 20.0
	ballRadiusI dd 20
	ballSpeed dd 2

	rectOneX dd 10
	rectOneY dd 100
	
	rectTwoX dd 989 
	rectTwoY dd 10 

	rectWidth dd 26 
	rectHeight dd 300 
	rectHalfWidth dd 13
	rectHalfHeight dd 150

	scoreSize dd 50
	scoreDivider db '-', 0x00

section .text
extern InitWindow
extern WindowShouldClose
extern BeginDrawing
extern ClearBackground
extern EndDrawing
extern CloseWindow
extern DrawRectangle
extern IsKeyPressed
extern IsKeyDown
extern SetTargetFPS
extern DrawCircle
extern DrawText

global _start
_start:
	mov edx, title
	mov esi, [winHeight] 
	mov edi, [winWidth]
	call InitWindow
	
	mov edi, 160
	call SetTargetFPS

	jmp mainLoop

mainLoop:
	call WindowShouldClose
	cmp rax, 0
	jne quit

	call updateBall

	mov edi, [rectOneX]
	mov esi, [rectOneY]
	call circleCollides

	mov edi, [rectTwoX]
	mov esi, [rectTwoY]
	call circleCollides

	call keepCircleInBounds

	call leftPaddleUp
	call leftPaddleDown
	call rightPaddleUp
	call rightPaddleDown

	call BeginDrawing
	
	mov edi, [backgroundColor]
	call ClearBackground

	call drawScores
	
	mov edi, [ballX]
	mov esi, [ballY]
	movss xmm0, [ballRadius]
	mov edx, [ballColor]
	call DrawCircle

	mov edi, [rectOneX]
	mov esi, [rectOneY]
	mov edx, [rectWidth]
	mov ecx, [rectHeight]
	mov r8d, [rectangleColor]
	call DrawRectangle
	
	mov edi, [rectTwoX]
	mov esi, [rectTwoY]
	mov edx, [rectWidth]
	mov ecx, [rectHeight]
	mov r8d, [rectangleColor]
	call DrawRectangle
	
	call EndDrawing

	jmp mainLoop

quit:
	call CloseWindow

	mov rax, 60
	mov rdi, 0
	syscall

intToAscii:	
	push rbp
	mov rbp, rsp
	sub rsp, 16 

	mov byte [rbp-4], 0x00
	mov byte [rbp-3], 0x00
	mov byte [rbp-2], 0x00
	mov byte [rbp-1], 0x0a
	
	lea r9, [rbp-2]

	divisionLoop:
		mov eax, edi
		cdq
		mov ebx, 10
		idiv ebx

		add dl, 48
		mov byte [r9], dl 
		dec r9
		
		cmp eax, 0
		je intToAsciiEpi
	
		mov edi, eax
		
		jmp divisionLoop

	intToAsciiEpi:

	mov rax, [r9+1] 

	add rsp, 16 
	pop rbp
	ret

drawScores:
	sub rsp, 16

	mov edi, [scoreLeft]
	call intToAscii

	push rax
	mov rdi, rsp
	mov esi, 462
	mov edx, 25
	mov ecx, [scoreSize]
	mov r8d, [ballColor]
	call DrawText
	pop rax

	mov edi, [scoreRight]
	call intToAscii
	push rax
	mov rdi, rsp
	mov esi, 562
	mov edx, 25
	mov ecx, [scoreSize]
	mov r8d, [ballColor]
	call DrawText
	pop rax

	add rsp, 8

	mov edi, scoreDivider
	mov esi, 516
	mov edx, 25
	mov ecx, [scoreSize]
	mov r8d, [ballColor]
	call DrawText
	
	add rsp, 8
	ret


keepCircleInBounds:
	mov edi, [ballX] ; ball smallest x
	mov esi, [ballY] ; smallest y
	mov edx, [ballX] ; largest x
	mov ecx, [ballY] ; largest y

	sub edi, [ballRadiusI]
	sub esi, [ballRadiusI]
	add edx, [ballRadiusI]
	add ecx, [ballRadiusI]
	
	cmp edi, 0
	jle touchLeftSide

	cmp esi, 0 
	jle negateY 

	cmp edx, [winWidth]
	jge touchRightSide

	cmp ecx, [winHeight]
	jge negateY 
	
	negateX:
		ret

	negateY:
		mov edi, [ballVelY]
		neg edi
		mov [ballVelY], edi
		
		ret

touchLeftSide:
	mov edi, [ballVelX]
	neg edi
	mov [ballVelX], edi

	mov edi, [scoreRight]
	inc edi	
	mov [scoreRight], edi

	ret

touchRightSide:
	mov edi, [ballVelX]
	neg edi
	mov [ballVelX], edi

	mov edi, [scoreLeft]
	inc edi	
	mov [scoreLeft], edi

	ret

; pass in edi rect X pos, esi rect Y pos
circleCollides:
	; calcualte distance between rectangle and circle in absolute values
	add edi, [rectHalfWidth] ; rect pos is top left corner so add half width and height to pos to get center
	add esi, [rectHalfHeight]
	
	push rdi
	push rsi

	; subtract ball position and take abs
	sub edi, [ballX]
	mov edx, edi
	neg edx
	cmovns edi, edx

	sub esi, [ballY]
	mov edx, esi
	neg edx
	cmovns esi, edx
	
	; calculate minimum distance needed to be colliding
	mov edx, [rectHalfWidth]
	mov ecx, [rectHalfHeight]
	add edx, [ballRadiusI] 
	add ecx, [ballRadiusI]
	
	cmp edi, edx
	jge noCollision
	
	cmp esi, ecx
	jge noCollision

	cmp edi, [rectHalfWidth]
	jle collides

	cmp esi, [rectHalfHeight]
	jle collides

	sub edi, [rectHalfWidth]
	sub esi, [rectHalfHeight]
	imul edi, edi
	imul esi, edi

	add edi, esi
	mov esi, [ballRadiusI]
	imul esi, esi

	cmp edi, esi
	jle collides

	noCollision:
		pop rsi
		pop rdi
		ret

	collides:	
		pop rsi ; Y
		pop rdi ; X
	
		mov r8d, [ballX]
		mov r9d, [ballY]

		sub r8d, edi
		sub r9d, esi
		
		mov edi, r8d 
		mov esi, r9d	
	
		imul edi, edi
		imul esi, esi
		
		add edi, esi
		cvtsi2ss xmm0, edi
		sqrtss xmm0, xmm0 ; xmm0 is magnitude of vector edi, esi	 
	
		cvtsi2ss xmm1, r8d 
		cvtsi2ss xmm2, r9d 
		
		divss xmm1, xmm0
		divss xmm2, xmm0
		
		mov esi, [ballSpeed]
		cvtsi2ss xmm0, esi

		mulss xmm1, xmm0
		mulss xmm2, xmm0

		cvtss2si esi, xmm1
		cvtss2si edi, xmm2

		mov [ballVelY], edi

		cmp esi, 0
		jne setX
		
		mov esi, [ballVelX]
		neg esi 

		setX:
			mov [ballVelX], esi
			ret

updateBall:
	mov eax, [ballX]
	mov ebx, [ballY]
	add eax, [ballVelX]
	add ebx, [ballVelY]
	mov [ballX], eax
	mov [ballY], ebx
	ret

leftPaddleUp:
	mov edi, dword 87
	call IsKeyDown
	cmp al, 0
	je skipToTheEnd 

	mov eax, [rectOneY]
	sub eax, dword 1
	cmp eax, 0
	je skipToTheEnd

	mov [rectOneY], eax

	skipToTheEnd:
		ret

rightPaddleUp:
	mov edi, dword 265 
	call IsKeyDown
	cmp al, 0
	je rightPaddleUpEpi 

	mov eax, [rectTwoY]
	sub eax, dword 1
	cmp eax, 0
	je rightPaddleUpEpi 

	mov [rectTwoY], eax

	rightPaddleUpEpi:
		ret

leftPaddleDown:
	mov edi, dword 83
	call IsKeyDown
	cmp al, 0
	je leftPaddleDownEpi 

	mov eax, [rectOneY]
	add eax, dword 1
	mov ebx, eax
	add ebx, dword [rectHeight]
	cmp ebx, [winHeight] 
	jge leftPaddleDownEpi 
	
	mov [rectOneY], eax
	
	leftPaddleDownEpi:
		ret

rightPaddleDown:
	mov edi, dword 264 
	call IsKeyDown
	cmp al, 0
	je rightPaddleDownEpi 

	mov eax, [rectTwoY]
	add eax, dword 1
	mov ebx, eax
	add ebx, dword [rectHeight]
	cmp ebx, [winHeight] 
	jge rightPaddleDownEpi 
	
	mov [rectTwoY], eax
	
	rightPaddleDownEpi:
		ret
