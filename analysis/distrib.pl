#!/usr/bin/env perl
#
#

use strict;
use warnings;

use Math::Random qw(random_normal random_poisson random_uniform
		    random_binomial random_set_seed);

use Time::HiRes qw(gettimeofday);

my ($distrib, $fmt, @args) = @ARGV;

my $usage = "Usage: $0 gauss fmt n mean std\n".
    " "x(8+length($0))."uniform fmt n low high\n".
    " "x(8+length($0))."poisson fmt n mu\n".
    " "x(8+length($0))."binomial fmt n nt p\n";

(scalar @args) or die "$usage";

my $seeda = substr(join("", gettimeofday()), -8, 8);
my $seedb = substr(join("", gettimeofday()), -8, 8);
#die "$seeda $seedb\n";
random_set_seed($seeda, $seedb);

my @variates;

if ($distrib eq "gauss") {
    defined $args[1] or die "$usage";
    @variates = random_normal(@args);
}

if ($distrib eq "uniform") {
    defined $args[1] or die "$usage";
    @variates = random_uniform(@args);
}

if ($distrib eq "poisson") {
    $args[0] or die "$usage";
    @variates = random_poisson(@args);
}

if ( $distrib eq "binomial" ) {
    $args[1] or die "$usage";
    @variates = random_binomial(@args);
}


foreach my $variate (@variates) {
    printf STDOUT "$fmt\n", $variate;
}
exit 0;
