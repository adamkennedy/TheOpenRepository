package Aspect::Advice;

use strict;
use warnings;

our $VERSION = '0.91';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Install and save the lexical hook
	$self->{hook} = $self->_install;

	return $self;
}

sub code {
	$_[0]->{code};
}

sub pointcut {
	$_[0]->{pointcut};
}

sub lexical {
	$_[0]->{lexical};
}

sub DESTROY {
	$_[0]->{hook}->() if $_[0]->{hook};
}

1;

__END__

=pod

=head1 NAME

Aspect::Advice - Change how Perl code is run at a pointcut

=head1 SYNOPSIS

  # Trace calls to all functions in all MyAccount classes
  use Aspect;
  
  before {
      print 'Called: '. $_->sub_name;
  } call qw/^MyAccount::/;
  
  
  
  # Repeat using the pure object-oriented interface
  use Aspect::Advice::Before ();
  use Aspect::Pointcut::Call ();

  my $advice = Aspect::Advice::Before->new(
     pointcut => Aspect::Pointcut::Call->new( qr/^MyAccount::/ ),
     code     => sub {
          print 'called: '. $_->sub_name;
     },
  );

=head1 DESCRIPTION

An "advice" in AOP lingo is composed of a condition (known as a
L<Aspect::Pointcut|pointcut>) and some code that will run when that
pointcut is true.

This code is run before, after, or around the target pointcut depending on
the particular advice type declaration used.

You do not normally create advice using the constructor. By C<use()>ing
L<Aspect|::Aspect>, you get five advice declaration subroutines imported.

C<before> is used to indicate code that should run prior to the function
being called. See L<Aspect::Advice::Before> for more information.

C<after> is used to indicate code that should run following the function
being called, regardless of whether it returns normally or throws an
exception. See L<Aspect::Advice::After> for more information.

C<around> is used to take deeper control of the call and gives you your
own lexical scope between the caller and callee, with a specific C<proceed>
call required in your code to execute the target function. See
L<Aspect::Advice::Around> for more information.

Two more specialised variants of C<after> are also available.

C<after_returning> is used to indicate code that should run following the
function, but ignoring exceptions and allowing them to raise normally. See
L<Aspect::Advice::AfterReturning> for more information.

C<after_throwing> is used to indicate code that should run only when the
target function throws an exception. See L<Aspect::Advice::AfterThrowing>
for more information.

Then the advice code is called, it is provided with an L<Advice::Point>
object which describes the context of the call to the target function, and
allows you to change it.

This parameter is provided both via the topic variable C<$_> (since version
0.90) and additionally as the first parameter to the advice code (which may
be deprecated at some point in the future).

If you are creating C<advice> objects directly via the OO interface, you
should never use this class directly but instead use the class of the
particular type of advice you want to create.
 
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
