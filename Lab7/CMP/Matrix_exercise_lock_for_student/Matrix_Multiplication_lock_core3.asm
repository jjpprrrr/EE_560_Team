;-----------------------------------
;EE560 ASM Lab
;Summer 2016
;Topic: Matrix Multiplication
;Auther: Heqing Huang
;-----------------------------------


;-----------------------------------
;This is core Three
;This is core Three
;This is core Three
;-----------------------------------


;-----------------------------------
;Memory Allocation
;-----------------------------------
;In the Main memory, we have totally 1024 locations, each location holds a word.
;So it is 1024 X 32 bits = 1024 X 4 Bytes = 1024 X 1 Words.
;Basically the address we are talking about is the WORD Address, so it should be divided by 4.
;Remember the location and the address are different and they all starting from 0:
;Locatin 0 <=> Address  is 0 (First location)
;Location 1 <=> Address  is 4 (not 1 or 2)
;Location 512 <=> Address is 512*4 = 2048
;Location 1023 <=> Address is 4092 (Last location)

;In the ASM code, when we are talking about the memory, we are talking about the address.
;For example: LW $1, 200($0); Load the data in word address 200 from memory. In our design we usually access a word rather then a byte so he address here is word address. 

;Two parts are fixed - The Matrix A and B, please follow the exact location(address) in your code.
;Others(Lock L, Sum Result S, Barrier B) address is also defined here. Please follow the address so that it is easier for you and for us to debug and test the result. 
;------------------------------------
;Matrix A:
;Location: 0 ~ 15 (Totally 16 locations)
;Address: 0 ~ 60

;Matrix B:
;Location: 16 ~ 31(Totally 16 locations)
;Address: 64 ~ 124

;LOCK:
;Location: 32
;Address: 128

;SUM Result:
;Location 33
;Adderss: 132

;Barrier:
;Location: 34
;Address: 136


;-------------------------------------


;-----------------------------------
;Register Allocation
;-----------------------------------
;The register holds some intermediate value for calculation or process.
;Here we have pre-define the usage of some registers. You can follow them or use you own choose.
;When you write your code, if you need more registers except the defined registers here you can use the rest register as you wish 
;$0 always store 0, so do not use $0 as destination register.
;Each thread has its own register files so they are not sharing register
;-----------------------------------
;$0 - Store 0;
;$1 - Store data of the element of Matrix A from memory 
;$2 - Store data of the element of Matrix B from memory 
;$3 - Store the result of A X B
;$4 - Store the lock
;$5 - Store data of SUM from memory
;$6 - Store the barrier
;$7 - Store 16 to check barrier
;-----------------------------------


;------------------------------------
;Starting of the code
;Please keep the formant of each thread here
;------------------------------------



