#!/usr/bin/env perl
#
# original filename: viewEvent.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Feb 21, 2006  12:05:10 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/working/plaskett_detect
#

use strict;
use warnings;
use File::Basename;
use IO::Handle;
#use Term::ANSIcolor;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Elong2v;
use Local::Statistics;

my $exe = basename($0);
my $usage = "Usage: $exe rawfile [eventfile|addhead|hidehead] [tcol]\n";

my ($rawfile, $efile, $tcol) = @ARGV;
die $usage unless $rawfile;

my $elong = 180;
$elong *= $PI/180.0;

### initializations
##############################################################
my $tmpdir = "$ENV{HOME}/tmp";
my $fresDir = ($ENV{FRESDIR}) ? "$ENV{FRESDIR}" : "fresnelFiles";
my $tmpfile = "$tmpdir/viewEvent.tmp.dat";
my $recFile = "${efile}.rec";
my $recordfile = (defined($efile)) ? "${efile}.rec" : "event.rec";
my $number = '[+-]?\d+\.?\d*';

# ask if we should clobber any existing record file.
if (-s $recordfile) {
    printf STDOUT "\nRecord file $recordfile exists.  Clobber? [N/y]: ";
    my $clobb = <STDIN>;
    unlink $recordfile if $clobb =~ /^[yY]/;
}

# print a header in the record file
open (REC, ">>$recFile");
printf REC "# %s\n", `date`;
close (REC);


# zz file format columns
my %col = ("fits"=>0, "jd"=>1, "sec"=>2, "f1"=>3, "f2"=>4, "sm1"=>7, "sm2"=>8,
	   "nm1"=>9, "nm2"=>10, "x1"=>13, "y1"=>14, "x2"=>15, "y2"=>16, );

my @dummyEventRecord = (100,0,40,0, 0,0,0,0, ,0,0,0,0, 0);

# global variables
my @events;
my $dt = 1.5;
my $i = 0;        # event number
my $t = 0;
my $N = 0;
my $k = 1;        # fit number for a given event
my $j = 1;        # 
my $h = 0;



### read in the timeseries
####################################################################
my @ts;
my %events;
my @dummy_head = @dummyEventRecord;
push @{$events{0}}, [@dummyEventRecord] if ( ! defined($efile) );
open (TS, "$rawfile");
while (<TS>) { 

    my @line = split; 

    # if the events are listed in the header, get them now

    if ( /^\#/  and  defined($efile) and $efile=~/^addhead/) {

	$tcol = 4 unless $tcol;
	my ($index, $t_tmp) = @line[1,$tcol-1];

	# collect header info for events read from header
	$dummy_head[0] = $t_tmp if $index =~ /RStar/;
	$dummy_head[1] = $t_tmp if $index =~ /aa/;
	$dummy_head[2] = $t_tmp if $index =~ /AU/;
	$dummy_head[3] = $t_tmp if $index =~ /offset/;
	
	push @{$events{$t_tmp}}, []
	    if ($index =~ /\d\d+/ && defined($t_tmp) && $t_tmp =~ /$number/);
    }

    if ( /^\#/  and  defined($efile) and $efile=~/^hidehead/ and @line==7) {

	my ($hash, $No, $index, $t_tmp, $rad, $AU, $offset) = @line;

	push @{$events{$t_tmp}}, [100, $rad, $AU, $offset, 
				  0,0,0,0,
				  0,0,0,0, $t_tmp]
	    if ($index =~ /\d\d+/ && defined($t_tmp) && $t_tmp =~ /$number/);
    }

    next if /^\#/; 

    # if there's only time and Intensity, we'll have to fake the rest
    if (scalar @line == 2) {
	my @tmp = (1)x16;
	( $tmp[$col{sec}], $tmp[$col{nm1}] ) = @line;
	( $tmp[$col{f1}], $tmp[$col{f2}] ) = (1000,1100);
	( $tmp[$col{sm1}], $tmp[$col{sm2}] ) = (1200,1300);
	push @ts, \@tmp ;
    } else {
	push @ts, \@line;
    }
}
close (TS);
my $t_step = $ts[-1]->[$col{sec}]/(scalar @ts - 1);
#printf STDERR "t_step: $t_step\n";

my @I = map {$_->[$col{nm1}]} @ts;
my $rms = rms(\@I);
my $offset = 12*$rms;  # distance to offset the series for the two stars 


# the only way %events will have key/value pairs here is if they were taken
#   from the header while reading in the timeseries. Just need to add 
#   the event time to the dummy data.
# Can't remember why i didn't do this while reading in ... ???
if ($efile =~ /^addhead/) {
    foreach my $time_key (keys %events) {
	$dummy_head[-1] = $time_key;
	${ $events{$time_key} }[0] = [ @dummy_head ];
    }
}

