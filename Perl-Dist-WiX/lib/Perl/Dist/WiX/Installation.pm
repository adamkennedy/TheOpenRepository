package Perl::Dist::WiX::Installation;

=pod

=head1 NAME

Perl::Dist::WiX::Installation - Basic installation routines

=head1 VERSION

This document describes Perl::Dist::WiX::Installation version 1.100.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
install files.  

=head1 SYNOPSIS

	# This module is not to be used independently.

=head1 INTERFACE

=cut

use     5.008001;
use     strict;
use     warnings;
use     Perl::Dist::WiX::Exceptions;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

=pod

=head2 install_binary

	$self->install_binary(
		name => 'gmp',
	);

The C<install_binary> method is used by library-specific methods to
install pre-compiled and un-modified tar.gz or zip archives into
the distribution.

Returns true or throws an exception on error.

=cut

sub install_binary {
	my $self   = shift;
	my $binary = Perl::Dist::WiX::Asset::Binary->new(
		parent     => $self,
		install_to => 'c',             # Default to the C dir
		@_,
	);
	
	my $filelist = $binary->install();

	return $filelist;
} ## end sub install_binary

=head2 install_library

  $self->install_library(
	  name => 'gmp',
  );

The C<install_library> method is used by library-specific methods to
install pre-compiled and un-modified tar.gz or zip archives into
the distribution.

Returns true or throws an exception on error.

=cut

sub install_library {
	my $self    = shift;
	my $library = Perl::Dist::WiX::Asset::Library->new(
		parent => $self,
		@_,
	);
	
	my $filelist = $library->install();
	  
	return $filelist;
} ## end sub install_library


=pod

=head2 install_distribution

	$self->install_distribution(
	  name              => 'ADAMK/File-HomeDir-0.69.tar.gz,
	  force             => 1,
	  automated_testing => 1,
	  makefilepl_param  => [
		  'LIBDIR=' . File::Spec->catdir(
			  $self->image_dir, 'c', 'lib',
		  ),
	  ],
	);

The C<install_distribution> method is used to install a single
CPAN or non-CPAN distribution directly, without installing any of the
dependencies for that distribution.

It is used primarily during CPAN bootstrapping, to allow the
installation of the toolchain modules, with the distribution install
order precomputed or hard-coded.

It takes a compulsory 'name' param, which should be the AUTHOR/file
path within the CPAN mirror.

The optional 'force' param allows the installation of distributions
with spuriously failing test suites.

The optional 'automated_testing' param allows for installation
with the C<AUTOMATED_TESTING> environment flag enabled, which is
used to either run more-intensive testing, or to convince certain
Makefile.PLs that insist on prompting that there is no human around
and they REALLY need to just go with the default options.

The optional 'makefilepl_param' param should be a reference to an
array of additional params that should be passwd to the
C<perl Makefile.PL>. This can help with distributions that insist
on taking additional options via Makefile.PL.

Distributions that do not have a Makefile.PL cannot be installed via
this routine.

Returns true or throws an exception on error.

=cut

sub install_distribution {
	my $self = shift;
	my $dist = Perl::Dist::WiX::Asset::Distribution->new(
		parent => $self,
		@_,
	);

	my $filelist = $dist->install();
	my $module = $dist->get_module_name();	
	$module =~ s{::}{_}msg;
	$module =~ s{-}{_}msg;

	# Insert fragment.
	$self->insert_fragment( $module, $filelist->files );

	return $self;
} ## end sub install_distribution

=pod

=head2 install_distribution_from_file

	$self->install_distribution_from_file(
	  file              => 'c:\distdir\File-HomeDir-0.69.tar.gz',
	  force             => 1,
	  automated_testing => 1,
	  makefilepl_param  => [
		  'LIBDIR=' . File::Spec->catdir(
			  $self->image_dir, 'c', 'lib',
		  ),
	  ],
	);

The C<install_distribution_from_file> method is used to install a single
CPAN or non-CPAN distribution directly, without installing any of the
dependencies for that distribution, from disk.

It takes a compulsory 'file' param, which should be the location of the
distribution on disk.

The optional 'force' param allows the installation of distributions
with spuriously failing test suites.

The optional 'automated_testing' param allows for installation
with the C<AUTOMATED_TESTING> environment flag enabled, which is
used to either run more-intensive testing, or to convince certain
Makefile.PL that insists on prompting that there is no human around
and they REALLY need to just go with the default options.

The optional 'makefilepl_param' param should be a reference to an
array of additional params that should be passwd to the
C<perl Makefile.PL>. This can help with distributions that insist
on taking additional options via Makefile.PL.

Distributions that do not have a Makefile.PL cannot be installed via
this routine.

Returns true or throws an exception on error.

=cut

