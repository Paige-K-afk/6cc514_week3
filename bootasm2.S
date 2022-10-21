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

IntBuffer: .string "     "
cons_write_int:
    # output the 16-bit unsigned integer value in BX to the screen as an ASCII string of digits.
    # div takes ax and divides it by the given register. output is e high 16 bits in DX (remainder) and the low 16 bits in AX (quotient)
    # Take each didgit and offset it into ascii to print it out
    movw %bx, %ax
    movw $IntBuffer +4, %si
    write_int_cont:
    xor %dx, %dx
    movw $10, %cx
    div %cx

    # offset modulus (dx) by 48
    add $0x30, %dx 

    # write to buffer 
    movb %dl, (%si)

    # decrement SI   
    dec %si

    # -if the quotient is equal to zero, jump to end
    cmp $0x00, %ax
    jne write_int_cont # this will run if quotient is not 0

    inc %si  
    call    cons_write
    ret

HexChars: .ascii "0123456789ABCDEF"
cons_write_hex:
    movb    $0x0e, %ah 
    movw $4, %cx # cx is our counter.
    
    hex_cont: # so %cx doesnt keep getting reset.
    # use bit twiddling to shove the chunks out to only have the chunks you want.
    
    ROL $4, %bx 
    movw %bx, %si
    AND $0x000f, %si
    movb HexChars(%si), %al
    int     $0x10 
    loop hex_cont
   
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

    movw $0xFFFF, %bx
    call cons_write_int
    call cons_write_crlf
    movw $0x5432, %bx # in the hex writer, this shows as 5:5:, which is not correct. There is an issue with the hex display thing.
    call cons_write_hex
    call cons_write_crlf
    call cons_write_crlf

    # test values given in exersise:
    movw $65535, %bx # Display numbers in hex
    call cons_write_hex
    call cons_write_crlf
    movw $4660, %bx #  this is 0x1234 in hex. it displays as 1249. There is an issue with the hex display thing.
    call cons_write_hex
    call cons_write_crlf
    movw $0, %bx
    call cons_write_hex
    call cons_write_crlf
    movw $65535, %bx # Display unsigned short numbers
    call cons_write_int
    call cons_write_crlf
    movw $1234, %bx
    call cons_write_int
    call cons_write_crlf
    movw $0, %bx
    call cons_write_int
    call cons_write_crlf

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