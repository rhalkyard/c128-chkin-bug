DRIVE := 1571

C1541 = c1541
PETCAT = petcat
VICE128 = x128
VICE64 = x64sc
VICEFLAGS = -drive8type $(DRIVE)

.PHONY: all clean run64 run128

all: readtest64.d64 readtest128.d64

clean:
	rm -f *.prg *.txt *.d64 *.lbl *.lst

run64: readtest64.d64
	$(VICE64) $(VICEFLAGS) $<

run128: readtest128.d64
	$(VICE128) $(VICEFLAGS) $<

run: run128

readtest64.d64: readtest64.prg file1.seq file2.seq
readtest128.d64: readtest128.prg file1.seq file2.seq

readtest64.prg: readtest.asm 
readtest64.prg: TARGET=64
readtest128.prg: readtest.asm
readtest128.prg: TARGET=128

file1.txt: nlines=5
file2.txt: nlines=5

%.d64:
	$(C1541) -format "$(@:.d64=),xx" d64 $@ $(foreach f,$^,-write $f $(call dosname,$f))

%.prg:
	acme -o $@ -DTARGET=$(TARGET) -f cbm --vicelabels $(@:.prg=.lbl) --report $(@:.prg=.lst) $^

%.seq: %.txt
	$(PETCAT) -text -w2 -o $@ $<

%.txt:
	for linenum in $$(seq 1 $(nlines)); do echo "$(@:.txt=) line $$linenum" >> $@; done

# write .prg files as PRG, .seq files as SEQ
COMMA := ,
dosname=$(patsubst %.seq,%$(COMMA)s,$(1:.prg=))
