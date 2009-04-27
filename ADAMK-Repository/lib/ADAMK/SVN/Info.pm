package ADAMK::SVN::Info;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.11';

use Class::XSAccessor
	getters => {
		url      => 'URL',
		author   => 'LastChangedAuthor',
		revision => 'LastChangedRev',
		date     => 'LastChangedDate',
	};

sub new {
	my $class = shift;
	my %hash  = map {
		/^([^:]+)\s*:\s*(.*)$/;
		my $key   = "$1";
		my $value = "$2";
		$key =~ s/\s+//g;
		( $key, $value );
	} grep {
		length $_
	} @_;
	bless \%hash, $class;
}

1;
