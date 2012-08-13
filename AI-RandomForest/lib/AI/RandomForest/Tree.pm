package AI::RandomForest::Tree;

use strict;
use warnings;
use Params::Util ();
use Object::Tiny qw{
	root
};

our $VERSION = '0.01';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	return $self;
}





######################################################################
# Main Methods

sub resolve {
	my $self   = shift;
	my $sample = shift;
	my $cursor = $self->root or die "No root branch";

	while ($cursor) {
		if ( $sample->[ $cursor->{variable} ] > $cursor->{separator} ) {
			$cursor->{nright}++;
			$cursor = $cursor->{right};
		} else {
			$cursor->{nleft}++;
			$cursor = $cursor->{left};
		}
		next if Params::Util::_INSTANCE($cursor, 'AI::RandomForest::Branch');
		return $cursor;
	}
}

1;
