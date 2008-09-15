package Getopt::Intuit;

=pod

=head1 NAME

Getopt::Find::Local - DWIM location (and optional loading) of config files

=head1 DESCRIPTION

A common pattern used in Perl scripts is the configuration file-driven
process.

A program is started which will run through a fixed processing path
and then exit. This processing is driven by a configuration file.

In order to make the use of the program as simple as possible, it is
possible to describe a series of rules that will allow the program
to intuit the location of the controlling configuration file.



use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

1;
