#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Aspect;

my $sub_name = "My::Cflow::sub_to_match";
my $subject  = Aspect::Pointcut::Cflow->new( some_key => $sub_name );
my ($match, $runtime_context) =
	My::Cflow->new->sub_to_match($subject);
my $context = $runtime_context->{some_key};

ok( $match, 'match' );
is( $context->sub_name, $sub_name, 'sub_name' );
is( ref $context->self, 'My::Cflow', 'self' );

# -----------------------------------------------------------------------------

package My::Cflow;

sub new { bless {}, shift };

sub sub_to_match { shift->foo(pop) }

sub foo {
	my ($self, $subject) = @_;
	my $runtime = {
		sub_name => 'foo',
	};
	my $match = $subject->match_run($runtime);
	return ($match, $runtime);
}
