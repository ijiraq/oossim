#!/usr/bin/env perl
#
# this program generates fake data for a function provided.
# Steve Bickerton
# Tues. Sept 27, 2005
#

#use strict;
use warnings;

use Local::Constants;

use Math::Random qw(random_normal random_poisson random_uniform
		    random_binomial );
use Math::Trig;

my ($function, $n, $xlo, $xhi, $yerr, $xerr) = @ARGV;

my $usage = "Usage: $0 function n xlo xhi gauss:fmt:std\n".
    " "x(8+length($0))."function n xlo xhi uniform:fmt:plus_minus\n".
    " "x(8+length($0))."function n xlo xhi poisson:fmt\n".
    " "x(8+length($0))."function n xlo xhi clean:fmt\n".
    "\n".
    " Example: generate \'100*\$EXP**(-(\$x)**2/2)\' 100 -5 5 poisson:%.2f\n".
    "          generate \'sin(\$x)\' 100 \'-\$PI\' \'\$PI\' gauss:%.2f:1.0\n";

die "$usage" unless $yerr;

my ($ydistrib, $yfmt, @yerr) = split /:/, $yerr;

$xerr = "clean:$yfmt" unless $xerr;
my ($xdistrib, $xfmt, @xerr) = split /:/, $xerr;

#  need a subroutine to parse any strings and replace constants with values
sub substituteConstants ($) {
    my ($function) = @_;

    foreach my $symname (keys %Local::Constants::) {
	local *value = $Local::Constants::{$symname};
	$function =~ s/\$$symname/$value/g if defined $value;
    }
    return $function;
}

# a subroutine to generate a line to get random variates
sub get_variates($$@) {
    my ($axis,$distrib,@err) = @_;

    my $mean = 0;

    my $noiseline = "";
    if ($distrib eq "gauss") {
	my ($std) = @err;
	$std or die "$usage";
	printf "%-16s %s\n", "#std:", "$std";
	$noiseline .= "my \@${axis}variates = random_normal($n+1,$mean,$std);\n";
	
    } elsif ($distrib eq "uniform") {
	my ($plus_minus) = @err;
	$plus_minus or die "$usage";
	printf "%-16s %s\n", "#plus_minus:", "$plus_minus"; 
	$noiseline .= "my \@${axis}variates = random_uniform($n+1, -$plus_minus, $plus_minus);\n";
	
    } elsif ($distrib eq "poisson") {
	$noiseline .= "my \@${axis}variates;\n".
	    "foreach my \$value (\@values) {\n".
	    "    die \"Can't have negative values in a Poisson distribution\\n\" if \$value < 0;\n".
	    "    push \@${axis}variates, random_poisson(1, \$value);\n".
	    "}\n";
	
    } elsif ($distrib eq "clean" ) {
	$noiseline .= "my \@${axis}variates = (0)x($n+1);\n";
    }

    return $noiseline;
}

# initializations
$xhi2 = eval substituteConstants($xhi);
$xlo2 = eval substituteConstants($xlo);
my $dx = ($xhi2 - $xlo2)/$n;

my $function2 = substituteConstants($function);

printf "%-16s %s\n", "#function:", "$function";
printf "%-16s %s\n", "#function_sub:", "$function2";
printf "%-16s %s\n",  "#xlo:", "$xlo ($xlo2)";
printf "%-16s %s\n",  "#xhi:", "$xhi ($xhi2)";
printf "%-16s %s\n",  "#n:", "$n";
printf "%-16s %s\n",  "#xdistrib:", "$xdistrib";
printf "%-16s %s\n",  "#ydistrib:", "$ydistrib";

# now make a script to calculate the function (i used to do this with
#   an eval statement but it was incredibly slow).

my $script = "#!/usr/bin/env perl\n".
    "#\n".
    "#\n".
    "use strict;\n".
    "use warnings;\n".
    "use Math::Random qw(random_normal random_poisson random_uniform random_binomial);\n".
    "use Math::Trig;\n".
    
    "my \@values;\n".
    "foreach my \$i (0 .. $n) {\n".
    "    my \$x = $xlo2 + \$i*$dx;\n".
    "    push \@values, $function2;\n".
    "}\n";


# make the y-noise
$script .= get_variates("x", $xdistrib, @xerr);
$script .= get_variates("y", $ydistrib, @yerr);


# output the data
$script .= "foreach my \$j (0 .. $n) {\n".
    "    my \$x = $xlo2 + \$j*$dx + \$xvariates[\$j];\n";

if ($ydistrib eq "poisson") {
    $script .=  "    my \$outvalue =  \$yvariates[\$j];\n";
} else {
    $script .= "    my \$outvalue = \$values[\$j]+\$yvariates[\$j];\n";
}

my $form = "%$xfmt %$yfmt\\n";
$script .= "    printf STDOUT \"$form\", \$x, \$outvalue;\n".
    "}\n";



# dump the temp script
my $tmp_script = "$ENV{HOME}/tmp/generate.tmp.pl";
open (TMP, ">$tmp_script");
printf TMP "$script\n";
close (TMP);
chmod (0744, "$tmp_script");

system ("$tmp_script");

#unlink "$tmp_script";

exit 0;
