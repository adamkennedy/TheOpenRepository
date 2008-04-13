package Perl::Portable;

=pod

=head1 NAME

Perl::Portable - Support class for "Perl on a Stick" distribtions

=head1 DESCRIPTION

B<THIS MODULE IS HIGHLY EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT
NOTICE.>

B<YOU HAVE BEEN WARNED!>

"Portable" is a term used for applications that are installed onto a
portable storage device (most commonly a USB memory stick) rather than
onto a single host.

This technique has become very popular for Windows applications, as it
allows a user to make use of their own software on typical publically
accessible computers at libraries, hotels and internet cafes.

Converting a Windows application into portable form has a specific set
of challenges, as the application has no access to the Windows registry,
no access to "My Documents" type directories, and does not exist at a
reliable filesystem path (because the portable storage medium can be
mounted at an arbitrary volume or filesystem location).

B<Perl::Portable> provides a methodology and implementation to support
the creating of  "Portable Perl" distributions. While this will initially
be focused on a Windows implementation, wherever possible the module will
be built to be platform-agnostic.

=cut

use 5.010;
use strict;
use Carp             'croak';
use List::Util       ();
use Params::Util     qw{ _STRING _HASH _ARRAY };
use File::Spec       ();
use YAML::Tiny       ();
use Win32::Env::Path ();

use vars qw{$VERSION $FAKE_PERL};
BEGIN {
	$VERSION   = '0.01';

	# This variable is provided exclusively for the
	# use of test scripts.
	$FAKE_PERL = undef;
}

use Object::Tiny qw{
	dist_volume
	dist_dirs
	dist_root
	abs_conf
	abs_perl
};





#####################################################################
# Constructors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Param checking
	unless ( _STRING($self->dist_volume) ) {
		croak('Missing or invalid dist_volume param');
	}
	unless ( _STRING($self->dist_dirs) ) {
		croak('Missing or invalid dist_dirs param');
	}
	unless ( _STRING($self->dist_root) ) {
		croak('Missing or invalid dist_root param');
	}
	unless ( _HASH($self->{portable}) ) {
		croak('Missing or invalid portable param');
	}
	unless ( _HASH($self->{portable}->{ENV}) ) {
		croak('Missing or invalid ENV key in portable.conf');
	}
	unless ( _ARRAY($self->{portable}->{ENV}->{PATH}) ) {
		croak('Missing or invalid ENV.PATH key in portable.conf');
	}
	unless ( _ARRAY($self->{portable}->{ENV}->{LIB}) ) {
		croak('Missing or invalid ENV.LIB key in portable.conf');
	}
	unless ( _ARRAY($self->{portable}->{ENV}->{INCLUDE}) ) {
		croak('Missing or invalid ENV.INCLUDE key in portable.conf');
	}

	# Derive some absolute paths
	$self->{abs_end_path} = [
		map { $self->_dir($_) }
		@{$self->portable
	];

	return $self;
}

sub find {
	my $class    = shift;
	my $abs_perl = ($ENV{HARNESS_ACTIVE} and $FAKE_PERL) ? $FAKE_PERL : $^X;

	# The path to Perl has a localized path.
	# G:\\strawberry\\perl\\bin\\perl.exe
	# Split it up, and search upwards to try and locate the
	# portable.conf file in the distribution root.
	my ($dist_volume, $d, $f) = File::Spec->splitpath($abs_path);
	my @d = File::Spec->splitdir($d);
	pop @d if $d[-1] eq '';
	my $dist_dirs = List::Util::first {
			File::Spec->catpath( $v, $_, $class->portable_conf )
		}
		map {
			File::Spec->catdir(@d[0 .. $_])
		} ( 0 .. $#d );
	unless ( defined $dist_dirs ) {
		croak("Failed to find the portable.conf file");
	}

	# Derive the main paths from the plain dirs
	my $dist_root = File::Spec->catpath($v, $dist_dirs);
	my $abs_conf  = File::Spec->catpath($v, $dist_dirs, $class->portable_conf );

	# Load the YAML file
	my $portable = YAML::Tiny::LoadFile( $abs_conf );
	unless ( _HASH($portable) ) {
		croak("Missing or invalid portable.conf file");
	}

	# Hand off to the main constructor
	$class->new(
		dist_volume => $dist_volume,
		dist_dirs   => $dist_dirs,
		dist_root   => $dist_root,
		abs_conf    => $abs_conf,
		abs_perl    => $abs_perl,
		portable    => $portable,
	);
}





#####################################################################
# Configuration Accessors

sub portable_conf {
	'portable.conf';
}

sub portable_env_path {
	@{ $_[0]->{portable}->{ENV}->{PATH} };
}

sub portable_env_lib {
	@{ $_[0]->{portable}->{ENV}->{LIB} };
}

sub portable_env_include {
	@{ $_[0]->{portable}->{ENV}->{INCLUDE} };
}





#####################################################################
# Support Methods

# Convert a portable path into a relative path
sub _dir {
	my $self = shift;
	my $unix = shift;
	my @dir  = File::Spec::Unix->splitdir($unix);
	File::Spec->catdir( $self->dist_root, @dir );
}

sub _file {
	my $self = shift;
	my $unix = shift;
	my ($v,$d,$f) = File::Spec::Unix->splitpath($unix);
	$d = File::Spec->catdir( $self->dist_root, $d );
	File::Spec->catfile(
		File::Spec->catdir(
			$self->dist_root,
			$d,
		),
		$f,
	);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Portable>

For other issues, or commercial support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://win32.perl.org/>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
