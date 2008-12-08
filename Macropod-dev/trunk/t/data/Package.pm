package t::data::Package;
require Exporter;
@ISA = qw(Exporter);
use strict;
use warnings;
use Carp qw( confess );
use vars qw( $VERSION @EXPORT @MacropodInfo );
@EXPORT = qw( @MacropodInfo );





sub funcScalar ($) {

}

sub funcList (@) {

}

sub funcHash (%) {

}

sub funcManyProto ($&%) {

}


sub funcPlain {
  my ($name,$var) = @_;

}

sub method1 {
  my ($self) = @_;
  
  my $cb = sub {
    my $result = shift;
    
  }

}



sub methodOverLoad {
  my ($self) = shift;
  $self->SUPER::methodOverLoad( @_ );

}


1;
