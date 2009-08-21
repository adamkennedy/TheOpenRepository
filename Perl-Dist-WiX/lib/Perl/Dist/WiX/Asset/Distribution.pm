package Perl::Dist::WiX::Asset::Distribution;

use Moose;
use MooseX::Types::Moose qw( Str Maybe ); 
use File::Remove qw();

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_name',
	required => 1,
);

has module_name => (
	is       => 'ro',
	isa      => Maybe[Str],
	reader   => 'get_module_name',
	init_arg => 'mod_name',
	lazy     => 1,
	default  => sub { my $self = shift; return $self->_name_to_module($self->get_name()); },
);

has force => (
	is       => 'ro',
	isa      => Bool,
	reader   => 'get_force',
	lazy     => 1,
	default  => sub { !! $_[0]->parent->force },
);

has automated_testing => (
	is       => 'ro',
	isa      => Bool,
	reader   => 'get_automated_testing',
	default  => 0,
);

has release_testing => (
	is       => 'ro',
	isa      => Bool,
	reader   => 'get_release_testing',
	default  => 0,
);

has makefilepl_param => (
	is       => 'ro',
	isa      => ArrayRef,
	reader   => '_get_makefilepl_param',
	default  => sub { return [] },
);

has buildpl_param => (
	is       => 'ro',
	isa      => ArrayRef,
	reader   => '_get_buildpl_param',
	default  => sub { return [] },
);

has inject => (
	is       => 'ro',
	isa      => Maybe['URI'],
	reader   => '_get_inject',
	default => undef,
);

has automated_testing => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_packlist',
	default  => 1,
);

has packlist => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_packlist',
	default  => 1,
);

sub BUILD {
	my $self = shift;

	if ( $self->get_name eq $self->get_url and not _DIST($self->_get_name) ) {
		# TODO: Throw exception instead.
		Carp::croak("Missing or invalid name param");
	}

	return;
}

sub install {
	my $self = shift;
	my $name = $self->_get_name();
	my $parent = $self->_get_parent();
	
# If we don't have a packlist file, get an initial filelist to subtract from.
	my $module = $self->_get_module_name();
	my $filelist_sub;

	if ( not $self->_get_packlist() ) {
		$filelist_sub = File::List::Object->new->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$parent->trace_line( 5,
			    "***** Module being installed $module"
			  . " requires packlist => 0 *****\n" );
	}

	# Download the file
	my $tgz =
	  $self->_mirror( $self->abs_uri( $parent->cpan ), $parent->modules_dir, );

	# Where will it get extracted to
	my $dist_path = $name;
	$dist_path =~ s{\.tar\.gz}{}msx;   # Take off extensions.
	$dist_path =~ s{\.zip}{}msx;
	$dist_path =~ s{.+\/}{}msx;        # Take off directories.
	my $unpack_to = catdir( $parent->build_dir, $dist_path );
	$parent->_add_to_distributions_installed($dist_path);

	# Extract the tarball
	if ( -d $unpack_to ) {
		$parent->trace_line( 2, "Removing previous $unpack_to\n" );
		File::Remove::remove( \1, $unpack_to );
	}
	$parent->_extract( $tgz => $parent->build_dir );
	unless ( -d $unpack_to ) {
		PDWiX->throw("Failed to extract $unpack_to\n");
	}

	my $buildpl = ( -r catfile( $unpack_to, 'Build.PL' ) ) ? 1 : 0;
	my $makefilepl = ( -r catfile( $unpack_to, 'Makefile.PL' ) ) ? 1 : 0;

	unless ( $buildpl or $makefilepl )
	{
		PDWiX->throw(
			"Could not find Makefile.PL or Build.PL in $unpack_to\n");
	}

	# Build using Build.PL if we have one
	# unless Module::Build is not installed.
	unless ( $self->_module_build_installed($parent->image_dir) )
	{
		$buildpl = 0;
		unless ( $makefilepl ) {
			PDWiX->throw("Could not find Makefile.PL in $unpack_to".
			  " (too early for Build.PL)\n");
		}
	} ## end unless ( ( -r catfile( catdir...

	# Can't build version.pm using Build.PL until Module::Build
	# has been upgraded.
	if ( $module eq 'version' ) {
		$parent->trace_line( 3, "Bypassing version.pm's Build.PL\n" );
		$buildpl = 0;
	}

	# Build the module
  SCOPE: {
		my $wd = $parent->_pushd($unpack_to);

		# Enable automated_testing mode if needed
		# Blame Term::ReadLine::Perl for needing this ugly hack.
		if ( $self->automated_testing ) {
			$parent->trace_line( 2,
				"Installing with AUTOMATED_TESTING enabled...\n" );
		}
		if ( $self->release_testing ) {
			$parent->trace_line( 2,
				"Installing with RELEASE_TESTING enabled...\n" );
		}
		local $ENV{AUTOMATED_TESTING} = $self->_get_automated_testing ? 1 : undef;
		local $ENV{RELEASE_TESTING}   = $self->_get_release_testing ? 1 : undef;

		$self->_configure($buildpl);

		$self->_install_distribution($buildpl);

	} ## end SCOPE:

	# Making final filelist.
	my $filelist;
	if ($self->_get_packlist()) {
		$filelist = $self->search_packlist($module);
	} else {
		$filelist = File::List::Object->new()->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$filelist->subtract($filelist_sub)->filter( $parent->filters );
	}
	
	return $filelist;
} ## end sub install_distribution

