package Aspect::Pointcut::Cflow;

use strict;
use warnings;
use Carp                   ();
use Params::Util           ();
use Aspect::Pointcut       ();
use Aspect::Pointcut::Call ();
use Aspect::AdviceContext  ();

our $VERSION = '0.45';
our @ISA     = 'Aspect::Pointcut';

use constant KEY  => 0;
use constant SPEC => 2;





######################################################################
# Constructor Methods

sub new {
	my $class = shift;
	unless ( Params::Util::_IDENTIFIER($_[0]) ) {
		Carp::croak('Invalid runtime context key');
	}

	# Generate it via call
	my $call = Aspect::Pointcut::Call->new($_[1]);
	return bless [ $_[0], @$call ], $class;
}





######################################################################
# Weaving Methods

# To make cflow work we need to hook (sadly) everything
sub match_define {
	return 1;
}

# The cflow pointcuts do not curry at all.
# So they don't need to clone, and can be used directly.
sub match_curry {
	return $_[0];
}





######################################################################
# Runtime Methods

sub match_run {
	my $self    = shift;
	my $runtime = shift;
	my $caller  = $self->find_caller or return 0;
	my $context = Aspect::AdviceContext->new(
		sub_name => $caller->{sub_name},
		pointcut => $self,
		params   => $caller->{params},
	);
	$runtime->{$self->[KEY]} = $context;
	return 1;
}

sub find_caller {
	my $self  = shift;
	my $level = 2;
	while ( my $context = $self->caller_info($level++) ) {
		return $context if $self->[SPEC]->( $context->{sub_name} );
	}
	return undef;
}

sub caller_info {
	my $self  = shift;
	my $level = shift;

	package DB;

	my %call_info;
	@call_info{qw(
		calling_package
		sub_name
		has_params
	)} = (CORE::caller($level))[0, 3, 4];

	return defined $call_info{calling_package}
		? {
			%call_info,
			params => [
				$call_info{has_params} ? @DB::args : ()
			],
		} : 0;
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Cflow - Cflow pointcut

=head1 SYNOPSIS

  Aspect::Pointcut::Cflow->new;

=head1 DESCRIPTION

None yet.

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
