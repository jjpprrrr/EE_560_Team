;-----------------------------------
;EE560 ASM Lab
;Summer 2016
;Topic: Matrix Multiplication
;Auther: Heqing Huang
;Version: Lockless 
;-----------------------------------


;-----------------------------------
;This is core Two
;This is core Two
;This is core Two
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
;$4 - Store the lock -- Since we do not need lock here there is no need for this register here but for simplicity we keep it here but we are not using it. 
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
LW $3, 32($0);  loading A0 to $3
LW $4, 96($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------LOAD LINK SHARED C------
LL0_T0: LL $6, 132($0);
ADD $6, $6, $5;
SC $6, 132($0);
BEQ $0, $6, LL0_T0;
;------END OF LOAD LINK SHARED C------

;------LOAD LINK BARRIER COUNTER------
LL1_T0: LL $7, 136($0);
ADDI $7, $7, 1;
SC $7, 136($0);
BEQ $0, $7, LL1_T0;
;------LOAD LINK BARRIER COUNTER------

;------DEAL WITH BARRIER COUNTER------
ADDI $1, $0, 16; initialize $8 to 16
LW $2, 136($0); load the barrier counter
BNE $1, $2, Sleep_T0; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T0: J Sleep_T0;


	
;#################################################################
; 							THREAD 1
;#################################################################
;------LOADING OPERANDS------
LW $3, 36($0);  loading A0 to $3
LW $4, 100($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------LOAD LINK SHARED C------
LL0_T1: LL $6, 132($0);
ADD $6, $6, $5;
SC $6, 132($0);
BEQ $0, $6, LL0_T1;
;------END OF LOAD LINK SHARED C------

;------LOAD LINK BARRIER COUNTER------
LL1_T1: LL $7, 136($0);
ADDI $7, $7, 1;
SC $7, 136($0);
BEQ $0, $7, LL1_T1;
;------LOAD LINK BARRIER COUNTER------

;------DEAL WITH BARRIER COUNTER------
ADDI $1, $0, 16; initialize $8 to 16
LW $2, 136($0); load the barrier counter
BNE $1, $2, Sleep_T1; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T1: J Sleep_T1;


;#################################################################
; 							THREAD 2
;#################################################################
;------LOADING OPERANDS------
LW $3, 40($0);  loading A0 to $3
LW $4, 104($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------LOAD LINK SHARED C------
LL0_T2: LL $6, 132($0);
ADD $6, $6, $5;
SC $6, 132($0);
BEQ $0, $6, LL0_T2;
;------END OF LOAD LINK SHARED C------

;------LOAD LINK BARRIER COUNTER------
LL1_T2: LL $7, 136($0);
ADDI $7, $7, 1;
SC $7, 136($0);
BEQ $0, $7, LL1_T2;
;------LOAD LINK BARRIER COUNTER------

;------DEAL WITH BARRIER COUNTER------
ADDI $1, $0, 16; initialize $8 to 16
LW $2, 136($0); load the barrier counter
BNE $1, $2, Sleep_T2; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T2: J Sleep_T2;

;#################################################################
; 							THREAD 3
;#################################################################
;------LOADING OPERANDS------
LW $3, 44($0);  loading A0 to $3
LW $4, 108($0); loading B0 to $4
MULT $5, $3, $4; multiply A0 with B0 and put the result in $5
;------END OF LOADING OPERANDS------

;------LOAD LINK SHARED C------
LL0_T3: LL $6, 132($0);
ADD $6, $6, $5;
SC $6, 132($0);
BEQ $0, $6, LL0_T3;
;------END OF LOAD LINK SHARED C------

;------LOAD LINK BARRIER COUNTER------
LL1_T3: LL $7, 136($0);
ADDI $7, $7, 1;
SC $7, 136($0);
BEQ $0, $7, LL1_T3;
;------LOAD LINK BARRIER COUNTER------

;------DEAL WITH BARRIER COUNTER------
ADDI $1, $0, 16; initialize $8 to 16
LW $2, 136($0); load the barrier counter
BNE $1, $2, Sleep_T3; if barrier is not 16, go to sleep
CACHE 10101, 128($0);
Sleep_T3: J Sleep_T3;