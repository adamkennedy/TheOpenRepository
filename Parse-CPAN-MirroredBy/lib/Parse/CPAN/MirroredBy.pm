package Parse::CPAN::MirroredBy;

use 5.006;
use strict;
use warnings;
use Carp         'croak';
use Params::Util qw{ _CODELIKE _HANDLE };

my $DOMAIN = qr/(?-xism:(?: |(?:[A-Za-z](?:(?:[-A-Za-z0-9]){0,61}[A-Za-z0-9])?(?:\.[A-Za-z](?:(?:[-A-Za-z0-9]){0,61}[A-Za-z0-9])?)*)))/;





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
		last if ! $string;
		$line = $line + 1;

		# Remove the useless lines
		next if $string =~ /^\s*$/;
		next if $string =~ /^\s*#/;

		# Hostname or property?
		if ( $string =~ /^\s/ ) {
			# Property
			unless ( $string =~ /^\s+(\w+)\s+=\s+\"(.+)\"$/ ) {
				croak("Invalid propery on line $line");
			}
			$mirror ||= {};
			$mirror->{"$1"} = "$2";

		} else {
			# Hostname
			unless ( $string =~ /^($DOMAIN)\:\s*$/ ) {
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
	foreach my $op ( @{$self->{filters} ) {
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
