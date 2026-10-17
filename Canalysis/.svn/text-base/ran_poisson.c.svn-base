#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <time.h>

#include "util.h"
#include "memalloc.h"

int main(int argc, char *argv[])
{
  int N;
  double mu;
  double P;

  if ( argc < 4 ) {
    fprintf(stderr, "Usage: %s mu N P\n", argv[0]);
    exit(EXIT_FAILURE);
  } else { 
    mu = atof(argv[1]);
    N = atoi(argv[2]);
    P = atof(argv[3]);
  }

  /* allocate memory for values */
  unsigned int *values = mem_malloc(N * sizeof(unsigned int) );

  /* init the generator and get the values */
  const gsl_rng_type *T;
  gsl_rng *r;
  gsl_rng_env_setup();
  T = gsl_rng_default;
  r = gsl_rng_alloc(T);
  gsl_rng_set(r, time(NULL));

  for (int i=0;i<N;i++) { values[i] = gsl_ran_poisson(r, mu); }

  gsl_rng_free(r);

  /* output */
  const double inv_N = 1.0/N;
  for (int i=0;i<N;i++) { printf("%.6g %d\n", i*P*inv_N, values[i]); }

  mem_free(values); 
  assert( show_leaks(&memlist) == 0);

  return(EXIT_SUCCESS);
}
