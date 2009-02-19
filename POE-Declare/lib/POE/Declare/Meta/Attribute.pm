package POE::Declare::Meta::Attribute;

use 5.008007;
use strict;
use POE::Declare::Meta::Slot ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'POE::Declare::Meta::Slot';
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
