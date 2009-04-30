package Aspect::Advice;

use strict;
use warnings;
use Carp;
use Aspect::AdviceContext;
use Aspect::Weaver;


our $VERSION = '0.15';


sub new {
	my ($class, $type, $code, $pointcut) = @_;
	my $self = bless {
		weaver   => Aspect::Weaver->new, # a weaver that will install advice code
		hooks    => undef,               # list of Hook::LexWrap hooks
		type     => $type,               # before or after
		code     => $code,               # the advice code
		pointcut => $pointcut,           # the advice pointcut
	}, $class;
	$self->install;
	return $self;
}

# private ---------------------------------------------------------------------

sub install {
	my $self     = shift;
	my $weaver   = $self->weaver;
	my $type     = $self->type;
	my $pointcut = $self->pointcut;
	my $code     = $self->code;
	# find all pointcuts that are statically matched
	# wrap the method with advice code and install the wrapper
	for my $sub_name ($weaver->get_sub_names) {
		next unless $pointcut->match_define($sub_name);
		my $wrapped_code = $self->wrap_code($type, $code, $pointcut, $sub_name);
		$self->add_hooks
			($weaver->install($type, $sub_name, $wrapped_code));
	}
}

# return wrapper sub to be installed instead of original
# wrapper sub creates context then calls advice code
# it runs only if the pointcut answers true to match_run()
sub wrap_code {
	my ($self, $type, $code, $pointcut, $sub_name) = @_;

	return sub {
		# hacked Hook::LexWrap calls hooks with 3 params
		my ($params, $original, $return_value) = @_;
		my $runtime_context = {};
		return unless $pointcut->match_run($sub_name, $runtime_context);

		# create context for advice code
		my $advice_context = Aspect::AdviceContext->new(
			sub_name       => $sub_name,
			type           => $type,
			pointcut       => $pointcut,
			params         => $params,
			return_value   => $return_value,
			original       => $original,
			%$runtime_context,
		);
		
		# execute advice code with its context
		if (wantarray)
			{ () = &$code($advice_context) }
		elsif (defined wantarray)
			{ my $dummy = &$code($advice_context) }
		else
			{ &$code($advice_context) }

		# if proceeding to original, modify params, else modify return value
		if ($type eq 'before' && $advice_context->proceed)
			{ @$params = $advice_context->params }
		else
			{ $_[-1] = $advice_context->return_value }
	};
}

sub add_hooks { push @{shift->{hooks}}, shift }

sub weaver   { shift->{weaver}   }
sub type     { shift->{type}     }
sub code     { shift->{code}     }
sub pointcut { shift->{pointcut} }

1;

__END__

=head1 NAME

Aspect::Advice - change how Perl code is run at a pointcut

=head1 SYNOPSIS

  # creating using public interface: trace calls to Account subs
  use Aspect;
  before { print 'called: '. shift->sub_name } call qw/^Account::/;

  # creating using internal interface
  use Aspect::Advice;
  $advice = Aspect::Advice->new(before =>
     { print 'called: '. shift->sub_name },
     call qw/^Account::/
  );

=head1 DESCRIPTION

An advice is composed of a pointcut and some code that will run at the
pointcut. The code is run C<before> or C<after> the pointcut, depending
on advice C<type>.

You do not normally create advice using the constructor. By C<use()>ing
L<Aspect|::Aspect>, you get 2 subs imported: C<before()> and C<after()>,
that do what you need. They also store the advice if called in void
context, so you do not need to keep in scope. The advice code will be
removed when the advice object is destroyed.

The advice code is given one parameter: an L<Aspect::AdviceContext>. You
use this object to change the parameter list for the matched sub, modify
return value, find out information about the matched sub, and more.

This class has no public methods that do anything, but there are
accessors C<weaver()>, C<type()>, C<code()>, and C<pointcut()>, if you
need them.

=head1 SEE ALSO

See the L<Aspect|::Aspect> pod for a guide to the Aspect module.

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

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

Ran Eilam C<< <eilara@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2001 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

