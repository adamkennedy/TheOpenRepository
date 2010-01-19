package Aspect::Library::Breakpoint;

use strict;
use warnings;
use Aspect::Modular        ();
use Aspect::Advice::Before ();

our $VERSION = '0.39';
our @ISA     = 'Aspect::Modular';

sub get_advice {
	my $self = shift;
	Aspect::Advice::Before->new(
		lexical  => $self->lexical,
		pointcut => $_[0],
		code     => sub {
			$DB::single = 1;
			1;
			DB->skippkg('Aspect::Advice::Hook');
		},
	);
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Breakpoint - A breakpoint aspect

=head1 SYNOPSIS

  use Aspect;

  aspect Breakpoint => call qr/^Foo::refresh/;

  my $f1 = Foo->refresh_foo;
  my $f2 = Foo->refresh_bar;

  # The debugger will go into single statement mode for both methods

=head1 SUPER

L<Aspect::Modular>

=head1 DESCRIPTION

B<THIS MODULE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE>

C<Aspect::Library::Breakpoint> is a reusable aspect for implementing
breakpoints in the debugger in patterns that are more complex than
the native debugger supports.

=head1 SEE ALSO

See the L<Aspect> pods for a guide to the Aspect module.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
