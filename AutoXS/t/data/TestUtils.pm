
package TestUtils;
use strict;
use warnings;

sub get_number_of_tests {
  my $info = $_[0]->get_info();
  return keys(%{$info->{match}}) + keys(%{$info->{not_match}});
}

sub is_xs {
  my $class = shift;
  my $func = shift;

  no strict 'refs';
  my $sym = \%{$class."::"};
  if ($func =~ /::([^:]+)$/) {
    $func = $1;
  }
  warn("Could not find sub $func in class $class"), return() if not exists($sym->{$func});
  local *symbol = $sym->{$func};
  my $coderef = *symbol{CODE} or return();
  my $codeobj = B::svref_2object($coderef);
  return() unless ref $codeobj eq 'B::CV';
  return 1 if $codeobj->XSUB;
  return();
}

sub dump_sub {
  my $class = shift;
  my $func = shift;

  no strict 'refs';
  my $sym = \%{$class."::"};
  if ($func =~ /::([^:]+)$/) {
    $func = $1;
  }

  local *symbol = $sym->{$func};
  my $coderef = *symbol{CODE} or return();
  my $codeobj = B::svref_2object($coderef);
  return() unless ref $codeobj eq 'B::CV';
  return() if $codeobj->XSUB;
  return $codeobj->ROOT->as_opgrep_pattern();
}

sub get_info {
  return {
    not_match => {
      get_info => 1,
      is_xs => 1,
      get_number_of_tests => 1,
      test_matching => 1,
    },
    match => {},
  };
}

sub test_matching {
  my $class = shift; 
  require Test::More;

  my $info = $class->get_info();
  foreach my $match (sort keys %{$info->{match}}) {
    Test::More::ok(! ! $class->is_xs($match), "$match was replaced");
  }
  foreach my $match (sort keys %{$info->{not_match}}) {
    Test::More::ok(!$class->is_xs($match), "$match was not replaced");
  }
}

1;
