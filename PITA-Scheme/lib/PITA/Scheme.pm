package PITA::Scheme;

=pod

=head1 NAME

PITA::Scheme - PITA Testing Schemes

=head1 SYNOPSIS

=head1 DESCRIPTION

While most of the PITA system exists outside the guest testing images and
tries to have as little interaction with them as possible, there is one
part that needs to be run from inside it.

PITA::Scheme objects live inside the image and does three main tasks.

1. Unpack the package and prepare the testing environment

2. Run the sequence of commands to execute the tests and capture
the results.

3. Package the results as a L<PITA::Report> and send it to the
L<PITA::Host::ResultServer>.

This functionality is implemented in a module structure that is highly
subclassable. In this way, L<PITA> can support multiple different
testing schemes for multiple different languages and installer types.

=head1 Setting up a Testing Image

Each image that will be set up will require a bit of customisation,
as the entire point of this type of testing is that every environment
is different.

However, by keeping most of the functionality in the L<PITA::Scheme>
objects, all you should need to do is to arrange for a simple Perl
script to be launched, that feeds some initial configuration to the
L<PITA::Scheme> object.

And it should do the rest. Or die... but we'll cover that later.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp         ();
use IPC::Cmd     ();
use File::Spec   ();
use File::Temp   ();
use Params::Util '_HASH',
                 '_CLASS',
                 '_INSTANCE';
use Config::Tiny ();
use PITA::Report ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;
	my %p      = @_; # p for params
	unless ( $class eq __PACKAGE__ ) {
		Carp::croak("Scheme class $_[0] does not implement a new method");
	}

	# Check some params
	unless ( $p{injector} ) {
		Carp::croak("Scheme 'injector' was not provided");
	}
	### Might not be needed now we don't write back to it
	#unless ( File::Spec->file_name_is_absolute($p{injector}) ) {
	#	Carp::croak("Scheme 'injector' is not an absolute path");
	#}
	unless ( -d $p{injector} ) {
		Carp::croak("Scheme 'injector' does not exist");
	}
	unless ( -r $p{injector} ) {
		Carp::croak("Scheme 'injector' cannot be read, insufficient permissions");
	}

	# Find a temporary directory to use for the testing
	$p{workarea} ||= File::Temp::tempdir();
	unless ( $p{workarea} ) {
		Carp::croak("Scheme 'workarea' not provided and automatic detection failed");
	}
	unless ( -d $p{workarea} ) {
		Carp::croak("Scheme 'workarea' directory does not exist");
	}
	unless ( -r $p{workarea} and -w _ ) {
		Carp::croak("Scheme 'workarea' insufficient permissions");
	}

	# Find the scheme config file
	my $scheme_conf = File::Spec->catfile(
		$p{injector}, 'scheme.conf',
		);
	unless ( -f $scheme_conf ) {
		Carp::croak("Failed to find scheme.conf in the injector");
	}
	unless ( -r $scheme_conf ) {
		Carp::croak("No permissions to read scheme.conf");
	}

	# Load the config file
	my $config = Config::Tiny->read( $scheme_conf );
	unless ( _INSTANCE($config, 'Config::Tiny') ) {
		Carp::croak("Failed to load scheme.conf config file");
	}

	# Split out instance-specific options
	my $instance = delete $config->{instance};
	unless ( _HASH($instance) ) {
		Carp::croak("No instance-specific options in scheme.conf");
	}

	# If provided, apply the optional lib path so some libraries
	# can be upgraded in a pince without upgrading all the images
	if ( $instance->{lib} ) {
		my $libpath = File::Spec->catdir( $p{injector}, split( /\//, $instance->{lib}) );
		unless ( -d $libpath ) {
			Carp::croak("Injector lib directory does not exist");
		}
		unless ( -r $libpath ) {
			Carp::croak("Injector lib directory has no read permissions");
		}
		require lib;
		lib->import( $libpath );
	}

	# Build a ::Request object from the config
	require PITA::Report;
	my $request = PITA::Report::Request->__from_Config_Tiny($config);
	unless ( _INSTANCE($request, 'PITA::Report::Request') ) {
		Carp::croak("Failed to create report Request object from scheme.conf");
	}

	# Resolve the specific schema class for this test run
	my $scheme = $request->scheme;
	my $driver = join( '::', 'PITA', 'Scheme', map { ucfirst $_ } split /\./, lc($scheme || '') );
	unless ( $scheme and _CLASS($driver) ) {
		Carp::croak("Request contains an invalid scheme name '$scheme'");
	}

	# Load the scheme class
	eval "require $driver;";
	if ( $@ =~ /^Can\'t locate PITA/ ) {
		Carp::croak("Scheme driver $driver does not exist on this Guest");
	} elsif ( $@ ) {
		Carp::croak("Error loading scheme driver $driver: $@");
	}

	# FINALLY hand off ALL those params to the scheme class constructor
	return $driver->new( %p,
		scheme_conf => $scheme_conf,
		config      => $config,
		instance    => $instance,
		request     => $request,
		);
}

sub injector {
	$_[0]->{injector};
}

sub workarea {
	$_[0]->{workarea};
}

sub scheme_conf {
	$_[0]->{scheme_conf};
}

sub config {
	$_[0]->{config};
}

sub instance {
	$_[0]->{instance};
}

sub request {
	$_[0]->{request};
}





#####################################################################
# PITA::Scheme Methods

sub load_config {
	my $self = shift;

	# Load the config file
	$self->{config} = Config::Tiny->new( $self->{config_file} )
		or Carp::croak("Failed to load config file: "
			. Config::Tiny->errstr);

	# Validate some basics

	1;
}

# Nothing, yet
sub prepare_package {
	my $self = shift;
	1;
}

sub execute_command {
	my ($self, $cmd) = @_;
	my ($success, $error_code, undef, $stdout_buf, $stderr_buf )
		= IPC::Cmd::run( command => $cmd, verbose => 0 );
	my $command = PITA::Report::Command->new(
		system => $cmd,
		stdout => $stdout_buf,
		stderr => $stderr_buf,
		);
	unless ( _INSTANCE($command, 'PITA::Report::Command') ) {
		Carp::croak("Error creating ::Command");
	}
	$command;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Scheme>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

The Perl Image Testing Architecture (L<http://ali.as/pita/>)

L<PITA>, L<PITA::Report>, L<PITA::Host::ResultServer>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
