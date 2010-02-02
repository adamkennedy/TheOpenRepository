package Aspect::Pointcut::Wantarray;

use strict;
use warnings;
use Carp             ();
use Aspect::Pointcut ();

our $VERSION = '0.43';
our @ISA     = 'Aspect::Pointcut';

use constant VOID   => 1;
use constant SCALAR => 2;
use constant LIST   => 3;





######################################################################
# Constructor Methods

sub new {
	my $class = shift;
	my $want  = shift;
	return bless [ LIST   ], $class if $want;
	return bless [ SCALAR ], $class if defined $want;
	return bless [ VOID   ], $class;
}





######################################################################
# Weaving Methods

sub match_define {
	return 1;
}

# For wantarray pointcuts we keep the original
sub match_curry {
	return $_[0];
}





######################################################################
# Runtime Methods

sub match_run {
	my $self    = shift;
	my $runtime = shift;
	unless ( exists $runtime->{wantarray} ) {
		Carp::croak("The wantarray field in the runtime state does not exist");
	}
	if ( $runtime->{wantarray} ) {
		return $self->[0] == LIST;
	} elsif ( defined $runtime->{wantarray} ) {
		return $self->[0] == SCALAR;
	} else {
		return $self->[0] == VOID;
	}
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Wantarray - A pointcut for the wantarray call context

=head1 SYNOPSIS

  use Aspect;
  
  # Catch events in all three contexts
  my $pointcut = wantlist & wantscalar & wantvoid;

=head1 DESCRIPTION

The C<Aspect::Pointcut::Wantarray> pointcut allows the creation of
aspects that only trap calls made in a particular context (list, scalar
or void).

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
