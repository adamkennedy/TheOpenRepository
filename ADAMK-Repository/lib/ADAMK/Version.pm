package ADAMK::Version;

use 5.008;
use strict;
use warnings;
use Perl::Version ();

our $VERSION = '0.11';
our @ISA     = 'Perl::Version';

sub clone {
	my $self = shift;
	return $self->new("$self");
}

sub next_stable {
	my $self = shift;
	my $new  = $self->clone;
	$new->inc_version;
	return $new;
}

sub next_developer {
	my $self = shift;
	my $new  = $self->clone;
	unless ( $new->alpha ) {
		# When moving to a new alpha, also move to a new version
		$new->inc_version;
	}
	$new->inc_alpha;
	return $new;
}

1;
