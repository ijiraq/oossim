pro satskyaccess

;  -------------------------------------------------------------------------
;  read/restore Earth apparent RA and DEC values for a full year
;  (from July 1st 2009 till June 30th 2010) with a two-minutes resolution
;  the satellite positional data were calculated with STK Satellite Tool Kit
;  this can be done for any Low Earth Orbit under investigation
;  -------------------------------------------------------------------------

RESTORE, FILENAME = 'most.type.orbit.sav'

; retrieved information from the .sav file'
; etime0 = JD -2400000.0 of first data point
; etime  = time array in [d]
; e_ra   = earth right ascension array [deg] 0-360
; e_de   = earth declination array [deg] -90,90

ndat = n_elements(etime) ; total number of data points ie array size

horb = 820.     ; MOST orbit height [km]
porb = 101.413  ; MOST orbit period [min]
e_rad= 6371.    ; mean earth radius [km]
eangl= acos(e_rad/(e_rad+horb))*!RADEG    ; semi grazing angle [deg]

earth_lim =   5.0        ; limit angle to earth limb  [deg]
sun_lim   =  90.0        ; limit angle to sun         [deg]


; check object -> eps Ori RA = 5h 36m 38.61 , DEC = -1d 11m 49.30s

ra_field  =  84.1608     ; ra of field/star to investigate [deg]
de_field  = -1.1970      ; de of field/star to investigate [deg]

; calculate Sun RA and DEC

SUNPOS, etime+etime0+2400000.d0, ra_sun, de_sun

e_dist  = sphdist(ra_field, de_field, e_ra,   e_de,  /degree)
sundist = sphdist(ra_field, de_field, ra_sun, de_sun,/degree)

; find the times (indices of the etime array) when your limits are not
; violated for the sun and for the earth

ie_f = where(e_dist  ge (eangl*2.)+earth_lim)
is_f = where(sundist ge sun_lim)

; just a test plot

; window,1

; plot, etime[ie_f],e_dist(ie_f),psym=1,xstyle=1,xrange=[0.,365.],ystyle=1,yrange=[0,180]
; oplot,etime[is_f],sundist(is_f),psym=2,color=120


end