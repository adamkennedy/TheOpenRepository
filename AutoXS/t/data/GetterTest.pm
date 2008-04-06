
package GetterTest;
use strict;
use warnings;
use base 'TestUtils';
use AutoXS::Getter;

sub new {return bless {map {("${_}cc" => $_)} 'a'..'j'} => __PACKAGE__;}

sub get_info {
  my $class = shift;
  my $info = $class->SUPER::get_info();
  my $match = $info->{match};
  my $nmatch = $info->{not_match};
  foreach (
      qw(get_acc get_bcc get_ccc get_dcc get_ecc get_fcc get_gcc get_icc get_jcc)
  ) {
    $match->{"".__PACKAGE__."::$_"} = 1;
  }

  foreach (
      qw(new)
  ) {
    $nmatch->{"".__PACKAGE__."::$_"} = 1;
  }
  return $info
}

sub get_acc { $_[0]->{acc} }

sub get_bcc {
  my $self = shift;
  $self->{bcc}
}

sub get_ccc {
  my $self = shift;
  return $self->{ccc};
}

sub get_dcc { return $_[0]->{dcc} }

sub get_ecc { shift->{ecc} }

sub get_fcc {
  my ($self) = @_;
  $self->{fcc}
}

sub get_gcc {
  my ($self) = @_;
  return $self->{gcc};
}

sub get_icc {
  my ($self) = shift;
  $self->{icc}
}

sub get_jcc {
  my ($self) = shift;
  return $self->{jcc};
}

1;
