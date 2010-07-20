package Aspect::AdviceContext;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.91';
our @ISA     = 'Aspect::Point';

1;

__END__

=pod

=head1 NAME

Aspect::AdviceContext - The Join Point context (DEPRECATED)

=head1 SYNOPSIS

  $pointcut = call qr/^Person::[gs]et_/
            & cflow company => qr/^Company::/;
  
  # using in 'before' advice code
  before {
     my $context = shift;             # context is only param to advice code
     print $context->type;            # 'before': advice type: before/after
     print $context->pointcut;        # $pointcut: the pointcut for this advice
     print $context->sub_name;        # package + sub name of matched sub
     print $context->package_name;    # 'Person': package name of matched sub
     print $context->short_sub_name;  # sub name of matched sub
     print $context->self;            # 1st parameter to matched sub
     print $context->params->[1];     # 2nd parameter to matched sub
     $context->append_param($rdbms);  # append param to matched sub
     $context->append_params($a, $b); # append params to matched sub
     $context->return_value(4)        # don't proceed to matched sub, return 4
     $context->original->(x => 3);    # call matched sub, don't proceed
     $context->proceed(1);            # do proceed to matched sub after all
     print $context->company->name;   # access cflow pointcut advice context
  } $pointcut;

=head1 DESCRIPTION

B<This module has been deprecated and is included for back-compatibility.>
See L<Aspect::Point> for the replacement to this module.

Advice code is called when the advice pointcut is matched. In this code,
there is always a need to access information about the context of the
advice. Information like: what is the actual sub name matched? What are
the parameters in this call that we matched? Sometimes you want to change
the context for the matched sub: append a parameter, or even stop the
matched sub from being called.

You do all these things through the C<AdviceContext>. It is the only
parameter provided to the advice code. It provides all the information
required about the match context, and allows you to change the behavior
of the matched sub.

Note that modifying parameters through the context, in the code of an
I<after> advice, will have no effect, since the matched sub has already
been called.

=head1 CFLOW CONTEXT

If the pointcut of an advice is composed of at least one
L<Aspect::Pointcut::Cflow>, advice code may require not only the context
of the advice, but also the context of the cflows. This is required if
you want to find out, for example, what is the name of the sub that
matched a cflow. E.g. for the synopsis example above, what method of
C<Company> started the chain of calls that eventually reached the get/set
on C<Person>?

You can access cflow context in the synopsis above, by calling:

  $context->company;

You get it from the main advice context, by calling a method named after
the context key used in the cflow spec. In the synopsis pointcut
definition, the cflow part was:

  cflow company => qr/^Company::/
        ^^^^^^^

An C<AdviceContext> will be created for the cflow, and you can access it
using the key C<company>.

=head1 EXAMPLES

Print parameters to matched sub:

  before { my $c = shift; print join(',', $c->params) } $pointcut;

Append a parameter:

  before { shift->append_param('extra-param') } $pointcut;

Don't proceed to matched sub, return 4 instead:

  before { shift->return_value(4) } $pointcut;

Call matched sub again, and again, until it returns something defined:

  after {
     my $context = shift;
     my $return  = $context->return_value;
     while (!defined $return)
        { $return = $context->original($context->params) }
     $context->return_value($return);
  } $pointcut;

Print the name of the C<Company> object that started the chain of calls
that eventually reached the get/set on C<Person>:

  before { print shift->company->name } $pointcut;

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
