# When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
# a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
# eventually switch the processor into 32-bit mode.

# This code is linked to assume a starting address of 0x7C00 which is where the BIOS
# will load a boot segment.

.code16                         # Assemble for 16-bit mode
.globl start
start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

cons_write_crlf:
    movb    $0x0e, %ah          # Output CR
    movb    $0x0d, %al
    int     $0x10
    movb    $0x0a, %al          # Output LF
    int     $0x10
    ret

cons_writeline:
    call    cons_write
    call    cons_write_crlf
    ret   

cons_write_int:
    # output the 16-bit unsigned integer value in BX to the screen
    # as an ASCII string of digits.
    # put num in dx (high) and ax (low), Dx = 0. take AX, use integer devision to divide it by 10.
    # take each didgit and offset it into ascii to print it out
    movw %bx, %ax
    write_int_cont:
    xor %dx, %dx
    movw $10, %cx
    div %cx

    # %ax, (num_result)
    # %dx, (num_modulus)

    # offset modulus (dx) by 48
    add $0x30, %dx 
    # move result to bx for safekeeping before output occurs
    movw %ax, %bx

    # WRITE
    movb    $0x0e, %ah 
    movb    %dl, %al 
    int     $0x10 
    movw %bx, %ax # move it back to ax
    # -if num_result equal zero, jump to end
    cmp $0x00, %ax
    je write_int_end

    jmp write_int_cont

    write_int_end:
    ret

real_start:
    movb    %dl, (boot_device) # Boot device number is passed in DL from BIOS. Save it hear since DL might get trashed

    movw    $boot_message, %si  # Display our boot message
    call    cons_writeline

    movw    $booted_from_msg, %si
    call    cons_write

    movb    (boot_device), %dl
    cmp     $0x80, %dl
    jge     harddrive

    movw    $fd, %si
    jmp     finish

harddrive:
    movw    $hd, %si

finish:
    call    cons_writeline

    movw $0xFFFF,(num)
    movw (num), %bx
    call cons_write_int

endless_loop:                   # Loop forever more
    jmp     endless_loop    

# Program data

boot_device:
    .byte   0

boot_message:     
    .string "Boot Loader Stage 2 loaded"             
booted_from_msg:
    .string "Booting from "
fd: .string "floppy disk"
hd: .string "hard drive"
num: .string