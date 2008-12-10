package t::data::Package;
require Exporter;
@ISA = qw(Exporter);
use strict;
use warnings;
use Carp qw( confess cluck );
use vars qw( $VERSION @EXPORT @MacropodInfo );
use parent qw( Class::Accessor IO::Socket );
@EXPORT = qw( @MacropodInfo );

__PACKAGE__->mk_accessors( qw/ hint order / );
__PACKAGE__->mk_ro_accessors( qw/ help / );


=pod

=head1 NAME

t::data::Package

=head1 SYNOPSIS

Provide some examples of Macropod capability in parsing and deriving 
meaning from perl source.

=head1 METHODS

=head2 funcScalar

twiddle a scalar in dangerous ways

=cut 



sub funcScalar ($) {
 no strict qw/refs/;
}

sub funcList (@) {

}

sub funcHash (%) {
 no warnings 'undefined';
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
