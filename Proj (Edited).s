# Joshua Vitullo
# Howard Cheng
# Dakota Smith
# CSCE 350 - 503

# Project 1

.data
	msg:						.asciiz "Enter postfix expression:\n"
	error_msg1: 				.asciiz "Stack popping failed."
	error_msg2: 				.asciiz "Input not in correct format."		
	Top: 						.word 0 			# Top of stack
	Top2:						.word 0 			# For passing items in the stack
	N:							.word 20			# Only stores 20 characters (according to project example)
	M: 							.space 160			# Initial array space
	M2: 						.space 160			# Array space for postfix
	FL: 						.word M 			# Freelist (Points to M)
	
.text
.globl main

main:
	la $a0, msg				
	li $v0, 4
	syscall
	
	jal mem_init
	
	la $a0, M2
	li $v0, 8				# read string
	syscall
	
	jal eval

	move $a0, $v0
	li 	$v0, 1
	syscall
	
	li	$v0, 10
	syscall


#------------------------------------------------------------------	
# Part 1 by Howard Cheng
#------------------------------------------------------------------

# Initialize array (void mem_init())

mem_init:
	la 	$t0, FL
	lw	$t0, ($t0)				# Load M into $t0
	lw 	$t2, N

init_for:
	beq $t1, $t2, init_return	# $t1 = i
	addi $t3, $t0, 8			# 8 bytes for character and pointing to the next element
	sw $t3, 4($t0)
	addi $t0, $t0, 8
	addi $t1, $t1, 1
	j init_for
	
init_return:
	jr $ra

#------------------------------------------------------------------

# Allocate memory block (block_t* mem_alloc())
	
mem_alloc:
	la $t0, FL
	bne	$t0, $0, alloc_next
	sub $v0, $0, 1	# throw exception in postfix (part 4)
	j alloc_return
	
alloc_next:
	lw $v0, ($t0)			# $a1 = $t0's first element
	lw $t1, 4($v0)			# $t1 = next element from $a1
	sw $t1, ($t0)			# Update current pointer as next pointer
	sw $0, 4($v0)			# Clear old pointer
	
alloc_return:
	jr	$ra

#------------------------------------------------------------------

# Deallocate memory block (void mem_dealloc(block_t *p)
	
mem_dealloc:
	move $t0, $a0
	bnez $t0, dealloc_next
	li $t0, -1
	
	j dealloc_return
	
dealloc_next:
	la 	$t1, FL
	lw $t2, ($t1)	# p->next = FL
	sw $t2, 4($t0)	
	sw $0, ($t0)	
	sw $t0, ($t1)	# FL = p
	
dealloc_return:
	jr $ra

#------------------------------------------------------------------
# Part 2 by Howard Cheng
#------------------------------------------------------------------

# Assign the val field (void set_data_int(data_t* p, int integer)

set_data_int:		# $a1 = int value
	sw $a1,($a0)	# store int into memory block
	jr 	$ra

# Print data (void print_data(data_t* p))
	
print_data:
	li $v0, 1
	lw $a0, ($a0)
	syscall
	
	jr $ra
	
#------------------------------------------------------------------	
# Part 3 by Joshua Vitullo
#------------------------------------------------------------------	

# Push character into stack (void stack_push(data_t* d))

stack_push:	
	sub $sp, 8
	sw 	$ra, ($sp) 		# variables to stack
	sw 	$a0, 4($sp)
	jal mem_alloc
	
	move $t0, $v0 		# pointer to t0
	lw 	$ra, ($sp) 		# variables from stack
	lw 	$a0, 4($sp)

	lw 	$t1, ($a0)		 # int from pointer
	sw 	$t1, ($t0) 		 # store int
	la 	$t1, Top

	lw 	$t2, ($t1)		 # t2 is pointer 
	sw 	$t2, 4($t0) 
	sw 	$t0, ($t1)		 # Top to a new block

	addi $sp, 8			 # pointer to origin
	jr 	$ra

# Pop top element from stack (data_t* stack_pop())
	
stack_pop:
	addi $sp, -4		 # save return address
	sw 	$ra, ($sp)
	
	la 	$t0, Top 
	lw 	$t1, ($t0) 
	beqz $t1, stack_ex	 # check for null character
	
	lw	$t3, ($t1) 
	la	$v0, Top2
	sw 	$t3, ($v0) 		 # save data value
	
	lw 	$t2, 4($t1) 	 # save value
	sw 	$t2, ($t0)		 # next pointer
	
	move $a0, $t1
	jal mem_dealloc
	
	la	$v0, Top2		 # Pass items in stack
	lw 	$ra, ($sp)
	addi $sp, 4
	jr 	$ra

