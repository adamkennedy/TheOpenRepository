package Perl::Dist::WiX::Asset::Launcher;

use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str );
use File::Spec::Functions qw( catfile );
use Perl::Dist::WiX::Exceptions;

our $VERSION = '1.102';
$VERSION =~ s/_//ms;

with 'Perl::Dist::WiX::Role::NonURLAsset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_name',
	required => 1,
);

has bin => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_bin',
	required => 1,
);

sub install {
	my $self = shift;

	my $bin = $self->_get_bin();

	# Check the script exists
	my $to =
	  catfile( $self->_get_image_dir(), 'perl', 'bin', $bin . '.bat' );
	unless ( -f $to ) {
		PDWiX->throw(qq{The script "$bin" does not exist});
	}

	my $icons     = $self->_get_icons();
	my $icon_type = ref $icons;
	$icon_type ||= 'undefined type';
	if ( 'Perl::Dist::WiX::IconArray' ne $icon_type ) {
		PDWiX->throw(
"Icons array is of type $icon_type, not a Perl::Dist::WiX::IconArray"
		);
	}

	my $icon_id =
	  $self->_get_icons()
	  ->add_icon( catfile( $self->_get_dist_dir(), "$bin.ico" ),
		"$bin.bat" );

	# Add the icon.
	$self->_add_icon(
		name     => $self->get_name(),
		filename => $to,
		fragment => 'StartMenuIcons',
		icon_id  => $icon_id
	);

	return 1;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Launcher - Start menu launcher asset for a Win32 Perl

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Launcher->new(
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
