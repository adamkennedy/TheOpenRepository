package Perl::Dist::WiX::Asset::DistBase;

use 5.008001;
use Moose;
use File::Spec::Functions qw( catdir catfile );
use Params::Util qw ( _INSTANCE );

require URI;
require File::Spec::Unix;

our $VERSION = '1.090_102';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)

sub _configure {
	my $self    = shift;
	my $buildpl = shift;
	my $name    = $self->get_name();

	$self->_trace_line( 2, "Configuring $name...\n" );
	$buildpl
	  ? $self->_perl( 'Build.PL',    @{ $self->_get_buildpl_param } )
	  : $self->_perl( 'Makefile.PL', @{ $self->_get_makefilepl_param } );

	return;
} ## end sub _configure

sub _install_distribution {
	my $self    = shift;
	my $buildpl = shift;
	my $name    = $self->get_name();

	$self->_trace_line( 1, "Building $name...\n" );
	$buildpl ? $self->_build() : $self->_make();

	unless ( $self->_get_force() ) {
		$self->_trace_line( 2, "Testing $name...\n" );
		$buildpl ? $self->_build('test') : $self->_make('test');
	}

	$self->_trace_line( 2, "Installing $name...\n" );
	$buildpl
	  ? $self->_build(qw/install uninst=1/)
	  : $self->_make(qw/install UNINST=1/);

	return;
} ## end sub _install_distribution

sub _name_to_module {
	my $self = shift;
	my $dist = shift;

	$self->_trace_line( 3, "Trying to get module name out of $dist\n" );

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
	my $self      = shift;
	my $image_dir = $self->_get_image_dir();

	my $perl_dir = catdir( $image_dir, 'perl' );
	my @dirs = (
		catdir( $image_dir, qw( perl vendor lib Module ) ),
		catdir( $image_dir, qw( perl site lib Module ) ),
		catdir( $image_dir, qw( perl lib Module ) ),
	);

	foreach my $dir (@dirs) {
		return 1 if -f catfile( $dir, 'Build.pm' );
	}

	return 0;
} ## end sub _module_build_installed

#####################################################################
# Main Methods

sub _abs_uri {
	my $self = shift;

	# Get the base path
	my $cpan = _INSTANCE( $self->_get_cpan(), 'URI' );
	unless ($cpan) {
		PDWiX::Parameter->throw("Did not get a cpan URI\n");
	}

	# Generate the full relative path
	my $name = $self->get_name();
	my $path = File::Spec::Unix->catfile(
		'authors', 'id',
		substr( $name, 0, 1 ),
		substr( $name, 0, 2 ), $name,
	);

	my $answer = URI->new_abs( $path, $cpan );
	$self->_set_url( $answer->as_string() );
	return $answer;
} ## end sub _abs_uri

#####################################################################
# Support Methods

sub _DIST {
	my $it = shift;
	unless ( defined $it and not ref $it ) {
		return undef;
	}
	unless ( $it =~ q|^([A-Z]){2,}/| ) {
		return undef;
	}
	return $it;
}

1;

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Asset::DistBase - Support routines for distribution assets.

=head1 SYNOPSIS

	# Not to be used independently.

=head1 DESCRIPTION

This module provides support routines that 
L<Perl::Dist::WiX::Asset::Distribution|Perl::Dist::WiX::Asset::Distribution> 
and L<Perl::Dist::WiX::Asset::DistFile|Perl::Dist::WiX::Asset::DistFile> 
both use.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>, 
L<Perl::Dist::WiX::Asset::Distribution|Perl::Dist::WiX::Asset::Distribution>,
and L<Perl::Dist::WiX::Asset::DistFile|Perl::Dist::WiX::Asset::DistFile> 

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
