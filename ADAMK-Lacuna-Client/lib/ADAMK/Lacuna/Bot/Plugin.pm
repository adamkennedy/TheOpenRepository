package ADAMK::Lacuna::Bot::Plugin;

use 5.008;
use strict;
use warnings;
use Params::Util ();

our $VERSION = '0.01';

sub new {
  my $class = shift;
  my $param = shift;
  if ( Params::Util::_HASH0($param) ) {
    return bless { %$param }, $class;
  } elsif ( Params::Util::_ARRAY0($param) ) {
    return bless { @$param }, $class;
  } else {
    return bless { }, $class;
  }
}

# Stub
sub run {
  return 1;
}

1;
