package Aspect::Hook::LexWrap;

use strict;
use warnings;
use 5.006;
use Carp::Heavy; # added by eilara as hack around caller() core dump
use Carp;


our $VERSION = '0.21';


*CORE::GLOBAL::caller = sub {
        my ($height) = ($_[0]||0);
        my $i=1;
        my $name_cache;
        while (1) {
                my @caller = CORE::caller($i++) or return;
                $caller[3] = $name_cache if $name_cache;
                $name_cache = $caller[0] eq 'Aspect::Hook::LexWrap' ? $caller[3] : '';
                next if $name_cache || $height-- != 0;
                return wantarray ? @_ ? @caller : @caller[0..2] : $caller[0];
        }
};

{
    no strict 'refs';
    sub import { *{caller()."::wrap"} = \&wrap }
}

sub wrap (*@) {
	my ($typeglob, %wrapper) = @_;
	$typeglob = (ref $typeglob || $typeglob =~ /::/)
		? $typeglob
		: caller()."::$typeglob";
    no strict 'refs';
	my $original = ref $typeglob eq 'CODE' && $typeglob
		     || *$typeglob{CODE}
		     || croak "Can't wrap non-existent subroutine ", $typeglob;
	croak "'$_' value is not a subroutine reference"
		foreach grep {$wrapper{$_} && ref $wrapper{$_} ne 'CODE'}
			qw(pre post);
	no warnings 'redefine';
	my ($caller, $unwrap) = *CORE::GLOBAL::caller{CODE};
	my $prototype = prototype($original)? '('. prototype($original). ')': '';
	# any way to set prototypes other than eval?
    my $imposter;
	eval '$imposter = sub '. $prototype. q{{
			if ($unwrap) { goto &$original }
			my ($return, $prereturn);
			if (wantarray) {
				$prereturn = $return = [];
				() = $wrapper{pre}->(\@_, $original, $return) if $wrapper{pre};
				if (ref $return eq 'ARRAY' && $return == $prereturn && !@$return) {
					$return = [ &$original(@_) ];
					() = $wrapper{post}->(\@_, $original, $return)
						if $wrapper{post};
				}
				return ref $return eq 'ARRAY' ? @$return : ($return);
			}
			elsif (defined wantarray) {
				$return = bless sub {$prereturn=1}, 'Aspect::Hook::LexWrap::Cleanup';
				my $dummy = $wrapper{pre}->(\@_, $original, $return) if $wrapper{pre};
				unless ($prereturn) {
					$return = &$original(@_);
					$dummy = scalar $wrapper{post}->(\@_, $original, $return)
						if $wrapper{post};
				}
				return $return;
			}
			else {
				$return = bless sub {$prereturn=1}, 'Aspect::Hook::LexWrap::Cleanup';
				$wrapper{pre}->(\@_, $original, $return) if $wrapper{pre};
				unless ($prereturn) {
					&$original(@_);
					$wrapper{post}->(\@_, $original, $return)
						if $wrapper{post};
				}
				return;
			}
	}};
	ref $typeglob eq 'CODE' and return defined wantarray
		? $imposter
		: carp "Uselessly wrapped subroutine reference in void context";
	*{$typeglob} = $imposter;
	return unless defined wantarray;
	return bless sub{ $unwrap=1 }, 'Aspect::Hook::LexWrap::Cleanup';
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

This is Hook::LexWrap with a small change: instead of getting C<(@_,
$return)> as their parameters, wrappers get C<(\@_, $original, $return)>.
This allows you to inject and remove parameters for the wrapped sub, and
to call the original sub from the wrapper.  Both are unsupported in the
original.

=head1 ORIGINAL AUTHOR

Damian Conway (damian@conway.org)

=head1 SEE ALSO

See the L<Aspect|::Aspect> pods for a guide to the Aspect module.

=head1 COPYRIGHT

      Copyright (c) 2001, Damian Conway. All Rights Reserved.
    This module is free software. It may be used, redistributed
        and/or modified under the same terms as Perl itself.

=cut
