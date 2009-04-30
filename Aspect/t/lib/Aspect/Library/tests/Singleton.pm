package Aspect::Library::tests::Singleton;

use strict;
use warnings;
use Carp;
use Test::More;
use Aspect::Library::Singleton;

use base qw(Test::Class);

my $Demo_Class = 'Aspect_Library_Singleton_Foo';

sub aspect: Test {
	my $self = shift;

	my $aspect = Aspect::Library::Singleton->new
		("${Demo_Class}::new");

	my $foo1 = $Demo_Class->new;
	my $foo2 = $Demo_Class->new;
	is $foo1, $foo2, 'there can only be one';
}

# -----------------------------------------------------------------------------

package Aspect_Library_Singleton_Foo;

sub new { bless {}, shift };

1;

