package Aspect::Pointcut::Highest;

use strict;
use warnings;
use Carp             ();
use Params::Util     ();
use Aspect::Pointcut ();

our $VERSION = '0.41';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Constructor Methods

sub new {
	bless [ ], $_[0];
}





######################################################################
# Weaving Methods

sub match_define {
	return 1;
}

# Call pointcuts curry away to null, because they are the basis
# for which methods to hook in the first place. Any method called
# at run-time has already been checked.
sub curry_run {
	bless [ 0 ], $_[0];
}





######################################################################
# Runtime Methods

sub match_run {
	my $self    = shift;
	my $cleanup = sub { $self->[0]-- };
	bless $cleanup, 'Aspect::Pointcut::Highest::Cleanup';
	$_[0]->{highest} = $cleanup;
	return ! $self->[0]++;
}

package Aspect::Pointcut::Highest::Cleanup;

sub DESTROY {
	$_[0]->();
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Call - Call pointcut

=head1 SYNOPSIS

    Aspect::Pointcut::Call->new;

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
