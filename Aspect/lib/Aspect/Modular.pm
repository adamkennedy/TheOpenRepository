package Aspect::Modular;

use strict;
use warnings;
use Carp;


our $VERSION = '0.26';


# creating --------------------------------------------------------------------

sub new {
	my $self = bless {}, shift;
	$self->{advice} = [$self->get_advice(@_)];
	return $self;
}

# template methods ------------------------------------------------------------

sub get_advice {}

1;

__END__

=pod

=head1 NAME

Aspect::Modular - base class for reusable aspects

=head1 SYNOPSIS

  # subclassing to create a reusable aspect
  package Aspect::Library::ConstructorTracer;
  use Aspect;
  use base 'Aspect::Modular';
  sub get_advice {
     my ($self, $pointcut) = @_;
     after
        { print 'created object: '. shift->return_value. "\n" }
        $pointcut;
  }

  # using the new aspect
  package main;
  use Aspect;
  # print message when constructing new Person
  aspect ConstructorTracer => call 'Person::new';

=head1 DESCRIPTION

All reusable aspect inherit from this class. Such aspects are created in
user code, using the C<aspect()> sub exported by L<Aspect|::Aspect>. You
call C<aspect()> with the class name of the reusable aspect (it must
exist in the package C<Aspect::Library>), and any parameters (pointcuts,
class names, code to run, etc.) the specific aspect may require.

The L<Wormhole|Aspect::Library::Wormhole> aspect, for example, expects 2
pointcut specs for the wormhole source and target, while the
L<Profiler|Aspect::Library::Profiler> aspect expects a pointcut object,
to select the subs to be profiled.

You create a reusable aspect by subclassing this class, and providing one
I<template method>: C<get_advice()>. It is called with all the parameters
that were sent when user code created the aspect, and is expected to
return L<Aspect::Advice> object/s, that will be installed while the
reusable aspect is still in scope. If the C<aspect()> sub is called in
void context, the reusable aspect is installed until class reloading or
interpreter shutdown.

Typical things a reusable aspect may want to do:

=over 4

=item *

Install advice on pointcuts specified by the caller

=item *

Push (vs. OOP pull) subs and base classes into classes specified by
the caller

=back

=head1 SEE ALSO

See the L<Aspect|::Aspect> pod for a guide to the Aspect module.

You can find examples of reusable aspects in the C<Aspect::Library>
package. L<Aspect::Library::Singleton> for example.

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

