PD:=pandoc -s -t revealjs

OBJS=building-code.html slurm-advanced.html slurm-troubleshoot.html
all: $(OBJS)

%.html: %.md
	$(PD) -o $@ $<

.PHONY: all clean

clean:
	-rm -f $(OBJS)
