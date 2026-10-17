#!/usr/bin/env python
"""
Given an the size of the object of interest as a command line arguement
returns the density of such objects per square degree.  First value
returned is for the 'broken powerlaw' and the second value is for a 
uniform powerlaw."""

import math, sys
import optparse

# -- globals -- 

rho = 0.8                  # g cm-3
rho = rho * (1.0E5)**3.0/1.0E3  # Put rho into kg/km3
r_min = 1.0                # smallest object to consider, in km

## Sky Area of oort cloud (in square arcseconds)
mass_earth = 5.9742E24    ## Mass of Earth in Kilos

def CNDF(r,r0,q):
    """return the cumulative number of objects"""
    return -(r0/(1.0-q))*(r/r0)**(1.0-q)


def CMDF(r,r0,q):
    """return the cummulative mass"""
    if q < 4.0 :
       return (4.0/3.0)*math.pi*rho*((r0**4)/(4.0-q))*(r/r0)**(4.0-q)
    else:
       return -(4.0/3.0)*math.pi*rho*((r0**4)/(4.0-q))*(r/r0)**(4.0-q)


def main():

    parser=optparse.OptionParser()
    parser.add_option("--q_small",type="float",default=3.0,
                      help="Slope of the small-size past break")
    parser.add_option("--q_large",type="float",default=4.5,
                      help="Slope of the large-size past break")
    parser.add_option("--r_break",type="float",default=25.,
                      help="Break radius, in kilometers")
    parser.add_option("--r_max",type="float",default=2.5E3,
                      help="Radius of largest object to consider")
    parser.add_option("--mass",type="float",default=3,
                      help="Mass of disk, in Earth masses")
    parser.add_option("--width",type="float",default=45.0,
                      help="Width of the particle belt")


    (opt,args) = parser.parse_args()

    ### a cheap, approximate, area scaling
    A = math.sqrt(2.0)*2.0*math.pi*206265.0**2   * (opt.width/45.0)
    
    if len(args)!=1:
        sys.stderr.write("Program only takes one argument, the size of object\n")
        sys.stderr.write("try ./oort.py --help for more details")
        sys.exit(-1)

    r_in=float(args[0])/1000.0 # convert to km

    ### Some constants....
        
    q_small=opt.q_small
    q_large=opt.q_large
    r_break  = opt.r_break  # size, in km, where we break between q_large and q_small
    r_max    = opt.r_max # largest object to consider, in km
    mass_oort = opt.mass*mass_earth ## oort cloud is 3 times mass of earth


     
    ## compute the value of r0 based on the desired mass of the belt
    ## ie.  Normallize this sucker, ie determine the r0 that, for the
    ## anticpated total mass, results in 1 object per unit area
    r0 = 1.0
    total_mass = A*CMDF(r_min,r0,q_large)
    r0 =(mass_oort/total_mass)**(1./q_large)
    
    ### compute the density of objects per arcsecond2
    n_uniform = CNDF(r_in,r0,q_large)



    ### do the same thing, but now with a 'broken powerlaw'
    ### first compute the normalization again.
    ### we can't invert the problem this time, so look for a
    ### convergent solution.

    mass_total=0.0
    r_large=r0
    while ( math.fabs((mass_total - mass_oort)/mass_oort) > 0.01 ) :

        if mass_total > mass_oort:
            r_large = r_large * 0.99
        else:
            r_large = r_large * 1.01

            
        ### set r_small so the function is smooth at r_break
        N_large = CNDF(r_break,r_large,q_large)
        r_small = 1.0
        N_small = CNDF(r_break,r_small,q_small)
        r_small = (N_large/N_small)**(1.0/q_small)
        mass_total =A*(CMDF(r_min,r_small,q_small)-CMDF(r_break,r_small,q_small)+CMDF(r_break,r_large,q_large))
                
    n_bpl = CNDF(r_in,r_small,q_small)
    print n_bpl, n_uniform

if __name__=='__main__':
    main();
