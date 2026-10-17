# Use these two lines if f77 is your fortran compiler
#FC = f77
#FFLAGS = -e -O3
#----------------------------------------------------------------------

# Use these two lines if g77 is your fortran compiler
FC = g77
#FFLAGS = -03
#----------------------------------------------------------------------

%.o : %.f 
	$(FC) -c $(FFLAGS) $<

# the objects
wobjects := makespec parse util
wobjects := $(addsuffix .o,$(wobjects))
makespec : $(wobjects)
	$(FC) $(FFLAGS) -o makespec $(wobjects)

.PHONY : clean
clean :
	rm *.o

# to be added later...maybe
#INSTALL=install
#BINDIR=$(HOME)/usr/bin

#.PHONY: install uninstall
#install:
#  $(INSTALL) makespec $(BINDIR)

#uninstall:
#  $(RM) $(BINDIR)/makespec
