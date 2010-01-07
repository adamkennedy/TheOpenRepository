package Aspect::Advice;

use strict;
use warnings;

our $VERSION = '0.31';

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

sub forever {
	$_[0]->{forever};
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

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 SEE ALSO

You can find AOP examples in the C<examples/> directory of the
distribution.

=head1 COPYRIGHT AND LICENSE

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
