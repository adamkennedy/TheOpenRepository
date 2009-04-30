package Aspect::Library::Profiler;

use strict;
use warnings;
use Carp;
use Aspect;


our $VERSION = '0.15';


use base 'Aspect::Modular';

my $Timer = Aspect::Benchmark::Timer::ReportOnDestroy->new;

sub get_advice {
	my ($self, $pointcut) = @_;
	my $before = before { $Timer->start(shift->sub_name) } $pointcut;
	my $after  = after  { $Timer->stop (shift->sub_name) } $pointcut;
	return ($before, $after);
}

package Aspect::Benchmark::Timer::ReportOnDestroy;
use base qw(Benchmark::Timer);
sub DESTROY { print scalar shift->reports }

1;

__END__

=head1 NAME

Aspect::Library::Profiler - reusable method call profiling aspect

=head1 SYNOPSIS

  # profile all subs on SlowObject
  aspect Profiler => call qr/^SlowObject::/;

  # will be profiled
  SlowObject->foo;

  # will not
  FastObject->bar;

=head1 SUPER

L<Aspect::Modular>

=head1 DESCRIPTION

This class implements a reusable aspect that profiles subroutine calls.
It uses C<Benchmark::Timer> to profile elapsed times for your calls to
the affected methods. The profiling report will be printed to C<STDERR>
at the end of program execution.

The design comes from C<Attribute::Profiled> by Tatsuhiko Miyagawa.

=head1 WHY

  +-------------+
  |      A      |
  +-------------+
  | X -> Y <- Z |
  +-^-----------+

Suppose you want to profile some code, call it C<X>, part of a larger
program, called C<A>. So you run your program under a profiler, and
notice most of the time is spent not in C<X>, but in C<Y>. C<X> uses
C<Y>, but so does C<Z>. You only want to profile how C<X> uses C<Y>, not
how C<Z> uses C<Y>. This is where this aspect can help- you can install a
profiling aspect with a C<cflow()> pointcut, to profile only usage of
C<Y> by code in the call flow of C<X>.

=head1 SEE ALSO

See the L<Aspect|::Aspect> pods for a guide to the Aspect module.

You can find an example of using this aspect in the C<examples/> directory
of the distribution.

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

