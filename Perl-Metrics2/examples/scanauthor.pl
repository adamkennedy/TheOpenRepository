#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Perl::Metrics2    ();
use CPAN::Mini::Visit ();
# use Aspect::Library::Trace qr/^Perl::Metrics2::\w+/;

our $VERSION = '0.02';

my $author = $ARGV[0] or die "Did not provide an author id";

CPAN::Mini::Visit->new(
	root     => 'D:\\minicpan',
	acme     => 0,
	# author   => $author,
	callback => sub {
		print STDERR "# $_[0]\n";
		eval { # Ignore errors
			Perl::Metrics2->process_distribution($_[2]);
		};
	},
)->run;
