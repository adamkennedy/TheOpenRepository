package Aspect::Advice::After;

use strict;
use warnings;

# Added by eilara as hack around caller() core dump
# NOTE: Now we've switched to Sub::Uplevel can this be removed? --ADAMK
use Carp::Heavy    (); 
use Carp           ();
use Sub::Uplevel   ();
use Aspect::Advice ();

our $VERSION = '0.28';
our @ISA     = 'Aspect::Advice';

# NOTE: To simplify debugging of the generated code, all injected string
# fragments will be defined in $UPPERCASE, and all lexical variables to be
# accessed via the closure will be in $lowercase.
sub _install {
	my $self     = shift;
	my $pointcut = $self->pointcut;
	my $code     = $self->code;

	# Get the curried version of the pointcut we will use for the
	# runtime checks instead of the original.
	# Because $MATCH_RUN is used in boolean conditionals, if there
	# is nothing to do the compiler will optimise away the code entirely.
	my $curried   = $pointcut->curry_run;
	my $MATCH_RUN = $curried ? '$curried->match_run($name, $runtime)' : 1;

	# When an aspect falls out of scope, we don't attempt to remove
	# the generated hook code, because it might (for reasons potentially
	# outside our control) have been recursively hooked several times
	# by both Aspect and other modules.
	# Instead, we store an "out of scope" flag that is used to shortcut
	# past the hook as quickely as possible.
	# This flag is shared between all the generated hooks for each
	# installed Aspect.
	my $out_of_scope = undef;

	# Find all pointcuts that are statically matched
	# wrap the method with advice code and install the wrapper
	foreach my $name ( $pointcut->match_all ) {
		my $NAME = $name; # For completeness

		no strict 'refs';
		my $original = *$name{CODE};
		unless ( $original ) {
			Carp::croak("Can't wrap non-existent subroutine ", $name);
		}

		# Any way to set prototypes other than eval?
		my $PROTOTYPE = prototype($original);
		   $PROTOTYPE = defined($PROTOTYPE) ? "($PROTOTYPE)" : '';

		# Generate the new function
		no warnings 'redefine';
		eval <<"END_PERL"; die $@ if $@;
		*$NAME = sub $PROTOTYPE {
			if ( \$out_of_scope ) {
				# Lexical Aspect is out of scope
				goto &\$original;
			}

			my \$runtime   = {};
			my \$wantarray = wantarray;
			if ( \$wantarray ) {
				my \$return = [
					Sub::Uplevel::uplevel(
						1, \$original, \@_,
					)
				];
				return \@\$return unless $MATCH_RUN;

				# Create the context
				my \$context = Aspect::AdviceContext->new(
					type         => 'after',
					pointcut     => \$pointcut,
					sub_name     => \$name,
					wantarray    => \$wantarray,
					params       => \\\@_,
					return_value => \$return,
					original     => \$original,
					\%\$runtime,
				);

				# Execute the advice code
				() = &\$code(\$context);

				# Get the (potentially) modified return value
				\$return = \$context->return_value;
				if ( ref \$return eq 'ARRAY' ) {
					return \@\$return;
				} else {
					return ( \$return );
				}
			}

			if ( defined \$wantarray ) {
				my \$return = Sub::Uplevel::uplevel(
					1, \$original, \@_,
				);
				return \$return unless $MATCH_RUN;

				# Create the context
				my \$context = Aspect::AdviceContext->new(
					type         => 'after',
					pointcut     => \$pointcut,
					sub_name     => \$name,
					wantarray    => \$wantarray,
					params       => \\\@_,
					return_value => \$return,
					original     => \$original,
					\%\$runtime,
				);

				# Execute the advice code
				my \$dummy = &\$code(\$context);
				return \$context->return_value;

			} else {
				Sub::Uplevel::uplevel(
					1, \$original, \@_,
				);
				return unless $MATCH_RUN;

				# Create the context
				my \$context = Aspect::AdviceContext->new(
					type         => 'after',
					pointcut     => \$pointcut,
					sub_name     => \$name,
					wantarray    => \$wantarray,
					params       => \\\@_,
					return_value => undef,
					original     => \$original,
					\%\$runtime,
				);

				# Execute the advice code
				&\$code(\$context);
				return;
			}
		};
END_PERL
	}

	# Return the lexical descoping hook.
	# This MUST be stored and run at DESTROY-time by the
	# parent object calling _install. This is less bullet-proof
	# than the DESTROY-time self-executing blessed coderef
	return sub { $out_of_scope = 1 };
}

1;
