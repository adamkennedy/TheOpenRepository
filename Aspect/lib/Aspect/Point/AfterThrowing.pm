package Aspect::Point::AfterThrowing;

=pod

=head1 NAME

Aspect::Point - The Join Point context for "after_throwing" advice code

=head1 SYNOPSIS

=head1 METHODS

=cut

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.97_04';
our @ISA     = 'Aspect::Point';

use constant type => 'after_throwing';

sub exception {
	my $self = shift;
	return $self->{exception} unless @_;
	$self->{proceed}   = 0;
	$self->{exception} = shift;
}

1;

=pod

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
