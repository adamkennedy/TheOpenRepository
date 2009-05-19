package Aspect::Pointcut;

use strict;
use warnings;
use Carp;
use Aspect::Pointcut::AndOp;
use Aspect::Pointcut::OrOp;
use Aspect::Pointcut::NotOp;
use Data::Dumper;


our $VERSION = '0.16';


use overload
	'&'  => sub { Aspect::Pointcut::AndOp->new(@_) },
	'|'  => sub { Aspect::Pointcut::OrOp ->new(@_) },
	'!'  => sub { Aspect::Pointcut::NotOp->new(@_) },
	'""' => sub { Dumper shift };

sub new {
	my ($class, @spec) = @_;
	my $self = bless {}, $class;
	$self->init(@spec);
	return $self;
}

# TODO: if it is 'eq' we can jusy grab it
sub match {
	my ($self, $spec, $sub_name) = @_;
	return
		ref $spec eq 'Regexp'? $sub_name =~ $spec:
		ref $spec eq 'CODE'  ? $spec->($sub_name):
		$spec eq $sub_name;
}

sub init {}

# template methods ------------------------------------------------------------

sub match_define { 1 }
sub match_run    { 1 }

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut - pointcut base class

=head1 DESCRIPTION

A running program can be seen as a collection of events. Events like a
sub returning from a call, or a package being used. These are called join
points. A pointcut defines a set of join points, taken from all the join
points in the program. Different pointcut classes allow you to define the
set in different ways, so you can target the exact join points you need.

Pointcuts are constructed as trees; logical operations on pointcuts with
one or two arguments (not, and, or) are themselves pointcut operators.
You can construct them explicitly using object syntax, or you can use the
convenience functions exported by Aspect and the overloaded operators
C<!>, C<&> and C<|>.

=head1 SEE ALSO

See the L<Aspect|::Aspect> pod for a guide to the Aspect module.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

Ran Eilam C<< <eilara@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2001 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

