package Aspect::Hook::LexWrap;

use 5.006;
use strict;
use warnings;
use Carp::Heavy  (); # added by eilara as hack around caller() core dump
use Carp         ();
use Sub::Uplevel ();

our $VERSION = '0.22';

sub wrap {
	my ($typeglob, $pre, $post) = @_;

	# Check and normalise the typeglob
	$typeglob = (ref $typeglob || $typeglob =~ /::/)
		? $typeglob
		: caller()."::$typeglob";
	no strict 'refs';
	my $original = ref $typeglob eq 'CODE' ? $typeglob : *$typeglob{CODE};
	unless ( $original ) {
		Carp::croak("Can't wrap non-existent subroutine ", $typeglob);
	}

	# Check the wrappers
	if ( $pre and ref $pre ne 'CODE' ) {
		Carp::croak("'pre' value is not a subroutine reference");
	}
	if ( $post and ref $post ne 'CODE' ) {
		Carp::croak("'post' value is not a subroutine reference");
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
				$prereturn = $return = [];
				() = $pre->(
					\@_, $original, $return
				) if $pre;
				if (
					# It's still an array
					ref $return eq 'ARRAY'
					and
					# It's still the SAME array
					$return == $prereturn
					and
					# It's still empty
					! @$return
				) {
					$return = [
						Sub::Uplevel::uplevel(
							1, $original, @_,
						)
					];
					() = $post->(
						\@_, $original, $return
					) if $post;
				}
				return ref $return eq 'ARRAY'
					? @$return
					: ( $return );

			} elsif ( defined wantarray ) {
				$return = bless sub {
					$prereturn = 1
				}, 'Aspect::Hook::LexWrap::Cleanup';
				my $dummy = $pre->(
					\@_, $original, $return
				) if $pre;
				unless ( $prereturn ) {
					$return = Sub::Uplevel::uplevel(
						1, $original, @_,
					);
					$dummy = scalar $post->(
						\@_, $original, $return
					) if $post;
				}
				return $return;

			} else {
				$return = bless sub {
					$prereturn = 1
				}, 'Aspect::Hook::LexWrap::Cleanup';
				$pre->(
					\@_, $original, $return
				) if $pre;
				unless ( $prereturn ) {
					Sub::Uplevel::uplevel(
						1, $original, @_,
					);
					$post->(
						\@_, $original, $return
					) if $post;
				}
				return;
			}
	}};
	if ( ref $typeglob eq 'CODE' ) {
		unless ( defined wantarray ) {
			Carp::carp("Uselessly wrapped subroutine reference in void context");
		}
		return $imposter;
	}
	*{$typeglob} = $imposter;
	return unless defined wantarray;
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
