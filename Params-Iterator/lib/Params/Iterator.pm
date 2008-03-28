use Params::Iterator;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless {
		'-state' => [],
		'-order' => [],
	}, $class;
	return $self;
}

1;
