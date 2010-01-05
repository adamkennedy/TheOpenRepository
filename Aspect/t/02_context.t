#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13;
use Aspect::AdviceContext;

my $runtime_context = { foo => 'FOO' };
my @params = qw(a b c);
my $subject = Aspect::AdviceContext->new(
	sub_name     => 'SOME_PACKAGE_ROOT::SOME_PACKAGE::SUB_NAME',
	type         => 'TYPE',
	pointcut     => 'POINTCUT',
	params       => \@params,
	return_value => 'RETURN_VALUE',
	%$runtime_context,
);

foreach ( qw( type pointcut return_value foo ) ) {
	is( $subject->$_, uc($_), $_ );
}

is(
	$subject->sub_name,
	'SOME_PACKAGE_ROOT::SOME_PACKAGE::SUB_NAME',
	'sub_name',
);
is(
	$subject->package_name,
	'SOME_PACKAGE_ROOT::SOME_PACKAGE',
	'package_name',
);
is( $subject->short_sub_name, 'SUB_NAME', 'short_sub_name' );

is_deeply( [$subject->params], [qw(a b c)], 'initial params' );
is( a => $subject->self, 'access 1st param' );

$subject->return_value('baz');
is( $subject->return_value, 'baz', 'set return_value' );

$subject->append_param('d');
is_deeply( [$subject->params], [qw(a b c d)], 'append_param' );

$subject->append_params('e', 'f');
is_deeply( [$subject->params], [qw(a b c d e f)], 'append_params' );

$subject->params(qw(x y z));
is_deeply( [$subject->params], [qw(x y z)], 'set params' );
