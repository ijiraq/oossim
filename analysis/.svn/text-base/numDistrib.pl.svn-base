#!/usr/bin/env perl
#
# original filename: numDistrib.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Feb  2, 2006  14:25:14 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

#use strict;
use warnings;

use Local::Constants;
use Math::Trig;

my ($function, $xlo, $xhi, $fmt, $N) = @ARGV;

my $usage = "Usage: $0 function xlo xhi fmt N\n".
    "\n".
    " Example: $0 \'100*\$EXP**(-(\$x)**2/2)\' -5 5 %.2f 100\n";

die "$usage" unless $N;


#  need a subroutine to parse any strings and replace constants with values
sub substituteConstants ($) {
    my ($function) = @_;

    foreach my $symname (keys %Local::Constants::) {
	local *value = $Local::Constants::{$symname};
	$function =~ s/\$$symname/$value/g if defined $value;
    }
    return $function;
}

# initializations
$xhi2 = eval substituteConstants($xhi);
$xlo2 = eval substituteConstants($xlo);
my $xrange = ($xhi2 - $xlo2);
my $dx = ($xhi2 - $xlo2)/$N;
my $dx2 = ($xhi2 - $xlo2)/100;

my $function2 = substituteConstants($function);

printf "%-16s %s\n", "#function:", "$function";
printf "%-16s %s\n", "#function_sub:", "$function2";
printf "%-16s %s\n",  "#xlo:", "$xlo ($xlo2)";
printf "%-16s %s\n",  "#xhi:", "$xhi ($xhi2)";
printf "%-16s %s\n",  "#fmt:", "($fmt)";
printf "%-16s %s\n",  "#N:", "$N";

# now make a script to calculate the function (i used to do this with
#   an eval statement but it was incredibly slow).

my $script = "#!/usr/bin/env perl\n".
    "#\n".
    "#\n".
    "use strict;\n".
    "use warnings;\n".
    "use lib \"\$ENV{HOME}/libperl\";\n".
    "use Local::Constants;\n".
    "use Math::Random qw(random_normal random_poisson random_uniform random_binomial);\n".
    "use Math::Trig;\n".
    
    # get the max
    "my \$x = $xlo2;\n".
    "my \$max = $function2;\n".
    "my \$min = $function2;\n".
    "for (my \$j=$xlo2; \$j<$xhi2; \$j+=$dx2) {\n".
    "    \$x = \$j;\n".
    "    my \$y = $function2;\n".
    "    \$max = \$y if (\$y > \$max);\n".
    "    \$min = \$y if (\$y < \$min);\n".
    "}\n".

    # get values under the curve
    "my \$dy = (\$max - \$min);\n".
    "my \@values;\n".
    "my \$i=0;\n".
    "while (\$i < $N) {\n".
    "    \$x = $xlo2 + $xrange*rand();\n".
    "    my \$y = \$min + \$dy*rand();\n".
    "    my \$f = $function2;\n".
    "    if (\$y<\$f) {\n".
    "        push \@values, \$x;\n".
    "        \$i++;\n".
    "    }\n".
    "}\n".

    "foreach my \$value (\@values) {\n".
    "    printf STDOUT \"%$fmt\\n\", \$value;\n".
    "}\n".
    "".
    "".
    "".
    "\n";

# dump the temp script
my $tmp_script = "$ENV{HOME}/tmp/numDistrib.tmp.pl";
open (TMP, ">$tmp_script");
printf TMP "$script\n";
close (TMP);
chmod (0744, "$tmp_script");

system ("$tmp_script");

#unlink "$tmp_script";
exit 0;
