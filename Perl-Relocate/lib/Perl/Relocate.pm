package Perl::Relocate;

=pod

=head1 NAME

Perl::Relocate - Move the perl installation from one place to another

=head1 DESCRIPTION

As of Perl 5.10.0, Perl is officially "relocatable".

That is, it supports moving the Perl binary from one place to another.

This SHOULD enable such things as "portable" installs onto memory sticks,
and allowing for arbitrary installation paths on Win32.

Unfortunately, not everything is completely straight forward.

A number of confiruation-type files continue to record the "current"
installation path in explicit form, and will break things when the
installation is moved, even if the perl binary itself support the move.

Various hand-written or product-specific (such as the ActivePerl-specific
reloc_perl.bat) exist to fix this, but the solutions have not previously
existed in a generic and reusable form.

B<Perl::Relocate> was created specifically to distill and encapsulate
the methodology for moving a perl install from one place to another,
and for correcting a perl installation that has been relocated due to
circumstances outside the control of B<Perl::Relocate> (for example the
volume (Win32) or mount point (Unix) can change arbitrary at any time
without the physical location of the Perl install itself changing.

Although it is being created primarily for the use of Vanilla/Strawberry
Perls, it is being done in a way that allows Vanilla/Strawberry to
retain their policy of not using any product-specific code that is not
available to the general Perl community.

It is also hoped that in time the number of changes that need to be made
can be reduced by making changes to these config files to pull paths from
implicitly-derived paths instead of storing them explicitly.

If and when these changes occur, Perl::Relocate will serve as a central
repository of knowledge on what should be changed and when for various
versions of Perl.

=head2 Assumptions

Currently, this module assumes a Perl distribution is installed under a
single root path. It does not assume that the distribution root path and
the perl root path are identical, allowing support for distribution
layouts from the Vanilla Perl family.

This module assumes Windows-style limitations on file locking. As a result,
it will aggressively avoid loading any of the modules that it needs to
modify (Config.pm, Config_heavy.pl, CPAN/Config.pm being the primary files).

=head1 METHODS

=cut

use 5.010;
use strict;

# Any modules we use must NOT use Config or CPAN::Config
use File::Spec ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}

use Object::Tiny qw{
	from
	to
	perl
	bin
	exe
};





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Do we have from and to locations
	unless ( $self->from ) {
		die "Missing or invalid 'from' path";
	}
	unless ( $self->to ) {
		die "Missing or invalid 'to' path";
	}

	# Which path do we use to scan for auto-detected relative sub-paths
	my $scan_root;
	if ( -d $self->from ) {
		$scan_root = $self->from;
	} elsif ( -d $self->to ) {
		$scan_root = $self->to;
	} else {
		die "Neither the 'from' or 'to' paths exist";
	}

	# Look for the perl executable
	# This is completely Vanilla-specific, but will suffice for the
	# first development release.
	if ( -e File::Spec->catfile( $scan_root, "perl\\bin\\perl.exe" ) ) {
		$self->{perl} = "perl";
		$self->{bin}  = "perl\\bin";
		$self->{exe}  = "perl\\bin\\perl.exe";
	} else {
		die "Failed to auto-locate the Perl executable";
	}

	$self;
}





#####################################################################
# Main Methods

1;

=pod

=head1 TO DO

- Write the implementation

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Relocate>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://win32.perl.org/>, L<http://strawberryperl.org/>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
