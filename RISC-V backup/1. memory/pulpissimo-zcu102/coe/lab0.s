.globl _start

.text
.align 4
__irq_vector_base:
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     0x1c008074 #__timer_lo_irq_handler # timer lo interrupt, number 10
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2
  j     __no_irg_handler
  .align 2

__init:
	la x10, __irq_vector_base
	csrw mtvec, x10 					# setting interrupt vector base
	la sp, __sp2   						# setting stack pointer
	j _start
# Do not change any position of instuction above this (you can replace)

__timer_lo_irq_handler:
  add sp, sp, -128
  sw ra, 0(sp)
  jal __store_registers # save all registers

  lw x10, 0(x11)
  xori x10, x10, 1
  sw x10, 0(x11)

  jal __load_registers
  lw ra, 0(sp)
  add sp, sp, 128
  mret

__no_irg_handler:
  j __no_irg_handler

__load_registers:
	
	lw x8, 120(sp)
  lw x9, 124(sp)
  csrw mepc, x8
  csrw mstatus, x9

  lw x3, 4(sp)
  lw x4, 8(sp)
  lw x5, 12(sp)
  lw x6, 16(sp)
  lw x7, 20(sp)
  lw x8, 24(sp)
  lw x9, 28(sp)
  lw x10, 32(sp)
  lw x11, 36(sp)
  lw x12, 40(sp)
  lw x13, 44(sp)
  lw x14, 48(sp)
  lw x15, 52(sp)
  lw x16, 56(sp)
  lw x17, 60(sp)
  lw x18, 64(sp)
  lw x19, 68(sp)
  lw x20, 72(sp)
  lw x21, 76(sp)
  lw x22, 80(sp)
  lw x23, 84(sp)
  lw x24, 88(sp)
  lw x25, 92(sp)
  lw x26, 96(sp)
  lw x27, 100(sp)
  lw x28, 104(sp)
  lw x29, 108(sp)
  lw x30, 112(sp)
  lw x31, 116(sp)
  ret 

__store_registers:
  
  sw x3, 4(sp)
  sw x4, 8(sp)
  sw x5, 12(sp)
  sw x6, 16(sp)
  sw x7, 20(sp)
  sw x8, 24(sp)
  sw x9, 28(sp)
  sw x10, 32(sp)
  sw x11, 36(sp)
  sw x12, 40(sp)
  sw x13, 44(sp)
  sw x14, 48(sp)
  sw x15, 52(sp)
  sw x16, 56(sp)
  sw x17, 60(sp)
  sw x18, 64(sp)
  sw x19, 68(sp)
  sw x20, 72(sp)
  sw x21, 76(sp)
  sw x22, 80(sp)
  sw x23, 84(sp)
  sw x24, 88(sp)
  sw x25, 92(sp)
  sw x26, 96(sp)
  sw x27, 100(sp)
  sw x28, 104(sp)
  sw x29, 108(sp)
  sw x30, 112(sp)
  sw x31, 116(sp)

  csrr x8, mepc
  csrr x9, mstatus
  sw x8, 120(sp)
  sw x9, 124(sp)
	ret


	
_start:

	csrrci x15, mstatus, 8		# clearing mie bit to do some setting

 	# start irq_mask setting
 	li x10, 0x1a109804
 	li x11, 0x400							# turn on the timer_lo mask
 	sw x11, 0(x10)
 	# end irq_mask_setting

	# start timer setting

	li x10, 0x1a10b000				# address of timer
	
	li x11, 0x1  							# reset timer 								_lo
	sw x11, 0x20(x10)				

	li x11, 0x0     					# setting count as zero  			_lo
	sw x11, 0x8(x10)

	li x11, 0x1000            # setting compare as 0x1000 	_lo
	sw x11, 0x10(x10)					

	li x11, 0x14							# setting configuration				_lo
	sw x11, 0x0(x10)					# turn on the irq enable bit	_lo
														# set as cycle mode						_lo

	li x11, 0x1 							# start timer 								_lo
	sw x11, 0x18(x10)	

	# end timer setting

	csrrsi x15, mstatus, 8 	 	# setting mie bit after do some setting

	j forever

forever:
	nop
	j forever



.data
.align 16
__sp1: .space 1024
__sp2: .space 1024
