#!/usr/bin/env perl
#
# original filename: qsort.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Jul 20, 2007  16:14:25 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe infile [options]\n".
    "     -d(char)    delimiting character\n".
    "     -n          numeric sort\n".
    "     -r          reverse sort\n".
    "     -ccolumn    sort by column number\n".
    "     -cccolumn   second column number\n".
    "     -nn         second column numeric\n".
    "     -rr         second column reverse\n";

my ($infile, @args) = @ARGV;
die $usage unless $infile;

my ($numeric,$reverse,$column) = (0,0,0);
my ($numeric2,$reverse2,$column2,$twocolumn) = (0,0,0,0);
foreach my $option (@args) {

    next unless my ($opt) = $option =~ /-(\w+)/;
    $numeric = 1    if ($opt =~ /^n$/);
    $reverse = 2    if ($opt =~ /^r$/);
    $numeric2 = 1    if ($opt =~ /^nn$/);
    $reverse2 = 2    if ($opt =~ /^rr$/);
    
    if (my ($tmp) = $opt =~ /^c(\d+)$/) {
	$column = $tmp-1;
    }
    if (my ($tmp) = $opt =~ /^cc(\d+)$/) {
	$column2 = $tmp-1;
	$twocolumn = 4;
    }

}

die "Column ($column) is not an integer.\n" unless $column=~/^\d+$/;

sub numb ($$$) {my ($a,$b,$c) = @_; $a->[$c] <=> $b->[$c]; } 
sub text ($$$) {my ($a,$b,$c) = @_; $a->[$c] cmp $b->[$c]; }
sub numbR ($$$) {my ($a,$b,$c) = @_; $b->[$c] <=> $a->[$c]; } 
sub textR ($$$) {my ($a,$b,$c) = @_; $b->[$c] cmp $a->[$c]; }

my ($comp1,$comp2);
my $op = $numeric + $reverse;
if    ($op == 0) {  $comp1 = \&text;  }
elsif ($op == 1) {  $comp1 = \&numb;  } 
elsif ($op == 2) {  $comp1 = \&textR; } 
elsif ($op == 3) {  $comp1 = \&numbR; }
my $op2 = $numeric2 + $reverse2;
if    ($op2 == 0) {  $comp2 = \&text;  }
elsif ($op2 == 1) {  $comp2 = \&numb;  } 
elsif ($op2 == 2) {  $comp2 = \&textR; } 
elsif ($op2 == 3) {  $comp2 = \&numbR; }


# read in the file
my @lines;
my $comments = "";
open (INFILE, "$infile");
while(<INFILE>) {
    if ( $_=~/^\#/ ) {
	$comments .= $_;
	next;
    }
    push @lines, [(split), $_];
}
close(INFILE);

# sort
@lines = sort { $comp1->($a,$b,$column) || $comp2->($a,$b,$column2) } @lines;

# output
printf STDOUT "$comments";
foreach my $lineref (@lines) {
    my $line = $$lineref[-1];
    printf "$line";
}


exit 0;
