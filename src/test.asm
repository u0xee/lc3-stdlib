        .ORIG 3000
        LD R0, char_A
        ADD R1, R0, 1
        HALT

char_A  .FILL x7FFF
        .END
