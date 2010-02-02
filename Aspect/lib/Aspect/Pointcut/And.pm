package Aspect::Pointcut::And;

use strict;
use warnings;
use Aspect::Pointcut        ();
use Aspect::Pointcut::Logic ();

our $VERSION = '0.43';
our @ISA     = qw{
	Aspect::Pointcut::Logic
	Aspect::Pointcut
};





######################################################################
# Weaving Methods

sub match_define {
	my $self = shift;
	foreach ( @$self ) {
		return unless $_->match_define(@_);
	}
	return 1;
}

sub match_contains {
	my $self = shift;
	return 1 if $self->isa($_[0]);
	foreach my $child ( @$self ) {
		return 1 if $child->match_contains($_[0]);
	}
	return '';
}

sub match_runtime {
	my $self = shift;
	foreach my $child ( @$self ) {
		return 1 if $child->match_runtime;
	}
	return 0;
}

sub match_curry {
	my $self = shift;
	my @list = @$self;

	# Collapse nested And clauses
	while ( scalar grep { $_->isa('Aspect::Pointcut::And') } @list ) {
		@list = map {
			$_->isa('Aspect::Pointcut::And') ? @$_ : $_
		} @list;
	}

	# Should we strip out the call pointcuts
	my $strip = shift;
	unless ( defined $strip ) {
		# Are there any elements that MUST exist at run-time?
		if ( $self->match_runtime ) {
			# If we have any nested logic that themselves contain
			# call pointcuts, we can't strip.
			$strip = not scalar grep {
				$_->isa('Aspect::Pointcut::Logic')
				and
				$_->match_contains('Aspect::Pointcut::Call')
			} @list;
		} else {
			# Nothing at runtime, so we can strip
			$strip = 1;
		}
	}

	# Curry down our children
	@list = grep { defined $_ } map {
		$_->isa('Aspect::Pointcut::Call')
		? $strip
			? $_->match_curry($strip)
			: $_
		: $_->match_curry($strip)
	} @list;

	# If none are left, curry us away to nothing
	return unless @list;

	# If only one remains, curry us away to just that child
	return $list[0] if @list == 1;

	# Create our clone to hold the curried subset
	return ref($self)->new( @list );
}





######################################################################
# Runtime Methods

sub match_run {
	my $self = shift;
	foreach ( @$self ) {
		return unless $_->match_run(@_);
	}
	return 1;
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::And - Logical 'and' operation pointcut

=head1 SYNOPSIS

    Aspect::Pointcut::And->new;

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
