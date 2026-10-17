#!/usr/bin/env perl
#
# original filename: conditions.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sun Jul 23, 2006  16:14:25 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#

use strict;
use warnings;
use File::Basename;

use LWP::Simple;

my $exe = basename($0);
my $usage = "Usage: $exe city\n".
    "gets the current Enviro-canada conditions for a Canadian city.\n";

my ($city) = @ARGV;
die $usage if $city and $city =~ /help/;


# read in the database
my $database = "$ENV{HOME}/.weather_citycodes.dat";
my %code;
open (DATABASE, "$database");
while (<DATABASE>) {
    my ($data_city, $prov, $number) = split;
    $data_city = lc($data_city);
    $code{$data_city} = [$prov, $number];
}
close (DATABASE);


$city = ($city) ? 
    lc($city) : ($ENV{EC_CODE}) ? 
    lc("$ENV{EC_CODE}") : lc("Hamilton");
die "City $city not found\n" unless $code{$city};

# put together the URL
my ($prov, $number) = @{$code{$city}};
my $htmlfile = "${prov}-${number}_metric_e.html";

my $city_url = "http://www.weatheroffice.ec.gc.ca/city/pages/".$htmlfile;



##########################################################################
#
#     This section used to build the database
#
#my @prov = 
#    ("bc", "ab", "sk", "mb", "on", "qc", "nb", "ns", "nf", "pe", "nt", "yk");
#my @max = (93, 72, 55, 67, 173, 169, 36, 43, 44, 6, 31, 17);
#
#open (DATABASE, ">database");
#foreach my $i (0 .. $#prov) {
#
#    my $prov = $prov[$i];
#    my $max = $max[$i];
#
#    foreach my $j (1 .. $max) {
#	my $file = "${prov}-${j}_metric_e.html";
#	my $city_url = "http://www.weatheroffice.ec.gc.ca/city/pages/".$file;
#
#	# get the page
#	my $content = get($city_url);
#	#my  $content = `cat on-77_metric_e.html`;
#	next unless $content;
#
#	my ($city) = $content =~ /\<title\>(\w+),/;
#	$city = "undefined" unless $city;
#	warn "Couldn't get $city_url\n" unless $city;
#
#	printf DATABASE "%-24s %2s %3d\n", $city, $prov, $j;
#	printf STDERR "$prov $j/$max\n";
#
#    }
#}
#close(DATABASE);
#exit 1;


# get the page
my $content = get($city_url);
#my $content = `cat on-77_metric_e.html`;
die "Couldn't get $city_url\n" unless $content;


# go through the page and get the info.
my ($T) = $content =~ /Temperature\<\/dt\>\s*\<dd\>(-?\d+)\&deg;C\<\/dd\>/;
my ($P, $trend) = $content =~ /\<dd\>(\d+\.\d) kPa\<span class=\"(\w+)\"/;
my ($hum) = $content =~ /\<dd\>(\d{1,3}) \%\<\/dd\>/;
my ($dew) = $content =~ /Dewpoint\<\/dt\>\s*\<dd\>(-?\d+)\&deg;C\<\/dd\>/;
my ($direction,$speed) = $content =~ /\<dd\>(\w{1,3}) (\d{1,3}) km\/h/;
my ($date) = $content =~ /Observed at: (.*\d\d\d\d \d?\d:\d\d \wM \w\wT)\<\/div\>/;

my $got_dew = 1;
unless ($dew) {
    $dew = 0;
    $got_dew  = 0;
}

#Humidex
my $zero = 273.16;
my $EXP = 2.718281828;
my $e = 6.11 * $EXP**(5417.7530 * ( (1.0/273.16) - (1.0/($dew+$zero) ) ) );
my $h = (0.5555)*($e - 10.0);
my $hx = sprintf "%d", $T + $h + 0.5;

#Windchill Temperature   0.5 added to round instead of truncate
my $WC = sprintf "%d", 0.045*(5.2735*sqrt($speed) + 10.45 - 0.2778*$speed)*($T - 33.0)+33 + 0.5;


# make string forms of each value to be printed
my @trend = split //, $trend;
my ($Ts, $dews, $Ps, $trends, $hums, $winds) = 
    ("$T C ($hx) ($WC)", "$dew C", "$P kPa", join("", @trend),"${hum}%", "$direction $speed km/h");

my $space = 4;
my ($Tl, $dewl, $Pl, $tl,$huml ,$windl) = 
    map {$space + length($_)} ($Ts, $dews, $Ps, $trends, $hums, $winds);
my $Tlp = $Tl + 2;

my $formS = "# %${Tl}s %${dewl}s %${Pl}s %${tl}s %${huml}s %${windl}s";
my $form = "%${Tlp}s %${dewl}s %${Pl}s %${tl}s %${huml}s %${windl}s";

my $humLabel = ($got_dew) ? "Hum" : "Hum*";
my $head = sprintf "$formS", "Temp ($humLabel) (WC)", "Dew", "Press", "Trend", "Hum", "Wind"; 
my $string = sprintf "$form", $Ts, $dews, $Ps, $trends, $hums, $winds;
print STDOUT "#  $date\n$head\n$string\n";

exit 0;
