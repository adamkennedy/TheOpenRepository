package Aspect::Pointcut;

=pod

=head1 NAME

Aspect::Pointcut - API for determining which events should be hooked

=head1 DESCRIPTION

Aspect-Oriented Programming implementations draw much of their power from the
flexibility that can be applied to when a function call should or should not
be hooked.

B<Aspec::Pointcut> provides a robust and powerful API for defining the rules
for when a function call should be hooked, and then applying the rules as
optimally as possible. This optimisation is particularly important for any
pure-Perl implementation, which cannot hook deeply into the underlying 
virtual machine as you might with a Java or Perl XS-based implementation.

A running program can be seen as a collection of events. Events like a
sub returning from a call, or a package being used. These are called join
points. A pointcut defines a set of join points, taken from all the join
points in the program. Different pointcut classes allow you to define the
set in different ways, so you can target the exact join points you need.

Pointcuts are constructed as trees; logical operations on pointcuts with
one or two arguments (not, and, or) are themselves pointcut operators.
You can construct them explicitly using object syntax, or you can use the
convenience functions exported by Aspect and the overloaded operators
C<!>, C<&> and C<|>.

=head1 METHODS

=cut

use strict;
use warnings;
use Aspect::Pointcut::Or  ();
use Aspect::Pointcut::And ();
use Aspect::Pointcut::Not ();

our $VERSION = '0.45';

use overload (
	# Keep traditional Perl boolification and stringification
	'bool' => sub () { 1 },
	'""'   => sub { ref $_[0] },

	# Overload bitwise boolean operators to perform logical transformations.
	'|'    => sub { Aspect::Pointcut::Or ->new( $_[0], $_[1] ) },
	'&'    => sub { Aspect::Pointcut::And->new( $_[0], $_[1] ) },
	'!'    => sub { Aspect::Pointcut::Not->new( $_[0]        ) },

	# Everything else should fail to match and throw an exception
);





######################################################################
# Constructor

=pod

=head2 new

The C<new> constructor creates new pointcut objects.

All pointcut classes define their own rules around the parameters that are
provided, but once created these pointcuts can then all be mixed together in
an arbitrary fashion.

Note: Unlike most Perl objects the default and recommended underlying datatype
for pointcut objects is an C<ARRAY> reference rather than C<HASH> references.
This is done because pointcut code can directly impact the speed of function
calls, and so is extremely performance sensitive.

=cut

sub new {
	my $class = shift;
	bless [ @_ ], $class;
}





######################################################################
# Weaving Methods

my %PRUNE;
my %IGNORE;
BEGIN {
	# Classes we should not recurse down into
	%PRUNE  = map { $_ => 1 } qw{
		main
		CORE
		DB
		Aspect
	};

	# Classes we should not hook functions in
	%IGNORE = map { $_ => 1 } qw{
		Aspect
		Carp
		Carp::Heavy
		Config
		CORE
		DB
		DynaLoader
		Exporter
		Exporter::Heavy
		IO
		IO::Handle
		Regexp
		Sub::Uplevel
		UNIVERSAL
		attributes
		base
		feature
		fields
		lib
		strict
		warnings
		warnings::register
	};
}

=pod

=head2 match_all

  my @fully_resolved_function_names = $pointcut->match_all();

The C<match_all> method is the primary compile-time function called on the
pointcut model by the core Aspect library.

It will examine the list of all loaded functions and identify those which
could potentially match, and will need to have hooks installed to intercept
calls to those functions.

These functions will not necesarily all result in Aspect code being run.
Some functions may be called in all cases, but often further run-time
analyis needs to be done before we can be sure the particular function call
respresents a match.

Returns a list of fully-resolved function names
(e.g. "Module::Name::function")

=cut

