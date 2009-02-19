package POE::Declare::Meta::Slot;

use 5.008007;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub name {
	$_[0]->{name};
}





#####################################################################
# Main Methods

# By default, a slot contains nothing
sub compile {
	return { package => '' };
}

1;