### read in the events
###################################################################
if ( defined($efile)  and  -s $efile ) {
    open (EVENTS, "$efile");

    while (<EVENTS>) { 
	next if /^\#/; 
	
	my $t_limit = 1.0;
	if ($tcol) {
	    my ($t) = map {sprintf "%.3f",$_} (split)[$tcol-1];
	    push @{$events{$t}}, [@dummyEventRecord];
	} else {
	    my @record = split;
	    my ($RStar, $aa, $AU, $offset, 
		$icor, $mgcor, $cor0, $corN, 
		$ichi, $mgchi, $chi0, $chiN) = @record;
	    
	    $mgcor = 1e-9 if $mgcor==0.0;
	    $cor0 = 1e-9 if $cor0==0.0;
	    $mgchi = 1e-9 if $mgchi==0.0;
	    $chi0 = 1e-9 if $chi0==0.0;
	    my $cor_ratio = ($mgcor>$cor0) ? $cor0/$mgcor : $mgcor/$cor0;
	    my $chi_ratio = ($mgchi>$chi0) ? $chi0/$mgchi : $mgchi/$chi0;
	    my $rank = $mgcor*$cor_ratio + abs($mgchi*$chi_ratio);
	    my $time = sprintf "%.3f", $icor*$t_step;
	    push @record, ($time, $rank);
	    
	    # if it's close to one that we already have, put it with that one
	    my $t_key = $time;
	    foreach my $existingT (keys %events) {
		$t_key = $existingT if ( abs($time-$existingT) < $t_limit );
	    }

	    push @{$events{$t_key}}, [@record];	
	    
	}
    }
    close (EVENTS);

    die "No events in $efile ... exiting\n" unless (keys %events);
}



# sort the events by time
@events = sort {$a<=>$b} keys %events;

# sort each event by rank
foreach my $key ( keys %events ) {
#    @{ $events{$key} } = sort {$b->[5] <=> $a->[5]} @{ $events{$key} };
    @{ $events{$key} } = sort {$b->[-1] <=> $a->[-1]} @{ $events{$key} };
}

# variables from input files
my $tmax = $ts[-1]->[$col{sec}];
$N = scalar @events - 1;
$t = $events[$i];
my $Nk = scalar @{$events{$t}};



### Data culling and dump to tmp file
################################################################
sub dumpData ($$$) {

    my ($tsref, $t, $dt) = @_;

    my ($Imin, $Imax, $f1min, $f1max, $f2min, $f2max) = 
	(100,  0,     1e6,    0,      1e6,    0     );
    open (TMP, ">$tmpfile");
    foreach my $pt (@$tsref) {
	my ($t2, $nm1, $nm2, $f1, $f2, $sm1, $sm2) = 
	    @{$pt}[ $col{sec}, $col{nm1}, $col{nm2},
		    $col{f1}, $col{f2}, $col{sm1}, $col{sm2} ];

	if (  $t2 > $t-$dt   &&    $t2 < $t+$dt   ) {
	    printf TMP "%.5f %.5f %.5f %.5f %.5f %.5f %.5f".
		"\n", $t2, $nm1, $nm2-$offset, $f1, $f2, $sm1, $sm2;
	    
	    # get the max and min of the Intensity values
	    my ($mintmp, $maxtmp) = sort {$a<=>$b} ($nm1, $nm2);
	    $Imax = $maxtmp if ($maxtmp>$Imax);
	    $Imin = $mintmp if ($mintmp<$Imin);
	    $f1max = $f1 if ($f1>$f1max);
	    $f1min = $f1 if ($f1<$f1min);
	    $f2max = $f2 if ($f2>$f2max);
	    $f2min = $f2 if ($f2<$f2min);
	}
    }
    close (TMP);

    return ($Imin, $Imax, $f1min, $f1max, $f2min, $f2max);
}