sub match_all {
	my $self    = shift;
	my @matches = ();

	# Quick initial root package scan to remove the need
	# for special-casing of main:: in the recursive scan.
	no strict 'refs';
	my @search = ();
	my ($key,$value);
	while ( ($key,$value) = each %{*{"::"}} ) {
		next unless defined $value;
		local (*ENTRY) = $value;
		next unless defined *ENTRY{HASH};
		next unless $key =~ /^([^\W\d]\w*)::\z/;

		# Suppress aggressively ignored things
		if ( $IGNORE{$1} and $PRUNE{$1} ) {
			next;
		}

		push @search, $1;
	}

	# Search using a simple package list-recursion
	while ( my $package = shift @search ) {
		no strict 'refs';
		my ($key,$value);
		while ( ($key,$value) = each %{*{"$package\::"}} ) {
			next if $key =~ /[^\w:]/;
			next unless defined $value;
			my $name = "$package\::$key";
			local(*ENTRY) = $value;

			# Is this a matched function?
			if (
				defined *ENTRY{CODE}
				and
				not $IGNORE{$package}
				and
				not $Aspect::EXPORTED{$name}
				and
				$self->match_define($name)
			) {
				push @matches, $name;
			}

			# Is this a package we should recurse into?
			if (
				not $PRUNE{$package}
				and
				$name =~ s/::\z//
				and
				defined *ENTRY{HASH}
			) {
				push @search, $name;
			}
		}
	}

	return @matches;
}

=pod

=head2 match_define

  my $should_hook = $pointcut->match_define();

At compile time, the only common factor in predicting the future state of
a function call is the name of the function itself.

The C<match_define> method is called on the pointcut for each
theoretically-matchable function in the entire Perl namespace that part of
an ignored namespace, passing a single parameter of the fully-resolved
function name.

The method will determine if the function B<might> match, and needs to be
hooked for further checking at run-time, potentially calling C<match_define>
on child objects as well.

Returns true if the function might match the pointcut, or false if the
function can never possibly match the pointcut and should never be checked
at run-time.

=cut

sub match_define {
	my $class = ref $_[0] || $_[0];
	die("Method 'match_define' not implemented in class '$class'");
}

=pod

=head2 match_contains

  my $contains_any = $pointcut->match_contains('Aspect::Pointcut::Call');

The C<match_contains> method provides a convenience for the optimisation
system which is used to check for the existance of a particular condition
type anywhere within the pointcut object tree.

Returns true if the tree contains any conditions of that type, or false
if not.

=cut

sub match_contains {
	my $self = shift;
	return 1 if $self->isa($_[0]);
	return '';
}

=pod

=head2 match_curry

  my $optimized_pointcut = $raw_pointcut->match_curry();

In a production system, pointcut declarations can result in large and
complex B<Aspect::Pointcut> object trees.

Because this tree can contain a large amount of structure that is no longer
relevant at run-time, making a long series of prohibitively expensive
cascading C<match_run> calls before every single function call.

To reduce this cost down to something more reasonable, pointcuts are run
through a currying process ( see L<http://en.wikipedia.org/wiki/Currying> ).

A variety of optimisations are used to simplify boolean nesting, to remove
tests that are irrelevant once the compile-time hooks have all been set up,
and that the currying process can determine will never need to be tested.

The currying process will generate and return a new pointcut tree that is
independant from the original, and that can perform a match test at the
minimum possible computational cost.

Returns a new optimised B<Aspect::Pointcut> object if any further testing
needs to be done at run-time for the pointcut. Returns null (C<undef> in
scalar context or C<()> in list context) if the pointcut can be curried
away to nothing, and no further testing needs to be done at run-time.

=cut

sub match_curry {
	my $class = ref $_[0] || $_[0];
	die("Method 'match_curry' not implemented in class '$class'");
}

sub match_runtime {
	return 1;
}





######################################################################
# Runtime Methods

=pod

=head2 match_run

  my $match_boolean = $pointcut->match_run( $context );

The C<match_run> is used to test hooked functions at run-time to determine
if the current invocation of the function matches the pointcut conditions.

It is passed an L<Aspect::Context> object representing the current function
invocation.

Returns true if the current invocation matches the pointcut and should have
its advice run, or false if the current invocation is not part of the
pointcut and the advice should not be run for this function call.

=cut

sub match_run {
	my $class = ref $_[0] || $_[0];
	die("Method 'match_run' not implemented in class '$class'");
}

1;

__END__

=pod

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
