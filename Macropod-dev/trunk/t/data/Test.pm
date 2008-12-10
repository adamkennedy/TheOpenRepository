package t::data::Test;
use strict;
use warnings;
use Carp qw( confess cluck );
use vars '$VERSION', '@EXPORT',  '@MacropodInfo' ;
use base qw( Test::More );
use Module::Foo;

*bar = \&Module::Foo::bar;

=pod

=head1 funcScalar

twiddle something on this scalar

=cut

sub funcScalar ($) {

}

sub funcList (@) {

}

sub funcHash (%) {

}

sub funcManyProto ($&%) {

}

=pod

=head2 funcPlain

do something boring 

=cut

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
