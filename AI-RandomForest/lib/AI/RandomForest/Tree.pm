package AI::RandomForest::Tree;

use strict;
use warnings;
use Object::Tiny qw{
	root
	left
	right
};

our $VERSION = '0.01';

sub resolve {
	my $self   = shift;
	my $sample = shift;
	unless ( $self->root ) {
		die "No root branch";
	}

	my $cursor = $self->root;
	while ($cursor) {
		if ( $sample->[ $cursor->variable ] > $cursor->greater ) {
			$cursor = $cursor->right or return $self->right;
		} else {
			$cursor = $cursor->left or return $self->left;
		}
	}
}

1;
