package Aspect::Pointcut::Or;

use strict;
use warnings;
use Aspect::Pointcut        ();
use Aspect::Pointcut::Logic ();

our $VERSION = '0.45';
our @ISA     = qw{
	Aspect::Pointcut::Logic
	Aspect::Pointcut
};





######################################################################
# Weaving Methods

sub match_define {
	my $self = shift;
	foreach ( @$self ) {
		return 1 if $_->match_define(@_);
	}
	return;
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

	# Collapse nested logical clauses
	while ( scalar grep { $_->isa('Aspect::Pointcut::Or') } @list ) {
		@list = map {
			$_->isa('Aspect::Pointcut::Or') ? @$_ : $_
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
		return 1 if $_->match_run(@_);
	}
	return;
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Or - Logical 'or' pointcut

=head1 SYNOPSIS

  # High-level creation
  my $pointcut1 = call 'one' | call 'two' | call 'three';
  
  # Manual creation
  my $pointcut2 = Aspect::Pointcut::Or->new(
      Aspect::Pointcut::Call->new('one'),
      Aspect::Pointcut::Call->new('two'),
      Aspect::Pointcut::Call->new('three'),
  );

=head1 DESCRIPTION

B<Aspect::Pointcut::And> is a logical condition, which is used
to create higher-order conditions from smaller parts.

It takes two or more conditions, and applies appropriate logic during the
various calculations that produces a logical set-wise 'and' result.

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
