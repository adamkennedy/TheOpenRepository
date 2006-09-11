package POE::Declare::Meta::Attribute;

use strict;
use base 'POE::Declare::Meta::Slot';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Main Methods

sub compile {
	my $self = shift;
	my $code = {
		package => $self->compile_package,
		};
	return $code;	
}

sub compile_package { return <<"END_PERL" }
sub $_[0]->{name} {
	\$_[0]->{$_[0]->{name}};
}
END_PERL

1;
