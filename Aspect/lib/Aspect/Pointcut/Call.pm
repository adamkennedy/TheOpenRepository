package Aspect::Pointcut::Call;

use strict;
use warnings;
use Carp             ();
use Params::Util     ();
use Aspect::Pointcut ();

our $VERSION = '0.45';
our @ISA     = 'Aspect::Pointcut';

use constant ORIGINAL     => 0;use constant COMPILE_CODE => 1;
use constant RUNTIME_CODE => 2;
use constant COMPILE_EVAL => 3;
use constant RUNTIME_EVAL => 4;





######################################################################
# Constructor Methods

# The constructor stores three values.
# $self->[0] is the original specification provided to the constructor
# $self->[1] is a function form of the condition that has a sub name passed
#            in and returns true if matching or false if not.
# $self->[2] is a either a string that is a fragment of Perl that can be eval'ed
#            with $_ set to a join point object, or a function in the style of
#            the $self->[1] param above and taking the sub name param. Returns
#            true if matching or false if not.
sub new {
	my $class = shift;
	my $spec  = shift;
	if ( Params::Util::_STRING($spec) ) {
		my $string = '"' . quotemeta($spec) . '"';
		return bless [
			$spec,
			eval "sub () { \$_[0] eq $string }",
			eval "sub () { \$_ eq $string }",
			eval "sub () { \$_->{sub_name} eq $string }",
			"\$_ eq $string",
			"\$_->{sub_name} eq $string",
		], $class;
	}
	if ( Params::Util::_CODELIKE($spec) ) {
		return bless [
			$spec,
			$spec,
			sub { $spec->($_) },
			sub { $spec->($_->{sub_name}) },
			sub { $spec->($_) },
			sub { $spec->($_->{sub_name}) },
		], $class;
	}
	if ( Params::Util::_REGEX($spec) ) {
		# Special case serialisation of regexs
		my $regex = "$spec";
		$regex =~ s|^\(\?([xism]*)-[xism]*:(.*)\)\z|/$2/$1|s;
		return bless [
			$spec,
			eval "sub () { \$_[0] =~ $regex }",
			eval "sub () { $regex }",
			eval "sub () { \$_->{sub_name} =~ $regex }",
			$regex,
			"\$_->{sub_name} =~ $regex",
		], $class;
	}
	Carp::croak("Invalid function call specification");
}





######################################################################
# Weaving Methods

sub match_runtime {
	return 0;
}

# Call pointcuts curry away to null, because they are the basis
# for which methods to hook in the first place. Any method called
# at run-time has already been checked.
sub match_curry {
	return;
}

# Compiled string form of the pointcut
sub match_compile1 {
	$_[0]->[4];
}

# Compiled string form of the pointcut
sub match_compile2 {
	$_[0]->[5];
}





######################################################################
# Runtime Methods

# Because we now curry away this pointcut, theoretically we should just
# return true. But if it is ever run inside a negation it returns false
# results. So since this should never be run due to currying leave the
# method resolving to the parent class die'ing stub.
# Having this method die will allow us to more easily catch places where
# this method is being called incorrectly.
sub match_run {
	$_[0]->[1]->($_[1]->{sub_name});
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Call - Call pointcut

=head1 SYNOPSIS

  use Aspect;
  
  # High-level creation
  my $pointcut1 = call 'one';
  
  # Manual creation
  my $pointcut2 = Aspect::Pointcut::Call->new('one');

=head1 DESCRIPTION

None yet.

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
