package Aspect::Pointcut::Cflow;

use strict;
use warnings;
use Carp                   ();
use Params::Util           ();
use Aspect::Pointcut       ();
use Aspect::Pointcut::Call ();
use Aspect::AdviceContext  ();

our $VERSION = '0.37';
our @ISA     = 'Aspect::Pointcut';

use constant KEY  => 0;
use constant SPEC => 1;





######################################################################
# Constructor Methods

sub new {
	my $class = shift;
	unless ( Params::Util::_IDENTIFIER($_[0]) ) {
		Carp::croak('Invalid runtime context key');
	}
	bless [ $_[0], Aspect::Pointcut::Call->spec($_[1]) ], $class;
}





######################################################################
# Weaving Methods

# To make cflow work we need to hook (sadly) everything
sub match_define {
	return 1;
}

# The cflow pointcuts do not curry at all.
# So they don't need to clone, and can be used directly.
sub curry_run {
	return $_[0];
}





######################################################################
# Runtime Methods

sub match_run {
	my ($self, $sub_name, $runtime_context) = @_;
	my $caller_info = $self->find_caller;
	return 0 unless $caller_info;
	my $advice_context = Aspect::AdviceContext->new(
		sub_name => $caller_info->{sub_name},
		pointcut => $self,
		params   => $caller_info->{params},
	);
	$runtime_context->{$self->[KEY]} = $advice_context;
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
