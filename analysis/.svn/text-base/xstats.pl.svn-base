#!/usr/bin/env perl
#
#

use strict;
use warnings;

use lib "$ENV{HOME}/libperl2";
use Local::Statistics;
use Local::Misc;


my $usage = "Usage: $0 [infile] operation args\n".
    "       operations = sum, mean, rms, median, min, max, kurt, skew\n".
    "                    standard, range, all, menaClip, rmsClip\n".
    "       args  mean/rmsClip:  nSigma tolerance max_iter\n".
    "             mode:  bins\n";

die "$usage" unless @ARGV;

my $chars = 8;
my $number = '[+-]?\d+\.?\d*';

# define references to the functions
my %op = ( 
	   "sum"=>\&sum,           "mean"=>\&mean,       "rms"=>\&rms, 
	   "median"=>\&median,     "min"=>\&min,         "max"=>\&max, 
	   "range"=>\&range,       "kurt"=>\&kurt,       "skew"=>\&skew, 
	   "standard"=>\&standard, "all"=>\&all,         "mode"=>\&mode,
	   "rmsClip"=>\&rmsClip,  "meanClip"=>\&meanClip,"srms"=>\&srms
	   );

# get the inverse hash for lookups with the function refs
my %opname = reverse %op;

# separate the operations and filenames
my (@op, @files, @args);
foreach my $arg (@ARGV) { 

    if ( $op{$arg} ) {

	if ($arg eq "standard") {
	    push @op, (\&sum, \&mean, \&rms, \&srms, \&median, \&min, \&max);
	} elsif ($arg eq "all") {
	    push @op, (\&sum, \&mean, \&rms, \&srms, \&median, \&min, \&max, 
		       \&skew, \&kurt, \&rmsClip, \&meanClip);
	} elsif ($arg eq "range") {
	    push @op, (\&min, \&max);	    
	} else {
	    push @op, $op{$arg};
	}

    } elsif ( -s $arg ) {
	push @files, $arg;
    } else {
	push @args, $arg;
    }
}
@ARGV = @files;

# set some defaults for the clipping algorithms
my ($nSigma, $tol, $maxiter) = (3, 0.001, 20);
my ($bins) = (100);


# read in the data
my @data;
my $max_columns = 0;
while (<>) { 

    next if $_=~/^\#/;
    my @line = split;
    my $columns = scalar @line;
    foreach my $column (0 .. $columns-1) {
	push @{$data[$column]}, $line[$column] 
	    if ($line[$column]=~/^$number$/); 
    }
    $max_columns = ($columns>$max_columns) ? ($columns) : ($max_columns);
}


# print a header with column numbers
printf STDOUT "%-9s", "#stat";
foreach my $column (0 .. $max_columns-1) { 
    printf "%${chars}d  ", $column+1;
}
printf "\n";


# print the number of values in the column
printf STDOUT "%-9s", "#N";
foreach my $column (0 .. $max_columns-1) { 
    printf "%${chars}d  ", scalar @{$data[$column]} ;
}
printf "\n";


# get the operations for each column and print them
my $clip = 0;
foreach my $op (@op) {    

    printf STDOUT "%-9s",$opname{$op};

    foreach my $column (0 .. $max_columns-1) {


	my @params = ( $data[$column] );

	if ( $opname{$op}=~/Clip$/ ) {

	    # set default arguments for the clipping versions
	    if (! $clip) {
		$nSigma = ($args[0]) ? (shift @args) : $nSigma;
		$tol    = ($args[1]) ? (shift @args) : $tol;
		$maxiter= ($args[2]) ? (shift @args) : $maxiter;
	    }
	    push @params, ($nSigma, $tol, $maxiter);

	    $clip += 1;
	}

	if ( $opname{$op}=~/^mode$/ ) {

	    # set default arguments for the clipping versions
	    $bins = shift @args;
	    push @params, ($bins);
	}


	my ($value) = $op->( @params );   # call the func thru a ref
	my $form = labelFormat($value, $chars);
	printf STDOUT "$form  ", $value;

    }
    printf STDOUT "\n";

}
printf STDOUT "\n";

exit 0;