sub _configure {
	my $self = shift;
	my $buildpl = shift;
	my $parent = $self->_get_parent();

	$parent->trace_line( 2, "Configuring $name...\n" );
	$buildpl
	  ? $parent->_perl( 'Build.PL',    @{ $self->_get_buildpl_param } )
	  : $parent->_perl( 'Makefile.PL', @{ $self->_get_makefilepl_param } );
	  
	return;
}

sub _install_distribution {
	my $self = shift;
	my $buildpl = shift;
	my $parent = $self->_get_parent();
	
	$parent->trace_line( 1, "Building $name...\n" );
	$buildpl ? $parent->_build : $parent->_make;
		
	unless ( $self->_get_force() ) {
		$parent->trace_line( 2, "Testing $name...\n" );
		$buildpl ? $parent->_build('test') : $parent->_make('test');
	}
	
	$parent->trace_line( 2, "Installing $name...\n" );
	$buildpl
	  ? $parent->_build(qw/install uninst=1/)
	  : $parent->_make(qw/install UNINST=1/);
		  
	return;
}

sub _name_to_module {
	my ( $self, $parent, $dist ) = @_;
	
	$parent->trace_line( 3, "Trying to get module name out of $dist\n" );

#<<<
	my ( $module ) = $dist =~ m{\A  # Start the string...
					[A-Za-z/]*      # With a string of letters and slashes
					/               # followed by a forward slash. 
					(.*?)           # Then capture all characters, non-greedily 
					-\d*[.]         # up to a dash, a sequence of digits, and then a period.
					}smx;           # (i.e. starting a version number.)
#>>>
	$module =~ s{-}{::}msg;

	return $module;
} ## end sub _name_to_module

sub _module_build_installed {
	my $self = shift;
	my $image_dir = shift;
	
	my $perl_dir = catdir($image_dir, 'perl');
	my @dirs = (
		catdir( $image_dir, qw( perl vendor lib Module ) ),
		catdir( $image_dir, qw( perl site lib Module ) ),
		catdir( $image_dir, qw( perl lib Module ) ),
	);
	
	foreach my $dir (@dirs) {
		return 1 if -f catfile ($dir, 'Build.pm');
	}
	
	return 0;
}

=pod

=head1 NAME

Perl::Dist::Asset::Distribution - "Perl Distribution" asset for a Win32 Perl

=head1 SYNOPSIS

  my $distribution = Perl::Dist::Asset::Distribution->new(
      name  => 'MSERGEANT/DBD-SQLite-1.14.tar.gz',
      force => 1,
  );

=head1 DESCRIPTION

