                                                ;************************************************************************************;
                                                ;                                                                                  *\;
                                                ;      Copyright (c) 2012-2016                            Mohamed El Sayed          *\;
                                                ;      www.platxend.tk                    lowlevelcode.blogspot.com          *\;
                                                ;             This is a intended to support the freeware community                 *\;
                                                ;                                                                                  *\;
                                                ;                -- All rights reserved -- Use at your own risk --                 *\;
                                                ;                                                                                  *\;
                                                ;***********************************************************************************\;
                                                ;       File             : KERNEL.asm                                              *\;
                                                ;       Built with       : NASM ver. 2.12.01                                       *\;
                                                ;       Building command : nasm -f bin KERNEL.asm -o kernel.bin                    *\;
                                                ;************************************************************************************;




;SETTING UP THE STACK AND SEGMENTS
CLI                             ;CLEAR INTERRUPTS TO SET THE SEGMENT
MOV AX, 0X0000                  ;SET THE BOTTOM OF THE STACK
MOV SS, AX
MOV SP, 0XFFFF                  ;SET THE TOP OF THE STACK
STI                             ;RESTORE THE INTERRUPTS

;SETTING UP THE SEGMENTS
MOV AX, 2000H
MOV DS, AX
MOV FS, AX
MOV ES, AX
MOV GS, AX

MOV [BOOT_DEVICE], DL

;NOW THE CPU WILLL LOAD THIS FILE AS A KERNEL, WE CAN START TO CODE ITS FUNCTIONS

MOV AL, 03H
CALL SET_VID_MODE               ;SETS THE VIDEO MODE TO DEFAULT
CALL CLEAR                      ;CLEARE THE SCREEN
MOV SI, RIGHTS_MSG
CALL ECHO                       ;PRINT THE MAIN MESSAGE

PROMPET_LABEL:
        MOV SI, TERMINAL
        CALL ECHO

        ;READING INPUT
        MOV DI, INPUT		        ;|	CLEARING THE INPUT BUFFER
        MOV AL, 0	       		;|
        MOV CX, 256			;|	SET ALL ITS BYTES TO ZERO
        REP STOSB                       ;|      THIS COMMAND SOTRES A BYTE FROM AL INTO DI CX TIMES

        MOV AX, INPUT		
        MOV DI, INPUT		

READ_LOOP:
        CALL KB_SERVICES
        CMP AL, 13
        JE DONE_R

        CMP AL, 8
        JE BACKSPACE

        JMP NOR

BACKSPACE:
        CMP DI, INPUT
        JE READ_LOOP
        MOV AH, 0EH
        MOV AL, 8
        INT 10H
        MOV AL, 32
        INT 10H
        MOV AL, 8
        INT 10H
        DEC DI
        JMP READ_LOOP

NOR:
        MOV AH, 0EH		;|PRINT THE CHAR ON THE SCREEN, AL DONT NEED TO BE MODIFIED
        INT 10H			;|SINCE IT ALREADY HAVE THE VALUE OF THE CHAR
        STOSB			;STORE THE CHAR IN AL TO DI (THE INPUT BUFFER)
        JMP READ_LOOP

DONE_R:
        MOV AX, 0
        STOSB
        CALL N_NEWLINE

;COMPARE THE STRING WE GOT WITH ZERO,
;IF IT ALREADY ZERO THAT MEANS THE USER HITS ENTER WITHOUT TYPING ANY THING SO
;JUST PRINT A NEW LINE AND GO BACK TO THE PROMPET
        MOV SI, INPUT
        CMP BYTE [SI],0
        JE PROMPET_LABEL
;ALL BUILT IN COMMANDS STARTS HERE
        MOV DI, HELP_STR
        CALL RECOGNIZE_INPUT
        JC HELP_CMD

        MOV DI, ABOUT_STR
        CALL RECOGNIZE_INPUT
        JC ABOUT_CMD

        MOV DI, CLS_STR
        CALL RECOGNIZE_INPUT
        JC CLS_CMD

        MOV DI, SHUT_STR
        CALL RECOGNIZE_INPUT
        JC CHECK_YN

        MOV DI, TIME_STR
        CALL RECOGNIZE_INPUT
        JC TIME_CMD

        MOV DI, FILES_STR
        CALL RECOGNIZE_INPUT
        JC FILES_CMD
;AND ENDS HERE

;IF THE COMMAND IS NOT A DEFINED COMMAND, THIS CODE WILL BE EXECUTED
        CALL ECHO
        MOV SI, ERROR_CMD_MSD
        CALL ECHO
        JMP PROMPET_LABEL


;### VARIABLES SECTION ###
TEMP                           EQU              24576
BOOT_DEVICE                     DB              0 
FILES_LIST                     TIMES            1024    DB      0
FILES_STR                       DB              "files",0
TIME_STR                        DB              "time",0
CONF_MSG                        DB              "Are you sure ? (Y/N)",0
SHUT_STR                        DB              "shutdown",0         
CLS_STR                         DB              "cls",0
ABOUT_STR                       DB              "about",0
ABOUT_MSG                       DB              ";Litesoft OS Kernel Copyright (C) 2012-2016;This OS inteded to supported the freeware community;You may use its code for your own OPEN SOURCE Operating system;Coded By : Mohamed El Sayed;engmohamedelsayed007@gmail.com;lowlevelcode.blogspot.com;;",0
ERROR_CMD_MSD		        DB		" Is not a defined command;",0
HELP_MSG			DB		"List of the supported commands :;   1-help ;   2-time ;   3-cls ;   4-about ;   5-shutdown ;",0
HELP_STR			DB		"help",0
INPUT         TIMES 256         DB                        0
RIGHTS_MSG                      DB              "Litesoft OS Kernel Copyright (C) 2012-2016 By Mohamed El Sayed;",0
TERMINAL                        DB              "L-OS:\> ",0

%INCLUDE "inc/util.asm"
