package Aspect::Pointcut;

use strict;
use warnings;
use Aspect::Pointcut::Or  ();
use Aspect::Pointcut::And ();
use Aspect::Pointcut::Not ();

our $VERSION = '0.44';

use overload (
	# Keep traditional Perl boolification and stringification
	'bool' => sub () { 1 },
	'""'   => sub { ref $_[0] },

	# Overload bitwise boolean operators to perform logical transformations.
	'|'    => sub { Aspect::Pointcut::Or ->new( $_[0], $_[1] ) },
	'&'    => sub { Aspect::Pointcut::And->new( $_[0], $_[1] ) },
	'!'    => sub { Aspect::Pointcut::Not->new( $_[0]        ) },

	# Everything else is free to throw an exception
);





######################################################################
# Constructor

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

sub match_runtime {
	return 1;
}

# Find the list of all matching subs
sub match_all {
	my $self    = shift;
	my @matches = ();

	# Quick initial root package scan to remove the need
	# for special-casing of main:: in the recursive scan.
	no strict 'refs';
	my @search = ();
	my ($key,$value);
	while ( ($key,$value) = each %{*{"::"}} ) {
		local (*ENTRY) = $value;
		next unless defined $value;
		next unless $key =~ s/^([^\W\d]\w*)::\z/$1/;
		next unless defined *ENTRY{HASH};

		# Suppress aggressively ignored things
		if ( $IGNORE{$key} and $PRUNE{$key} ) {
			next;
		}

		push @search, $key;
	}

	# Search using a simple package list-recursion
	while ( my $package = shift @search ) {
		no strict 'refs';
		my ($key,$value);
		while ( ($key,$value) = each %{*{"$package\::"}} ) {
			next unless $key =~ /^\w+(?:::)?\z/;
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

sub match_define {
	my $class = ref $_[0] || $_[0];
	die("Method 'match_define' not implemented in class '$class'");
}

sub match_contains {
	my $self = shift;
	return 1 if $self->isa($_[0]);
	return '';
}

sub match_curry {
	my $class = ref $_[0] || $_[0];
	die("Method 'curry' not implemented in class '$class'");
}





######################################################################
# Runtime Methods

sub match_run {
	my $class = ref $_[0] || $_[0];
	die("Method 'match_run' not implemented in class '$class'");
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut - pointcut base class

=head1 DESCRIPTION

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
