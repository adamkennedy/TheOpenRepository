package PPI::Cache::Archive;

use 5.008;
use strict;
use PPI::Cache            1.203 ();
use File::Find::Rule       0.30 ();
use File::Find::Rule::VCS  1.05 ();
use File::Find::Rule::Perl 1.06 ();

our $VERSION = '0.01';

sub create {
	my $archive = shift;
	my $cache   = shift;

	# Scan the cache for documents
	my @files   = File::Find::Rule->ignore_svn->

}

sub extract {
	my $archive = shift;
	my $cache   = shift;

}

1;
