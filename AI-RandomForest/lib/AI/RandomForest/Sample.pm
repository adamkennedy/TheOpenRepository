package AI::RandomForest::Sample;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

1;
