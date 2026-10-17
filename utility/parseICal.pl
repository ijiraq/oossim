#!/usr/bin/env perl
# from: developer.apple.com/internet/appleapplications/icalendarfiles.html
# 2008-03-24

use warnings;
use Date::ICal;
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

my $usage = "$0 icsfile\n";
my ($icsfile) = @ARGV;
die $usage unless $icsfile and -s $icsfile;

#my $c = new CGI();

#print $c->header();
#print $c->start_html('Simple Calendar Parser');
#print "This basic iCalendar file parser can display simple non-repeating events<br><br>";

open(FILE,$icsfile) or die "Cannot open sample .ics file 'example.ics'";

my $showfile = '';
while(<FILE>)
{
    $showfile .= $_;
    chomp();
    my ($prop,$val) = split(':',$_);
    dispatch($prop,$val);
}
#print "<br><br>The raw .ics file:<br><br><pre>$showfile</pre><br>";
#print $c->end_html();

## handle the DTSTART property
sub dtstart
{
    my ($dtstring,@pp) = @_;
    my $tzone = '';
    # check the parameter list for a time zone (we're just going to display it)
    for my $p (@pp)
    {
       if ($p =~ s/TZID=(.*)/$1/i)
       {
           $tzone = " ($p time)";
           last;
       }
    }
    return "Starts: " . pretty_dt($dtstring) . "$tzone";
}

## handle the BEGIN property (only recognize VEVENTs)
sub begin
{
    my ($d,@pp) = @_;
    # only deal with VEVENT
    my $ret = $d eq 'VEVENT' ? "<strong>Event</strong>" : undef;
    return $ret;
}

## handle the SUMMARY property
sub summary
{
    my $s = shift;
    return "Summary: $s";
}


sub dispatch
{
    # set up a hash of references to functions to call for a few selected properties
    # anything else will be ignored
	
    my %funcs = ( 'BEGIN' => \&begin , 
                'SUMMARY' => \&summary , 
                'DTSTART' => \&dtstart );

    my ($prop_params,$data) = @_;
    # properties can be followed by optional parameters, separated by a semicolon

    my @prop_params = split(';',$prop_params);

    if ( $funcs{$prop_params[0]} )
    {
        my $output = &{ $funcs{$prop_params[0]} }($data,@prop_params);
        #print "$output <br>\n" if $output;
        print "$output\n" if $output;
    }
}

## use Date::ICal to parse a date-time string
sub pretty_dt
{
    my $dstring = shift;
    my $ical = Date::ICal->new( ical => $dstring );
    $ical->offset(0); # no time zone math (we're displaying the timezone, if supplied)
    my $pdate = my $day = $ical->month . '/' . $ical->day . '/' . $ical->year;
    $pdate .= ' ' . $ical->hour . ':' . ($ical->min > 10 ? $ical->min : '0' . $ical->min);
    return $pdate;
}
