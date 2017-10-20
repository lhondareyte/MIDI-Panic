# Makefile generique pour les gputils
#
PRG=panic
SRCS=$(PRG).asm
ASMFLAGS="-w1 -D HAVE_RUNNING_STATUS"
PROCS=12c508 16f84

all: 508 84 clean

debug: 508 84
sources: $(SRCS)

508:	sources Makefile
	@printf "Compiling for 12c$@ device ... "
	@gpasm $(ASMFLAGS) -n -a inhx8m -p p12c508 $(SRCS) -o $(PRG)$@.hex
	@echo "Ok."

84:	sources
	@printf "Compiling for 16f$@ device ... "
	@gpasm $(ASMFLAGS) -n -a inhx8m -p p16f84a $(SRCS) -o $(PRG)$@.hex
	@echo "Ok."

toast: 508 sources
	@sleep 1
	@printf "Programmation de la cible ..."
	@prog84 -T 12c5x8 -x $(HEX)
	@echo "Ok."

toast84: 84 sources
	@printf "Clearing device ..."
	@prog84 -z
	@echo "Ok."
	@sleep 1
	@printf "Programming device ..."
	@prog84 -x panic84.hex
	@echo "Ok."

clean:
	@printf "Cleaning ..."
	@rm -f *.cod *~ *.lst
	@echo "Ok."

mrproper: clean
	@rm -f *.hex *.bin
