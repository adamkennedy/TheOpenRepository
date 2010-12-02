package ADAMK::Lacuna::Client::Builder;

# Tools for mass-generation of convenience code

use 5.008;
use strict;
use warnings;

sub build_subaccessors {
	my $self   = shift;
	my $pkg    = caller();
	my $method = shift;
	my $code   = "package $pkg;\n\n" . join "\n\n", map { <<"END_PERL" } @_;
sub $_ {
  \$_[0]->$method->{$_};
}
END_PERL
	eval $code;
	die $@ unless $@;

	return 1;
}

1;
