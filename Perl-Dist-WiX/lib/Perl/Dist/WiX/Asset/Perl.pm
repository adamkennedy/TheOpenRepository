package Perl::Dist::WiX::Asset::Perl;

# Perl::Dist asset for the Perl source code itself

use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str HashRef ArrayRef Bool );
use File::Spec::Functions qw( catdir splitpath rel2abs catfile );
require File::Remove;
require File::Basename;

our $VERSION = '1.102';
$VERSION =~ s/_//ms;

with 'Perl::Dist::WiX::Role::Asset';
extends 'Perl::Dist::WiX::Asset::DistBase';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has license => (
	is       => 'ro',
	isa      => HashRef,
	reader   => '_get_license',
	required => 1,
);

has patch => (
	is       => 'ro',
	isa      => ArrayRef,
	reader   => '_get_patch',
	required => 1,
);

has unpack_to => (
	is      => 'ro',
	isa     => Str,
	reader  => '_get_unpack_to',
	default => q{},
);

has install_to => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_install_to',
	required => 1,
);

has force => (
	is      => 'ro',
	isa     => Bool,
	reader  => '_get_force',
	lazy    => 1,
	default => sub { $_[0]->parent->force ? 1 : 0 },
);

has git => (
	is      => 'ro',
	isa     => Str,
	reader  => '_get_git',
	default => undef,
);


sub install {
	my $self = shift;

	$self->_trace_line( 0, 'Preparing ' . $self->_get_name . "\n" );

	my $fl2 = File::List::Object->new->readdir(
		catdir( $self->_get_image_dir, 'perl' ) );

	my $git = $self->_get_git();

	my $tgz;
	if ( not defined $git ) {

		# Download the file
		$tgz =
		  $self->_mirror( $self->_get_url(), $self->_get_download_dir(), );
	}

	my $unpack_to =
	  catdir( $self->_get_build_dir(), $self->_get_unpack_to() );
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		File::Remove::remove( \1, $unpack_to );
	}

	my $perlsrc;
	if ( defined $git ) {

		# Copy to the build directory.
		$self->_copy(
			URI->new( $self->_get_url() )->file(),
			catdir( $unpack_to, 'perl-git' ) );
		$perlsrc = 'perl-git';
	} else {

		# Unpack to the build directory
		my @files = $self->_extract( $tgz, $unpack_to );

		# Get the versioned name of the directory
		( $perlsrc = $tgz ) =~ s{[.] tar[.] gz\z | [.] tgz\z}{}msx;
		$perlsrc = File::Basename::basename($perlsrc);
	}

	# Pre-copy updated files over the top of the source
	my $patch   = $self->_get_patch;
	my $version = $self->_get_pv_human;
	if ($patch) {

		# Overwrite the appropriate files
		foreach my $file ( @{$patch} ) {
			$self->_patch_file( "perl-$version/$file" => $unpack_to );
		}
	}

	# Copy in licenses
	if ( ref $self->_get_license() eq 'HASH' ) {
		my $licenses = $self->_get_license();
		my $license_dir = catdir( $self->_get_image_dir(), 'licenses' );
		if ( defined $git ) {
			foreach my $key ( keys %{$licenses} ) {
				$self->_copy( catfile( $unpack_to, $key ),
					catfile( $license_dir, $licenses->{$key} ) );
			}
		} else {
			$self->_extract_filemap( $tgz, $self->_get_license(),
				$license_dir, 1 );
		}
	} ## end if ( ref $self->_get_license...)

	# Build win32 perl
  SCOPE: {

		# Prepare to patch
		my $image_dir = $self->_get_image_dir();
		my $INST_TOP = catdir( $image_dir, $self->_get_install_to() );
		my ($INST_DRV) = splitpath( $INST_TOP, 1 );

		my $wd = $self->_pushd( $unpack_to, $perlsrc, 'win32' );

		my $perldir;
		if ( defined $git ) {
			$perldir = 'perl-git';
		} else {
			$perldir = "perl-$version";
		}

		$self->_trace_line( 2, "Patching makefile.mk\n" );
		$self->_patch_file(
			"$perldir/win32/makefile.mk" => $unpack_to,
			{   dist     => $self->_get_parent(),
				INST_DRV => $INST_DRV,
				INST_TOP => $INST_TOP,
			} );

		PDWiX->throw('Debugging stop');
			
		$self->_trace_line( 1, "Building perl $version...\n" );
		$self->_make;

		my $long_build =
		  Win32::GetLongPathName( rel2abs( $self->_get_build_dir() ) );

		my $force = $self->_get_force();
		if (   ( not $force )
			&& ( $long_build =~ /\s/ms )
			&& ( $self->_get_pv_human() eq '5.10.0' ) )
		{
			$force = 1;
			$self->_trace_line( 0, <<"EOF");
***********************************************************
* Perl 5.10.0 cannot be tested at this point.
* Because the build directory
* $long_build
* contains spaces when it becomes a long name,
* testing the CPANPLUS module fails in 
* lib/CPANPLUS/t/15_CPANPLUS-Shell.t
* 
* You may wish to build perl within a directory
* that does not contain spaces by setting the build_dir
* (or temp_dir, which sets the build_dir indirectly if
* build_dir is not specified) parameter to new to a 
* directory that does not contain spaces.
*
* -- csjewell\@cpan.org
***********************************************************
EOF
		} ## end if ( ( not $force ) &&...)

		unless ($force) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->_trace_line( 1, "Testing perl...\n" );
			$self->_make('test');
		}

		$self->_trace_line( 1, "Installing perl...\n" );
		$self->_make(qw/install UNINST=1/);
	} ## end SCOPE:

	if (4 == $self->_gcc_version()) {
		$self->_copy(
			catdir ($self->_get_image_dir(), 'c',    'bin', 'libgcc_s_sjlj-1.dll'),
			catdir ($self->_get_image_dir(), 'perl', 'bin', 'libgcc_s_sjlj-1.dll'),
		);
	}
	
	my $fl_lic = File::List::Object->new()
	  ->readdir( catdir( $self->_get_image_dir(), 'licenses', 'perl' ) );
	$self->_insert_fragment( 'perl_licenses', $fl_lic );

	my $fl = File::List::Object->new()
	  ->readdir( catdir( $self->_get_image_dir(), 'perl' ) );
	$fl->subtract($fl2)->filter( $self->_filters );
	$self->_insert_fragment( 'perl', $fl, 1 );

	return 1;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Perl - "Perl core" asset for a Win32 Perl

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Perl->new(
    ...
  );

=head1 DESCRIPTION

TODO: Document

=head1 METHODS

TODO: Document

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

The install method installs the website link described by the
B<Perl::Dist::WiX::Asset::Website> object and returns a file
that was installed as a L<File::List::Object> object.

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

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
