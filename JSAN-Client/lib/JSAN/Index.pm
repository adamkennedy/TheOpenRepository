package JSAN::Index;

=pod

=head1 NAME

JSAN::Index - JavaScript Archive Network (JSAN) SQLite/CDBI Index

=head1 DESCRIPTION

JSAN is the JavaScript Archive Network, a port of CPAN to JavaScript.

You can find the JSAN at L<http://openjsan.org>.

As well as a flat text file index like CPAN, the JSAN index is also
distributed as a L<DBD::SQLite> database.

C<JSAN::Index> is a L<Class::DBI> wrapper built around the JSAN
SQLite index.

It allow you to easily do all sorts of nifty things with the index in a
simple and straight forward way.

=head2 Using The JSAN Index / Terminology

Once loaded, most of the functionality of the index is accessed through
the classes that implement the various objects in the index.

These are:

=over 4

=item L<JSAN::Index::Author>

An author is a single human (or under certain very special circumstances
a company or mailing list) that creates distributions and uploads them
to the JSAN.

=item L<JSAN::Index::Distribution>

A distribution is a single software component that may go through a number
of releases

=item L<JSAN::Index::Release>

A release is a compressed archive file containing a single version of a
paricular distribution.

=item L<JSAN::Index::Library>

A library is a single class, or rather a "pseudo-namespace", that
defines an interface to provide some functionality. Distributions often
contain a number of libraries, making up a complete "API".

=back

=head1 METHODS

There are only a very limited number of utility methods available
directly from the C<JSAN::Index> class itself.

=cut

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.13';
}

# Load the components
use JSAN::Index::CDBI         ();
use JSAN::Index::Extractable  ();
use JSAN::Index::Author       ();
use JSAN::Index::Distribution ();
use JSAN::Index::Release      ();
use JSAN::Index::Library      ();





#####################################################################
# Top-level Methods

=pod

=head2 dependency param => $value

The C<dependency> method creates and returns an dependency resolution 
object that is used by L<JSAN::Client> to schedule which releases to
install.

If the optional parameter 'build' is true, creates a build-time
dependency resolve, which will additionally install releases only needed
for testing.

Returns an L<Algorithm::Dependency> object.

=cut

sub dependency {
	my $class  = shift;
	JSAN::Index::Release::_Dependency->new( @_ );
}





#####################################################################
# Private Classes

# Algorithm::Dependency::Ordered for the ::Release data

package JSAN::Index::Release::_Dependency;

use Params::Util '_INSTANCE';

use base 'Algorithm::Dependency::Ordered';

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my %params = @_;

	# Apply defaults
	$params{source} ||= JSAN::Index::Release::_Source->new( %params );

	# Hand off to superclass constructor
	my $self = $class->SUPER::new( %params )
		or Carp::croak("Failed to create JSAN::Index::Release::_Dependency object");

	# Save the type for later
	$self->{build} = !! $params{build};

	$self;
}

sub build { $_[0]->{build} }

sub schedule {
	my $self     = shift;
	my @schedule = @_;

	# Convert things in the schedule from index objects to
	# release source strings as needed
	my @cleaned = ();
	foreach my $item ( @schedule ) {
		if ( defined $item and ! ref $item and $item =~ /^(?:\w+)(?:\.\w+)*$/ ) {
			$item = JSAN::Index::Library->retrieve( name => $item );
		}
		if ( _INSTANCE($item, 'JSAN::Index::Library') ) {
			$item = $item->release;
		}
		if ( _INSTANCE($item, 'JSAN::Index::Release') ) {
			$item = $item->source;
		}
		push @cleaned, $item;
	}

	$self->SUPER::schedule(@cleaned);
}

# Algorithm::Dependency::Source for the ::Release data

package JSAN::Index::Release::_Source;

use Algorithm::Dependency::Item ();
use base 'Algorithm::Dependency::Source';

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my %params = @_;

	# Create the basic object
	my $self = $class->SUPER::new();

	# Set the methods to use
	$self->{requires_releases} = 1;
	if ( $params{build} ) {
		$self->{build_requires_releases} = 1;
	}

	$self;
}

sub _load_item_list {
	my $self = shift;

	### FIXME: This is crudely effective, but a little innefficient.
	###        Later, we should be able to determine which subset of
	###        these can never be called, and leave them out of the list.

	# Get every single release in the index
	my @releases = JSAN::Index::Release->retrieve_all;

	# Wrap the releases in the Adapter objects
	my @items  = ();
	foreach my $release ( @releases ) {
		my $id      = $release->source;

		# Get the list of dependencies
		my @depends = ();
		if ( $self->{requires_releases} ) {
			push @depends, $release->requires_releases;
		}
		if ( $self->{build_requires_releases} ) {
			push @depends, $release->build_requires_releases;
		}

		# Convert to a distinct source list
		my %seen = ();
		@depends = grep { ! $seen{$_} } map { $_->source } @depends;

		# Add the dependency
		my $item = Algorithm::Dependency::Item->new( $id => @depends )
			or die "Failed to create Algorithm::Dependency::Item";
		push @items, $item;
	}

	\@items;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Client>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
