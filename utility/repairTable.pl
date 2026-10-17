#!/usr/bin/env perl 
#
#  program repairTable.pl
#    This program is used to fill in the blanks in a table with dummy 
#    characters so that the data can be read-in using white-space
#    as a delimiter.
#  NOTE: it doesn't work for tab-separated data.
#

use strict;
use warnings;

my ($infile) = @ARGV;

die "Usage: repairTable infile\n" if (!$infile);

open(INFILE, "$infile");

my $linelength = length (<INFILE>);
my $delimChar = " ";   # output delimiter
my $dummyChar = "x";   # char to use to fill in blank space

# percentage of column occupied to rule out that the column is a field
# separator 
my $percentFill = 0.05;

# rewind the input file
seek (INFILE,0,0);


###############################################################
#
# Go through the file and count the character in each COLUMN
#
###############################################################3 

my @alphaNums = (0)x$linelength;
my $lines = 0;
while (<INFILE>) {

    # ignore comments and blank lines
    if ($_ !~ /^\#/ && length($_)>1) {

	my $stringOrig = $_;
	my @chars = split //, $stringOrig;

	my $count = 0;
	my $lastchar;

	# make a mask
	# only spots which are always blank will remain 0
	foreach my $char (@chars) {
	    $alphaNums[$count]++ if ($char !~ /\s/);
	    $count++;
	}

    }
    $lines++;
}

# now divide by the number of lines in the file.
@alphaNums = map {$_ / $lines} @alphaNums;


#############################################################33
#
#  OK, if more than ($percentFill)% of the lines have a character 
#      in a given column, assume the column is NOT a field separator
#      (ie it's data).  Otherwise, assume it should be a delimiter.
#      Fill in anything that shouldn't be blank (not a delimiter).
#
##################################################################

# rewind
seek (INFILE,0,0);
while (<INFILE>) {

    # ignore comments and blank lines
    if ($_ !~ /^\#/ && length($_)>1) {

	my $stringOrig = $_;
	my @chars = split //, $stringOrig;

	my $count = 0;
	foreach my $char (@chars) {

	    # if it's a real honest-to-god character, keep it
	    if ($char !~ /\s/ || $char =~ /\n/) {
		printf STDOUT "$char";

	    # if it's whitespace, decide if it's a blank or a delimiter
	    } elsif ($char =~ /\s/ && $char !~ /\n/) {
		printf STDOUT "$delimChar" if ($alphaNums[$count]<$percentFill);
		printf STDOUT "$dummyChar" if ($alphaNums[$count]>=$percentFill);
	    }
	    $count++;
	}

    }
}
    


close (INFILE);

