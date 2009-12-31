package Aspect::Advice::Before;

use strict;
use warnings;

# Added by eilara as hack around caller() core dump
# NOTE: Now we've switched to Sub::Uplevel can this be removed? --ADAMK
use Carp::Heavy     (); 
use Carp            ();
use Aspect::Cleanup ();
use Aspect::Advice  ();

our $VERSION = '0.24';
our @ISA     = 'Aspect::Advice';

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

# This should never be called by our own code.
# It only exists for back-compatibility purposes.
sub type {
	return 'before';
}

sub _install {
	my $self     = shift;
	my $pointcut = $self->pointcut;
	my $code     = $self->code;

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
		no strict 'refs';
		my $original = *$name{CODE};
		unless ( $original ) {
			Carp::croak("Can't wrap non-existent subroutine ", $name);
		}

		# Any way to set prototypes other than eval?
		my $prototype = prototype($original);
		   $prototype = defined($prototype) ? "($prototype)" : '';

		# Generate the new function
		no warnings 'redefine';
		eval "sub $name $prototype " . q{{
			if ( $out_of_scope ) {
				# Lexical Aspect is out of scope
				goto &$original;
			}

			# Apply any runtime-specific context checks
			my $runtime = {};
			unless ( $pointcut->match_run($name, $runtime) ) {
				goto &$original;
			}

			# Prepare the context object
			my $wantarray = wantarray;
			my $context   = Aspect::AdviceContext->new(
				type         => 'before',
				pointcut     => $pointcut,
				sub_name     => $name,
				wantarray    => $wantarray,
				params       => \@_,
				return_value => $wantarray ? [ ] : undef,
				original     => $original,
				%$runtime,
			);

			# Array context needs some special return handling
			if ( $wantarray ) {
				# Run the advice code
				() = &$code($context);

				if ( $context->proceed ) {
					@_ = $context->params;
					goto &$original;
				}

				# Don't run the original
				my $rv = $context->return_value;
				if ( $rv eq 'ARRAY' ) {
					return @$rv;
				} else {
					return ( $rv );
				}
			}

			# Scalar and void have the same return handling.
			# Just run the advice code differently.
			if ( defined $wantarray ) {
				my $dummy = &$code($context);
			} else {
				&$code($context);
			}

			# Do they want to shortcut?
			unless ( $context->proceed ) {
				return $context->return_value;
			}

			# Continue onwards to the original function
			@_ = $context->params;
			goto &$original;
		}};
		die $@ if $@;
	}

	# Return the lexical hook
	return Aspect::Cleanup->new( sub { $out_of_scope = 1 } );
}

1;
