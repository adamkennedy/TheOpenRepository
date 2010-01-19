package Aspect::Pointcut::Throwing;

use strict;
use warnings;
use Carp             ();
use Params::Util     ('_STRING', '_INSTANCE');
use Aspect::Pointcut ();

our $VERSION = '0.40';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Weaving Methods

sub match_define {
	return 1;
}

# Call pointcuts curry away to null, because they are the basis
# for which methods to hook in the first place. Any method called
# at run-time has already been checked.
sub curry_run {
	return $_[0];
}





######################################################################
# Runtime Methods

sub match_run {
	my ($self, undef, $runtime) = @_;
	unless ( exists $runtime->{exception} ) {
		# We are not in an exception
		return 0;
	}
	my $spec      = $self->[0];
	my $exception = $runtime->{exception};
	if ( ref $spec eq 'Regexp' ) {
		if ( defined _STRING($exception) ) {
			return $exception =~ $spec ? 1 : 0;
		} else {
			return 0;
		}
	} else {
		if ( defined _INSTANCE($exception, $spec) ) {
			return 1;
		} else {
			return 0;
		}
	}
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Throwing - Exception typing pointcut

  use Aspect;
  
  # Catch Foo exceptions and return true instead
  after { $_[0]->return_value(1) } throwing 'Foo::Exception';

=head1 DESCRIPTION

The B<Aspect::Pointcut::Throwing> pointcut is used to match situations
in which an after() or after_throwing() advice returns a specific
exception string or object.

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
