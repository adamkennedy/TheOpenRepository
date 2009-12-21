package Aspect::Hook::LexWrap;

use 5.006;
use strict;
use warnings;
use Carp::Heavy  (); # added by eilara as hack around caller() core dump
use Carp         ();
use Sub::Uplevel ();

our $VERSION = '0.22';

sub pre {
	my ($typeglob, $code) = @_;

	# Check and normalise the typeglob
	no strict 'refs';
	my $original = *$typeglob{CODE};
	unless ( $original ) {
		Carp::croak("Can't wrap non-existent subroutine ", $typeglob);
	}

	# Check the wrappers
	unless ( ref $code eq 'CODE' ) {
		Carp::croak("Code value is not a subroutine reference");
	}

	# State variable for use in the closure (eep)
	my $unwrap = undef;

	# Any way to set prototypes other than eval?
	my $prototype = prototype($original);
	   $prototype = defined($prototype) ? "($prototype)" : '';

	# Generate the new function
	no warnings 'redefine';
	eval "sub $typeglob $prototype " . q{{
			if ( $unwrap ) { goto &$original }
			my ($return, $prereturn);
			if ( wantarray ) {
				$prereturn = $return = [];
				() = $code->( \@_, $original, $return );
				unless (
					# It's still an array
					ref $return eq 'ARRAY'
					and
					# It's still the SAME array
					$return == $prereturn
					and
					# It's still empty
					! @$return
				) {
					return ref $return eq 'ARRAY'
						? @$return
						: ( $return );
				}

			} elsif ( defined wantarray ) {
				$return = bless sub {
					$prereturn = 1
				}, 'Aspect::Hook::LexWrap::Cleanup';
				my $dummy = $code->( \@_, $original, $return );
				return $return if $prereturn;

			} else {
				$return = bless sub {
					$prereturn = 1
				}, 'Aspect::Hook::LexWrap::Cleanup';
				$code->( \@_, $original, $return );
				return if $prereturn;
			}

			goto &$original;
	}};
	die $@ if $@;
	return bless sub {
		$unwrap = 1
	}, 'Aspect::Hook::LexWrap::Cleanup';
}

sub post {
	my ($typeglob, $post) = @_;

	# Check and normalise the typeglob
	no strict 'refs';
	my $original = *$typeglob{CODE};
	unless ( $original ) {
		Carp::croak("Can't wrap non-existent subroutine ", $typeglob);
	}

	# Check the wrappers
	if ( ref $post ne 'CODE' ) {
		Carp::croak("Code is not a subroutine reference");
	}

	# State variable for use in the closure (eep)
	my $unwrap = undef;

	# Any way to set prototypes other than eval?
	no warnings 'redefine';
	my $prototype = prototype($original);
	   $prototype = defined($prototype) ? "($prototype)" : '';
	my $imposter  = eval "sub $prototype " . q{{
			if ( $unwrap ) { goto &$original }
			my ($return, $prereturn);
			if ( wantarray ) {
				$return = [
					Sub::Uplevel::uplevel(
						1, $original, @_,
					)
				];
				() = $post->(
					\@_, $original, $return
				);
				return ref $return eq 'ARRAY'
					? @$return
					: ( $return );

			} elsif ( defined wantarray ) {
				$return = Sub::Uplevel::uplevel(
					1, $original, @_,
				);
				my $dummy = scalar $post->(
					\@_, $original, $return
				);
				return $return;

			} else {
				Sub::Uplevel::uplevel(
					1, $original, @_,
				);
				$post->( \@_, $original, [] );
				return;
			}
	}};
	*$typeglob = $imposter;
	return bless sub {
		$unwrap = 1
	}, 'Aspect::Hook::LexWrap::Cleanup';
}

package Aspect::Hook::LexWrap::Cleanup;

sub DESTROY { $_[0]->() }

use overload
	q{""}   => sub { undef },
	q{0+}   => sub { undef },
	q{bool} => sub { undef };

1;

__END__

=pod

=head1 NAME

Aspect::Hook::LexWrap - Lexically scoped subroutine wrappers

=head1 DESCRIPTION

This is Hook::LexWrap with a small change: instead of getting C<(@_, $return)>
as their parameters, wrappers get C<(\@_, $original, $return)>.

This allows you to inject and remove parameters for the wrapped sub, and
to call the original sub from the wrapper.  Both are unsupported in the
original.

=head1 AUTHOR

Damian Conway <damian@conway.org>

=head1 SEE ALSO

See the L<Aspect|::Aspect> pods for a guide to the Aspect module.

=head1 COPYRIGHT

      Copyright (c) 2001, Damian Conway. All Rights Reserved.
    This module is free software. It may be used, redistributed
        and/or modified under the same terms as Perl itself.

=cut
