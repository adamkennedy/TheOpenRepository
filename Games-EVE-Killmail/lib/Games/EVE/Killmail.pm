package Games::EVE::Killmail;

use 5.005;
use strict;
use Carp         'croak';
use DateTime     ();
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	datetime
	victim
	alliance
	corp
	ship
	system
	security
};

use Games::EVE::Killmail::InvolvedParty ();
use Games::EVE::Killmail::DestroyedItem ();





#####################################################################
# Constructors and Accessors

sub parse_string {
	my $class   = shift;
	my $rawmail = _STRING(shift)
		or croak("Did not pass a string to parse_string");

	# Split into lines, trimming
	$rawmail =~ s/^\s+//s;
	$rawmail =~ s/\s+$//s;
	my @lines = split /\n/, $rawmail;
	foreach ( @lines ) {
		# Trim all whitespace
		s/^\s+//s;
		s/\s+$//s;
	}

	# The first line should be a timestamp
	my $timestamp = shift @lines;
	unless ( $timestamp =~ /^(\d\d\d\d)\.(\d\d)\.(\d\d) (\d\d)\:(\d\d)$/ ) {
		croak("Invalid timestamp line '$timestamp'");
	}
	my $datetime = DateTime->new(
		year   => "$1",
		month  => "$2",
		day    => "$3",
		hour   => "$4",
		minute => "$5",
		second => 0,
		locale => 'C',
		) or croak("Failed to create DateTime for timestamp '$timestamp'");

	# Skip over blanks
	while ( ! length $lines[0] ) { shift @lines; next }

	# Create the basic object
	my $involved  = [];
	my $destroyed = [];
	my $self      = $class->new(
		rawmail   => $rawmail,
		datetime  => $datetime,
		victim    => undef,
		alliance  => undef,
		corp      => undef,
		ship      => undef,
		system    => undef,
		security  => undef,
		involved  => $involved,
		destroyed => $destroyed,
		);

	# Parse the subject and attributes
	while ( defined(my $line = shift @lines) ) {
		unless ( $line =~ /^(\w+): (.+)$/ ) {
			# End of section
			last;
		}
		my $key = lc $1;
		my $value = $2;
		if ( $key eq 'destroyed' ) {
			$key = 'ship';
		}
		$self->{$key} = $value;
	}

	# The next section should be the involved parties
	my $involved_line = shift @lines;
	unless ( $involved_line eq 'Involved parties:' ) {
		croak("Did not get expected 'Involved parties:' section");
	}

	# Skip over blanks
	while ( ! length $lines[0] ) { shift @lines; next }

	# Parse the involved parties
	while ( $lines[0] and $lines[0] =~ /^Name:/ ) {
		push @$involved, Games::EVE::Killmail::InvolvedParty->parse_lines( \@lines );

		# Skip over blanks
		while ( ! length $lines[0] ) { shift @lines; next }
	}

	# The next section should be destroyed items
	my $destroyed_line = shift @lines;
	unless ( $destroyed_line eq 'Destroyed items:' ) {
		croak("Did not get expected 'Destroyed items:' section");
	}

	# Skip over blanks
	while ( ! length $lines[0] ) { shift @lines; next }

	# Each line should be a seperate item
	while ( _STRING($lines[0]) ) {
		push @$destroyed, Games::EVE::Killmail::DestroyedItem->parse_string( shift @lines );
	}

	return $self;
}

sub involved {
	@{$_[0]->{involved}};
}

sub destroyed {
	@{$_[0]->{destroyed}};
}

1;

__END__

=pod

=head1 NAME

Games::EVE::Killmail - Object representation of an EVE Online killmail

=head1 SYNOPSIS

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

=cut
