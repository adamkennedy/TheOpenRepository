package Aspect::Pointcut::Wantarray;

use strict;
use warnings;
use Carp             ();
use Aspect::Pointcut ();

our $VERSION = '0.45';
our @ISA     = 'Aspect::Pointcut';

use constant VOID   => 1;
use constant SCALAR => 2;
use constant LIST   => 3;





######################################################################
# Constructor Methods

sub new {
	return bless [
		LIST,
		'$_->{wantarray}',
	], $_[0] if $_[1];

	return bless [
		SCALAR,
		'defined $_->{wantarray} and not $_->{wantarray}',
	], $_[0] if defined $_[1];

	return bless [
		VOID,
		'not defined $_->{wantarray}',
	], $_[0];
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

Aspect::Pointcut::Wantarray - A pointcut for the run-time wantarray context

=head1 SYNOPSIS

  use Aspect;
  
  # High-level creation
  my $pointcut1 = wantlist | wantscalar | wantvoid;
  
  # Manual creation
  my $pointcut2 = Padre::Pointcut::Or->new(
    Padre::Pointcut::Wantarray->new( 1 ),     # List
    Padre::Pointcut::Wantarray->new( 0 ),     # Scalar
    Padre::Pointcut::Wantarray->new( undef ), # Void
  );

=head1 DESCRIPTION

The C<Aspect::Pointcut::Wantarray> pointcut allows the creation of
aspects that only trap calls made in a particular calling context
(list, scalar or void).

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
