package Geo::MapInfo::MIF;

use strict;
use File::Slurp;
use Text::CSV;
use Params::Util  qw{_INSTANCE};

our $VERSION = '0.01';

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub trim($)	{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}