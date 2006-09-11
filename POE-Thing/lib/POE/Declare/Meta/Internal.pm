package POE::Declare::Meta::Internal;

use strict;
use base 'POE::Declare::Meta::Attribute';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self;
}

sub name {
	$_[0]->{name};
}





#####################################################################
# Main Methods

sub compile {
	my $self = shift;
	my $code = {
		package => '',
		};
	return $code;
}

1;
