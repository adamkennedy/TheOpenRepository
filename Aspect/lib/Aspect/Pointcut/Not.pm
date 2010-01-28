package Aspect::Pointcut::Not;

use strict;
use warnings;
use Aspect::Pointcut ();

our $VERSION = '0.42';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Weaving Methods

sub match_define {
	return ! shift->[0]->match_define(@_);
}

sub match_contains {
	my $self = shift;
	return 1 if $self->isa($_[0]);
	return 1 if $self->[0]->match_contains($_[0]);
	return '';
}

# Logical not inherits it's curryability from the element contained
# within it. We continue to be needed if and only if something below us
# continues to be needed as well.
# For cleanliness (and to avoid accidents) we make a copy of ourself
# in case our child curries to something other than it's pure self.
sub match_curry {
	my $self  = shift;
	my $child = $self->[0]->match_curry;
	return unless $child;

	# Handle the special case where the collapsing pointcut results
	# in a "double not". Fetch the child of our child not and return
	# it directly.
	if ( $child->isa('Aspect::Pointcut::Not') ) {
		return $child->[0];
	}

	# Return our clone with the curried child
	my $class = ref($self);
	return $class->new( $child );
}





######################################################################
# Runtime Methods

sub match_run {
	return ! shift->[0]->match_run(@_);
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Not - Logical 'not' operation pointcut

=head1 SYNOPSIS

    Aspect::Pointcut::Not->new;

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
