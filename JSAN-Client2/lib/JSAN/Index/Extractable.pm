package ORDB::JSAN::Extractable;

# ORDB::JSAN::Extractable provides a common base class for the various
# things that can be identified by a tarball and extracted to the local
# filesystem (or elsewhere).
#
# For each of the methods, when called on a C<ORDB::JSAN::Release> it
# extracts that release, when called on a C<ORDB::JSAN::Distribution>
# extracts from the most recent release, and when call on a
# C<ORDB::JSAN::Library> extracts the release that the library is
# contained in (according to the indexer).

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.16';
}

sub extract_libs {
	my $self = shift;
	$self->extract_resource('lib', @_);
}

sub extract_tests {
	my $self = shift;
	$self->extract_resource('tests', @_);
}

sub extract_resource {
	my $class = ref $_[0] || $_[0];
	Carp::croak("$class does not implement method 'extract_resource'");
}

1;
