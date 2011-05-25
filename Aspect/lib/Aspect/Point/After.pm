package Aspect::Point::After;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.981';
our @ISA     = 'Aspect::Point';

use constant type => 'after';





######################################################################
# Aspect::Point Methods

sub proceed {
	Carp::croak("Cannot call proceed in after advice");
}

1;

__END__

=pod

=head1 NAME

Aspect::Point - The Join Point context for "after" advice code

=head1 SYNOPSIS

  # The range of join point context methods available in after advice
  after {
  
  } call 

=head1 METHODS

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
