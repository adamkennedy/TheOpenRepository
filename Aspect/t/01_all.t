#!/usr/bin/perl

require 5.008;

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Carp;
use FindBin;
use lib ("$FindBin::Bin/../lib", "$FindBin::Bin/lib");
use Test::Class;
# use Test::NoWarnings;

$ENV{TEST_VERBOSE} = 0;

sub runtime_use {
	my $package = shift;
	eval "use $package;";
	croak "Cannot use [$package]: $@" if $@;
}

my @classes;

BEGIN {
	my @ALL_TESTS = qw(
 		Aspect::Pointcut::tests::Call
 		Aspect::Pointcut::tests::Cflow
 		Aspect::tests::AdviceContext
		Aspect::tests::Advice
 		Aspect::Library::tests::Singleton
 		Aspect::Library::tests::Wormhole
		Aspect::Library::tests::Listenable
	);

	my $thing = 'Aspect::'. ($ARGV[0] || '');
	$thing =~ s/(::)?([^:]+)?$/${
		\( $1 || '')
	}tests::${
		\( $2 || '')
	}/;

	@classes = $thing eq 'Aspect::tests::' ? @ALL_TESTS : ($thing);

	foreach my $class ( @classes ) {
		runtime_use($class);
	}
}

Test::Class->runtests(@classes);

1;

__END__

=pod

=head1 NAME

run_tests.pl - run Aspect unit tests

=head1 SYNOPSIS

  # run all tests
  perl run_tests.pl
  
  # a specific test case, no need to prefix with Aspect:: or add the tests:: part
  perl run_tests.pl Weaver
  perl run_tests.pl Pointcut::Call

=cut
