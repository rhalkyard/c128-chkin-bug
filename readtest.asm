;***************************************
; Reproducer for CHKIN bug seen on Commodore 128
; 
; Reads a line at a time from two files, 'file1' and 'file2'
;***************************************

!cpu 6510
!ct pet

; Kernal routines
SETBNK = $f73f
READST = $ffb7
SETLFS = $ffba
SETNAM = $ffbd
OPEN = $ffc0
CLOSE = $ffc3
CHKIN = $ffc6
CLRCHN = $ffcc
CHRIN = $ffcf
CHROUT = $ffd2
;***************************************

LFN1 = 2 ; file number for file 1
SA1 = 2 ; secondary address for file 1
LFN2 = 3 ; file number for file 2
SA2 = 3 ; secondary address for file 2

DEVICE = $ba ; default device number

!if TARGET = 128 {
* = $1c01
} else {
* = $0801
}

; BASIC header
!byte $b, $08, $a, 0 
!byte $9E ; SYS
; start address as decimal digits  
!byte '0' + start % 10000 / 1000     
!byte '0' + start %  1000 /  100        
!byte '0' + start %   100 /   10        
!byte '0' + start %    10
!byte 0, 0, 0 ; end BASIC
;***************************************

; Execution starts here
start
; Open file1 and read a line from it
!if TARGET=128 {
    lda #0 ; load/store from RAM0
    ldx #0 ; fetch filename from RAM0
    jsr SETBNK
}

    lda #filename1_len
    ldx #<filename1
    ldy #>filename1
    jsr SETNAM

    lda #LFN1   ; file number
    ldx DEVICE ; device number
    ldy #SA1   ; secondary address
    jsr SETLFS

    jsr OPEN
    bcc +
    ldx #err_open
    jmp errexit
+
    ldx #LFN1
    jsr do_chkin
    jsr readline


; Open file2 and read a line from it
!if TARGET=128 {
    lda #0 ; load/store from RAM0
    ldx #0 ; fetch filename from RAM0
    jsr SETBNK
}

    lda #filename2_len
    ldx #<filename2
    ldy #>filename2
    jsr SETNAM

    lda #LFN2   ; file number
    ldx DEVICE ; device number
    ldy #SA2   ; secondary address
    jsr SETLFS

    jsr OPEN
    bcc +
    ldx #err_open
    jmp errexit
+
    ldx #LFN2
    jsr do_chkin
    jsr readline

; read a line from file1
    ldx #LFN1
    jsr do_chkin
    jsr readline

; read the remaining lines from file2
; until we hit EOF
    ldx #LFN2
    jsr do_chkin

-   jsr readline
    ora #0 ; x contains READST result
    beq -

    lda #LFN2
    jsr CLOSE ; close file2

; read the remaining lines from file1
; until we hit EOF
    ldx #LFN1
    jsr do_chkin
-   jsr readline
    ora #0
    bne +
    jmp -
+   
    lda #LFN1
    jsr CLOSE ; close file1

    jsr CLRCHN ; reset input to console
    rts ; quit to BASIC

;***************************************
; Call CHKIN and exit if it fails
; Destroys A, X
;***************************************
do_chkin
    jsr CHKIN
    jsr READST
    bne +
    rts
+   ldx #err_chkin
    jmp errexit

;***************************************
; Print A as a PETSCII character, 
; escaping nonprinting characters as 
; hex values
; Preserves registers
;***************************************
ESCOUT
    cmp #$20
    bcc ++      ; $00-$19 : hex
    cmp #$a1
    bcs +       ; $a1-$ff : print
    cmp #$7f
    bcs ++      ; $80-a0 : hex
+   jmp CHROUT
++
    pha  
    lda #$12
    jsr CHROUT
    lda #'['
    jsr CHROUT
    pla
    pha
    jsr bytetohex
    lda #']'
    jsr CHROUT  
    lda #$92
    jsr CHROUT
    pla
    rts

;***************************************
; Print A as two hex digits
; preserves registers
;*************************************** 
bytetohex
    pha
    lsr
    lsr
    lsr
    lsr
    jsr nybtohex
    pla
    and #$0f
    jsr nybtohex
    rts

;***************************************
; Print a nybble as a hex digit
; A must be between $00 and $0f
; Destroys A
;*************************************** 
nybtohex
    clc
    adc #$30
    cmp #$3a
    bcc +
    adc #6 ; + carry = 7
+   jsr CHROUT
    rts

;***************************************
; Read a line from current input device
; Echoes data to screen
; Destroys X
; Returns A=0 on success, A!=0 on EOF
;***************************************
readline
-   jsr CHRIN
    jsr ESCOUT
    tax
    jsr READST
    ora #0
    bne + ; stop on EOF
    cpx #$0d
    beq ++ ; stop on newline
    jmp - ; otherwise, keep going

+   ldx #msg_eof
    jsr printstr ; print EOF marker
++  pha
    lda #$0d
    jsr CHROUT
    pla
    rts

;***************************************
; Print an message and exit
; Call with string-table offset in X
;***************************************
errexit
    jsr printstr
    pha
    lda #':'
    jsr CHROUT
    pla
    jsr bytetohex

    lda #$0d
    jsr CHROUT

    jsr CLRCHN
    rts

;***************************************
; Print a message
; Call with string-table offset in X
;***************************************
printstr
    pha
-   lda stringtbl,x
    beq +
    jsr CHROUT
    inx
    bne -
+   pla
    rts

;***************************************
; String table
;***************************************
stringtbl
err_open = * - stringtbl
    !text "open err",0
err_chkin = * - stringtbl
    !text "chkin err",0
msg_eof = * - stringtbl
    !text $12,"[eof]",$92,0

;***************************************
; Filenames
;***************************************
filename1
    !text "file1,r"
filename1_len = * - filename1
filename2
    !text "file2,r"
filename2_len = * - filename2
