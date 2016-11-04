        ;; Cole Frederick
        .ORIG x3000

        JSR main                ; call function
        HALT

heap    .FILL 0
null    .FILL 0
        ;; Function malloc_init, R0 is start address, R1 is heap size, no return
malloc_init
        ST R0, heap             ; head pointer
        ADD R1, R1, -2          ; subtract size of heap cell
        STR R1, R0, 1           ; store size of heap cell
        LD R1, null
        STR R1, R0, 0           ; store next node ptr (null)
        RET

mal_R1  .FILL 0
mal_R2  .FILL 0
mal_R3  .FILL 0
mal_R4  .FILL 0
mal_R5  .FILL 0
mal_min_size   .FILL -4         ; minimum cell size, negative for convenience
        ;; Function malloc, R0 is space requested, other registers preserved
        ;; return ptr to new space in R0, or null ptr upon failure
malloc
        ST R1, mal_R1
        ST R2, mal_R2
        ST R3, mal_R3
        ST R4, mal_R4
        ST R5, mal_R5

        LD R1, mal_min_size
        ADD R2, R0, R1          ; R0 - min_size
        BRn malloc_too_small
        NOT R0, R0              ; R0 = -R0
        ADD R0, R0, 1
        BR malloc_R0_ready
malloc_too_small
        LD R0, mal_min_size

malloc_R0_ready
        LEA R1, heap            ; R1 holds addr of head ptr
        LDR R2, R1, 0           ; R2 holds addr of first heap cell

malloc_search
        BRz malloc_fail         ; hit end of list, null ptr
        LDR R3, R2, 1           ; R3 = R2->size
        ADD R4, R3, R0          ; R3 - space_requested
        BRn malloc_continue     ; heap cell too small

        ;; R4 = space left in cell after current allocation
        ;; don't split cell if the leftover would be smaller than min_size
        LD R5, mal_min_size
        ADD R5, R5, -2
        ADD R5, R5, R4          ; leftover - 2 (cell) - min_size
        BRn malloc_unlink_return

        NOT R0, R0              ; R0 = -R0 (size requested from malloc)
        ADD R0, R0, 1
        STR R0, R2, 1           ; R2->size = R0

        ADD R3, R2, R0          ; offset cell addr by size
        ADD R3, R3, 2           ; further offset by size of cell
        ;; R3 is addr of new split heap cell
        ADD R4, R4, -2          ; R4 was leftover total, take out cell size
        STR R4, R3, 1           ; R3->size = R4
        LDR R4, R2, 0           ; R4 = R2->next
        STR R4, R3, 0           ; R3->next = R4
        STR R3, R2, 0           ; R2->next = R3
        BR malloc_unlink_return

malloc_unlink_return
        LDR R3, R2, 0           ; R3 = R2->next
        STR R3, R1, 0           ; R1->next = R3
        ADD R0, R2, 2           ; R0 is addr of memory
        BR malloc_exit

malloc_continue
        ;; Advance pointers for next loop iteration
        ADD R1, R2, 0           ; R1 = R2
        LDR R2, R2, 0           ; R2 = R2->next
        BR malloc_search

malloc_fail
        LD R0, null
        BR malloc_exit

malloc_exit
        LD R1, mal_R1
        LD R2, mal_R2
        LD R3, mal_R3
        LD R4, mal_R4
        LD R5, mal_R5
        RET

        ;; Function free, R0 is ptr to free, no return
free
        ST R1, mal_R1
        ST R2, mal_R2

        ADD R0, R0, -2          ; get addr of heap cell
        LEA R1, heap            ; R1 holds addr of head ptr
        LDR R2, R1, 0           ; R2 holds addr of first heap cell
        ;; link freed node in front of list
        STR R2, R0, 0           ; R0->next = head
        STR R0, R1, 0           ; head = R0

        LD R1, mal_R1
        LD R2, mal_R2
        RET



        ;; test malloc
heap_size       .FILL #50
main_R7         .FILL 0

three           .FILL #3
ten             .FILL #10
fifteen         .FILL #15
twenty          .FILL #20


main
        ST R7, main_R7          ; save return addr

        ;; initialize heap
        LEA R0, heap_start
        LD R1, heap_size
        JSR malloc_init

        LEA R1, ptr_array           ; pointer storage

        ;; malloc(20)
        LD R0, twenty
        JSR malloc
        STR R0, R1, 0

        ;; malloc(3) - rounds up to min size of 4
        LD R0, three
        JSR malloc
        STR R0, R1, 1

        ;; malloc(15) - doesn't split, would leave cell of size 3
        LD R0, fifteen
        JSR malloc
        STR R0, R1, 2

        ;; malloc(10) fails
        ;; (20 + 2) + (4 + 2) + (15 + 2) = 45
        LD R0, ten
        JSR malloc              ; returns null ptr

        ;; free(ptr20), head of heap list
        LDR R0, R1, 0
        JSR free

        ;; free(ptr3), new head of list
        LDR R0, R1, 1
        JSR free

        ;; malloc(10) succeeds!
        ;; passes over small cell
        ;; splits 20 cell, leaves cell of size 8
        LD R0, ten
        JSR malloc

        ;; We didn't free all malloc'd memory,
        ;; Memory leak!!
        ;; oh well
        LD R7, main_R7          ; restore return addr
        RET

ptr_array   .BLKW #3

heap_start      .FILL 0
        .END
