
package SetterTest;
use strict;
use warnings;
use base 'TestUtils';
use AutoXS::Setter;

sub new {return bless {map {("${_}" => $_)} 'a'..'z'} => __PACKAGE__;}

sub get_info {
  my $class = shift;
  my $info = $class->SUPER::get_info();
  my $match = $info->{match};
  my $nmatch = $info->{not_match};
  foreach (
    'a'..'k'
  ) {
    $match->{"".__PACKAGE__."::set_$_"} = 1;
  }

  foreach (
      qw(new set_bad_a set_bad_b set_bad_c set_bad_d set_bad_e set_bad_f)
  ) {
    $nmatch->{"".__PACKAGE__."::$_"} = 1;
  }
  return $info
}


#check
  sub set_a { $_[0]->{a} = $_[1] }
  sub set_b { ($_[0]->{$b}) = $_[1] }

#check
  sub set_c {
    my ($self, $val) = @_;
    $self->{c}= $val;
  }
  sub set_d {
    my $self = shift;
    my $val = shift;
    $self->{d} = $val;
  }
  sub set_e {
    my $self = $_[0];
    my $val = $_[1];
    $self->{e} = $val;
  }
  sub set_f {
    my $self = shift;
    $self->{f} = shift;
  }
  sub set_g {
    my $self = shift;
    $self->{g} = $_[0]
  }
  sub set_h {
    my $self = $_[0];
    $self->{h} = $_[1]
  }
  sub set_i {
    my $self = shift;
    ($self->{i}) = @_;
  }
#check
  sub set_j { $_[0]->{j} = $_[1]; return() }
#check
  sub set_k { $_[0]->{k} = $_[1]; return(undef) }

  
  sub set_bad_a { $_[0]->{a} = shift}
  sub set_bad_b { $_[0]->{b} = shift }
#check
  sub set_bad_c { ($_[0]->{c}) = shift }
#check
  sub set_bad_d { shift->{d} = shift }
#check
  sub set_bad_e { shift->{e} = $_[0] }
#check
  sub set_bad_f { (shift->{f}) = @_ }

1;
