
;UI FUNCTIONS

;1-ECHO AND ITS DEPENDANCIES

ECHO:                   ;-=-=-=PRINTING FUNCTION =-=-=-;
        LODSB                   ;MOV ONE CHAR FROM SI TO AL AND DELETE IT FROM SI
        CMP AL, 0               ;CHECK IF THE VALUE IN AL=0, IF ITS ZERO THEN WE
        JE DONE                 ;WE ARE DONE PRINTING, AND JUMP BACK TO THE MAIN FUNCTION
        CMP AL, 59
        JE NEWLINE
        MOV AH, 0EH             ;THE FUNCTION CODE FOR PRINTING (TELETYPE PRINTING)
        INT 10H                 ;BIOS CALL
        JMP ECHO                ;IF WE ARRIVED TO THIS LINE THATS MEAN WE ARE NOT DONE WITH
                                ;PRINTING THE WHOLE STREING SO JUMP BACK AND COMPLETE THE PROCESS

DONE:                   ;LABEL CONTAINS ONE INSTRUCTION TO JUMP BACK TO THE LINE 
        RET                     ;WHERE WE CALLED THE ECHO FUNCTION

NEWLINE:
        PUSHA
        MOV AH,0EH
        MOV AL, 13
        INT 10H
        MOV AL, 10 
        INT 10H 
        POPA
        JMP ECHO

SET_VID_MODE:                    ;INPUT -> AL=VIDEO MODE
        PUSHA
        MOV AH, 0H                       ;CHANGING THE VIDEO MODE 
        INT 10H
        POPA
        RET

CLEAR:
        PUSHA
        MOV AH, 09H
        MOV BH, 0
        MOV BL, 00000111B
        MOV AL, ''
        MOV CX, 2000
        INT 10H
        POPA
        RET

N_NEWLINE:
        PUSHA
        MOV AH,0EH
        MOV AL, 13
        INT 10H
        MOV AL, 10 
        INT 10H 
        POPA
        RET


RESET_DRIVE:				                ;RESET FLOPPY DRIVE FUNCTION
        MOV AX, 0       					;THE FUNCTION CODE TO RESET DRIVE
        MOV DL, BYTE [BOOT_DEVICE]	                        ;DRIVE ID TO RESET
        INT 13H
        RET


HELP_CMD:
        CLC
        MOV SI, HELP_MSG
        CALL ECHO
        JMP PROMPET_LABEL

ABOUT_CMD:
        CLC
        MOV SI, ABOUT_MSG
        CALL ECHO
        JMP PROMPET_LABEL

CLS_CMD:
        CLC 
        MOV AH, 00H
        MOV AL, 03H 
        INT 10H 
        JMP PROMPET_LABEL

CHECK_YN:
        CLC 
        MOV SI, CONF_MSG
        CALL ECHO
        MOV AH, 00H 
        INT 16H 
        CMP AL, 'Y'
        JE SHUT_DOWN
        CMP AL, 'y'
        JE SHUT_DOWN
        JMP SHUT_ABORT

SHUT_DOWN:
        MOV AX, 5307H
        MOV CX, 3 
        MOV BX, 1 
        INT 15H

SHUT_ABORT:
        CALL N_NEWLINE
        JMP PROMPET_LABEL

TIME_CMD:
        JMP PROMPET_LABEL       



