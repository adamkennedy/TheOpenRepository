package Getopt::Config;

=pod

=head1 NAME

Getopt::Config - DWIM location (and optional loading) of config files

=head1 DESCRIPTION

A common pattern used in Perl scripts is the configuration file-driven
process.

A program is started which will run through a fixed processing path
and then exit. This processing is driven by a configuration file.

use strict;
use File::HomeDir ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

1;
