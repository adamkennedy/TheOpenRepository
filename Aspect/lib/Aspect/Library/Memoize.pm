package Aspect::Library::Memoize;

use strict;
use warnings;
use Carp;
use Memoize;
use Aspect;
use Aspect::Modular ();

our $VERSION = '0.25';
our @ISA     = 'Aspect::Modular';

sub get_advice {
	my ($self, $pointcut) = @_;
	my %wrappers;
	before {
		my $context  = shift;
		my $sub_name = $context->sub_name;
		# would be difficult if Memoize did not have INSTALL => undef option
		$wrappers{$sub_name} ||= memoize($context->original, INSTALL => undef);
		my $wrapper = $wrappers{$sub_name};
		my @params  = $context->params;
		$context->return_value
			(wantarray? [$wrapper->(@params)]: $wrapper->(@params));
	} $pointcut; 
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Memoize - cross-cutting memoization

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

