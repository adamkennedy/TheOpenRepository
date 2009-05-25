#!/usr/bin/perl

# This examples demonstrates the use of Perl::Metrics2
# alongside CPAN::Mini::Visit to scan all distributions
# released by a single CPAN author and analyze the contents.

use 5.008;
use strict;
use warnings;
use PPI::Cache path => 'G:\\cache\\PPI-Cache';
use Perl::Metrics2    ();
use CPAN::Mini::Visit ();

# Ensure we have a newer than normal ORLite
use ORLite 1.21 ();

# Boost the hell out of the SQLite cache
Perl::Metrics2->do('PRAGMA cache_size = 200000');

our $VERSION = '0.02';

my $author  = $ARGV[0] or die "Did not provide an author id";

my $metrics = Perl::Metrics2->new( study => 1 );
my $counter = 0;

Perl::Metrics2->begin;		
CPAN::Mini::Visit->new(
	minicpan => 'D:\\minicpan',
	acme     => 0,
	# author   => $author,
	ignore   => [ qr/PDF-API/ ],
	callback => sub {
		my $the = shift;
		$counter++;
		unless ( $counter % 100 ) {
			Perl::Metrics2->commit_begin;
		}
		print STDERR "# $counter - $the->{dist}\n";
		eval { # Ignore errors
			$metrics->index_distribution($the->{dist}, $the->{tempdir});
			$metrics->process_distribution($the->{tempdir});
		};
	},
)->run;
Perl::Metrics2->commit;
