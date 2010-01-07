package Aspect::Library::Memoize;

use 5.008002;
use strict;
use warnings;
use Memoize           1.01 ();
use Aspect::Modular   0.32 ();
use Aspect::Advice::Before ();

our $VERSION = '0.30';
our @ISA     = 'Aspect::Modular';

sub get_advice {
	my %wrappers = ();
	Aspect::Advice::Before->new(
		lexical  => $_[0]->lexical,
		pointcut => $_[1],
		code     => sub {
			my $context = shift;
			my $name    = $context->sub_name;

			# Would be difficult if Memoize did not have INSTALL => undef option
			$wrappers{$name} ||= Memoize::memoize(
				$context->original,
				INSTALL => undef,
			);

			# Set the correct return value
			# NOTE: This seems overly complicated, refactor?
			$context->return_value(
				wantarray ? [
					$wrappers{$name}->($context->params)
				]
				: $wrappers{$name}->($context->params)
			);
		},
	);
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Memoize - Cross-cutting memoization

=head1 SYNOPSIS

  # memoize all subs that have '_slow_' in their name, under package MyApp
  aspect Memoize => call qr/^MyApp::.*_slow_/;

=head1 SUPER

L<Aspect::Modular>

=head1 DESCRIPTION

An aspect interface on the Memoize module. Only difference from Memoize
module is that you can specify subs to be memoized using pointcuts.

Works by memoizing on the 1st call, and calling the memoized version on
subsequent calls.

=head1 SEE ALSO

See the L<Aspect|::Aspect> pods for a guide to the Aspect module.

You can find an example of using this aspect in the C<examples/> directory
of the distribution.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 SUPPORT

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Aspect-Library-Memoize>.

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
