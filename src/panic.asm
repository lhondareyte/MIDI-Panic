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
;	$Id: panic.asm,v 1.13 2012/04/09 16:21:40 luc Exp $
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

ifdef USE_INTERNAL_OSC
	__CONFIG _CP_OFF & _WDT_OFF & _IntRC_OSC
else
	__CONFIG _CP_OFF & _WDT_OFF & _HS_OSC
endif

else
	#include <p12c508.inc> 
	#define 	RAMBASE		0x07
	#define		PORT		GPIO
	#define		KEY1		PORT,0	; pin 7
	#define		KEY2		PORT,1	; pin 6
	#define		RS_SWITCH	PORT,3
	#define		MIDIOUT		PORT,4  ; pin 3
	#define 	MIDI_IN		PORT,5  ; pin 2
	#define		MASK 		b'11101111'

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
	movwf	OSCCAL		; Calibration de l'oscillateur interne
				; La valeur de calibration se trouve dans
				; W lors d'un reset.
endif

	goto	init

;************************************************************************;
;     Generation des signaux logiques à 31250 Bauds soit 32uS par bit    ;
;************************************************************************;

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

	bcf	MIDIOUT		; transition à 10uS

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
	bsf	MIDIOUT		; transition à 10uS

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
;************************************************************************;

send_char
	movlw	8		; un octet = 8 bits
	movwf 	bits		; initialisation du compteur de bits
	call	StartBit	; START BIT

next_bit

    	nop			; **** Ajustement ******
	rrf 	buffer,f	; Rotation de buffer
	btfsc	STATUS,C	; pour tester la retenue 
	call	UnLogic		; si C=1 on envoie un "1"

	btfss	STATUS,C
	call 	ZeroLogic	; sinon, on envoie "0"


	decfsz	bits,1		; Si compteur de bit à zéro
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

	bsf	MIDIOUT		; Sortie MIDI à 1
	call	pause200mS
	
;************************************************************************;
;   Pour eviter des problèmes de glissement de temps, la duree de la     ;
;   boucle PASS-THROUGHT doit etre multiple de 32uS. Ici, elle dure 8uS, ;
;   soit 32uS/4.                                                         ;
;************************************************************************;
	
Wait_Release_Keys
	btfss	KEY1		; Si une des touches est enfoncée
	goto	Wait_Release_Keys; on attend son relachement
	
Normal_Operation

	btfsc	MIDI_IN		; PASS-THROUGHT MIDI : On recopie MIDI_IN
	bsf	MIDIOUT		; sur MIDIOUT. Les deux btfsX à suivre sont 
	btfss	MIDI_IN		; moins couteux en temps que des "goto".
	bcf	MIDIOUT

	btfss	KEY1		; Si KEY1 est enfoncée, on va au
	goto	read_keys	; traitement clavier.
				; sinon, on continue le PASS-THROUGHT
	goto	Normal_Operation

;************************************************************************;
;                     FIN de boucle PASS-THROUGHT                        ;
;************************************************************************;
;  Pour reduire la boucle PASS-THROUGHT, je teste uniquement KEY2:       ;
;  S1 met à "1" KEY1 et KEY2 (voir diode D1)                             ;
;  S2 met à "1" uniquement KEY2                                          ;
;  Donc, dans la boucle PASS-THROUGHT, on regarde si une touche est      ;
;  enfoncée. Dans la boucle read_keys, on determine quelle touche est    ;
;  enfoncée.                                                             ;
;************************************************************************;

read_keys
	btfss	KEY2		
	goto	All_sounds_off
	goto 	Panic

;************************************************************************;
;                     Envoi du Panic                                     ;
;************************************************************************;

Panic	
	bsf	MIDIOUT		; nettoyage sortie MIDI
	call	pause320uS
	movlw	d'16'
	movwf	canal		; Initialisation du compteur de canaux

next_channel_0

	movf	canal,f
	btfsc	STATUS,Z

	goto	Wait_Release_Keys
	decf	canal,f

	movlw	d'128'
	movwf	notes		; Initialisation du compteur de notes

next_note

	decf	notes,f

;  Gestion du RUNNING STATUS, Si S3 est ON, on active le RS

	btfsc	RS_SWITCH
	goto	no_running_status

	movf	notes,w		; Si le numero de note
	xorlw	d'127'		; est different de 127,
	btfss	STATUS,Z	; on n'envoie pas le bit de
	goto	running_status	; status (running status)

no_running_status

	movlw	0x80
	addwf	canal,w
	movwf	buffer		; Preparation du message NoteOff (0x80+canal)
	call	send_char	; Envoi du Note-OFF

running_status

	movf	notes,w
	movwf	buffer
	call 	send_char	; Envoi du numéro de note

	movlw 	0
	movwf	buffer
	call	send_char	; Envoi du bit de status (velocité=0)

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

	
	movf	canal,f		; Test si dernier canal
	btfsc	STATUS,Z	; Prochain canal sinon
	goto	wait		; Fin de All Sounds Off
	goto	next_channel_1
wait

	goto	Wait_Release_Keys

	end                     ; Jamais atteint
