
	subroutine lowercase(a)
* converts a string to lowercase
	implicit none
	character*(*) a
	integer i,ic
	do 10 i=1,len(a)
	ic=ichar(a(i:i))
	if ( (ic.ge.ichar('A')) .and. (ic.le.ichar('Z')) ) a(i:i)=char(ic+32)
10	continue
	return
	end
******************

	subroutine str(n,a,nl)
* given a integer, N, returns a string A of length NL
* that looks like N
* eg. str(345,a,4) will set a  to "0345"
	character*(*) a
	character hex(0:9) /'0','1','2','3','4','5','6','7','8','9'/

	do 10 i=1,nl
	ic=n/10**(i-1)
	id=mod(ic,10)
	nn=nl-i+1
	a(nn:nn)=hex(id)
10	continue

	return
	end
****************************

	function ibot(a)
* returns an integer definitely just less than a
	ibot=int(a)
	if (ibot.gt.a) ibot=ibot-1
	return
	end
*************************

	function itop(a)
* returns an integer definitely just greater than a
	itop=-int(-a)
	if (itop.lt.a) itop=itop+1
	return
	end
*************************


