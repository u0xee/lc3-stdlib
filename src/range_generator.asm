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
        ADD R0, R0, 0           ; So calling code can BRz to check for null ptr
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

range_template
        LD R0, range_curr
        LD R1, range_exhausted
        BRz range_not_exhausted
        RET
range_not_exhausted
        LD R1, range_step
        ADD R1, R0, R1          ; next = curr + step
        ST R1, range_curr       ; update static var

        ST R2, range_R2
        LD R2, range_stop
        NOT R2, R2              ; R2 = -R2
        ADD R2, R2, 1

        ADD R1, R1, R2          ; next - stop
        BRn range_n
        BRz range_z

        ADD R1, R0, R2          ; curr - stop
        BRp range_still_good
        BR range_now_exhausted
range_n
        ADD R1, R0, R2          ; curr - stop
        BRn range_still_good
        BR range_now_exhausted
range_z
        ADD R1, R0, R2          ; curr - stop
        BRz range_still_good
        BR range_now_exhausted

range_now_exhausted
        AND R2, R2, 0
        ADD R2, R2, 1           ; R2 = 1
        ST R2, range_exhausted  ; set exhausted flag
range_still_good
        LD R2, range_R2
        AND R1, R1, 0           ; R1 = 0, tells caller not exhausted
        RET

range_curr      .FILL 0
range_exhausted .FILL 0
range_step      .FILL -1
range_stop      .FILL -4
range_temp_R2   .FILL 0
range_template_end .FILL 0

range_R0        .FILL 0
range_R1        .FILL 0
range_R2        .FILL 0
range_R3        .FILL 0
range_R7        .FILL 0
range_start_default    .FILL 0
range
        ST R7, range_R7
        LD R0, range_start_default
        JSR range_start
        LD R7, range_R7
        RET

range_start_R7 .FILL 0
range_stop_default      .FILL x7FFF
range_start
        ST R7, range_start_R7
        LD R1, range_stop_default
        JSR range_start_stop

range_start_stop
range_start_stop_step .FILL 0

shim
        ST R7, shim_R7
        LD R0, shim_fptr
        LEA R1, shim_data
        JSRR R0
        LD R7, shim_R7
        ADD R0, R0, 0           ; set CC
        RET
shim_R7         .FILL 0
shim_fptr       .FILL 0
shim_data       .FILL 0


        ;; test malloc
heap_size       .FILL #200
main_R7         .FILL 0
list_head       .FILL 0

two             .FILL #2
twenty          .FILL #20
alpha           .FILL 'a'
alpha_caps      .FILL 'A'

main
        ST R7, main_R7          ; save return addr

        ;; initialize heap
        LEA R0, heap_start
        LD R1, heap_size
        JSR malloc_init


loop    JSR range_template
        BRz loop

        LD R2, twenty           ; R2 = 20

grow
        BRnz end_grow
        LD R0, two              ; R0 = 2
        JSR malloc              ; R0 is returned ptr
        BRz null_ptr_error
        STR R2, R0, 1           ; R0->data = R2 (counter)
        LD R1, list_head
        STR R1, R0, 0           ; R0->next = head
        ST R0, list_head        ; head = new_node_ptr
        ADD R2, R2, -1
        BR grow

end_grow

        LD R0, list_head
print_free
        BRz end_print
        LDR R1, R0, 1           ; R1 = R0->data
        LDR R2, R0, 0           ; R2 = R0->next
        JSR free                ; free(R0)
        LD R0, alpha            ; R0 = 'a'
        ADD R0, R0, R1          ; R0 += R1
        OUT
        ADD R0, R2, 0           ; R0 = R2
        BR print_free

end_print

        LD R7, main_R7          ; restore return addr
        RET

null_ptr_error
        LEA R0, null_error_str
        PUTS
        BR end_print

null_error_str
        .STRINGZ "Out of memory error: malloc!"

heap_start      .FILL 0
        .END
