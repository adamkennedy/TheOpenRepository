package Aspect::Advice::After;

use strict;
use warnings;

# Added by eilara as hack around caller() core dump
# NOTE: Now we've switched to Sub::Uplevel can this be removed? --ADAMK
use Carp::Heavy     (); 
use Carp            ();
use Sub::Uplevel    ();
use Aspect::Cleanup ();
use Aspect::Advice  ();

our $VERSION = '0.23';
our @ISA     = 'Aspect::Advice';

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

# This should never be called by our own code.
# It only exists for back-compatibility purposes.
sub type {
	return 'after';
}

sub install {
	my $self     = shift;
	my $pointcut = $self->pointcut;
	my $code     = $self->code;

	# Find all pointcuts that are statically matched
	# wrap the method with advice code and install the wrapper
	foreach my $name ( $pointcut->match_all ) {
		my $wrapped = sub {
			# Hacked Hook::LexWrap calls hooks with 3 params
			my ($params, $original, $return_value) = @_;
			my $runtime_context = {};
			return unless $pointcut->match_run($name, $runtime_context);

			# Create context for advice code
			my $advice_context = Aspect::AdviceContext->new(
				sub_name       => $name,
				type           => 'after',
				pointcut       => $pointcut,
				params         => $params,
				return_value   => $return_value,
				original       => $original,
				%$runtime_context,
			);

			# Execute advice code with its context
			if ( wantarray ) {
				() = &$code($advice_context)
			} elsif ( defined wantarray ) {
				my $dummy = &$code($advice_context);
			} else {
				&$code($advice_context);
			}

			# Modify return value
			$_[-1] = $advice_context->return_value;
		};
 		$self->add_hooks(
			$self->hook( $name, $wrapped )
		);
	}
}

sub hook {
	my $self = shift;

	# Check and normalise the typeglob
	no strict 'refs';
	my $typeglob = shift;
	my $original = *$typeglob{CODE};
	unless ( $original ) {
		Carp::croak("Can't wrap non-existent subroutine ", $typeglob);
	}

	# Check the wrappers
	my $code = shift;
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
				$return = [
					Sub::Uplevel::uplevel(
						1, $original, @_,
					)
				];
				() = $code->(
					\@_, $original, $return
				);
				return ref $return eq 'ARRAY'
					? @$return
					: ( $return );

			} elsif ( defined wantarray ) {
				$return = Sub::Uplevel::uplevel(
					1, $original, @_,
				);
				my $dummy = scalar $code->(
					\@_, $original, $return
				);
				return $return;

			} else {
				Sub::Uplevel::uplevel(
					1, $original, @_,
				);
				$code->( \@_, $original, [] );
				return;
			}
	}};
	die $@ if $@;
	return bless sub {
		$unwrap = 1
	}, 'Aspect::Cleanup';
}

1;