###  The Gnuplot script
################################################################
sub gpScript ($$$$$$$$) {

    my ($file, $t, $dt, $extrema, $events, $kShow, $jStart, $hardcopy) = @_;
    my ($Imin, $Imax, $f1min, $f1max, $f2min, $f2max) = @$extrema;

    my $date = `date`;
    chomp $date;

    my $event0ref = ${ $events{$t} }[$kShow-1];
    my ($radShow, $AUshow, $offsetShow, $mgcorShow, $cor0Show, $mgchiShow, $chi0Show, $tShow) = 
	defined $event0ref ? 
	@{ $event0ref }[1,2,3,5,6,9,10,12] : (@dummyEventRecord[1,2,3,5,6,9,10],$t);

    my $vRet = elong2v($elong, $AUshow);
    my $fresfile = sprintf "${fresDir}/fres-%05d_%05d", $radShow, $AUshow;

    my $offset_rounded = 0.1*( int($offset/0.1 + 0.5) );
    my ($y1nMin, $y1nMax, $y2nMin, $y2nMax) = (1.0-2.0*$offset_rounded, 1.0+3.0*$offset_rounded, "","");
    $y1nMin = $Imin - 1.4*$offset if ( ($Imin-1.4*$offset) < $y1nMin);
    $y1nMax = "YMAX" if ( -s $fresfile );
    my ($ytic, $yticRaw) = ($offset_rounded<0.21? $offset_rounded:0.20, 400);
    my $mytic = $offset_rounded / 2.0;

    my $plotwidth = ($hardcopy) ? 1.0 : 0.63;
    my $textwidth = 1.0 - $plotwidth;

    my $ytext = 0.90;
    my $dy = 0.05;
    my $xtext = $plotwidth+0.00*$textwidth;

    my $basefile = ( defined($efile) and -s $efile ) ? ${efile} : "event";
    my $ebase = (defined($efile)) ? basename($efile) : "no File";
    $ebase =~ s/_/\\_/g;
    my $terminal = "x11 enhanced";
    my $output = "";
    my $tmargin = "3";
    my $title = "File: ${ebase}   Event $i/$N";

    if ($hardcopy) {
	$terminal = "postscript eps enhanced \"Helvetica\" 16";
	$output = "\'${basefile}_${tShow}.eps\'";
	$tmargin = "5";
	$title = "File: ${ebase}   Event $i/$N     printed: $date\\nModel: ${radShow}m KBO at ${AUshow}AU (${offsetShow}m offs)    x-cor: $mgcorShow/$cor0Show   x-chi: $mgchiShow/$chi0Show";
    }

    # basic setup
    my $gp = "#!/usr/bin/env gnuplot\n".
	"reset\n".
	"set terminal $terminal\n".
	"set output $output\n".
	"set tmargin $tmargin\n".
	"set lmargin 12\n".
	"set rmargin 5\n".

	"set grid mytic ytic xtic\n".


	"set multiplot\n".

	"set size $plotwidth,0.5\n".
	"set xrange [$t-$dt:$t+$dt]\n".
	"set yrange  [$y1nMin:$y1nMax]\n".
	"set ytic $ytic mirror\n".
	"set mytic 2\n".

	# put lines at the hit locations
	"set arrow 1 from $tShow,1.0-0.4*$offset to $tShow,1.0+0.4*$offset nohead lc rgb \"dark-green\" \n".
	"set arrow 2 from $tShow,(1.0-$offset)-0.4*$offset to $tShow,(1.0-$offset)+0.4*$offset nohead lc rgb \"dark-green\" \n";



    # list of info ... but not for the hardcopy
    if ( ! $hardcopy ) {
	my $j = 1;
	my $header = sprintf "%2s %5s %5s %5s  %-11s %-11s","No", "Rad", "AU", "I.P.", "cor/cor0", "chi/chi0";
	$gp .= "set label 999 \"$date\" at screen (1.0+$xtext)/2.0,$ytext+$dy cen\n";
	$gp .= "set label 1000 \"$header\" at screen $xtext,$ytext left\n";
	foreach my $hit ( @{$events{$t}} ) {
	    my ($RStar, $aa, $AU, $offset, $icor, $cor, $cor0, $corN, $ichi, $chi, $chi0, $chiN, $time) = @$hit;
	    my $ytext2 = $ytext-($j-$jStart+1)*$dy;
	    my $remaining = $Nk - $j;
	    my $tc = ($kShow == $j) ? "rgb \"red\"" : "rgb \"black\"";
	    my $data = sprintf "%2d %5d %5d %5d %5.2f/%.2f %5.2f/%.2f", $j, $aa, $AU, $offset, $cor, $cor0, $chi, $chi0;
	    $gp .= "set label $j \"$data\" at screen $xtext,$ytext2 tc $tc left\n"
		if ($ytext2 > 0.05  and $j>=$jStart);
	    $gp .= "set label $j \"-- $remaining more (last is $Nk) --\" at screen ($xtext+1.0)/2.0,$ytext2 cen\n"
		if ($ytext2 < 0.05  and $ytext2 > 0.0 );
	    $j++;
	}
    }
    
    # top plot
    $gp .= "set origin 0,0.5\n".
	"set title \"$title\"\n".
	"set xlabel \"Time (seconds)\"\n".
	"set ylabel \"I/<I>\"\n".
	"set key below\n".
	#"set offsets 0,0,0.05,0.05\n".
	"plot \'$file\' using 1:2 t \"East Star (L)\" w lp lc rgb \"red\" pt 1,".
	" \'\' using 1:3 t \"West Star (R)\" w lp lc 3 pt 1";


    # overlay the pattern if available
    if (-s $fresfile) {

	my $fresOffsetfile = "$tmpdir/fresOffsettmp";
	system ("offsetPattern $fresfile $offsetShow 1 > $fresOffsetfile");
	my $max_line = `cstats $fresOffsetfile $offsetShow 1 | grep max_val`;
	my $min_line = `cstats $fresOffsetfile $offsetShow 1 | grep min_val`;
	my ($fp_max) = (split /\s+/,$max_line)[3];
	my ($fp_min) = (split /\s+/,$min_line)[3];
	my $fp_depth = 1.0 - $fp_min;

	my $colour = "green";
	$colour = "red"   if ($efile=~/\.L\./);
	$colour = "blue"  if ($efile=~/\.R\./);

	my $ymax_new = 1.0 + $offset + $fp_depth + ($fp_max-1.0);
	$gp =~ s/YMAX/$ymax_new/;

	$gp .= ",".
	    " \'$fresOffsetfile\' using (\$2/$vRet+$tShow):(\$3+0.5*$offset+$fp_depth) t \"\" w l lt 1 lw 2 lc rgb \"$colour\",".
	    " \'$fresOffsetfile\' u  (-\$2/$vRet+$tShow):(\$3+0.5*$offset+$fp_depth) t \"\" w l lt 1 lw 2 lc rgb \"$colour\"\n";
    } else { $gp .= "\n"; }
    $gp .= "unset tmargin\n";

	    
    # middle plot
    $gp .= "set size $plotwidth,0.25\n".
	"set autoscale y\n".
	"unset grid\n".
	"set grid xtic ytic\n".
	"set ytic $yticRaw mirror\n".
	"set origin 0,0.25\n".
	"set title \"Raw Data\"\n".
	"set xlabel \"\"\n".
	"set ylabel \"ADU\"\n".
	"set tmargin 3\n".
	"set bmargin 0.6\n".
	"unset key\n".
	"set xtics textcolor rgb \"white\"\n".
	"set offsets 0, 0, $yticRaw, $yticRaw\n".
	"plot \'$file\' using 1:(\$6>10?\$6:(1/0)) t \"Star 1\" w l lc rgb \"red\",".
	"  \'\' u 1:(\$4>10?\$4:(1/0)) t \"\" w lp lc rgb \"red\" pt 1\n".


	# bottom plot
	"set autoscale y\n".
	"set origin 0,0.0\n".
	"set title \"\"\n".
	"set offsets 0, 0, $yticRaw, $yticRaw\n".
	"unset bmargin\n".
	"set xlabel \"Time (seconds)\"\n".
	"set tmargin 0.6\n".
	"unset xtics\n".
	"set xtics\n".
	"plot  \'$file\' u 1:(\$7>10?\$7:(1/0)) t \"Star 2\" w l lc rgb \"blue\",".
	"  \'\' u 1:(\$5>10?\$5:(1/0)) t \"\" w lp lc rgb \"blue\" pt 1\n".
	"unset multiplot\n".
	"reset\n";
    
    $h = 0;
    return $gp;
}