FILES_CMD:
        PUSHA
        MOV DI, FILES_LIST              ;INIT. DI FOR INDEXING THE BYTES OF THE VARIABLE

        CALL RESET_DRIVE

        ;1- SETTING UP AND LOADING THE ROOT DIR.
        MOV AH, 02H						;THE FUNCTION CODE FOR LOADING ROOT DIR.
        MOV AL, 14						;THE SIZE OF THE ROOT DIR. THE ROOT DIR. = 14 AND WE WANT TO LOAD IT ALL SO AL=14
        MOV BX, TEMP					        ;THE TEMP STORAGE FOR THE DATA WILL BE READED OR LOADED
        MOV CH, 0 						;TRACK WE WANT TO LOAD, ITS TRACK 0 BEACUSE THE ROOT DIR. LOCATED THERE (CYLINDER)
        MOV CL, 2						;SECTOR WE WANT TO LOAD, ITS SECTOR 2 BEACUSE THE ROOT DIR. LOCATED THERE
        MOV DH, 1						;HEAD WE WANT TO LOAD, ITS HEAD 1 BEACUSE THE ROOT DIR. LOCATED THERE
        PUSHA							;TO BE ABLE TO RETRY TO LOAD ROOT DIR. IF INT 13H FAILED
        LOAD_RD:
        INT 13H
        JNC LOAD_RD_DONE			        	;IF WE ARRIVE HERE, THATS MEAN THAT THE ROOT DIR. LOADED SUCCESSFULLY
        CALL RESET_DRIVE				        ;RESET FLOPPY FUNCTION CALL
        JMP LOAD_RD						;RETRY IF INT 13H FAILED


LOAD_RD_DONE:
        POPA

        MOV SI, TEMP

COMPARE_MARKERS:
        MOV AL, [SI+11]
        CMP AL, 0FH
        JE CONT
        CMP AL, 18H
        JE CONT
        CMP AL, 229
        JE CONT 
        CMP AL, 0
        JE FILES_LOADED

        MOV DX, SI
        MOV CX, 0

PUSH_FILES:
        MOV BYTE AL, [SI]
        CMP AL, ' '
        JE SPACE
        MOV BYTE [DI], AL 
        INC DI
        INC SI 
        INC CX 

        CMP CX, 8
        JE ADD_DOT
        CMP CX, 11 
        JE STRING_SAVED
        JMP PUSH_FILES

ADD_DOT:
        MOV BYTE [DI], '.'
        INC DI 
        JMP PUSH_FILES

SPACE:
        INC SI 
        INC CX 
        CMP CX, 8 
        JE ADD_DOT
        JMP PUSH_FILES 

STRING_SAVED:
        MOV BYTE [DI], ';'
        INC DI 
        MOV SI, DX 

CONT:
        ADD SI, 32 
        JMP COMPARE_MARKERS

FILES_LOADED:
        MOV SI, FILES_LIST
        MOV AH, 0EH
        PRINT:
        LODSB
        CMP AL, 0
        JE DONE_PRINT_LIST
        CMP AL, ';'
        JE SEMI_COLON
        INT 10H
        JMP PRINT

SEMI_COLON:
        CALL NEWLINE
        JMP PRINT

DONE_PRINT_LIST:
        POPA
        JMP PROMPET_LABEL
        
RECOGNIZE_INPUT:
        PUSHA
REC_CMD:
        MOV AL, [SI]		;GET ONE BYTE OF SI (SI = THE COMMAND THAT THE USER ENTERED)
        CMP AL, 65
        JAE OK
BK:
        MOV AH, [DI]		;GET ONE BYTE OF DI (THE COMMAND WE WANNA TEST IF IT ENTERD OR NOT)
        CMP AL, AH
        JNE NOT_EQ
        CMP AL, 0 
        JE EQUAL
        INC SI				;|TO UPDATE THE CHAR WE ARE COMPARING
        INC DI				;|
        JMP REC_CMD

NOT_EQ:
        POPA
        CLC
        RET

EQUAL:
        POPA
        STC
        RET

OK:
        CMP AL, 90
        JA BK
        ADD AL, 32
        JMP BK

KB_SERVICES:
        PUSHA
        XOR AX, AX
        MOV AH, 10H
        INT 16H
        MOV [.TEMP_INPUT], AX		;TEMP VAR
        POPA
        MOV AX, [.TEMP_INPUT]
        RET
.TEMP_INPUT	DW	0


