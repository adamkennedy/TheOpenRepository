package ADAMK::Role::Make;

use 5.008;
use strict;
use warnings;
use ADAMK::Util       ();
use ADAMK::Repository ();

use vars qw{$VERSION $BIN_MAKE};
BEGIN {
	$VERSION    = '0.10';
	$BIN_MAKE ||= $Config::Config{make};
}

sub bin_make { $BIN_MAKE }

# Find the version of Module::Install in use
sub mi {
	my $self = shift;
	my $file = $self->file('Makefile.PL');
	unless ( -f $file ) {
		return undef;
	}

	# Find the version
	my $makefile = $self->_slurp($file);
	unless ( $makefile =~ /use\s+inc::Module::Install\b/ ) {
		# Doesn't use Module::Install
		return undef;
	}
	unless ( $makefile =~ /use\s+inc::Module::Install(?:::DSL)?\s+([\d.]+)/ ) {
		# Does not use a specific version of Module::Install
		return 0;
	}

	return "$1";
}

# Configure the distribution
sub run_makefile_pl {
	my $self  = shift;
	my $pushd = File::pushd::pushd($self->path);
	ADAMK::Util::shell(
		[ 'perl', 'Makefile.PL', @_ ],
		"Configuring $pushd",
	);
}

# Make the distribution
sub run_make {
	my $self  = shift;
	my $pushd = File::pushd::pushd($self->path);
	ADAMK::Util::shell(
		[ $self->bin_make, @_ ],
		"Configuring $pushd",
	);
}

# Test the distribution
sub run_make_test {
	shift->run_make('test');
}

1;
