package Aspect::Library::tests::Wormhole;

use strict;
use warnings;
use Carp;
use Test::More;
use Aspect::Library::Wormhole;

use base qw(Test::Class);

my $Demo_Prefix = 'Aspect_Library_Wormhole_';

sub aspect: Test {
	my $self = shift;

	my $aspect = Aspect::Library::Wormhole->new
		("${Demo_Prefix}A::a", "${Demo_Prefix}C::c");

	my $a = "${Demo_Prefix}A"->new;
	is $a->a, $a, 'C::c returns instance of calling A';
}

# -----------------------------------------------------------------------------

package Aspect_Library_Wormhole_A;
sub new { bless {}, shift }
sub a { "${Demo_Prefix}B"->b }

package Aspect_Library_Wormhole_B;
sub b { "${Demo_Prefix}C"->c }

package Aspect_Library_Wormhole_C;
sub c { pop }

1;