stack_exit:				# Return to operand routine
	la $t0, Top
	lw $t1, ($t0)
	slt $v0, $0, $t1
	jr $ra

stack_ex:				 # stack exception
	la $a0, error_msg1
	li $v0, 4
	syscall

	lw $ra, ($sp)
	addi $sp, 4
	li $v0, 10
	syscall
	jr 	$ra

#------------------------------------------------------------------	
# Part 4 by Dakota Smith
#------------------------------------------------------------------

eval:
	addi $sp, -4 			#save return address
	sw 	$ra,($sp)
	move $t7, $a0

# Evaluate left to right
	
parse:
	lb	$t0, ($t7)
	beq $t0, 10, pfexit 	# ascii for new line
	
	beq $t0, 43, addition 	# ascii for '+'
	beq $t0, 45, subtract	# ascii for '-'
	beq $t0, 42, multiply	# ascii for '*'
	beq $t0, 120, multiply 	# ascii for 'x'
	beq $t0, 47, divide		# ascii for '/'

	blt $t0, 48, pfexception	# throw exception for ascii value below '0'
	bgt	$t0, 57, pfexception 	# throw exception for ascii value above '9'

	sub $t0, $t0, 48			# reduce to number
	
	la	$a0, Top2
	sw	$t0, ($a0)
	jal stack_push

	addi $t7, $t7, 1 	
	j parse

#---Operand Routines------------------------------------------------------	
	
addition:
	jal stack_pop
	addi $sp, -4
	lw 	$t4 ,($v0)	#save return value
	sw	$t4, ($sp)
	
	jal stack_pop
	lw	$t4, ($sp)
	addi $sp, 4
	lw 	$t3 ,($v0)	# get last 2 digits from stack
	
	add $t3, $t3, $t4 
	la 	$a0, Top2
	sw	$t3, ($a0)	
	jal stack_push	# put sum back on stack
	
	addi $t7, $t7, 1
	j parse		# jump back for next character

subtract:
	jal stack_pop
	lw 	$t4 ,($v0)
	addi $sp, -4
	sw	$t4, ($sp)
	
	jal stack_pop
	lw	$t4, ($sp)
	addi $sp, 4
	lw 	$t3 ,($v0)	# get last 2 digits from stack
	
	
	sub $t3, $t3, $t4 # subtract operation t3-t4 order matters!
	la	$a0, Top2
	sw	$t3, ($a0)
	jal	stack_push	# put difference back on stack
	
	addi $t7, $t7, 1
	j parse			# jump back for next character
	
multiply:
	jal stack_pop
	lw 	$t4 ,($v0)
	addi $sp, -4
	sw	$t4, ($sp)	# get last 2 digits from stack
	
	jal stack_pop
	lw	$t4, ($sp)
	addi $sp, 4
	lw $t3 ,($v0) 	# get last 2 digits from stack
	
	mult $t3, $t4
	mflo $t3
	la	$a0, Top2	
	sw	$t3, ($a0)
	jal	stack_push	# put product back on stack
	
	addi $t7, $t7, 1
	j parse			# jump back for next character

divide:
	jal stack_pop
	lw 	$t4 ,($v0)
	addi $sp, -4
	sw	$t4, ($sp)
	
	jal stack_pop
	lw	$t4, ($sp)
	addi $sp, 4
	lw $t3 ,($v0)	# get last 2 digits from stack
	
	div $t3, $t4
	mflo $t3
	la 	$a0, Top2
	sw	$t3, ($a0)
	jal	stack_push	# put quotient back on stack
	
	addi $t7, $t7, 1
	j parse			# jump back for next character

pfexception:
	la 	$a0, error_msg2
	li 	$v0, 4
	syscall

	lw 	$ra, ($sp)
	addi $sp, 4
	li 	$v0, 10		
	syscall

pfexit:
	jal stack_pop	
	lw 	$v0, ($v0)	# final result is put into $v0
	addi $sp, -4
	sw 	$v0, ($sp)
	jal	stack_exit
	li	$t6, 1
	beq	$t6, $v0, pfexception

	lw	$v0, ($sp)	
	lw 	$ra, 4($sp)
	addi $sp, 8
	jr 	$ra