L<Perl::Dist::Inno> supports two methods for adding Perl modules to the
installation. The main method is to install it via the CPAN shell.

The second is to download, make, test and install the Perl distribution
package independantly, avoiding the use of the CPAN client. Unlike the
CPAN installation method, installation the distribution directly does
C<not> allow the installation of dependencies, or the ability to discover
and install the most recent release of the module.

This secondary method is primarily used to deal with cases where the CPAN
shell either fails or does not yet exist. Installation of the Perl
toolchain to get a working CPAN client is done exclusively using the
direct method, as well as the installation of a few special case modules
such as ones where the newest release is broken, but an older
or a development release is known to be good.

B<Perl::Dist::WiX::Asset::Distribution> is a data class that provides
encapsulation and error checking for a "Perl Distribution" to be
installed in a L<Perl::Dist::WiX>-based Perl distribution using this
secondary method.

It is normally created on the fly by the <Perl::Dist::WiX>
C<install_distribution> method (and other things that call it).

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::WiX::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut

use strict;
use Carp              ();
use Params::Util      qw{ _STRING _ARRAY _INSTANCE };
use File::Spec        ();
use File::Spec::Unix  ();
use URI               ();
use URI::file         ();






#####################################################################
# Constructor

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::Asset::Binary> object.

It inherits all the params described in the L<Perl::Dist::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the name of the package for the purposes
of identification.

This should match the name of the Perl distribution without any version
numbers. For example, "File-Spec" or "libwww-perl".

Alternatively, the C<name> param can be a CPAN path to the distribution
such as shown in the synopsis.

In this case, the url to fetch from will be derived from the name.

=item force

Unlike in the CPAN client installation, in which all modules MUST pass
their tests to be added, the secondary method allows for cases where
it is known that the tests can be safely "forced".

The optional boolean C<force> param allows you to specify is the tests
should be skipped and the module installed without validating it.

=item automated_testing

Many modules contain additional long-running tests, tests that require
additional dependencies, or have differing behaviour when installing
in a non-user automated environment.

The optional C<automated_testing> param lets you specify that the
module should be installed with the B<AUTOMATED_TESTING> environment
variable set to true, to make the distribution behave properly in an
automated environment (in cases where it doesn't otherwise).

=item release_testing

Some modules contain release-time only tests, that require even heavier
additional dependencies compared to even the C<automated_testing> tests.

The optional C<release_testing> param lets you specify that the module
tests should be run with the additional C<RELEASE_TESTING> environment
flag set.

By default, C<release_testing> is set to false to squelch any accidental
execution of release tests when L<Perl::Dist> itself is being tested
under C<RELEASE_TESTING>.

=item makefilepl_param

Some distributions illegally require you to pass additional non-standard
parameters when you invoke "perl Makefile.PL".

The optional C<makefilepl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Makefile.PL.

=back

The C<new> method returns a B<Perl::Dist::Asset::Distribution> object,
or throws an exception (dies) on error.

=cut


sub url { $_[0]->{url} || $_[0]->{name} }





#####################################################################
# Main Methods

sub abs_uri {
	my $self = shift;

	# Get the base path
	my $cpan = _INSTANCE(shift, 'URI');
	unless ( $cpan ) {
		Carp::croak("Did not pass a cpan URI");
	}

	# If we have an explicit absolute URI use it directly.
	my $new_abs = URI->new_abs($self->url, $cpan);
	if ( $new_abs eq $self->url ) {
		return $new_abs;
	}

	# Generate the full relative path
	my $name = $self->name;
	my $path = File::Spec::Unix->catfile( 'authors', 'id',
		substr($name, 0, 1),
		substr($name, 0, 2),
		$name,
	);

	URI->new_abs( $path, $cpan );
}





#####################################################################
# Support Methods

sub _DIST {
	my $it = shift;
	unless ( defined $it and ! ref $it ) {
		return undef;
	}
	unless ( $it =~ q|^([A-Z]){2,}/| ) {
		return undef;
	}
	return $it;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<Perl::Dist::Asset>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
