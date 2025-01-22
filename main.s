.section .data
    board: .byte ' ',' ',' ',' ',' ',' ',' ',' ',' ' #tablero vacío
    row_division: .asciz "\n"
    column_division: .asciz "|"
    space: .asciz " "
    buffer: .byte ' '
    clear_msg: .ascii "\033[2J\033[H"         # Código ANSI para limpiar la pantalla
    len_clear_msg = .- clear_msg

    #Mensajes
    msg1: .asciz "Introduce un índice entre 1 y 3: "
    len_msg1 = .- msg1
    err_message1: .asciz "Ese no es un índice válido!\n"
    len_err1 = .- err_message1
    win_message: .asciz "Ganador:\n"
    len_win = .- win_message
    draw_message: .asciz "Empate!\n"
    len_draw = .- draw_message
    turn_string: .asciz "Turno de: "
    len_t_string = .- turn_string

    # Turno
    turn: .asciz "o"

.section .text
    .global _start

_start:

.game_loop:
    call clear_screen

    # Rotar el turno
    mov turn, %ax
    cmp $'x', %ax
    je .set_o
.set_x:             
    mov $'x', %ax
    mov %ax, turn
    jmp .continue
.set_o:
    mov $'o', %ax
    mov %ax, turn

    # Imprimir mensaje del turno y el tablero
.continue:
    call print_turn
    call print_board

    # Recoger entrada del usuario
.user_action:
    call get_index #primer num
    push %ax
    call get_index #segundo num
    pop %bx
    sub $1, %bx
    imul $3, %bx, %bx
    add %bx, %ax
    sub $1, %ax

    # Comprobar si está vacía la casilla
    movb board(,%rax,1), %cl
    cmp $' ', %cl
    jne .user_action #si no es válido repetir

    # Poner la ficha
    mov turn, %bx 
    mov %bl, board(,%rax,1)

    # Comprobar victoria
    jmp check_win

.end_game:
    call print_turn
    call print_board

    #Llamada al sistema para salir
    
    mov $60, %eax   #syscall exit
    xor %edi, %edi  #código de salida 0
    syscall

print_turn:
    lea turn_string, %rsi
    mov $len_t_string, %rdx
    call print_rsi_rdx

    lea turn, %rsi
    mov $1, %rdx
    call print_rsi_rdx

    # Imprimir un salto de línea
    lea row_division, %rsi  # Dirección del separador
    mov $1, %rdx                  # Longitud del salto de línea
    call print_rsi_rdx
    ret

#Subrutina imprimir tablero
print_board:
    mov $0 , %r8  #índice inicial del tablero
    mov $0, %r9   #índice de columna

    lea column_division, %rsi 
    mov $1, %edx            
    call print_rsi_rdx

.loop_rows:
    lea board(,%r8,1), %rsi #index board + 0 offset + r8 * 1
    mov $1, %edx            #longitud: 1
    call print_rsi_rdx

    lea column_division, %rsi 
    mov $1, %edx            
    call print_rsi_rdx

    inc %r8
    inc %r9

 # Separar filas después de cada 3 caracteres
    mov %r9, %rcx
    cmp $3, %rcx              # Comprobar si %r9 es 3
    jne .loop_rows             # Si no es divisible, continuar con la fila
    mov $0, %r9

    # Imprimir un salto de línea
    lea row_division, %rsi  # Dirección del separador
    mov $1, %rdx                  # Longitud del salto de línea
    call print_rsi_rdx

    cmp $9, %r8
    je .end_loop

    lea column_division, %rsi 
    mov $1, %edx            
    call print_rsi_rdx

    jmp .loop_rows            # Volver al bucle

.end_loop:
.registers_clean:
    xor %r8, %r8        #limpeza de registros
    xor %r9, %r9
    xor %rax, %rax
    xor %rbx, %rbx
    xor %rcx, %rcx
    xor %rdx, %rdx
    xor %rsi, %rsi
    ret
    

