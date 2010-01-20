package Aspect::Advice::Around;

use strict;
use warnings;

# Added by eilara as hack around caller() core dump
# NOTE: Now we've switched to Sub::Uplevel can this be removed? --ADAMK
use Carp::Heavy           (); 
use Carp                  ();
use Sub::Uplevel          ();
use Aspect::Advice        ();
use Aspect::Advice::Hook  ();
use Aspect::AdviceContext ();

our $VERSION = '0.40';
our @ISA     = 'Aspect::Advice';

sub _install {
	my $self     = shift;
	my $pointcut = $self->pointcut;
	my $code     = $self->code;
	my $lexical  = $self->lexical;

	# Get the curried version of the pointcut we will use for the
	# runtime checks instead of the original.
	# Because $MATCH_RUN is used in boolean conditionals, if there
	# is nothing to do the compiler will optimise away the code entirely.
	my $curried   = $pointcut->curry_run;
	my $MATCH_RUN = $curried ? '$curried->match_run($runtime)' : 1;

	# When an aspect falls out of scope, we don't attempt to remove
	# the generated hook code, because it might (for reasons potentially
	# outside our control) have been recursively hooked several times
	# by both Aspect and other modules.
	# Instead, we store an "out of scope" flag that is used to shortcut
	# past the hook as quickely as possible.
	# This flag is shared between all the generated hooks for each
	# installed Aspect.
	# If the advice is going to last lexical then we don't need to
	# check or use the $out_of_scope variable.
	my $out_of_scope   = undef;
	my $MATCH_DISABLED = $lexical ? '$out_of_scope' : '0';

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
		package Aspect::Advice::Hook;

		*$NAME = sub $PROTOTYPE {
			# Is this a lexically scoped hook that has finished
			goto &\$original if $MATCH_DISABLED;

			# Apply any runtime-specific context checks
			my \$wantarray = wantarray;
			my \$runtime   = {
				sub_name  => \$name,
				wantarray => \$wantarray,
			};
			goto &\$original unless $MATCH_RUN;

			# Prepare the context object
			my \$context   = Aspect::AdviceContext->new(
				type         => 'around',
				pointcut     => \$pointcut,
				params       => \\\@_,
				return_value => \$wantarray ? [ ] : undef,
				original     => \$original,
				\%\$runtime,
			);

			# Array context needs some special return handling
			if ( \$wantarray ) {
				# Run the advice code
				() = Sub::Uplevel::uplevel(
					1, \$code, \$context,
				);

				# Don't run the original
				my \$rv = \$context->return_value;
				if ( ref \$rv eq 'ARRAY' ) {
					return \@\$rv;
				} else {
					return ( \$rv );
				}
			}

			# Scalar and void have the same return handling.
			# Just run the advice code differently.
			if ( defined \$wantarray ) {
				my \$dummy = Sub::Uplevel::uplevel(
					1, \$code, \$context,
				);
			} else {
				Sub::Uplevel::uplevel(
					1, \$code, \$context,
				);
			}

			return \$context->return_value;
		};
END_PERL
	}

	# If this will run lexical we don't need a descoping hook
	return unless $lexical;

	# Return the lexical descoping hook.
	# This MUST be stored and run at DESTROY-time by the
	# parent object calling _install. This is less bullet-proof
	# than the DESTROY-time self-executing blessed coderef
	return sub { $out_of_scope = 1 };
}

1;
