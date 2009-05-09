#!/usr/bin/perl

# This examples demonstrates the use of Perl::Metrics2
# alongside CPAN::Mini::Visit to scan all distributions
# released by a single CPAN author and analyze the contents.

use 5.008;
use strict;
use warnings;
use Perl::Metrics2    ();
use CPAN::Mini::Visit ();

my $author = $ARGV[0] or die "Did not provide an author id";

CPAN::Mini::Visit->new(
	root     => 'D:\\minicpan',
	acme     => 0,
	author   => $author,
	callback => sub {
		print STDERR "# $_[0]\n";
		eval { # Ignore errors
			Perl::Metrics2->index_distribution(
			Perl::Metrics2->process_distribution($_[2]);
		};
	},
)->run;
