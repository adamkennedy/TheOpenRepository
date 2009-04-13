package ADAMK::Role::Make;

use 5.008;
use strict;
use warnings;
use ADAMK::Util 'shell';

use vars qw{$VERSION $BIN_MAKE};
BEGIN {
	$VERSION    = '0.08';
	$BIN_MAKE ||= $Config::Config{make};
}

sub bin_make { $BIN_MAKE }

# Configure the distribution
sub run_makefile_pl {
	my $self  = shift;
	my $pushd = File::pushd::pushd($self->path);
	shell( [ 'perl', 'Makefile.PL', @_ ], "Configuring $pushd" );
}

# Make the distribution
sub run_make {
	my $self  = shift;
	my $pushd = File::pushd::pushd($self->path);
	shell( [ $self->bin_make, @_ ], "Configuring $pushd" );
}

# Test the distribution
sub run_make_test {
	shift->run_make('test');
}

1;
