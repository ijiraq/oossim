/*            */
/* Steven Bickerton */
/* Dept. of Physics/Astronomy, McMaster University */
/* bick@physics.mcmaster.ca*/
/* Made with makeScript, Sun Sep 24, 2006  15:37:41 DST */
/* Host: kuiper */
/* Working Directory: /1/home/bickersj/sandbox/Canalysis  */


#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <gsl/gsl_sf_erf.h>
/* #include <ncurses.h>  */
/* #include <unistd.h>  */
/* #include <string.h>  */

/* #define PI 3.141592654  */



void usage(char execName[]) {
    printf ("Usage: %s x\n", execName);
    exit(1);
}

int main(int argc, char *argv[])
{
  double erfx;

  if ( argc < 2 )
    usage(argv[0]);
  else {
    erfx = gsl_sf_erf_Q(atof(argv[1]));
  }
  
  erfx = 1.0 - erfx;

  printf ("# %-30s%-32s\n","2sided", "1sided");

  double Nexp2 = 1.0/(1.0-(2.0*(erfx-0.5)));
  double p2 = 2.0*(erfx-0.5);
  double Nexp1 =  1.0/(1.0-erfx);
  double p1 = erfx;

  if (Nexp2 <= 10000.0)
    printf ("%-9.4f   %17.15f   %9.4f   %17.15f\n", Nexp2, p2, Nexp1, p1);
  else 
    printf ("%-9.4g   %17.15f   %9.4g   %17.15f\n", Nexp2, p2, Nexp1, p1);


  return 0;

}
