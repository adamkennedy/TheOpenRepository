#!/usr/bin/perl

# This examples demonstrates the use of Perl::Metrics2
# alongside CPAN::Mini::Visit to scan all distributions
# released by a single CPAN author and analyze the contents.

use 5.008;
use strict;
use warnings;
use Perl::Metrics2    ();
use CPAN::Mini::Visit ();

# Boost the hell out of the SQLite cache
Perl::Metrics2->do('PRAGMA cache_size = 200000');

our $VERSION = '0.02';

my $author = $ARGV[0] or die "Did not provide an author id";

my $metrics = Perl::Metrics2->new( study => 1 );
my $counter = 0;

CPAN::Mini::Visit->new(
	root     => 'D:\\minicpan',
	acme     => 0,
	author   => $author,
	callback => sub {
		$counter++;
		print STDERR "# $counter - $_[0]\n";
		Perl::Metrics2->begin;		
		eval { # Ignore errors
			$metrics->process_distribution($_[2]);
			Perl::Metrics2->index_distribution(
			Perl::Metrics2->process_distribution($_[2]);
		};
		Perl::Metrics2->commit;
	},
)->run;
