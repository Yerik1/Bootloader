BITS 16              ; El código se ensamblará para modo real de 16 bits.
ORG 7C00h            ; La BIOS carga el boot sector en la dirección física 0x7C00.

start:
    cli              ; Deshabilita interrupciones mientras se configura el entorno.

    xor ax, ax       ; AX = 0. Se usa para limpiar varios segmentos.
    mov ds, ax       ; Data Segment = 0.
    mov es, ax       ; Extra Segment = 0.
    mov ss, ax       ; Stack Segment = 0.
    mov sp, 7C00h    ; El stack empieza en 0x7C00. 

    sti              ; Se vuelven a habilitar interrupciones.

    ; La BIOS deja en DL el número de unidad de arranque.
    mov [boot_drive], dl

    ; primer stage empezó.
    mov si, msg_boot
    call print_string

    ; --------------------------------------------------------
    ; Verificar soporte de INT 13h Extensions
    ; --------------------------------------------------------
    ; AH = 41h es la función de chequeo de extensiones.
    ; BX debe contener 55AAh como firma de entrada.
    ; Si la BIOS responde correctamente, BX regresará como AA55h.
    ; --------------------------------------------------------
    mov ah, 41h
    mov bx, 55AAh
    mov dl, [boot_drive]
    int 13h

    jc no_extensions ; Si Carry = 1, hubo error: no hay soporte.

    cmp bx, 0AA55h   ; Verificamos la firma de salida esperada.
    jne no_extensions

    ; --------------------------------------------------------
    ; Leer sectores del disco usando LBA (INT 13h, AH=42h)
    ; --------------------------------------------------------
    ; SI apunta al Disk Address Packet (DAP), estructura que
    ; describe cuántos sectores leer, desde cuál LBA y hacia
    ; qué dirección de memoria cargarlos.
    ; --------------------------------------------------------
    mov si, dap_packet
    mov ah, 42h
    mov dl, [boot_drive]
    int 13h

    jc disk_error    ; Si falla la lectura, mostramos error.

    ; Si todo salió bien, saltamos al código recién cargado.
    jmp 0000h:7E00h

no_extensions:
    ; Este camino se toma si la BIOS no soporta lecturas LBA extendidas.
    mov si, msg_noext
    call print_string
    jmp halt

disk_error:
    ; Este camino se toma si la lectura del segundo stage falla.
    mov si, msg_err
    call print_string
    jmp halt

halt:
    ; Apaga interrupciones y se queda detenido para siempre.
    cli
.hang:
    hlt              ; Reduce actividad del CPU hasta la próxima interrupción.
    jmp .hang        ; Bucle infinito.

; ============================================================
; print_string
; ------------------------------------------------------------
; Imprime una cadena terminada en 0 usando la BIOS de video.
; Entrada:
;   SI = dirección de la cadena
; Usa INT 10h / AH=0Eh (teletype output)
; ============================================================
print_string:
.next:
    lodsb            ; AL = byte apuntado por DS:SI, luego SI++.
    cmp al, 0        ; ¿Fin de cadena?
    je .done

    mov ah, 0Eh      ; Función BIOS: imprimir carácter.
    mov bh, 00h      ; Página de video 0.
    mov bl, 07h      ; Atributo/color (gris claro en texto).
    int 10h

    jmp .next
.done:
    ret

; Variable donde se guarda el disco desde el que se arrancó.
boot_drive db 0

; Mensajes terminados en 0.
msg_boot   db 13,10,'Legacy MBR: cargando stage...',13,10,0
msg_err    db 13,10,'Error leyendo stage por LBA.',13,10,0
msg_noext  db 13,10,'BIOS sin INT13h extensions.',13,10,0


dap_packet:
    db 10h           ; Tamaño del DAP = 16 bytes.
    db 00h           ; Reservado.
    dw 4             ; Leer 4 sectores.
    dw 7E00h         ; Offset de carga.
    dw 0000h         ; Segmento de carga.
    dq 1             ; Empezar desde LBA 1.

; ============================================================
; Tabla de particiones y firma final del MBR
; ------------------------------------------------------------
; Un MBR completo ocupa 512 bytes.
; Los últimos 66 bytes se reservan típicamente para:
;   - 64 bytes: tabla de particiones (4 entradas de 16 bytes)
;   - 2 bytes : firma 0xAA55
; ============================================================

times 446-($-$$) db 0

    ; Primera entrada de la tabla de particiones.
    ; Aquí se describe una partición arrancable.
    db 80h           ; 0x80 = partición activa / bootable.
    db 00h, 02h, 00h ; CHS inicial (valor heredado / compatibilidad).
    db 0Eh           ; Tipo de partición (FAT16 LBA, típicamente).
    db 0FFh, 0FFh, 0FFh ; CHS final.
    dd 1             ; LBA inicial de la partición.
    dd 5             ; Tamaño en sectores.

    ; Se reservan 3 entradas más vacías (3 * 16 bytes).
    times 16*3 db 0

    ; Firma obligatoria del boot sector.
    ; Sin esto, la BIOS normalmente no lo considera arrancable.
    dw 0AA55h
