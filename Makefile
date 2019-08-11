SHAREDIR=/usr/local/share/exp
BINDIR=/usr/local/bin

install:
	mkdir -p $(SHAREDIR)
	cp *.sh $(SHAREDIR)
	cp *.awk $(SHAREDIR)
	cp exp $(BINDIR)

uninstall:
	rm -rf $(SHAREDIR)
	rm -f $(BINDIR)/exp


