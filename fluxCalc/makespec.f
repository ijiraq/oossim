	program makespec
	implicit none
	character*3 metpos(-4:0) /'m40','m30','m20','m10','p00'/
	real wave (100),  flux(100)
	real wavec(125),reflec(125)
	real waved(100),    qe(100)

	integer teff /20000/
	integer bestTeff /20000/
	character*5 charBestTeff
	integer nTeff/68/
	integer standardTeff(68)

	integer imet /0/ 
	character*3 met  /'p00'/
	real vmag /15/

*** these variables will all be hard-coded
	real exposure /.025/
	real pitch    /1.0/
	real diameter /0.3/
	character*80 coating  /'Aluminum'/
	character*80 detector /'BkTh'/
	character*4 design /'perf'/
	character filter /'y'/
	real wave1 /0.4/, wave2/0.7/


	character*4 despos(4) /'gsfc','trwd','circ','perf'/
	real    fillfactor(4) /0.6273,0.6683,0.7146,0.7854/
	integer idesign
	logical checkname
	real allfactor

	integer nspec/100/,ncoat/125/,ndet/100/,i
	real aperture,reflecq,qeq,dw,fsum

* read the parameters	
	call parsei('makespec.par','teffective',teff)
	call parser('makespec.par','vmag'       ,vmag)
	
        call parser('makespec.par.hard','diameter'   ,diameter)
	call parsei('makespec.par.hard','metallicity',imet)
	call parser('makespec.par.hard','exposure'   ,exposure)
	call parser('makespec.par.hard','pitch'      ,pitch)
	call parsec('makespec.par.hard','coating'    ,coating)
	call parsec('makespec.par.hard','detector'   ,detector)
	call parsec('makespec.par.hard','design'     ,design)
	call parsec('makespec.par.hard','filter'     ,filter)
	call lowercase(filter)
	if (filter.eq.'y') then
		call parser('makespec.par.hard','wave1'      ,wave1)
		call parser('makespec.par.hard','wave2'      ,wave2)
	endif
	
* determine the closest valid Teff to use
	call readcolumnfile('data/teffvalues.data', standardTeff, nTeff)
        call findClosestNum(teff, standardTeff, bestTeff, nTeff)
	call str(bestTeff, charBestTeff, 5)

* set the metalicity
	imet=max(imet,-4)
	imet=min(imet,0)
	met=metpos(imet)
	
	call lowercase(filter)

* set the telescope design
	do 1 i=1,4
1	if (design.eq.despos(i)) idesign=i
	
* figure out the area of the mirror
	aperture = fillfactor(idesign) * ((diameter*100)**2)  ! mirror area

* work out the overall correction factor
	allfactor = 1.03e3                      ! convert to V=0
	allfactor = allfactor * 10**(-vmag/2.5) ! account for magnitude
	allfactor = allfactor * aperture        ! account for aperture
	allfactor = allfactor * exposure        ! account for exposure

* read the data
	call readfile('data/t'//charBestTeff//met//'.norm.form',wave ,flux  ,nspec)
	call readfile('data/g'//coating  ,wavec,reflec,ncoat)
	call readfile('data/g'//detector ,waved,qe    ,ndet)
	
* modify the spectrum to for reflectivity and quantum efficiency
* integrate over wavelength
	fsum=0.
	do 10 i=2,nspec-1
* look up the reflectivity and quantum efficiency values
	call linterpband(wavec,reflec,wave(i),reflecq,ncoat)
	call linterpband(waved,qe    ,wave(i),qeq    ,ndet)
	if (filter.eq.'y') then
		if ( (wave(i).lt.wave1).or.(wave(i).gt.wave2) ) flux(i)=0.
	endif
	reflecq=reflecq**3             !refelctivity
	flux(i)=flux(i)*reflecq*qeq    !quantum efficiency
	dw=(wave(i+1)-wave(i-1) )/2.   ! the intervals are not evenly spaced
	dw=dw*1e4                      ! (microns to Angstroms)
	fsum=fsum+flux(i)*dw
10	continue
	
* fsum is now normalized to V_AB = 1 photon corrected for QE and reflectivity
	fsum=fsum*allfactor
* fsum is now corrected for mirror size, exposure etc. etc.

	write(*,'(f15.5)') fsum
	stop
	end
********************
********************

	subroutine readfile(name,vec1,vec2,ndat)
* reads a 2 column file into two vectors
* ndat should be set to the largest expected array size
	implicit none
	integer ndat
	character*(*) name
	real vec1(ndat),vec2(ndat)
	integer i
	
	open(1,file=name)
	do 10 i=1,ndat
10	read(1,*,end=20) vec1(i),vec2(i)
20	close(1)
	ndat=i-1
	return
	end
***********************

	subroutine readcolumnfile(name,vec1,ndat)
* reads a 1 column file into a vector
* ndat should be set to the largest expected array size
	implicit none
	integer ndat
	character*(*) name
	integer vec1(ndat)
	integer i
	
	open(1,file=name)
	do 10 i=1,ndat
10	read(1,*,end=20) vec1(i)
20	close(1)
	ndat=i-1
	return
	end
**************************

	subroutine linterpband(x,y,xx,yy,n)
* linear interpolater.
* Given arrays (x) and (y) of length (n) it linearly interpolates
* at (xx) and returns (yy)
* (x) should be sorted
* if (xx) is not within the scope of (x), (yy) is set to zero
	real x(n),y(n)
	logical xnx1,xnx,xx1
	xnx1=(x(n).gt.x(1))
	xnx= (x(n).gt.xx)
	xx1= (xx  .gt.x(1))
	if (xnx.eqv.xx1) then
      JL=0      
      JU=N+1    
10    IF(JU-JL.GT.1)THEN        
        JM=(JU+JL)/2            
        IF((X(N).GT.X(1)).EQV.(XX.GT.X(JM)))THEN              
          JL=JM 
        ELSE    
          JU=JM 
        ENDIF   
      GO TO 10  
      ENDIF     
      nq=JL      
	sl=(y(nq+1)-y(nq))/(x(nq+1)-x(nq))
	yy=sl*(xx-x(nq))+y(nq)
	endif
	
	if (xx1.neqv.xnx1) yy=0.
	if (xnx.neqv.xnx1) yy=0.
	return
	end
***********************

	subroutine findClosestNum(x, list, bestNum, n)
*simple function to choose best integer from list given original number (x) 
*and the number of elements in list (n). Returns bestNum.

	integer x
	integer bestNum
	integer n
	integer i
	double precision diffSquared
	double precision bestDiffSquared/1.0/
	integer list(n)

	do i=0, n
	   diffSquared=(x-list(i))**2
	   if (bestDiffSquared.eq.(1.0)) then
	      bestNum=list(i)
	      bestDiffSquared=diffSquared
	   endif
	   if (diffSquared.eq.0) then
	      bestNum=list(i)
	      goto 10
	   endif
	   if (diffSquared.lt.bestDiffSquared) then
	      bestNum=list(i)
	      bestDiffSquared=diffSquared
	   endif

	end do
 10	return
	end
	


