package PITA::Guest::Server::Process;

# A Process.pm compatible wrapper around PITA::Guest::Server

use 5.008;
use strict;
use Process             ();
use PITA::Guest::Server ();

our $VERSION = '0.50';
our @ISA     = 'Process';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

1;