sub install_distribution_from_file {
	my $self = shift;
	my $dist = {
		automated_testing => 0,
		release_testing   => 0,
		packlist          => 1,
		force             => $self->force,
		@_,
	};
	my $name = $dist->{file};

	unless ( _STRING($name) ) {
		PDWiX::Parameter->throw(
			parameter => 'file',
			where     => '->install_distribution_from_file'
		);
	}
	if ( not -f $name ) {
		PDWiX::Parameter->throw(
			parameter => "file: $name does not exist",
			where     => '->install_distribution_from_file'
		);
	}

# If we don't have a packlist file, get an initial filelist to subtract from.
	my ( undef, undef, $filename ) = splitpath( $name, 0 );
	my $module = $self->_name_to_module("CSJ/$filename");
	my $filelist_sub;

	if ( not $dist->{packlist} ) {
		$filelist_sub = File::List::Object->new->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$self->trace_line( 5,
			    "***** Module being installed $module"
			  . " requires packlist => 0 *****\n" );
	}

	# Where will it get extracted to
	my $dist_path = $filename;
	$dist_path =~ s{\.tar\.gz}{}msx;   # Take off extensions.
	$dist_path =~ s{\.zip}{}msx;
	$self->_add_to_distributions_installed($dist_path);

	my $unpack_to = catdir( $self->build_dir, $dist_path );

	# Extract the tarball
	if ( -d $unpack_to ) {
		$self->trace_line( 2, "Removing previous $unpack_to\n" );
		File::Remove::remove( \1, $unpack_to );
	}
	$self->trace_line( 4, "Unpacking to $unpack_to\n" );
	$self->_extract( $name => $self->build_dir );
	unless ( -d $unpack_to ) {
		PDWiX->throw("Failed to extract $unpack_to\n");
	}

	unless ( ( -r catfile( $unpack_to, 'Makefile.PL' ) )
		or ( -r catfile( $unpack_to, 'Build.PL' ) ) )
	{
		PDWiX->throw(
			"Could not find Makefile.PL or Build.PL in $unpack_to\n");
	}

	my $buildpl = ( -r catfile( $unpack_to, 'Build.PL' ) ) ? 1 : 0;

	# Build the module
  SCOPE: {
		my $wd = $self->_pushd($unpack_to);

		# Enable automated_testing mode if needed
		# Blame Term::ReadLine::Perl for needing this ugly hack.
		if ( $dist->{automated_testing} ) {
			$self->trace_line( 2,
				"Installing with AUTOMATED_TESTING enabled...\n" );
		}
		if ( $dist->{release_testing} ) {
			$self->trace_line( 2,
				"Installing with RELEASE_TESTING enabled...\n" );
		}
		local $ENV{AUTOMATED_TESTING} = $dist->{automated_testing};
		local $ENV{RELEASE_TESTING}   = $dist->{release_testing};

		$self->trace_line( 2, "Configuring $name...\n" );
		$buildpl
		  ? $self->_perl( 'Build.PL',    @{ $dist->{buildpl_param} } )
		  : $self->_perl( 'Makefile.PL', @{ $dist->{makefilepl_param} } );

		$self->trace_line( 1, "Building $name...\n" );
		$buildpl ? $self->_build : $self->_make;

		unless ( $dist->{force} ) {
			$self->trace_line( 2, "Testing $name...\n" );
			$buildpl ? $self->_build('test') : $self->_make('test');
		}

		$self->trace_line( 2, "Installing $name...\n" );
		$buildpl
		  ? $self->_build(qw/install uninst=1/)
		  : $self->_make(qw/install UNINST=1/);
	} ## end SCOPE:

	# Making final filelist.
	my $filelist;
	if ( $dist->{packlist} ) {
		$filelist = $self->search_packlist($module);
	} else {
		$filelist = File::List::Object->new->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$filelist->subtract($filelist_sub)->filter( $self->filters );
	}
	my $mod_id = $module;
	$mod_id =~ s{::}{_}msg;
	$mod_id =~ s{-}{_}msg;

	# Insert fragment.
	$self->insert_fragment( $mod_id, $filelist->files );

	return $self;
} ## end sub install_distribution_from_file

## search_packlists should not be needed.
## If it's needed, pull it out of version 1.000.

=pod

=head2 install_module

  $self->install_module(
	  name => 'DBI',
  );

The C<install_module> method is a high level installation method that can
be used during the C<install_perl_modules> phase, once the CPAN toolchain
has been been initialized.

It makes the installation call using the CPAN client directly, allowing
the CPAN client to both do the installation and fulfill all of the
dependencies for the module, identically to if it was installed from
the CPAN shell via an "install Module::Name" command.

The compulsory 'name' param should be the class name of the module to
be installed.

The optional 'force' param can be used to force the install of module.
This does not, however, force the installation of the dependencies of
the module.

The optional 'packlist' param sshould be 0 if a .packlist file is not 
installed with the module.

Returns true or throws an exception on error.

=cut

sub install_module {
	my $self   = shift;
	my $module = Perl::Dist::WiX::Asset::Module->new(
		parent => $self,
		@_,
	);
	
	my $filelist = $module->install();
	my $name  = $module->get_name();
	
	# Make legal fragment id.
	$name =~ s{::}{_}gmsx;

	# Insert fragment.
	$self->insert_fragment( $name, $filelist->files )
	  unless ( 0 == scalar @{ $filelist->files } );

	return $self;
} ## end sub install_module