### command definitions
####################################################################
my %commands = (
		"show"  =>[\&show,     "Show current variable values"], 
		"n"     =>[\&nexti,    "show (n)ext plot."], 
		"p"     =>[\&previ,    "show (p)rev plot."],
		"f"     =>[\&forwk,    "(f)orward to next kernel."], 
		"b"     =>[\&backk,    "(b)ack to prev kernel."],
		"d"     =>[\&downj,    "scroll (d)own thru hits by 10."],
		"u"     =>[\&upj,      "scroll (u)p thru hits by 10."],
		"r"     =>[\&record,   "(r)ecord current event."],
		"h"     =>[\&hardcopy, "set (h)ardcopy (writes eps plot)."],
		"help"  =>[\&help,     "List of help commands."],
		"?"  =>[\&help,     "List of help commands."],
		"dt"    =>[\&setdt,    "set time range dt, eg. dt=4.5"], 
		"i"     =>[\&seti,     "set event no. i,  eg.  i=2"], 
		"t"     =>[\&sett,     "set time coord t,  eg.  t=123.45"], 
		"k"     =>[\&setk,     "set kernel no. k,  eg.  k=3"],
		"j"     =>[\&setj,     "set kernel no. j to top,  eg.  j=3"],
		"a"     =>[\&all,      "plot (a)ll data in range"],
		"q"     =>[\&quit,     "(q)uit viewEvent"],
		);

my %errors = ( 
	       "IRANGE"   => "Variable out of range  0 < i <= $N",
	       "TRANGE"   => "Variable out of range  0 < t <= $tmax",
	       "KRANGE"   => "Variable 'k' out of range",
	       "JRANGE"   => "Variable 'j' out of range",
	       "NOTFOUND" => "Command not found.",
	       );




### command subroutines
#####################################################################
sub show () {
    printf STDOUT "\n  t \t=\t $t (0 < t < $tmax)\n".
	"  dt \t=\t $dt\n".
	"  h \t=\t $h  (h = 0|1)\n";
	"  i \t=\t $i  (0 < i < $N)\n".
	"  j \t=\t $j  (0 < j < $Nk)\n".
	"  k \t=\t $k  (0 < k < $Nk)\n\n";
    
}
sub help () {
    printf STDOUT "\n";
    foreach my $command (sort keys %commands) {
	printf STDOUT "  %-10s = %s\n", $command, $commands{$command}->[1];
    }
    printf STDOUT "\n";
}
sub record () {

    # need k-1 as array starts at zero
    my @currentevent = @{ ${ $events{$t} }[$k-1] };  

    open (REC, ">>${recFile}\n");
    printf REC "%s\n", join(" \t", @currentevent);
    close (REC);
}
sub hardcopy () { $h = ($h) ? 0 : 1; }

sub nexti () { 
    if ($i<$N) { 
	$t = $events[++$i]; 
	$k=1; $j=1;
    } 
}
sub previ () { 
    if ($i>0)  { 
	$t = $events[--$i]; 
	$k=1; $j=1;
    } 
}
sub forwk () { 
    $k++ if ($k<$Nk); 
    downj() if ($k>$j+10); 
}
sub backk () { 
    $k-- if ($k>0); 
    upj() if ($k<$j); 
}
sub downj () { $j = ($j+10<=$Nk) ? ($j+10) : $j; }
sub upj () { $j = ($j-10>0) ? ($j-10) : 0; }
sub all () { }
sub setdt ($) { $dt = $_[0] ; }
sub sett  ($) { 
    if ( $_[0]<= $ts[-1]->[$col{"sec"}] && $_[0]>=0 ) {
	$t  = $_[0] ; 
    } else { error("TRANGE"); }
}
sub seti  ($) { 
    if ($_[0]<=$N && $_[0]>=0) {
	$i = $_[0];
	$k = 1; $j=1;
    } else { error("IRANGE"); }
    $t = $events[$i] ;
}
sub setk  ($) { 
    if ($_[0]<=$Nk && $_[0]>=0) {
	$k = $_[0];
	setj($k);
    } else { error("KRANGE"); }
}
sub setj  ($) { 
    if ($_[0]<=$Nk && $_[0]>=0) {
	$j = $_[0];
    } else { error("JRANGE"); }
}
sub error ($) { printf STDOUT "%s\n", $errors{$_[0]}; }
sub quit () { die "Exiting.\n"; }
#######################################################################






open (GP, "|gnuplot -geometry 800x480 2>> errors.gnuplot") or die "Unable to open gnuplot\n";
GP->autoflush(1);
my @extrema;
my $i_last = -1;
my $t_last = 0;
READIN: while (1) {

    # write a data tmp file and run gnuplot
    $Nk = defined($events{$t}) ? scalar @{ $events{$t} } : 0;
    @extrema = dumpData(\@ts, $t, $dt) unless ($i == $i_last && $t == $t_last);
    my $gp = gpScript($tmpfile, $t, $dt, \@extrema, \%events, $k, $j, $h);
    print GP "$gp"; 

    $i_last = $i;
    $t_last = $t;

    # make a prompt and read in a command
    my $command = "\n";
    while ( $command =~ /^\n$/) {
        printf STDOUT "\e[31;1m viewEvent > \e[0m";
	$command = <STDIN>;
    }
    chomp $command;


    # parse the command
    
    # if setting a variable    
    if ( my ($var,$val) = $command =~ /^(\w+)=($number)$/ ) {
	$commands{$var}->[0]->($val) if (  defined($commands{$var}) );
	error("NOTFOUND")            if (! defined($commands{$var}) );

    # else ... we must be processing a command
    } else {
	$commands{$command}->[0]->() if ( defined($commands{$command}) );
	error("NOTFOUND")            if (!defined($commands{$command}));
    }

}
close(GP);



exit 0;
