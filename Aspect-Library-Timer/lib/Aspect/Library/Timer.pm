package Aspect::Library::Timer;

use 5.008002;
use strict;
use warnings;
use Aspect::Modular 0.38 ();
use Time::HiRes   1.9718 ();

use vars qw{$VERSION @ISA $DEPTH};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'Aspect::Modular';
	$DEPTH   = 0;
}

sub get_advice {
	my $self     = shift;
	my $pointcut = shift;
	my $handler  = @_ ? shift : \&handler;
	Aspect::Advice::Around->new(
		lexical  => $self->lexical,
		pointcut => $pointcut,
		code     => sub {
			# Capture the time
			my @start = Time::HiRes::gettimeofday();
			$_[0]->run_original;
			my @stop  = Time::HiRes::gettimeofday();

			# Process the time
			$handler->(
				$_[0]->sub_name,
				\@start,
				\@stop,
				Time::HiRes::tv_interval(
					\@start,
					\@stop,
				)
			);

			return;
		},
	);
}

sub handler {
	my ( $name, $start, $stop, $interval );
	printf STDDERR "%s - %s\n", $name, $interval;
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Timer - Predefined timer pointcut

=head1 SYNOPSIS

  use Aspect;
  
  aspect Timer => call qr/^Foo::/;

  Foo::bar();
  
  package Foo;
  
  sub bar {
      sleep 1;
  }

=head1 DESCRIPTION

C<Aspect::Library::Timer> provides support for simple timers aspects.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Aspect-Library-Timer>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Aspect>

=head1 COPYRIGHT

Copyright 2009 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
