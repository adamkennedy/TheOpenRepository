package Aspect::Library::Singleton;

use strict;
use warnings;
use Aspect::Modular        ();
use Aspect::Advice::Before ();
use Aspect::Pointcut::Call ();

our $VERSION = '0.31';
our @ISA     = 'Aspect::Modular';

my %CACHE = ();

sub get_advice {
	my $self = shift;
	Aspect::Advice::Before->new(
		forever  => $self->forever,
		pointcut => Aspect::Pointcut::Call->new($_[0]),
		code     => sub {
			my $context = shift;
			my $class   = $context->self;
			$class      = ref $class || $class;
			if ( exists $CACHE{$class} ) {
				$context->return_value($CACHE{$class});
			} else {
				$CACHE{$class} = $context->run_original;
			}
		},
	);
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Singleton - A singleton aspect

=head1 SYNOPSIS

  use Aspect::Singleton;

  aspect Singleton => 'Foo::new';

  my $f1 = Foo->new;
  my $f2 = Foo->new;

  # now $f1 and $f2 refer to the same object

=head1 SUPER

L<Aspect::Modular>

=head1 DESCRIPTION

A reusable aspect that forces singleton behavior on a constructor. The
constructor is defined by a pointcut spec: a string. regexp, or code ref.

It is slightly different from C<Class::Singleton>
(L<http://search.cpan.org/~abw/Class-Singleton/Singleton.pm>):

=over

=item *

No specific name requirement on the constructor for the external
interface, or for the implementation (C<Class::Singleton> requires
clients use C<instance()>, and that subclasses override
C<_new_instance()>). With aspects, you can change the cardinality of
your objects without changing the clients, or the objects themselves.

=item *

No need to inherit from anything- use pointcuts to specify the
constructors you want to memoize. Instead of I<pulling> singleton
behavior from a base class, you are I<pushing> it in, using the aspect.

=item *

No package variable or method is added to the callers namespace

=back

Note that this is just a special case of memoizing.

=head1 SEE ALSO

See the L<Aspect|::Aspect> pods for a guide to the Aspect module.

You can find an example comparing the OO and AOP solutions in the
C<examples/> directory of the distribution.

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

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 SEE ALSO

You can find AOP examples in the C<examples/> directory of the
distribution.

=head1 COPYRIGHT AND LICENSE

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
