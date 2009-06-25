#!/usr/bin/perl

# This examples demonstrates the use of Perl::Metrics2
# alongside CPAN::Mini::Visit to scan all distributions
# released by a single CPAN author and analyze the contents.

use 5.008;
use strict;
use warnings;
use PPI::Cache path => 'G:\\cache\\PPI-Cache';
use CPAN::Mini::Visit      ();
use File::Find::Rule       ();
use File::Find::Rule::VCS  ();
use File::Find::Rule::Perl ();

our $VERSION = '0.01';

my $counter = 0;

CPAN::Mini::Visit->new(
	minicpan => 'G:\\minicpan',
	acme     => 0,
	# author   => $author,
	ignore   => [ qr/PDF-API/ ],
	callback => sub {
		my $the = shift;
		$counter++;
		print STDERR "# $counter - $the->{dist}\n";
		my @files = File::Find::Rule->ignore_svn->perl_test->in($the->{tempdir});
		foreach my $file ( @files ) {
			print "# $file\n";
			eval {
				PPI::Document->new($file);
			};
		};
	},
)->run;
