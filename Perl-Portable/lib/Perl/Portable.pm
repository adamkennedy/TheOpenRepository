package Perl::Portable;

=pod

=head1 NAME

Perl::Portable - Support code for "Perl on a Stick"

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

For now, see the code for more...

=cut

use 5.008;
use strict;
use Config           ();
BEGIN {
	require 'Config_heavy.pl';
}
use Carp             'croak';
use File::Spec       ();
use List::Util       ();
use Params::Util     qw{ _STRING _HASH _ARRAY };
use YAML::Tiny       ();

use vars qw{$VERSION $FAKE_PERL};
BEGIN {
	$VERSION   = '0.02';

	# This variable is provided exclusively for the
	# use of test scripts.
	$FAKE_PERL = undef;
}

use Object::Tiny qw{
	dist_volume
	dist_dirs
	dist_root
	conf
	perlpath
};





#####################################################################
# Constructors

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new( @_ );

	# Param checking
	unless ( exists $self->{dist_volume} ) {
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
		croak('Missing or invalid ENV key in portable.perl');
	}
	unless ( _ARRAY($self->{portable}->{ENV}->{PATH}) ) {
		croak('Missing or invalid ENV.PATH key in portable.perl');
	}
	unless ( _ARRAY($self->{portable}->{ENV}->{LIB}) ) {
		croak('Missing or invalid ENV.LIB key in portable.perl');
	}
	unless ( _ARRAY($self->{portable}->{ENV}->{INCLUDE}) ) {
		croak('Missing or invalid ENV.INCLUDE key in portable.perl');
	}
	unless ( _HASH($self->{portable}->{config}) ) {
		croak('Missing or invalid config key in portable.perl');
	}

	# Localize up the config entries
	my $config  = $self->{config} = {};
	my $pconfig = $self->{portable}->{config};
	my %file    = map { $_ => 1 } qw{ perlpath          };
	my %post    = map { $_ => 1 } qw{ ldflags lddlflags };
	foreach my $key ( sort keys %$pconfig ) {
		unless ( defined $pconfig->{$key} and length $pconfig->{$key} and ! $post{$key} ) {
			$config->{$key} = $pconfig->{$key};
			next;
		}
		my @parts = split /\//, $pconfig->{$key};
		if ( $file{$key} ) {
			$config->{$key} = File::Spec->catfile(
				$self->dist_root, @parts,
			);
		} else {
			$config->{$key} = File::Spec->catdir(
				$self->dist_root, @parts,
			);
		}
	}
	foreach my $key ( sort keys %post ) {
		$config->{$key} =~ s/\$(\w+)/$config->{$1}/g;
	}

	return $self;
}

my $DEFAULT = undef;

sub default {
	return $DEFAULT if $DEFAULT;

	# Get the perl executable location
	my $perlpath = ($ENV{HARNESS_ACTIVE} and $FAKE_PERL) ? $FAKE_PERL : $^X;

	# The path to Perl has a localized path.
	# G:\\strawberry\\perl\\bin\\perl.exe
	# Split it up, and search upwards to try and locate the
	# portable.perl file in the distribution root.
	my ($dist_volume, $d, $f) = File::Spec->splitpath($perlpath);
	my @d = File::Spec->splitdir($d);
	pop @d if $d[-1] eq '';
	my $dist_dirs = List::Util::first {
			-f File::Spec->catpath( $dist_volume, $_, portable_conf() )
		}
		map {
			File::Spec->catdir(@d[0 .. $_])
		} reverse ( 0 .. $#d );
	unless ( defined $dist_dirs ) {
		croak("Failed to find the portable.perl file");
	}

	# Derive the main paths from the plain dirs
	my $dist_root = File::Spec->catpath($dist_volume, $dist_dirs, '');
	my $conf      = File::Spec->catpath($dist_volume, $dist_dirs, portable_conf());

	# Load the YAML file
	my $portable = YAML::Tiny::LoadFile( $conf );
	unless ( _HASH($portable) ) {
		croak("Missing or invalid portable.perl file");
	}

	# Hand off to the main constructor
	$DEFAULT = __PACKAGE__->new(
		dist_volume => $dist_volume,
		dist_dirs   => $dist_dirs,
		dist_root   => $dist_root,
		conf        => $conf,
		perlpath    => $perlpath,
		portable    => $portable,
	);

	return $DEFAULT;
}





#####################################################################
# Configuration Accessors

sub portable_conf {
	'portable.perl';
}

sub portable_cpan {
	$_[0]->{portable}->{cpan};
}

sub portable_c_bin {
	$_[0]->{portable}->{c_bin};
}

sub portable_c_lib {
	$_[0]->{portable}->{c_lib};
}

sub portable_c_include {
	$_[0]->{portable}->{c_include};
}

sub portable_config {
	$_[0]->{portable}->{config};
}

sub portable_env {
	$_[0]->{portable}->{ENV};
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
# Main Interface

sub config {
	my $config = default()->{config};
	exists $config->{$_[0]} ? $config->{$_[0]} : $_[1];
}

sub apply {
	my $config = default()->{config};
	foreach my $k ( %$config ) {
		$Config::Config{$k} = $config->{$k};
	}
	return 1;
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
