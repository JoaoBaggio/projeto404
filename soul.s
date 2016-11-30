@================[INCLUDE]===============
.include "sets.inc"

@========================================
.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
    b RESET_HANDLER
.org 0x8
    b syscall_vector
.org 0x18
    b IRQ_HANDLER

@ ====================[data section]==============
.data
CONTADOR:
    .word 0

@ ================[text section]==================
.org 0x100
    .text
    .align 4

@ ------------------configures--------------------
configure_GPT:

    ldmfd sp!, {lr}
    @ Configures GPT
    mov r0, #0

    @ Carrega valor base de GPT
    ldr r1, =GPT_BASE

    @Registrador CR
    mov r0, 0x00000041
    str r0,[r1]

    @ Registrador PR
    mov r0, #0
    str r0,[r1,#GPT_PR]


    @ Registrador GPT_OCR1
    mov r0, #100
    str r0,[r1,#GPT_OCR1]

    @ Registrador GPT_IR
    mov r0, #1
    str r0,[r1,#GPT_IR]

    stmfd sp!, {lr}
    mov pc, lr
configure_GPIO:
    stmdb sp!, {lr}

    @ Mascara de entrada/saida
    ldr r0, =0xFFFC003E
	ldr r1, =GPIO_BASE

    @ Adiciona mascara em GDIR
    str r0, [r1, #GPIO_GDIR]

	mov r0, #0
  	str r0, [r1, #GPIO_DR]

    ldmfd sp!, {lr}
    mov pc,lr

configure_TZIC:
    stmfd sp!, {lr}
@ Liga o controlador de interrupcoes
    @ R1 <= TZIC_BASE

    ldr	r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)

    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_ENSET1]

    @ Configure interrupt39 priority as 1
    @ reg9, byte 3

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]

    @instrucao msr - habilita interrupcoes
    msr  CPSR_c, #0x13       @ SUPERVISOR mode, IRQ/FIQ enabled

    ldmfd sp!,{lr}
    mov pc, lr


@---------------------------------------------------------
    @ Zera o contador
    ldr r2, =CONTADOR  @lembre-se de declarar esse contador em uma secao de dados!
    mov r0,#0
    str r0,[r2]


RESET_HANDLER:
     @Set interrupt table base address on coprocessor 15.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0

    msr  CPSR_c, #0x1F       @ System mode


    bl configure_GPT
    bl configura_GPIO
    bl configure_TZIC

    msr  CPSR_c,  #0x10 @ User mode
    ldr pc, =0x77800700




IRQ_HANDLER:
    ldr r0, =GPT_BASE
    mov r1, #0x1
    str r1,[r0,#GPT_SR]

    ldr r2, =CONTADOR  @lembre-se de declarar esse contador em uma secao de dados!
    ldr r1,[r2]
    add r1,r1,#1
    str r1,[r2]

    movs pc, lr

syscall_vector:

    @ Salva o contexto
    stmfd sp!,{lr}

    @ Muda o modo sistema
    msr CPSR_c, #0x1F

    @ Verifica se eh a Syscall read_sonar
    cmp r7, #16
    bleq read_sonar


    @ Verifica se eh a Syscall register_proximity_callback
    cmp r7, #17
    bleq register_proximity_callback

    @ Verifica se eh a Syscall set_motor_speed
    cmp r7, #18
    bleq set_motor_speed

    @ Verifica se eh a Syscall set_motors_speed
    cmp r7, #19
    bleq set_motors_speed

    @ Verifica se eh a Syscall get_time
    cmp r7, #20
    bleq get_time

    @ Verifica se eh a Syscall set_time
    cmp r7, #21
    bleq set_time

    @ Verifica se eh a Syscall set_alarm
    cmp r7, #22
    bleq set_alarm

    ldmfd sp!, {lr}
    movs pc,lr

read_sonar:
    ldmfd sp!, {r0}

register_proximity_callback:

set_motor_speed:

set_motors_speed:

  stmfd sp!, {r4-r11,lr}

  ldr r2, =GPIO_BASE

  mov r3, #0x3F
  mov r4, r3, LSL #19
  orr r4, r4, r3, LSL #26
  mvn r4, r4     @ cleaning mask
  and r0, r0, r3 @ limited speed 0
  and r1, r1, r3 @ limited speed 1
  mov r3, r0, LSL #19
  orr r3, r3, r1, LSL #26

  ldr r0, [r2, #GPIO_DR]
  and r0, r0, r4
  orr r0, r0, r3

  str r0, [r2, #GPIO_DR]

  ldmfd sp!, {r4-r11,pc}

get_time:

set_time:

set_alarm:

