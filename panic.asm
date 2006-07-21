; 
;   Copyright (c) 2006 Luc HONDAREYTE
;   All rights reserved.
;  
;   Redistribution and use in source and binary forms, with or without
;   modification, are permitted provided that the following conditions
;   are met:
;   1. Redistributions of source code must retain the above copyright
;      notice, this list of conditions and the following disclaimer.
;  
;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
;   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
;   FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
;   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
;   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
;   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;	$Id: panic.asm,v 1.7 2006/07/18 13:09:44 luc Exp $
;
;************************************************************************;



ifdef __16F84A
	#include <p16f84a.inc>
	#define		RAMBASE	0x0C

	#define 	KEY1		PORTB,0	; pin 6
	#define		KEY2		PORTB,1	; pin 7
	#define 	RS_SWITCH	PORTB,2	; pin 8

	#define 	MIDI_IN		PORTA,1 ; pin 18
	#define		MIDIOUT		PORTA,2	; pin 1
	#define		PORT_REG	TRISA
	#define		MASK 		b'11111011'

	__CONFIG _CP_OFF & _WDT_OFF & _HS_OSC

else
	#include <p12c508.inc> 
	#define 	RAMBASE		0x07
	#define		PORT		GPIO
	#define		KEY1		PORT,0	; pin 7
	#define		KEY2		PORT,1	; pin 6
	#define		RS_SWITCH	PORT,3
	#define		MIDIOUT		PORT,4
	#define 	MIDI_IN		PORT,5
	#define		MASK 		b'11001111'

	__CONFIG _CP_OFF & _MCLRE_OFF & _WDT_OFF & _IntRC_OSC
endif


;************************************************************************;
;                              Variables                                 ;
;************************************************************************;

cblock	RAMBASE
	notes:1 		; compteur de notes
	canal:1 		; compteur de canaux

	counter1:1		; compteurs
	counter2:1		; pour les tempos

	bits:1 			; compteur de bits transmis (8+START+STOP)
	buffer:1   		; buffer de transmission	
endc

	org	0x00

ifndef __16F84A
				; Pour les 12C50x:
	movwf OSCCAL		; Calibration de l'oscillateur interne
				; La valeur de calibration se trouve dans
				; W lors d'un reset.
endif

	goto	init


				
;************************************************************************;
;     Generation des signaux logiques � 31250 Bauds soit 32uS par bit    ;
;************************************************************************;

;OneToZero
StartBit
        nop
	nop
        nop
	nop
	nop

ZeroLogic
	nop
	nop
	nop
	nop
	nop

	bcf	MIDIOUT		; transition � 10uS

	nop
	nop
	nop
	nop
	nop			

	nop
	nop
	nop
	nop
	nop			

	nop			
	nop			
	nop			
	nop
	nop

	retlw	0		

;************************************************************************;

;ZeroToOne
StopBit
        nop
	nop
        nop
	nop
	nop

	nop

UnLogic

	nop
	nop
	nop
	nop
	bsf	MIDIOUT		; transition � 10uS

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	retlw	0		; 30uS

;************************************************************************;
;               Transmission de 1 caractere avec 1 BIT de                ;
;                        START et un bit de STOP                         ;
;                                                                        ;
;    TODO: faire une macro transmit                                      ;
;************************************************************************;

send_char
	movlw	8		; un octet = 8 bits
	movwf 	bits		; initialisation du compteur de bits
	call	StartBit	; START BIT

;************************************************************************;
;    Routine a r�ecrire en plus propre mais critique au niveau timing
;                (li� aux routines zero_logic et un_logic)
;************************************************************************;
next_bit
        nop			; **** Ajustement ******
	rrf 	buffer,f	; Rotation de buffer
	btfsc	STATUS,C	; pour tester la retenue 
	goto	__UnLogic	; si C=1 on envoie un "1"

	call 	ZeroLogic	; sinon, on envoie "0"
	goto	__ZeroLogic

__UnLogic
	call	UnLogic

__ZeroLogic	 

;************************************************************************;

	decfsz	bits,1		; Si le compteur de bit
	goto	next_bit	; on traite le suivant

	call 	StopBit		; envoi du STOP BIT
	retlw	0			

;************************************************************************;
;          	  Pause de 320uS avant l'envoi d'un message              ;
;************************************************************************;

pause320uS

	nop
	nop
	nop
	nop
	nop
	movlw	d'31'
	movwf	counter1

loop_p	
	decf 	counter1,1
	btfsc	STATUS,Z
	retlw	0
	nop
	nop
	nop
	nop
	nop
	goto	loop_p

;************************************************************************;
;          	            Pause de 200mS                               ;
;************************************************************************;

pause200mS

	movlw	d'200'	
	movwf	counter2	
__loop_200
	decf	counter2,1
	btfsc	STATUS,Z
	retlw	0
	movlw	d'100'
	movwf	counter1
__loop_201
	nop
	nop
	decfsz	counter1,1
	goto __loop_201
	goto __loop_200	
		
;************************************************************************;
;                  Initialisation des ports                              ;
;************************************************************************;

init
				
	movlw	MASK	
			
