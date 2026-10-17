	subroutine parsec(filename,parname,cvalue)
* gets a parameter of type character (named parname) 
* out of a file (named filename)
* the parameter is return as cvalue
* cvalue should be set to the default value before calling parsec

	implicit none
	character*(*) filename,parname
	character*60 check
	integer icheck,idex,i,idex2
	character*(*) cvalue
	idex=0
	open(98,file=filename,status='old')
10	read(98,*,end=40,err=40) check
	call lowercase(check)
	icheck=index(check,' ')-1
	if (check(1:icheck).eq.parname) goto 20	
	idex=idex+1
	goto 10
	
20	rewind(98)      ! if we found the parameter
*	print*,parname
	do 30 i=1,idex
30	read(98,*)
	read(98,'(a60)') check     ! this is a bit of a kludge. live with it
	idex=index(check,' ')      ! find the first blank space
50	idex=idex+1                          ! search until we find
	if (check(idex:idex).eq.' ') goto 50 ! a real character
	check=check(idex:60)                 ! chop off everything before that
	idex=len(check)                      
	idex2=index(check,' ')-1             ! find any trailing spaces
	if (idex2.gt.0) idex=idex2
	idex2=index(check,'#')-1             ! or comment entries
	if (idex2.gt.0) idex=idex2
	if (idex.eq.60) goto 40              ! but if the rest of line is blank
	cvalue=check(1:idex)                 ! chop them off 
	goto 9000

40	continue       ! if we didn't find the parameter
	print*,'parse: parameter ',parname,' not found in ',filename
	print*,'parse: going with value ',cvalue
9000	close(98)
	return
	end
***************

	subroutine parsei(filename,parname,ivalue)
* gets a parameter of type integer (named parname) 
* out of a file (named filename)
* the parameter is return as ivalue
* ivalue should be set to the default value before calling parsei
* parsei calls parsec
	implicit none
	character*(*) filename,parname
	character*20 cvalue
	integer ivalue
	write(cvalue,*) ivalue
	call parsec(filename,parname,cvalue)
	read(cvalue,*,err=10) ivalue
	return
10	print*,'parse: parameter ',parname,' not found in ',filename
	print*,'parse: going with value ',ivalue
	return
	end
***************

	subroutine parser(filename,parname,rvalue)
* gets a parameter of type real (named parname) 
* out of a file (named filename)
* the parameter is return as rvalue
* rvalue should be set to the default value before calling parser
* parser calls parsec
	implicit none
	character*(*) filename,parname
	character*20 cvalue
	real rvalue
	write(cvalue,*) rvalue
	call parsec(filename,parname,cvalue)
	read(cvalue,*,err=10) rvalue
	return
10	print*,'parse: parameter ',parname,' not found in ',filename
	print*,'parse: going with value ',rvalue
	return
	end
***************

	logical function checkname(string)
* checks a file name, usually used to see we should be writing a file at all.
* returns a logical value of "false" if the file is named "none"
* returns a logical value "true" otherwise 
	character*(*) string 
	character*4 name4
	name4 = string(1:4)
	call lowercase(name4)
	checkname = (name4.ne.'none')
	return
	end
***********************
