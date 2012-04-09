# Makefile generique pour les gputils
#
# $Id: Makefile,v 1.2 2006/07/18 13:08:26 luc Exp $
PRG=panic
SRCS=$(PRG).asm
ASMFLAGS="-w1 -D HAVE_RUNNING_STATUS"
PROCS=12c508 16f84

all: 508 84 clean

sources: $(SRCS)

508:	sources Makefile
	@echo "Compilation du source $@"
	@gpasm $(ASMFLAGS) -n -a inhx8m -p p12c508 $(SRCS) -o $(PRG)$@.hex

84:	sources
	@echo "Compilation du source pour $@"
	@gpasm $(ASMFLAGS) -n -a inhx8m -p p16f84a $(SRCS) -o $(PRG)$@.hex

toast: 508 sources
	@sleep 1
	@echo "Programmation de la cible..."
	@prog84 -T 12c5x8 -x $(HEX)

toast84: 84 sources
	@echo "Effacement de la cible..."
	@prog84 -z
	@sleep 1
	@echo "Programmation de la cible..."
	@prog84 -x panic84.hex

clean:
	@rm -f *.cod *~ *.lst
mrproper: clean
	@rm -f *.hex
