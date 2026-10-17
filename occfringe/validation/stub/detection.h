/* Minimal stand-in for cdiffracSim/detection.h so fresnelT.c builds without FFTW/GSL. */
#ifndef DETECT_LIBRARY
#define DETECT_LIBRARY 1

typedef double FLOAT;

#define PI 3.141592654
#define TWOPI (2.0*PI)
#define PIHALF (PI/2.0)
#define AU_M  1.496e11
#define MAX_FILENAME 256*sizeof(char)

#define LAA      "aa"
#define LTEFF     "Teff"
#define LMAXX00  "maxX00"
#define LX00STEP "x00Step"
#define LRSTAR   "RStar"
#define LAU      "AU"
#define LOFFSET  "offset"
#define LANGLE   "angle"
#define LLAMBLO  "lambLo"
#define LLAMBHI  "lambHi"
#define LNSTARS  "nStars"
#define LNLAMBDA "nLambda"
#define LASPRAT  "aspectRatio"
#define LORDER   "order"

#endif
