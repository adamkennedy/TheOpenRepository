package Aspect::tests::Weaver;

use strict;
use warnings;
use Carp;
use Test::More;
use Aspect::Weaver;

use base qw(Test::Class);

my $Demo_Class = 'Aspect_Weaver_Foo';

sub setup: Test(setup) { shift->{subject} = Aspect::Weaver->new }

sub get_sub_names: Test(4) {
	my $self    = shift;
	my $subject = $self->{subject};
	my %names   = map { $_ => 1 } $subject->get_sub_names;
	ok $names{"${Demo_Class}::new"}, 'new';
	ok $names{"${Demo_Class}::foo"}, 'foo';
	ok !$names{'NonExisingClass::non_existing_method'}, 'non existing';
	ok !$names{'Aspect::Weaver::install'}, 'Aspect package method';
}

sub install {
	my $self    = shift;
	my $subject = $self->{subject};
	my $foo     = $Demo_Class->new;

	is $foo->foo(2), 3, 'not yet installed';

	{
		my $hook1 = $subject->install(before =>
			"${Demo_Class}::foo", sub { splice @{$_[0]}, 1, 1, $_[0]->[1] + 1 }
		);
		is $foo->foo(2), 4, 'pre increase second parameter';

		my $hook2 = $subject->install(after =>
			"${Demo_Class}::foo", sub { $_[-1]++ }
		);
		is $foo->foo(2), 5, 'post increase return value';
	}

	is $foo->foo(3), 4, 'now uninstalled';
}

# -----------------------------------------------------------------------------

package Aspect_Weaver_Foo;

sub new { bless {}, shift }

sub foo { $_[1] + 1 }

1;

