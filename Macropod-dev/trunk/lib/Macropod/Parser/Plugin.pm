package Macropod::Parser::Plugin;

use strict;
use warnings;

use Carp qw( confess );


sub new {
  my ($plugin,%args) = @_;
  return bless \%args, $plugin;
}

sub warning {
  my ($plugin,@message) = @_;
  $plugin->{parser}->warning( $_ ) for @message;
}

sub parse {
  confess __PACKAGE__ . ' plugins MUST override ->parse';
 
}


1;