ifdef __16F84A
	bsf	STATUS,5	; acces BANK1
	movwf	PORT_REG

	movlw	b'11111111'	; Les poussoirs sont sur le port B
	movwf	TRISB		;

	bcf	OPTION_REG,NOT_RBPU	; Activation des resistances de tirage
				; pour le port B.

	bcf	STATUS,5	; acces BANK0
else
	tris	PORT
	movlw	b'10000000'	; Activation des resistances de tirage
	option			; sur GP0, GP1 et GP3.
endif


;************************************************************************;
;                  Debut des hostilites...                               ;
;************************************************************************;

	bsf	MIDIOUT		; Sortie MIDI � 1

;************************************************************************;
;   Pour eviter des probl�mes de glissement de temps, la duree de la     ;
;   boucle PASS-THROUGHT doit etre multiple de 32uS. Ici, elle dure 8uS, ;
;   soit 32uS/4.                                                         ;
;************************************************************************;

wait_for_keys

	btfsc	MIDI_IN		; PASS-THROUGHT MIDI : On recopie MIDI_IN
	bsf	MIDIOUT		; sur MIDIOUT. Les deux btfsX � suivre sont 
	btfss	MIDI_IN		; moins couteux en temps que des "goto".

	bcf	MIDIOUT

	btfss	KEY1		; Si KEY1 est enfonc�e, on va au
	goto	read_keys	; traitement clavier.

	goto	wait_for_keys

;************************************************************************;
;                     FIN de boucle PASS-THROUGHT                        ;
;************************************************************************;
;  Pour reduire la boucle PASS-THROUGHT, je teste uniquement KEY2:
;  S1 met � "1" KEY1 et KEY2 (voir diode D1)
;  S2 met � "1" uniquement KEY2
;  Donc, dans la boucle PASS-THROUGHT, on regarde si une touche est 
;  enfonc�e. Dans la boucle read_keys, on determine quelle touche est
;  enfonc�e.
;************************************************************************;

read_keys
	btfss	KEY2		
	goto	All_sounds_off
;	goto 	panic		; panic est � suivre
	goto	All_notes_off

panic	
	bsf	MIDIOUT		; nettoyage sortie MIDI
	call	pause320uS
	movlw	d'16'
	movwf	canal		; Initialisation du compteur de canaux

next_channel_0

	movf	canal,f
	btfsc	STATUS,Z
;	goto	All_notes_off
	goto	wait_for_keys
	decf	canal,f

	movlw	d'128'
	movwf	notes		; Initialisation du compteur de notes

next_note

	decf	notes,f

;************************************************************************;
;  Gestion du RUNNING STATUS, Si S3 est ON, on active le RS
;************************************************************************;

	btfsc	RS_SWITCH
	goto	no_running_status

	movf	notes,w		; Si le numero de note
	xorlw	d'127'		; est different de 127,
	btfss	STATUS,Z	; on n'envoie pas le bit de 
	goto	running_status	; status (running status)

no_running_status

	movlw	80
	addwf	canal,w
	movwf	buffer		; Preparation du message NoteOff (0x80+canal)
	call	send_char	; Envoi du Note-OFF

running_status

	movf	notes,w
	movwf	buffer
	call 	send_char	; Envoi du num�ro de note

	movlw 	0
	movwf	buffer		 
	call	send_char	; Envoi du bit de status (velocit�=0)

	movf	notes,f	
	btfsc	STATUS,Z
	goto	next_channel_0
	goto	next_note
	
;************************************************************************;
;          Envoi du message "All sound Off" (0xBX + 0x79 + 0x00)         ;
;          X= valeur du canal MIDI                                       ;
;************************************************************************;

All_sounds_off

	bsf	MIDIOUT		; nettoyage sortie MIDI
	call	pause320uS
	movlw	d'16'
	movwf	canal		; Initialisation du compteur de canaux

next_channel_1
	decf	canal,f

	movlw	0xB0
	addwf	canal,w
	movwf	buffer		; Preparation du message AllNoteOff 
	call	send_char	; (0xB0+canal)

	movlw	0x79		; Message correct pour 
	movwf	buffer		; "All sound Off"
	call	send_char

	movlw	0
	movwf	buffer
	call	send_char

	movf	canal,f
	btfsc	STATUS,Z
	goto	wait
	goto	next_channel_1
wait
	call	pause200mS
	call 	pause200mS

	goto	wait_for_keys

;************************************************************************;
;          Envoi du message "All Notes OFF" (0xBX + 0x7B + 0x00)         ;
;          X= valeur du canal MIDI                                       ;
;************************************************************************;	

All_notes_off


	movlw	d'16'
	movwf	canal		; Initialisation du compteur de canaux

next_channel_2

	decf	canal,f

	movlw	0xB0
	addwf	canal,w
	movwf	buffer		; Preparation du message AllNoteOff 
	call	send_char	; (0xB0+canal)

	movlw	0x7B		; Message correct pour 
	movwf	buffer		; "All notes Off"
	call	send_char

	movlw	0
	movwf	buffer
	call	send_char

	movf	canal,f
	btfsc	STATUS,Z
;	goto	wait_for_keys
	goto	panic
	goto	next_channel_2

	end
;
