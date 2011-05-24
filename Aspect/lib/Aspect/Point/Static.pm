package Aspect::Point::Static;

=pod

=head1 NAME

Aspect::Point - The Join Point context for join point static parts

=head1 SYNOPSIS

=head1 METHODS

=cut

use strict;
use warnings;
use Carp          ();
use Aspect::Point ();

our $VERSION = '0.98';
our @ISA     = 'Aspect::Point';





######################################################################
# Error on anything this doesn't support

sub return_value {
	Carp::croak("Cannot call return_value on static part of join point");
}

sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	$key =~ s/^.*:://;
	Carp::croak("Cannot call $key on static part of join point");
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
