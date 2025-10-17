    addi x2, x0, 4      # x2 = 4
    addi x3, x0, 13     # x3 = 13
    addi x1, x0, 9      # x1 = 9

    add  x5, x3, x0     # x5 = x3 = 13
    add  x6, x3, x3     # x6 = 26
    add  x7, x6, x2     # x7 = 30
    add  x8, x7, x0     # x8 = 30

    addi x9,  x0, 1     # x9 = 1
    addi x10, x0, 21    # x10 = 21
    addi x11, x0, 12    # x11 = 12
    add  x12, x7, x0    # x12 = 30
    add  x13, x9, x0    # x13 = 1
    addi x14, x0, -10   # x14 = -10

    sw x11, 0(x0)       # mem[0]  = 12
    sw x7,  4(x0)       # mem[4]  = 30
    sw x3,  8(x0)       # mem[8]  = 13
    sw x6,  12(x0)      # mem[12] = 26
    sw x7,  16(x0)      # mem[16] = 30
    sw x7,  20(x0)      # mem[20] = 30
    sw x9,  24(x0)      # mem[24] = 1
    sw x10, 28(x0)      # mem[28] = 21

finish:
    jal x0, finish      # hold CPU
