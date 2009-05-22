package ADAMK::Role::Make;

use 5.008;
use strict;
use warnings;
use JSON              ();
use ADAMK::Util       ();
use ADAMK::Repository ();

use vars qw{$VERSION $BIN_MAKE};
BEGIN {
	$VERSION    = '0.11';
	$BIN_MAKE ||= $Config::Config{make};
}

sub bin_make { $BIN_MAKE }

# Find the version of Module::Install in use
sub module_install {
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

# Is the version of M:I bundled in the tarball bad?
sub bad_module_install {
	my $self = shift;

	# Do we use Module::Install
	my $module_install = $self->module_install;
	unless ( $module_install ) {
		return 0;
	}

	# Handle the single-release broken cases
	if ( CPAN::Version->vcmp($module_install, '0.84') == 0 ) {
		return 1;
	}
	if ( CPAN::Version->vcmp($module_install, '0.85') == 0 ) {
		return 1;
	}

	# Is the version too old in absolute terms?
	if ( CPAN::Version->vgt('0.61', $module_install) ) {
		return 1;
	}

	# If we don't use auto_install we are ok
	my $auto_install = $self->auto_install;
	unless ( $auto_install ) {
		return 0;
	}

	# Is the version older than the safe auto_install limit?
	if ( CPAN::Version->vgt('0.64', $module_install) ) {
		return 1;
	}

	# M:I version is ok
	return 0;
}

# Find the version of Module::Install bundled in /inc
sub inc_module_install {
	my $self = shift;
	my $file = $self->file('inc/Module/Install.pm');
	unless ( -f $file ) {
		return undef;
	}

	# Find the version
	return ExtUtils::MM_Unix->parse_version($file);
}

# Is the version of M:I bundled in the tarball bad?
sub bad_inc_module_install {
	my $self = shift;

	# Do we use Module::Install
	my $module_install = $self->inc_module_install;
	unless ( $module_install ) {
		return 0;
	}

	# Handle the single-release broken cases
	if ( CPAN::Version->vcmp($module_install, '0.84') == 0 ) {
		return 1;
	}
	if ( CPAN::Version->vcmp($module_install, '0.85') == 0 ) {
		return 1;
	}

	# Is the version too old in absolute terms?
	if ( CPAN::Version->vgt('0.61', $module_install) ) {
		return 1;
	}

	# If we don't use auto_install we are ok
	my $auto_install = $self->auto_install;
	unless ( $auto_install ) {
		return 0;
	}

	# Is the version older than the safe auto_install limit?
	if ( CPAN::Version->vgt('0.64', $module_install) ) {
		return 1;
	}

	# M:I version is ok
	return 0;
}

# Does the Makefile.PL use auto_install
sub auto_install {
	my $self = shift;
	my $file = $self->file('Makefile.PL');
	unless ( -f $file ) {
		return undef;
	}

	# Find the version
	my $makefile = $self->_slurp($file);
	unless ( $makefile =~ m/auto_install/s ) {
		return undef;
	}

	# This has auto_install
	return 1;
}

# Configure the distribution
sub run_makefile_pl {
	my $self  = shift;
	my $pushd = File::pushd::pushd($self->path);

	# Execute the Makefile.PL
	local $ENV{X_MYMETA} = 'JSON';
	ADAMK::Util::shell(
		[ 'perl', 'Makefile.PL', @_ ],
		"Configuring $pushd",
	);
	unless ( -f 'MYMETA.json' ) {
		return 1;
	}

	# Attempt to load the resulting JSON
	JSON::from_json(
		ADAMK::Util::slurp('MYMETA.json')
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
