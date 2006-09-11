package POE::Declare::Meta::Slot;

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
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
