#!/usr/bin/perl

# Recommend a mirror

use strict;
use URI               ();
use Mirror::CPAN 0.90 ();
use Time::Elapsed     ();

my $master = URI->new('http://www.cpan.org/');

# Bootstrap the object
print "Fetching master file...\n";
my $mirror = Mirror::CPAN->get($master);
unless ( $mirror ) {
	die("Failed to fetch '$master'");
}

# Show the details for the master
print "Name: "   . $mirror->name   . "\n";	
print "Master: " . $mirror->master . "\n";
show($mirror);

# Scan through the mirror
my $mirrors = $mirror->{mirrors};
foreach my $uri ( @$mirrors ) {
	my $option = $mirror->class->get($uri);
	show($option);
}

sub show {
	my $mirror  = shift;
	my $master  = $mirror->master;
	my $name    = $mirror->name;
	my $url     = $mirror->uri;
	my $lag     = int($mirror->lag * 1000) . 'ms';
	my $elapsed = Time::Elapsed::elapsed(int($mirror->age));
	print "\n";
	print "[$url]\n";
	print "    Lag: $lag\n";
	print "    Age: $elapsed\n";
}
