all: BUILD_DSK BNDSH.ROM


DSK_FNAME=bndsh.dsk
LOAD_ADDRESS=x9000


vpath %.asm src/ 


include CPC.mk


exec.o: $(wildcard src/*.asm)
rom.o: $(wildcard src/*.asm)

BNDSH: exec.o 
	$(call SET_HEADER,$^,$@,$(AMSDOS_BINARY),$(LOAD_ADDRESS),$(LOAD_ADDRESS))


BNDSH.ROM: rom.o
	cp $^ $@


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


CPCWIFI= 192.168.1.24

test_rom:
	./bootstrap.sh make && ../cpcxfer/xfer -f $(CPCWIFI) ./BNDSH.ROM 1 BNDSH && ../cpcxfer/xfer -r $(CPCWIFI)

test_exec:
	./bootstrap.sh make && ../cpcxfer/xfer -y $(CPCWIFI) BNDSH
