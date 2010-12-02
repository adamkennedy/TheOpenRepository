package ADAMK::Lacuna::Client::Builder;

# Tools for mass-generation of convenience code

use 5.008;
use strict;
use warnings;

sub build_fillmethods {
	my $self   = shift;
	my $pkg    = caller();
	my $method = shift;
	my $code   = join "\n\n", map { <<"END_PERL" } @_;
sub $_ {
  my \$self = shift;
  unless ( defined \$self->{$_} ) {
    \$self->$method;
  }
  return \$self->{$_};
}
END_PERL
	eval "package $pkg;\n\n$code\n\n1;\n";
	die $@ if $@;

	return 1;
}

sub build_subaccessors {
	my $self   = shift;
	my $pkg    = caller();
	my $method = shift;
	my $code   = join "\n\n", map { <<"END_PERL" } @_;
sub $_ {
  \$_[0]->${method}->{$_};
}
END_PERL
	eval "package $pkg;\n\n$code\n\n1;\n";
	die $@ if $@;

	return 1;
}

1;
