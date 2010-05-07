package Aspect::Pointcut::Throwing;

use strict;
use warnings;
use Carp             ();
use Params::Util     ('_STRING', '_INSTANCE');
use Aspect::Pointcut ();

our $VERSION = '0.45';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $spec  = shift;
	if ( Params::Util::_STRING($spec) ) {
		my $perl = 'Params::Util::_INSTANCE(\$_->{exception}, "$spec")';
		return bless [ $spec, sub { $_[0] eq $spec }, $perl ], $class;
	}
	if ( Params::Util::_CODELIKE($spec) ) {
		return bless [ $spec, $spec, $spec ], $class;
	}
	unless ( Params::Util::_REGEX($spec) ) {
		Carp::croak("Invalid function call specification");
	}
	return bless [ $spec,  ], $class;
}





######################################################################
# Weaving Methods

sub match_define {
	return 1;
}

# Call pointcuts curry away to null, because they are the basis
# for which methods to hook in the first place. Any method called
# at run-time has already been checked.
sub match_curry {
	return $_[0];
}





######################################################################
# Runtime Methods

sub match_run {
	my $self    = shift;
	my $runtime = shift;
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
  
  # Catch a Foo::Exception object exception
  after {
      $_[0]->return_value(1)
  } throwing 'Foo::Exception';
  
  # Catch a plain die with particular string

=head1 DESCRIPTION

The B<Aspect::Pointcut::Throwing> pointcut is used to match situations
in which an after() or after_throwing() advice block wishes to intercept
the throwing of a specific exception string or object.

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
