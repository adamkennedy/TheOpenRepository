package Aspect::Library::Timer;

use 5.008002;
use strict;
use warnings;
use Aspect::Modular 0.90 ();
use Time::HiRes   1.9718 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'Aspect::Modular';
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
			$_->run_original;
			my @stop  = Time::HiRes::gettimeofday();

			# Process the time
			$handler->(
				$_->sub_name,
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
	my ( $name, $start, $stop, $interval ) = @_;
	printf STDERR "%s - %s\n", $interval, $name;
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

L<Aspect>, L<Aspect::Library::ZoneTimer>

=head1 COPYRIGHT

Copyright 2009 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
