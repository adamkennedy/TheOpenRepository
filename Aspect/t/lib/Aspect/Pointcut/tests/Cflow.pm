package Aspect::Pointcut::tests::Cflow;

use strict;
use warnings;
use Carp;
use Test::More;
use Aspect::Pointcut::Cflow;

use base qw(Test::Class);

my $Demo_Class = 'Aspect_Pointcut_Cflow_Foo';

sub make_subject { Aspect::Pointcut::Cflow->new(some_key => pop) }

sub match_run: Test(3) {
	my $self = shift;
	my $sub_name = "${Demo_Class}::sub_to_match";
	my $subject = $self->make_subject($sub_name);
	my ($match, $runtime_context) =
		$Demo_Class->new->sub_to_match($subject);
	my $context = $runtime_context->{some_key};

	ok $match, 'match';
	is $context->sub_name, $sub_name, 'sub_name';
	is ref $context->self, $Demo_Class, 'self';
}

# -----------------------------------------------------------------------------

package Aspect_Pointcut_Cflow_Foo;

sub new { bless {}, shift };

sub sub_to_match { shift->foo(pop) }

sub foo {
	my ($self, $subject) = @_;
	my $runtime_context = {};
	my $match = $subject->match_run(foo => $runtime_context);
	return ($match, $runtime_context);
}

1;



