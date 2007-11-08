package t::lib::Bootstrap;

use strict;
use base 'Perl::Dist::Bootstrap';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub trace { Test::More::diag($_[1]) }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

sub install_perl_588 {
	return shift->SUPER::install_perl_588( @_, trace => sub { 1 } );
}

sub install_distribution {
	return shift->SUPER::install_distribution( @_, trace => sub { 1 } );
}

sub install_file {
	return shift->SUPER::install_file( @_, trace => sub { 1 } );
}

1;