;#################################################################
; 							THREAD 0
;#################################################################
;------LOADING OPERANDS------
LW $3, 48($0);  loading A0 to $3
LW $4, 112($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------GETING THE LOCK------
LOCK3_T0: LL $2, 128($0); load the lock (128 loc) to $2
BNE $0, $2, LOCK3_T0; check to see if it is locked already ? go back : keep going
ADDI $2, $2, 1; set the lock 
SC $2, 128($0); store the lock back to memory
BEQ $0, $2, LOCK3_T0; if failed, go back to the beginning
;------END OF GETING THE LOCK------

;------ADDING RESULT TO C------
LW $6, 132($0); load C to $6
ADD $6, $6, $5; add the mult result to C
SW $6, 132($0); store the C back to memory
;------END OF ADDING RESULT TO C------

;------INCREMENT BARRIER COUNTER------
LW $7, 136($0); load the barrier counter
ADDI $7, $7, 1; increment the barrier counter by 1
SW $7, 136($0); store back the barrier counter
;------END OF INCREMENT BARRIER COUNTER------

;------RELEASE THE LOCK------
SW $0, 128($0); release the lock 
;------END OF RELEASE THE LOCK------

;------DEAL WITH BARRIER COUNTER------
ADDI $8, $0, 16; initialize $8 to 16
LW $7, 136($0); load the barrier counter
BNE $7, $8, Sleep_T0; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T0: J Sleep_T0; Keeping the thread sleeping after it finishes its work


	
;#################################################################
; 							THREAD 1
;#################################################################
;------LOADING OPERANDS------
LW $3, 52($0);  loading A0 to $3
LW $4, 116($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------GETING THE LOCK------
LOCK3_T1: LL $2, 128($0); load the lock (128 loc) to $2
BNE $0, $2, LOCK3_T1; check to see if it is locked already ? go back : keep going
ADDI $2, $2, 1; set the lock 
SC $2, 128($0); store the lock back to memory
BEQ $0, $2, LOCK3_T1; if failed, go back to the beginning
;------END OF GETING THE LOCK------

;------ADDING RESULT TO C------
LW $6, 132($0); load C to $6
ADD $6, $6, $5; add the mult result to C
SW $6, 132($0); store the C back to memory
;------END OF ADDING RESULT TO C------

;------INCREMENT BARRIER COUNTER------
LW $7, 136($0); load the barrier counter
ADDI $7, $7, 1; increment the barrier counter by 1
SW $7, 136($0); store back the barrier counter
;------END OF INCREMENT BARRIER COUNTER------

;------RELEASE THE LOCK------
SW $0, 128($0); release the lock 
;------END OF RELEASE THE LOCK------

;------DEAL WITH BARRIER COUNTER------
ADDI $8, $0, 16; initialize $8 to 16
LW $7, 136($0); load the barrier counter
BNE $7, $8, Sleep_T1; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T1: J Sleep_T1; Keeping the thread sleeping after it finishes its work


;#################################################################
; 							THREAD 2
;#################################################################
;------LOADING OPERANDS------
LW $3, 56($0);  loading A0 to $3
LW $4, 120($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------GETING THE LOCK------
LOCK3_T2: LL $2, 128($0); load the lock (128 loc) to $2
BNE $0, $2, LOCK3_T2; check to see if it is locked already ? go back : keep going
ADDI $2, $2, 1; set the lock 
SC $2, 128($0); store the lock back to memory
BEQ $0, $2, LOCK3_T2; if failed, go back to the beginning
;------END OF GETING THE LOCK------

;------ADDING RESULT TO C------
LW $6, 132($0); load C to $6
ADD $6, $6, $5; add the mult result to C
SW $6, 132($0); store the C back to memory
;------END OF ADDING RESULT TO C------

;------INCREMENT BARRIER COUNTER------
LW $7, 136($0); load the barrier counter
ADDI $7, $7, 1; increment the barrier counter by 1
SW $7, 136($0); store back the barrier counter
;------END OF INCREMENT BARRIER COUNTER------

;------RELEASE THE LOCK------
SW $0, 128($0); release the lock 
;------END OF RELEASE THE LOCK------

;------DEAL WITH BARRIER COUNTER------
ADDI $8, $0, 16; initialize $8 to 16
LW $7, 136($0); load the barrier counter
BNE $7, $8, Sleep_T2; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T2: J Sleep_T2; Keeping the thread sleeping after it finishes its work

;#################################################################
; 							THREAD 3
;#################################################################
;------LOADING OPERANDS------
LW $3, 60($0);  loading A0 to $3
LW $4, 124($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------GETING THE LOCK------
LOCK3_T3: LL $2, 128($0); load the lock (128 loc) to $2
BNE $0, $2, LOCK3_T3; check to see if it is locked already ? go back : keep going
ADDI $2, $2, 1; set the lock 
SC $2, 128($0); store the lock back to memory
BEQ $0, $2, LOCK3_T3; if failed, go back to the beginning
;------END OF GETING THE LOCK------

;------ADDING RESULT TO C------
LW $6, 132($0); load C to $6
ADD $6, $6, $5; add the mult result to C
SW $6, 132($0); store the C back to memory
;------END OF ADDING RESULT TO C------

;------INCREMENT BARRIER COUNTER------
LW $7, 136($0); load the barrier counter
ADDI $7, $7, 1; increment the barrier counter by 1
SW $7, 136($0); store back the barrier counter
;------END OF INCREMENT BARRIER COUNTER------

;------RELEASE THE LOCK------
SW $0, 128($0); release the lock 
;------END OF RELEASE THE LOCK------

;------DEAL WITH BARRIER COUNTER------
ADDI $8, $0, 16; initialize $8 to 16
LW $7, 136($0); load the barrier counter
BNE $7, $8, Sleep_T3; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T3: J Sleep_T3; Keeping the thread sleeping after it finishes its work


