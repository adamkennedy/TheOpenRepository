package Perl::Dist::WiX::Asset::Distribution;

use Moose;
use MooseX::Types::Moose qw( Str Bool ArrayRef Maybe ); 
use File::Spec::Functions qw( catdir catfile );

# require Data::Dumper;
require File::Remove;
require URI;

our $VERSION = '1.090_102';
$VERSION = eval $VERSION;

with 'Perl::Dist::WiX::Role::Asset';
extends 'Perl::Dist::WiX::Asset::DistBase';

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
	default  => sub { return $_[0]->_name_to_module(); },
);

has force => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_force',
	lazy     => 1,
	default  => sub { !! $_[0]->_get_parent()->force },
);

has automated_testing => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_automated_testing',
	default  => 0,
);

has release_testing => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_release_testing',
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

#has inject => (
#	is       => 'ro',
#	isa      => Maybe['URI'],
#	reader   => '_get_inject',
#	default  => undef,
#);

has packlist => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_packlist',
	default  => 1,
);

has overwritable => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_overwritable',
	default  => 0,
);

sub BUILD {
	my $self = shift;

	if ( $self->get_name eq $self->_get_url and not _DIST($self->get_name()) ) {
		PDWiX::Parameter->throw("Missing or invalid name param\n");
	}

	return;
}

sub install {
	my $self = shift;
	
#	print Data::Dumper->new([$self], [qw(*self)])->Indent(1)->Maxdepth(1)->Dump();
	
	my $name = $self->get_name();
	my $build_dir = $self->_get_build_dir();
	
# If we don't have a packlist file, get an initial filelist to subtract from.
	my $module = $self->get_module_name();
	my $filelist_sub;

	if ( not $self->_get_packlist() ) {
		$filelist_sub = File::List::Object->new->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$self->_trace_line( 5,
			    "***** Module being installed $module"
			  . " requires packlist => 0 *****\n" );
	}

	# Download the file
	my $tgz =
	  $self->_mirror( $self->_abs_uri( $self->_get_cpan() ), $self->_get_modules_dir(), );

	# Where will it get extracted to
	my $dist_path = $name;
	$dist_path =~ s{\.tar\.gz}{}msx;   # Take off extensions.
	$dist_path =~ s{\.zip}{}msx;
	$dist_path =~ s{.+\/}{}msx;        # Take off directories.
	my $unpack_to = catdir( $build_dir, $dist_path );
	$self->_add_to_distributions_installed($dist_path);

	# Extract the tarball
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $build_dir );
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
	unless ( $self->_module_build_installed() )
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
		$self->_trace_line( 3, "Bypassing version.pm's Build.PL\n" );
		$buildpl = 0;
	}

	# Build the module
  SCOPE: {
		my $wd = $self->_pushd($unpack_to);

		# Enable automated_testing mode if needed
		# Blame Term::ReadLine::Perl for needing this ugly hack.
		if ( $self->_get_automated_testing() ) {
			$self->_trace_line( 2,
				"Installing with AUTOMATED_TESTING enabled...\n" );
		}
		if ( $self->_get_release_testing() ) {
			$self->_trace_line( 2,
				"Installing with RELEASE_TESTING enabled...\n" );
		}
		local $ENV{AUTOMATED_TESTING}   = $self->_get_automated_testing() ? 1 : undef;
		local $ENV{RELEASE_TESTING}     = $self->_get_release_testing() ? 1 : undef;
		local $ENV{PERL_MM_USE_DEFAULT} = 1;
		
		$self->_configure($buildpl);

		$self->_install_distribution($buildpl);

	} ## end SCOPE:

	# Making final filelist.
	my $filelist;
	if ($self->_get_packlist()) {
		$filelist = $self->_search_packlist($module);
	} else {
		$filelist = File::List::Object->new()->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$filelist->subtract($filelist_sub)->filter( $self->_filters );
	}
	
	my $module_name = $self->get_module_name();	
	$module_name =~ s{::}{_}msg;
	$module_name =~ s{-}{_}msg;

	# Insert fragment.
	$self->_insert_fragment( $module_name, $filelist, $self->_get_overwritable() );
	
	return 1;
} ## end sub install_distribution

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Distribution - "Perl Distribution" asset for a Win32 Perl

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Distribution->new(
      name  => 'MSERGEANT/DBD-SQLite-1.14.tar.gz',
      force => 1,
  );

=head1 DESCRIPTION

L<Perl::Dist::WiX> supports two methods for adding Perl modules to the
installation. The main method is to install it via the CPAN shell.

The second is to download, make, test and install the Perl distribution
package independently, avoiding the use of the CPAN client. Unlike the
CPAN installation method, installing the distribution directly does
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

It is normally created on the fly by the Perl::Dist::WiX
C<install_distribution> method (and other things that call it).

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::WiX::Role::Asset>.

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset> and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Asset::Distribution> object.

It inherits all the params described in the L<Perl::Dist::WiX::Role::Asset> 
C<new> method documentation, and adds some additional params.

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

The optional boolean C<force> param allows you to specify that the tests
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
execution of release tests when L<Perl::Dist::WiX> itself is being tested
under C<RELEASE_TESTING>.

=item makefilepl_param

Some distributions illegally require you to pass additional non-standard
parameters when you invoke "perl Makefile.PL".

The optional C<makefilepl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Makefile.PL.

=item buildpl_param

Some distributions require you to pass additional non-standard
parameters when you invoke "perl Build.PL".

The optional C<buildpl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Build.PL.

=back

The C<new> method returns a B<Perl::Dist::WiX::Asset::Distribution> object,
or throws an exception on error.

=head2 install

The install method installs the distribution described by the
B<Perl::Dist::WiX::Asset::Distribution> object and returns a list of files
that were installed as a L<File::List::Object> object.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, L<Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
