package Aspect::Advice::Before;

use strict;
use warnings;
use Aspect::Advice        ();
use Aspect::Hook::LexWrap ();

our $VERSION = '0.23';
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
				type           => 'before',
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

			# If proceeding to original, modify params, else modify return value
			if ( $advice_context->proceed ) {
				@$params = $advice_context->params;
			} else {
				$_[-1] = $advice_context->return_value;
			}
		};

		$self->add_hooks(
			Aspect::Hook::LexWrap::before( $name, $wrapped )
		);
	}
}

1;
