.data
val1: .word 1   # posición 0
val2: .word 2   # posición 4
val3: .word 4   # posición 8
val4: .word 8   # posición 12
val5: .word 16  # posición 16
val6: .word 32  # posición 20
res1: .word 0   # posición 24
res2: .word 0   # posición 28
res3: .word 0   # posición 32
res4: .word 0   # posición 36
res5: .word 0   # posición 40
res6: .word 0   # posición 44

.text
main:
    lw $t0, 0($zero) 
    lw $t1, 4($zero) 
    lw $t2, 8($zero) 
    lw $t3, 12($zero)
    lw $t4, 16($zero)
    lw $t5, 20($zero)
    add $t6, $t0, $t1
    sub $t7, $t4, $t2
    and $t8, $t1, $t5
    or  $t9, $t3, $t4
    slt $s0, $t2, $t5
    sub $s1, $t5, $t1
    sw $t6, 24($zero)
    sw $t7, 28($zero)
    sw $t8, 32($zero)
    sw $t9, 36($zero)
    sw $s0, 40($zero)
    sw $s1, 44($zero)
    beq $t0, $t1, end
    j main           
end:
    j end                # Fin del programa
