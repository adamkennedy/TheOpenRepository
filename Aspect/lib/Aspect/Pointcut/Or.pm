package Aspect::Pointcut::Or;

use strict;
use warnings;
use Aspect::Pointcut ();

our $VERSION = '0.38';
our @ISA     = 'Aspect::Pointcut';





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

sub curry_run {
	my $self = shift;

	# Reduce our children to the subset which themselves do not curry
	my @children = grep { $_->curry_run } @$self;

	# If none are left, curry us away to nothing
	return unless @children;

	# If only one remains, curry us away to just that child
	if ( @children == 1 ) {
		return $children[0];
	}

	# Create our clone to hold the curried subset
	my $class = ref($self);
	return $class->new( @children );
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

Aspect::Pointcut::Or - Logical 'or' operation pointcut

=head1 SYNOPSIS

    Aspect::Pointcut::Or->new;

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
