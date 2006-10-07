package CPAN::Inject;

use strict;
use File::Basename ();
use CPAN;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self;
}

sub inject_file {
	my $self = shift;
	my $file = shift;
	unless ( $file and -f $file and -r $file ) {
		Carp::croak("Did not provide a file name, or does not exist");
	}

	# Find the location to copy it to
	
}

1;
