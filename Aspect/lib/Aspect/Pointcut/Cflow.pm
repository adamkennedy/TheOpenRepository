package Aspect::Pointcut::Cflow;

use strict;
use warnings;
use Carp                  ();
use Aspect::Pointcut      ();
use Aspect::AdviceContext ();

our $VERSION = '0.28';
our @ISA     = 'Aspect::Pointcut';

sub new {
	my $class = shift;
	unless ( @_ == 2 ) {
		Carp::carp 'Cflow must be created with 2 parameters';
	}

	return bless {
		runtime_context_key => $_[0],
		spec                => $_[1],
	}, $class;
}

# The cflow pointcuts do not curry at all.
# So they don't need to clone, and can be used directly.
sub curry_run {
	return $_[0];
}

# To make cflow work we need to hook (sadly) everything
sub match_define {
	return 1;
}

sub match_run {
	my ($self, $sub_name, $runtime_context) = @_;
	my $caller_info = $self->find_caller;
	return 0 unless $caller_info;
	
	my $advice_context = Aspect::AdviceContext->new(
		sub_name => $caller_info->{sub_name},
		pointcut => $self,
		params   => $caller_info->{params},
	);
	$runtime_context->{$self->{runtime_context_key}} = $advice_context;
	return 1;
}

sub find_caller {
	my $self  = shift;
	my $level = 2;
	my $caller_info;
	while ( 1 ) {
		$caller_info = $self->caller_info($level++);
		last if
			!$caller_info ||
			$self->match($self->{spec}, $caller_info->{sub_name});
	}
	return $caller_info;
}

sub caller_info {
	my ($self, $level) = @_;
	package DB;
	my %call_info;
	@call_info {qw(calling_package sub_name has_params)} =
		(CORE::caller($level))[0, 3, 4];
	return defined $call_info{calling_package}?
		{ %call_info, params => [$call_info{has_params}? @DB::args: ()] }: 0;
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
