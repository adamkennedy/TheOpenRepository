package Aspect::Pointcut::Returning;

use strict;
use warnings;
use Carp             ();
use Aspect::Pointcut ();

our $VERSION = '0.99';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Weaving Methods

# Exception pointcuts always match at weave time and should curry away
sub curry_weave {
	return;
}

# Exception-related pointcuts do not curry.
sub curry_runtime {
	return $_[0];
}

sub compile_runtime {
	"defined \$_->{exception} and not ref \$_->{exception} and \$_->{exception} eq ''";
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Returning - Function returning without exception

  use Aspect;
  
  # Don't trap Foo::Exception object exceptions
  after {
      $_->return_value(1)
  } call 'Foo::bar' & returning;
  
=head1 DESCRIPTION

The B<Aspect::Pointcut::Returning> pointcut is used to match situations
in which C<after> advice should B<NOT> run when the function is throwing an
exception.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
