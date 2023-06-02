@ only one single instruction guaranteed to work in the pipeline
@ the following sequence has conflict, to be handled next
ADDI R5 R0 #123
ADDI R6 R0 #789
NOP
NOP
ADD R0 R5 R6
NOP
NOP
NOP
ADD R0 R0 R0
NOP
NOP
HALT

@ detect conflict, the result will be 'h246 instead of 'h1158. 
@ because when work on 'ADD R0 R5 R6', in the phase of op_gen, the R6 value was not yet written, the read value will be 0 instead of 'h789.
@ data hazard
