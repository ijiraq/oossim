#
#

INSTALL = /usr/bin/install
BINDIR = ${HOME}/usr/bin
LIBDIR = ${HOME}/usr/libperl/Local

PL = $(patsubst %.pl, %, $(wildcard *.pl))
PM = $(wildcard *.pm)


noop:
	echo "Only install and uninstall are defined"

.PHONY: install uninstall

install: $(PL) $(PM)
	$(INSTALL) $(PM) $(LIBDIR)/

uninstall:
	cd $(BINDIR); $(RM) $(PL)
	cd $(LIBDIR); $(RM) $(PM)
	cd $(PWD)

%:%.pl
	$(INSTALL) $< $(BINDIR)/$@
