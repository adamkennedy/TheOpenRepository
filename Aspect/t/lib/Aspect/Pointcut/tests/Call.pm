package Aspect::Pointcut::tests::Call;

use strict;
use warnings;
use Carp;
use Test::More;
use Aspect::Pointcut::Call;

use base qw(Test::Class);

my ($good_method, $bad_method) =	qw(
	SomePackage::some_method
	SomePackage::no_method
);

sub match_define: Test(6) {
	my $self = shift;
	$self->pointcut_ok(
		string => 'SomePackage::some_method',
		re     => qr/some_method/,
		code   => sub { shift eq $good_method },
	);
}

sub pointcut_ok {
	my ($self, %assertions) = @_;
	for my $type (keys %assertions) {
		my $subject = Aspect::Pointcut::Call->new($assertions{$type});
		ok $subject->match_define($good_method), "$type match";
		ok !$subject->match_define($bad_method), "$type no match";
	}
}

1;

