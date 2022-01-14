.globl _start

.text
.option norvc

__irq_vector_base:
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j   __no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler
	j	__no_irq_handler

_start:
	la x10, __irq_vector_base
	csrw mtvec, x10
	la sp, __sp2
	j _entry

_entry:
	j main

main:
	#pad_set_function
	addi t0, x0, 10 #LED2 - pad - a0
	srli s1, t0, 4 #padid
	slli s2, t0, 1 #padbit

	li t1, 0x1a104000 #apb soc ctrl base
	lw s3, 16(t1) #padfunc get
	li s4, 3
	sll s4, s4, s2
	not s4, s4
	and s3, s3, s4 #oldval
	li s4, 1
	sll s4, s4, s2
	or s3, s3, s4 #newval
	sw s3, 16(t1)
	
	li s1, 1
	sll t0, s1, t0 #mask
	li t1, 0x1a101000 #gpio
	lw t2, 0(t1) #dir
	or t2, t2, t0
	sw t2, 0(t1) #led1 as output

	lw t2, 4(t1) #enable
	not t3, t0
	and t2, t2, t3
	sw t2, 4(t1)

	lw t2, 12(t1) #padout
	or t2, t2, t0
	sw t2, 12(t1) 

__no_irq_handler:
	j __no_irq_handler

.data
.align 16
__sp1: .space 1024
__sp2: .space 1024
