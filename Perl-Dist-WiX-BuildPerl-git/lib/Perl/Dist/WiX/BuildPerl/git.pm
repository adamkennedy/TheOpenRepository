package Perl::Dist::WiX::BuildPerl::git;

=pod

=begin readme text

Perl::Dist::WiX::BuildPerl::git version 1.250_100

=end readme

=for readme stop

=head1 NAME

Perl::Dist::WiX::BuildPerl::git - Files and code for building Perl from a git checkout

=head1 VERSION

This document describes Perl::Dist::WiX::BuildPerl::git version 1.250_100.

=head1 DESCRIPTION

This module provides the routines and files that Perl::Dist::WiX uses in 
order to build Perl itself.  

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will require a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.

=head1 INTERFACE

=cut

use 5.010;
use Moose::Role;
use File::ShareDir qw();
use Perl::Dist::WiX::Asset::Perl qw();
use Perl::Dist::WiX::Exceptions;

our $VERSION = '1.250_100';
$VERSION =~ s/_//sm;

with 'Perl::Dist::WiX::Role::GitPlugin';

#####################################################################
# Perl installation support

=head2 install_perl_plugin

This routine is called by the 
C<install_perl|Perl::Dist::WiX::BuildPerl/install_perl> task, and installs
a git checkout of perl.

=cut



around '_install_perl_plugin' => sub {
	shift;
	my $self = shift;

	# Check for an error in the object.
	if ( not $self->bin_make() ) {
		PDWiX->throw('Cannot build Perl yet, no bin_make defined');
	}

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Get where the git checkout is.
	my $checkout = $self->git_checkout();

	# Install perl.
	my $perl = Perl::Dist::WiX::Asset::Perl->new(
		parent    => $self,
		url       => URI::file->new($checkout)->as_string(),
		file      => $checkout,
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config_sh.PL
			  win32/config_H.gc
			  }
		],
		license => {
			'perl-git/Readme'   => 'perl/Readme',
			'perl-git/Artistic' => 'perl/Artistic',
			'perl-git/Copying'  => 'perl/Copying',
		},
		git => $self->git_describe(),		
	);
	$perl->install();

	return 1;
}; ## end sub install_perl_plugin



around '_find_perl_file' => sub {
	my $orig = shift;
	my $self = shift;
	my $file = shift;
	
	my $location = undef;
	
	$location = eval { 
		File::ShareDir::module_file('Perl::Dist::WiX::BuildPerl::git', "default/$file");
	};
	
	if ($location) {
		return $location;
	} else {
		return $self->$orig($file);
	}
};



# Set the things that are defined by the perl version.

has 'perl_version_literal' => (
	is       => 'ro',
	init_arg => undef,
	default => '5.013004',
);

has 'perl_version_human' => (
	is       => 'ro',
	writer   => '_set_perl_version_human',
	init_arg => undef,
	default => 'git',
);

has '_perl_version_arrayref' => (
	is       => 'ro',
	init_arg => undef,
	default => sub {[5, 13, 4]},
);

# For git, this is the same as _perl_version_arrayref.
has '_perl_bincompat_version_arrayref' => (
	is       => 'ro',
	init_arg => undef,
	default => sub {[5, 13, 4]},
);

# I'll be updating this soon with a better snapshot,
# so for now, it's unknown.
has '_is_git_snapshot' => (
	is       => 'ro',
	init_arg => undef,
	default => 'unknown',
);

no Moose::Role;
1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=for readme continue

=head1 DEPENDENCIES

This module requires perl 5.10, L<Perl::Dist::WiX|Perl::Dist::WiX> 
version 1.250_001 or better, L<Moose|Moose> 1.09 or better, and 
L<File::ShareDir|File::ShareDir> 1.02 or better.

=for readme stop

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
