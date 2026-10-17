#!/usr/bin/env perl
#
# original filename: parsePineAddress.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Jan 10, 2007  13:26:53 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe addressBookFile\n";

my ($addressfile) = @ARGV;
die $usage unless $addressfile;


open (AFILE, "$addressfile") or die "Opening $addressfile: $!\n";
while (<AFILE>) {
    next if /\#/;
    my @line = split;

    # get rid of the < and > in the address <joe@shmo.com>
    $line[-1] =~ s/>//;
    $line[-1] =~ s/<//;

    # skip the line unless the last field is a valid email address
    next unless $line[-1] =~ /@/;

    # print it -- unless it's part of a listserve entry ... brackets and such
    printf "%s \t%s\n", $line[0], $line[-1] 
	unless ($line[0] =~ /[@\(\)]/ or $line[-1] =~ /[\(\),]/);
}
close (AFILE);

exit 0;
