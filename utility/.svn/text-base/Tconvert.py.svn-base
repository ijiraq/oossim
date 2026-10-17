#!/usr/bin/env python
#
# Steven Bickerton
# Dept. of Physics/Astronomy, McMaster University
# bick@physics.mcmaster.ca
# Made with makeScript, Wed Jan  2, 2008  11:20:39 EST
# Host: bender.astro.princeton.edu
# Working Directory: /Users/bick/sandbox/utility


import sys, math
    
def Usage():
    print """Usage: %s units(FC|CF|KF|FK|CK|KC) T""" % sys.argv[0]
    sys.exit(1)

def absZeroC():  return 273.15

def F2C(T):  return (5.0 / 9.0) * (T - 32.0)
def C2F(T):  return (9.0 / 5.0) * T + 32.0
def K2C(T):  return T - absZeroC()
def C2K(T):  return T + absZeroC()

def main():
    if len(sys.argv) != 3:
        Usage()

    units = sys.argv[1]
    T     = float(sys.argv[2])

    if units == 'FC': Tnew = F2C(T)
    elif units == 'CF': Tnew = C2F(T)
    elif units == 'FK': Tnew = C2K( F2C(T) ) 
    elif units == 'KF': Tnew = C2F( K2C(T) )
    elif units == 'KC': Tnew = K2C(T)
    elif units == 'CK': Tnew = C2K(T)
    else: 
        print "Units %s not defined." % units
        return 0

    print "%.3f" % Tnew

if __name__ == '__main__':
    main()
    