=pod

=head2 install_modules

  $self->install_modules( qw{
	  Foo::Bar
	  This::That
	  One::Two
  } );

The C<install_modules> method is a convenience shorthand that makes it
trivial to install a series of modules via C<install_module>.

As a convenience, it does not support any additional params to the
underlying C<install_module> call other than the name.

=cut

sub install_modules {
	my $self = shift;

	foreach my $name (@_) {
		$self->install_module( name => $name );
	}

	return $self;
}

=pod

=head2 install_par

The C<install_par> method extends the available installation options to
allow for the install of pre-compiled modules and pre-compiled C libraries
via "PAR" packages.

The compulsory 'name' param should be a simple identifying name, and does
not have any functional use.

The compulsory 'uri' param should be a URL string to the PAR package.

Returns true on success or throws an exception on error.

=cut

sub install_par {
	my $self = shift;

	# Create Asset::Par object.
	my $par = Perl::Dist::WiX::Asset::PAR->new(
		parent => $self,

		# not supported at the moment:
		#install_to => 'c', # Default to the C dir
		@_,
	);

	my $filelist = $par->install();
	
	# TODO: Put in fragment.
	
	return $self;
} ## end sub install_par

=pod

=head2 install_file

  # Overwrite the CPAN::Config
  $self->install_file(
	  share      => 'Perl-Dist CPAN_Config.pm',
	  install_to => 'perl/lib/CPAN/Config.pm',
  );
  
  # Install a custom icon file
  $self->install_file(
	  name       => 'Strawberry Perl Website Icon',
	  url        => 'http://strawberryperl.com/favicon.ico',
	  install_to => 'Strawberry Perl Website.ico',
  );

The C<install_file> method is used to install a single specific file from
various sources into the distribution.

It is generally used to overwrite modules with distribution-specific
customisations, or to install licenses, README files, or other
miscellaneous data files which don't need to be compiled or modified.

It takes a variety of different params.

The optional 'name' param provides an optional plain name for the file.
It does not have any functional purpose or meaning for this method.

One of several alternative source methods must be provided.

The 'url' method is used to provide a fully-resolved path to the
source file and should be a fully-resolved URL.

The 'file' method is used to provide a local path to the source file
on the local system, and should be a fully-resolved filesystem path.

The 'share' method is used to provide a path to a file installed as
part of a CPAN distribution, and accessed via 
L<File::ShareDir|File::ShareDir>.

It should be a string containing two space-separated values, the first
of which is the distribution name, and the second is the path within
the share dir of that distribution.

The final compulsory method is the 'install_to' method, which provides
either a destination file path, or alternatively a path to an existing
directory that the file be installed below, using its source file name.

Returns the file installed as a L<File::List::Object|File::List::Object> 
or throws an exception on error.

=cut

sub install_file {
	my $self = shift;
	my $file = Perl::Dist::WiX::Asset::File->new(
		parent => $self,
		@_,
	);

	my $filelist = $file->install();
	
	return $filelist;
} ## end sub install_file

=pod

=head2 install_launcher

  $self->install_launcher(
	  name => 'CPAN Client',
	  bin  => 'cpan',
  );

The C<install_launcher> method is used to describe a binary program
launcher that will be added to the Windows "Start" menu when the
distribution is installed.

It takes two compulsory param.

The compulsory 'name' param is the name of the launcher, and the text
that label will be displayed in the start menu (Currently this only
supports ASCII, and is not language-aware in any way).

The compulsory 'bin' param should be the name of a .bat script launcher
in the Perl bin directory. The program itself MUST be installed before
trying to add the launcher.

Returns true or throws an exception on error.

=cut

sub install_launcher {
	my $self     = shift;
	my $launcher = Perl::Dist::WiX::Asset::Launcher->new(
		parent => $self,
		@_,
	);

	$launcher->install();

	return $self;
} ## end sub install_launcher

=pod

=head2 install_website

  $self->install_website(
	  name       => 'Strawberry Perl Website',
	  url        => 'http://strawberryperl.com/',
	  icon_file  => 'Strawberry Perl Website.ico',
	  icon_index => 1,
  );

The C<install_website> param is used to install a "Start" menu entry
that will load a website using the default system browser.

The compulsory 'name' param should be the name of the website, and will
be the labelled displayed in the "Start" menu.

The compulsory 'url' param is the fully resolved URL for the website.

The optional 'icon_file' param should be the path to a file that contains the
icon for the website.

The optional 'icon_index' param should be the icon index within the icon file.
This param is optional even if the 'icon_file' param has been provided, by
default the first icon in the file will be used.

Returns true on success, or throws an exception on error.

=cut

sub install_website {
	my $self    = shift;
	my $website = Perl::Dist::Asset::Website->new(
		parent => $self,
		@_,
	);

	$website->install();
	
	return $self;
} ## end sub install_website

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
