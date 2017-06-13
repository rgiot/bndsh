all: BUILD_DSK


DSK_FNAME=bndsh.dsk
LOAD_ADDRESS=x9000


vpath %.asm src/ 


include CPC.mk


exec.o: $(wildcard src/*.asm)

BNDSH: exec.o 
	$(call SET_HEADER,$^,$@,$(AMSDOS_BINARY),$(LOAD_ADDRESS),$(LOAD_ADDRESS))

$(DSK_FNAME):
	$(call CREATE_DSK,$(DSK_FNAME))

BUILD_DSK: BNDSH $(DSK_FNAME)
	$(call PUT_FILE_INTO_DSK,$(DSK_FNAME),BNDSH)


clean:
	-rm *.o
	-rm *.exo
	-rm *.NOHEADER
	-rm *.lst
	-rm BNDSH

distclean: clean
	-rm $(DSK_FNAME)
	
launch: BUILD_DSK
	xdg-open $(DSK_FNAME)

