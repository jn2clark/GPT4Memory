.align 2
; Function signature: upsert(VectorDatabase* db, int index, float* vector, int vector_size)
.global upsert
.extern _malloc
.extern _free

upsert:

    ; Save callee-saved registers
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    ; Load arguments into registers
    mov x19, x0    ; db
    mov x20, x1    ; index
    mov x21, x2    ; vector
    mov x22, x3    ; vector_size

    ; Check if index is within range
    ldr w0, [x19, #4]         ; Load num_vectors into w0
    cmp w20, w0              ; Compare index and num_vectors
    b.hs index_out_of_range  ; If index >= num_vectors, branch to index_out_of_range

    ; Calculate the memory offset for the given index
    lsl x20, x20, #3           ; Multiply index by 8 (size of a pointer)
    add x20, x19, x20          ; Add offset to db to get the address of the vector

    ; Check if there's already a vector at that index
    ldr x0, [x20]              ; Load vector address into x0
    cbz x0, insert_new_vector  ; If vector address is NULL, branch to insert_new_vector

    ; Update existing vector
    ; (Assuming vector_size is the same for both old and new vectors)
    mov x23, x22               ; Save vector_size in x23
    copy_loop:
        ldr s0, [x21], #4      ; Load a float from input vector and post-increment x21
        str s0, [x0], #4        ; Store the float to the existing vector and post-increment x0
        subs x23, x23, #1       ; Decrement the counter
        b.gt copy_loop         ; If the counter is greater than 0, continue the loop

end_upsert:
    ; Restore callee-saved registers and return
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ret

; ...
insert_new_vector:
    ; Allocate memory for the new vector
    mov x0, x22                ; Move vector_size to x0
    lsl x0, x0, #2             ; Multiply vector_size by 4 (assuming float size is 4 bytes)
    bl _malloc                 ; Call _malloc, the result will be in x0 (new vector pointer)

    ; Store the new vector pointer in the database
    str x0, [x20]

    ; Copy the input vector to the newly allocated memory
    mov x23, x22               ; Save vector_size in x23
    copy_loop2:
        ldr s0, [x21], #4      ; Load a float from input vector and post-increment x21
        str s0, [x0], #4        ; Store the float to the new vector and post-increment x0
        subs x23, x23, #1       ; Decrement
        b.gt copy_loop2        ; If the counter is greater than 0, continue the loop

1:  ; memory_error

    ; Update the number of vectors in the database if necessary
    ldr w0, [x19, #4]          ; Load num_vectors into w0
    cmp x20, x0                ; Compare index and num_vectors
    b.ne 2f                    ; If index != num_vectors, skip updating

    ; ...
2:  ; end_upsert


; Function signature: int search(VectorDatabase* db, float* query_vector, int vector_size)
.global search

search:
    ; Save callee-saved registers
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    ; Load arguments into registers
    mov x19, x0    ; db
    mov x20, x1    ; query_vector
    mov x21, x2    ; vector_size

    ; Initialize variables for maximum dot product and corresponding index
    mov x22, #-1   ; Initialize index to -1
    mov x23, xzr   ; Initialize max_dot_product to 0

    ; Iterate through all the vectors in the database
    ldr w0, [x19, #4]    ; Load num_vectors into w0
    mov x1, xzr          ; Initialize loop counter to 0

iterate_vectors:
    cmp x1, x0           ; Compare loop counter and num_vectors
    b.hs end_search      ; If loop counter >= num_vectors, branch to end_search

    ; Calculate the memory offset for the current vector
    lsl x2, x1, #3           ; Multiply loop counter by 8 (size of a pointer)
    add x2, x19, x2          ; Add offset to db to get the address of the current vector
    ldr x2, [x2]             ; Load the address of the current vector into x2

    ; Calculate dot product between query_vector and the current vector
    ; Initialize accumulator to 0
    fmov s0, wzr
    mov x3, x21          ; Initialize loop counter for dot product calculation
dot_product_loop:
    cbz x3, update_max_similarity
    ldr s1, [x20], #4    ; Load a float from query_vector and post-increment x20
    ldr s2, [x2], #4     ; Load a float from the current vector and post-increment x2
    fmul s1, s1, s2      ; Multiply the floats
    fadd s0, s0, s1      ; Add the result to the accumulator
    sub x3, x3, #1       ; Decrement the loop counter
    sub x20, x20, x21, lsl #2 ; Reset x20 by subtracting vector_size * 4 from it
    b dot_product_loop
    
update_max_similarity:
    ; Compare the calculated dot product (s0) with the current maximum dot product (s23)
    fcmp s0, s23
    b.le next_vector

    ; If the calculated dot product is greater, update the maximum dot product and the corresponding index
    fmov s23, s0
    mov x22, x1

next_vector:
    add x1, x1, #1       ; Increment the loop counter
    b iterate_vectors

end_search:
    ; Restore callee-saved registers and return the index of the most similar vector
    mov x0, x22
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ret

; Function signature: void delete(VectorDatabase* db, int index)
.global delete
delete:
    ; Save callee-saved registers
    stp x19, x20, [sp, #-16]!

    ; Load arguments into registers
    mov x19, x0    ; db
    mov x20, x1    ; index

    ; Check if index is within range
    ldr w0, [x19, #4]         ; Load num_vectors into w0
    cmp x20, x0              ; Compare index and num_vectors
    b.hs index_out_of_range  ; If index >= num_vectors, branch to index_out_of_range

    ; Calculate the memory offset for the given index
    lsl x20, x20, #3           ; Multiply index by 8 (size of a pointer)
    add x20, x19, x20          ; Add offset to db to get the address of the vector

    ; Check if there's a vector at that index
    ldr x0, [x20]              ; Load vector address into x0
    cbz x0, end_delete         ; If vector address is NULL, branch to end_delete

    ; Free the memory for the vector and update the data structure (set the vector pointer to null)
    bl _free                    ; Call free to deallocate the memory
    mov x0, xzr                ; Set x0 to NULL (0)
    str x0, [x20]              ; Update the vector pointer in the database

    ; Update the number of vectors in the database if necessary
    ; (optional, depending on your implementation)

end_delete:
    ; Restore callee-saved registers and return
    ldp x19, x20, [sp], #16
    ret

index_out_of_range:
    ; Handle the index out of range case, e.g., return an error code or do nothing
    b end_delete
