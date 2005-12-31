package PITA::Driver::Qemu;

=pod

=head1 NAME

PITA::Driver::Qemu - PITA Host Driver for Qemu images

=head1 DESCRIPTION

The author is an idiot

=cut

use strict;
use base 'PITA::Driver::Image';
use Carp         ();
use File::Spec   ();
use File::Copy   ();
use File::Temp   ();
use File::Which  ();
use Params::Util '_INSTANCE';
use Config::Tiny ();
use PITA::Report ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check we got a (qemu) image
	unless ( $self->{image_file} ) {
		Carp::croak("Did not provide the location of the image_file");
	}
	unless ( -f $self->{image_file} and -r _ ) {
		Carp::croak("$self->{image_file}: image_file does not exist, or cannot be read");
	}

	# Check the request object
	unless ( _INSTANCE($self->{request}) ) {
		Carp::croak("Did not provide PITA::Request 'request'");
	}

	# Get ourselves a fresh tmp directory
	$self->{tempdir} = File::Temp::tempdir();
	unless ( -d $self->{tempdir} and -w _ ) {
		die("Temporary working direction $self->{tempdir} is not writable");
	}

	# Locate the qemu binary
	$self->{qemu_bin} ||= File::Which::which('qemu');
	unless ( $self->{qemu_bin} ) {
		Carp::croak("Cannot locate qemu, requires explicit param");
	}
	unless ( -x $self->{qemu_bin} ) {
		Carp::croak("Insufficient permissions to run qemu");
	}

	$self;
}

sub qemu_bin {
	$_[0]->{qemu_bin};	
}

sub request {
	$_[0]->{request};
}

sub image_file {
	$_[0]->{image_file};
}

sub tempdir {
	$_[0]->{tempdir};
}

sub snapshot {
	$_[0]->{snapshot};
}





#####################################################################
# Main Methods

sub save_host_config {
	my $self    = shift;
	my $options = _HASH(shift)
		or Carp::croak("No host options hash provided to save_host_config");

	# Create the basic Config::Tiny object
	my $config = $self->request->__as_Config_Tiny;

	# Add the host-specific config variables
	$config->{instance} = $options;

	# Save the config file
	my $file = File::Spec->catfile( $self->tempdir, 'scheme.conf' );
	$config->write( $file )
		or Carp::croak("Failed to write config to $file");

	1;
}

# Copy in the test package from some other location
sub save_test_package {
	my $self = shift;
	my $from = shift;
	unless ( -f $from and -r $_ ) {
		Carp::croak("Test package $from does not exist");
	}

	# Copy to where?
	my $to = File::Spec->catfile( $self->tempdir, $self->request->filename );
	
}

sub launch_image {
	my $self = shift;
	my $cmd  = join ' ',
		$self->qemu_bin,
		$self->snapshot ? ( '-snapshot' ) : (),
		'-nographic',
		$self->image_file;

	# Execute the command
	system( $cmd );

	
}

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Host-Driver-Qemu>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2001 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
