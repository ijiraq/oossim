#!/usr/bin/env perl
#
#  perl script "breed.pl" used to make multiple copies of a file.
#

use strict;
use warnings;

my ($number, $file) = @ARGV;

die "Usage: __FILE__ number file\n" if (!$file);

sub log10 ($) {return (  log(shift(@_))/log(10)  );}

my $digits = int ( log10($number) + 1);
my $fmt = "%s%0${digits}d.%s";

(my $filebase = $file) =~ s/(\w*).(\w*)/$1/;
(my $fileExt  = $file) =~ s/(\w*).(\w*)/$2/;

foreach my $n (1 .. $number) {

    my $newfile = sprintf ($fmt,$filebase,$n,$fileExt);
    printf STDERR "cp $file $newfile ... ";
    system ("cp $file $newfile");
    printf STDERR "done\n";

}
