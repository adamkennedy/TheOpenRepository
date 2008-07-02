package Parse::CPAN::MirroredBy;

=pod

=head1 NAME

Parse::CPAN::MirroredBy - Parse MIRRORED.BY

=head1 DESCRIPTION

Like the other members of the Parse::CPAN family B<Parse::CPAN::MirroredBy>
parses and processes the CPAN meta data file F<MIRRORED.BY>.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Carp         'croak';
use IO::File     ();
use Params::Util qw{ _CODELIKE _HANDLE };





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { filters => [] }, $class;
	return $self;
}

sub add_map {
	my $self = shift;
	my $code = _CODELIKE(shift);
	unless ( $code ) {
		croak("add_map: Not a CODE reference");
	}
	push @{$self->{filters}}, [ 'map', $code ];
	return 1;
}

sub add_grep {
	my $self = shift;
	my $code = _CODELIKE(shift);
	unless ( $code ) {
		croak("add_grep: Not a CODE reference");
	}
	push @{$self->{filters}}, [ 'grep', $code ];
	return 1;
}

sub add_bless {
	my $self  = shift;
	my $class = _DRIVER(shift, 'UNIVERSAL');
	unless ( $class ) {
		croak("add_bless: Not a valid class");
	}
	push @{$self->{filters}}, [ 'map', sub { bless $_, $class } ];
	return 1;
}





#####################################################################
# Parsing Methods

sub parse_file {
	my $self   = shift;
	my $handle = IO::File->new( $_[0], 'r' ) or croak("open: $!");
	return $self->parse( $handle );
}

sub parse {
	my $self   = shift;
	my $handle = _HANDLE(shift) or croak("Missing or invalid file handle");
	my $line   = 0;
	my $mirror = undef;
	my @output = ();

	while ( 1 ) {
		# Next line
		my $string = <$handle>;
		last if ! defined $string;
		$line = $line + 1;

		# Remove the useless lines
		chomp( $string );
		next if $string =~ /^\s*$/;
		next if $string =~ /^\s*#/;

		# Hostname or property?
		if ( $string =~ /^\s/ ) {
			# Property
			unless ( $string =~ /^\s+(\w+)\s+=\s+\"(.*)\"$/ ) {
				croak("Invalid property on line $line");
			}
			$mirror ||= {};
			$mirror->{"$1"} = "$2";

		} else {
			# Hostname
			unless ( $string =~ /^([\w\.-]+)\:\s*$/ ) {
				croak("Invalid host name on line $line");
			}
			my $current = $mirror;
			$mirror     = { hostname => "$1" };
			if ( $current ) {
				push @output, $self->_process( $current );
			}
		}
	}
	if ( $mirror ) {
		push @output, $self->_process( $mirror );
	}
	return @output;
}

sub _process {
	my $self   = shift;
	my @mirror = shift;
	foreach my $op ( @{$self->{filters}} ) {
		my $name = $op->[0];
		my $code = $op->[1];
		if ( $name eq 'grep' ) {
			@mirror = grep { $code->($_) } @mirror;
		} elsif ( $name eq 'map' ) {
			@mirror = map { $code->($_) } @mirror;
		}
	}
	return @mirror;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-CPAN-MirroredBy>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Parse::CPAN::Authors>, L<Parse::CPAN::Packages>,
L<Parse::CPAN::Modlist>, L<Parse::CPAN::Meta>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