check_win:
    # Comparar filas
    mov board, %al
    cmp $' ', %al
    je .next_check
    cmp %al, board+1
    jne .next_check
    cmp %al, board+2
    je .winner

.next_check:
    mov board+3, %al
    cmp $' ', %al
    je .next_check2
    cmp %al, board+4
    jne .next_check2
    cmp %al, board+5
    je .winner

.next_check2:
    mov board+6, %al
    cmp $' ', %al
    je .next_check3
    cmp %al, board+7
    jne .next_check3
    cmp %al, board+8
    je .winner

.next_check3:
    # Comparar columnas
    mov board, %al
    cmp $' ', %al
    je .next_check4
    cmp %al, board+3
    jne .next_check4
    cmp %al, board+6
    je .winner

.next_check4:
    mov board+1, %al
    cmp $' ', %al
    je .next_check5
    cmp %al, board+4
    jne .next_check5
    cmp %al, board+7
    je .winner

.next_check5:
    mov board+2, %al
    cmp $' ', %al
    je .next_check6
    cmp %al, board+5
    jne .next_check6
    cmp %al, board+8
    je .winner

.next_check6:
    # Comparar diagonales
    mov board, %al
    cmp $' ', %al
    je .next_check7
    cmp %al, board+4
    jne .next_check7
    cmp %al, board+8
    je .winner

.next_check7:
    mov board+2, %al
    cmp $' ', %al
    je .no_winner
    cmp %al, board+4
    jne .no_winner
    cmp %al, board+6
    je .winner

.no_winner:

check_full:
    mov $0, %rcx          # Inicializar el contador de índice a 0

.check_loop:
    cmp $9, %rcx          # Comparar el índice con el tamaño del buffer (9)
    je .full              # Si el índice es 9, el buffer está lleno

    mov board(,%rcx,1), %al  # Mover el byte en la dirección board + rcx a %al
    cmp $' ', %al         # Comparar el valor en %al con el carácter ' '
    je .not_full          # Si hay un espacio, el buffer no está lleno

    inc %rcx              # Incrementar el índice
    jmp .check_loop       # Repetir el bucle

.full:
    mov $'-', %ax         # Indicar que el buffer está lleno
    lea draw_message, %rsi
    mov $len_draw, %rdx
    call print_rsi_rdx
    mov turn, %ax
    jmp .end_game

.not_full:
    mov $'-', %ax
    jmp .game_loop         # Indicar que el buffer no está lleno

.winner:
    # Aquí puedes agregar código para manejar el caso de un ganador
    lea win_message, %rsi
    mov $len_win, %rdx
    call print_rsi_rdx
    mov turn, %ax
    jmp .end_game




.index_error:
    lea err_message1, %rsi  # Dirección del separador
    mov $len_err1, %rdx                  # Longitud del salto de línea
    call print_rsi_rdx

get_index:
    lea msg1, %rsi
    mov $len_msg1, %rdx
    call print_rsi_rdx 
    call get_input # devuelve un número en %al
    cmp $1, %al
    jl .index_error
    cmp $3, %al
    jg .index_error
    ret

get_input:
    mov $0, %rax           # Syscall número 0: read
    mov $0, %rdi           # File descriptor 0: stdin
    lea buffer, %rsi       # Dirección del buffer para guardar el input
    mov $2, %rdx           # Leer 1 byte
    syscall                # Leer un carácter de la entrada estándar

    movb buffer, %al       # Cargar el carácter leído en %al
    sub $'0', %al          # Convertir el carácter ASCII a su valor numérico

    ret                    # Retornar


print_rsi_rdx:
    # Imprimir un salto de línea
    mov $1, %rax                  # syscall: write
    mov $1, %rdi                  # stdout
    syscall
    ret

clear_screen:

    mov $1, %rax             # Syscall número 1: write
    mov $1, %rdi             # File descriptor 1: stdout
    lea clear_msg(%rip), %rsi # Dirección del mensaje de limpieza
    mov $len_clear_msg, %rdx             # Longitud del mensaje (4 bytes)
    syscall                  # Llamar a la syscall
    ret
