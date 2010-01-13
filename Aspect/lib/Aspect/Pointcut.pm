package Aspect::Pointcut;

use strict;
use warnings;
use Devel::Symdump        ();
use Aspect::Pointcut::Or  ();
use Aspect::Pointcut::And ();
use Aspect::Pointcut::Not ();

our $VERSION = '0.37';

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

my %UNTOUCHABLE;
BEGIN {
	%UNTOUCHABLE = map { $_ => 1 } qw(
		Carp
		Carp::Heavy
		Config
		CORE
		CORE::GLOBAL
		DB
		DB::fake
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
	);
}

# Find the list of all matching subs
sub match_all {
	my $self    = shift;
	my @matches = ();

	# Temporary hack to avoid a ton of warnings.
	# Remove when Devel::Symdump stops throwing warnings.
	local $^W = 0;

	foreach my $package ( Devel::Symdump->rnew->packages, 'main' ) {
		next if $UNTOUCHABLE{$package};
		next if $package =~ /^Aspect\b/;
		foreach my $name ( Devel::Symdump->new($package)->functions ) {
			# TODO: Need to filter Aspect exportable functions!
			push @matches, $name if $self->match_define($name);
		}
	}

	return @matches;
}

sub match_define {
	my $class = ref $_[0] || $_[0];
	die("Method 'match_define' not implemented in class '$class'");
}

sub curry_run {
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
