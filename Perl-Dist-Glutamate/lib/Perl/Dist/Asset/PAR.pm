package Perl::Dist::Asset::PAR;
use strict;

=pod

=head1 NAME

Perl::Dist::Asset::PAR - "Binary .par package" asset for a Win32 Perl

=head1 SYNOPSIS

  my $binary = Perl::Dist::Asset::PAR->new(
      name       => 'dmake',
  );
  
  # Or usually more like this:
  $perldistinno->install_par(
    name => 'Math::Symbolic',
    url => 'http://foo/Math-Symbolic-0.510-MSWin32-x86-multi-thread-5.10.0.par',
  );

=head1 DESCRIPTION

B<Perl::Dist::Asset::PAR> is a data class that provides encapsulation
and error checking for a "binary .par package" to be installed in a
L<Perl::Dist>-based Perl distribution.

It is normally created on the fly by the L<Perl::Dist::Inno> C<install_par>
method (and other things that call it). The C<install_par> routine
is currently implemented in this file and monkey-patched into
L<Perl::Dist::Inno> namespace. This will hopefully change in future.

The specification of the location to retrieve the package is done via
the standard mechanism implemented in L<Perl::Dist::Asset>.

=head1 METHODS

This class inherits from L<Perl::Dist::Asset> and shares its API.

=cut

package Perl::Dist::Inno;
sub install_par {
	my $self   = shift;
	require PAR::Dist;
	#require ExtUtils::InferConfig;

	my $par = Perl::Dist::Asset::PAR->new(
		parent     => $self,
		install_to => 'c', # Default to the C dir
		@_,
	);

	my $name = $par->name;
	$self->trace("Preparing $name\n");

	#my $Config = ExtUtils::InferConfig->new(
	#  perl => File::Spec->catdir($self->image_dir, 'perl', 'bin', 'perl'),
	#)->get_config;

	# set the appropriate installation paths
	my $perldir  = File::Spec->catdir($self->image_dir, 'perl');
	my $man1dir  = File::Spec->catdir($perldir, 'man1');
	my $man3dir  = File::Spec->catdir($perldir, 'man3');

	for ($man1dir, $man3dir) {
		mkdir($_) if not -d $_;
	}

	my $libdir = File::Spec->catdir($perldir, 'site', 'lib');
	my $bindir = File::Spec->catdir($perldir, 'bin');
	my $no_colon_name = $name;
	$no_colon_name =~ s/::/-/g;
	my $packlist = File::Spec->catfile($libdir, $no_colon_name, '.packlist');

	# install
	PAR::Dist::install_par(
		dist           => $par->url,
		inst_lib       => $libdir,
		inst_archlib   => $libdir,
		inst_bin       => $bindir,
		inst_script    => $bindir,
		inst_man1dir   => $man1dir, # shouldn't be there at all, undef not supported by PAR::Dist yet
		inst_man3dir   => $man3dir, # shouldn't be there at all, undef not supported by PAR::Dist yet
		packlist_read  => $packlist,
		packlist_write => $packlist,
	);

	return 1;
}


package Perl::Dist::Asset::PAR;

use strict;
use Carp           'croak';
use Params::Util   qw{ _STRING _HASH };
use base 'Perl::Dist::Asset';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}

use Object::Tiny qw{
	name
};





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::Asset::PAR> object.

It inherits all the params described in the L<Perl::Dist::Asset> C<new>
method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the logical (arbitrary) name of the package
for the purposes of identification. A sensible default would be the name of
the primary Perl module in the package.

=back

The C<new> constructor returns a B<Perl::Dist::Asset::PAR> object,
or throws an exception (dies) if an invalid param is provided.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Missing or invalid name param");
	}

	return $self;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Asset-PAR>

For other issues, contact the author.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<Perl::Dist::Asset>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Steffen Mueller, borrowing heavily from
Adam Kennedy's code.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
