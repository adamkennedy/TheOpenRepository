package Mirror::YAML;

use 5.005;
use strict;
use Params::Util      qw{ _STRING _POSINT _ARRAY0 _INSTANCE };
use YAML::Tiny        ();
use URI               ();
use Time::HiRes       ();
use Time::Local       ();
use LWP::Simple       ();
use Mirror::YAML::URI ();

use constant ONE_DAY     => 86700; # 1 day plus 5 minutes fudge factor
use constant TWO_DAYS    => 172800;
use constant THIRTY_DAYS => 2592000;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Wrapper for the YAML::Tiny methods

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	if ( _STRING($self->{uri}) ) {
		$self->{uri} = URI->new($self->{uri});
	}
	if ( _STRING($self->{timestamp}) and ! _POSINT($self->{timestamp}) ) {
		unless ( $self->{timestamp} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z$/ ) {
			return undef;
		}
		$self->{timestamp} = Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 );
	}
	unless ( _ARRAY0($self->{mirrors}) ) {
		return undef;
	}
	foreach ( @{$self->{mirrors}} ) {
		if ( _STRING($_->{uri}) ) {
			$_->{uri} = URI->new($_->{uri});
			$_ = Mirror::YAML::URI->new( %$_ ) or return undef;
		}
	}
	return $self;
}

sub read {
	my $class = shift;
	my $yaml  = YAML::Tiny->read( @_ );
	$class->new( %{ $yaml->[0] } );
}

sub read_string {
	my $class = shift;
	my $yaml  = YAML::Tiny->read_string( @_ );
	$class->new( %{ $yaml->[0] } );
}

sub write {
	my $self = shift;
	$self->as_yaml_tiny->write( @_ );
}

sub write_string {
	my $self = shift;
	$self->as_yaml_tiny->write_string( @_ );
}

sub as_yaml_tiny {
	my $self = shift;
	my $yaml = YAML::Tiny->( { %$self } );
	if ( defined $yaml->{source} ) {
		$yaml->{source} = "$yaml->{source}";
	}
	$yaml;
}





#####################################################################
# Mirror::YAML Methods

sub name {
	$_[0]->{name};
}

sub uri {
	$_[0]->{uri};
}

sub timestamp {
	$_[0]->{timestamp};
}

sub age {
	$_[0]->{age} or time - $_[0]->{timestamp};
}

sub benchmark {
	$_[0]->{benchmark};
}

sub mirrors {
	@{ $_[0]->{mirrors} };
}





#####################################################################
# Main Methods

sub check_mirrors {
	my $self = shift;
	foreach my $mirror ( $self->mirrors ) {
		next if defined $mirror->{live};
		$mirror->get;
	}
	return 1;
}

# Does the mirror with the newest timestamp newer than ours
# have a different master? If so, update our master server.
# This lets us survive major reorgansations, as long as some
# of the existing mirrors are retained.
sub check_master {
	my $self = shift;

	# Make sure we have checked the mirrors
	$self->check_mirrors;

	# Anti-hijacking measure: Only do this if our current
	# age is more than 30 days. We can almost certainly
	# handle a 1 month changeover period, otherwise things
	# will only be bad for a month.
	if ( $self->age < THIRTY_DAYS ) {
		return 1;
	}

	# Find all the servers updated in the last 2 days.
	# All of them except 1 must agree (prevent hijacking,
	# and handle accidents or anti-update attack from older server)
	my %uri = ();
	map { $uri{$_->uri}++ } grep { $_->age >= 0 and $_->age < TWO_DAYS } $self->mirrors;
	my @uris = sort { $uri{$b} <=> $uri{$a} } keys %uri;
	unless ( scalar(@uris) <= 2 and $uris[0] and $uris[0] >= (scalar($self->mirrors) - 1) ) {
		# Data is weird or currupt
		return 1;
	}

	# Master has moved.
	# Pull the new master server mirror.yaml
	my $new_uri = Mirror::YAML::URI->new(
		uri => URI->new( $uris[0] ),
		) or return 1;
	$new_uri->get or return 1;

	# To avoid pulling a whole bunch of mirror.yml files again
	# copy any mirrors from our set to the new 
	my $new = $new_uri->yaml or return 1;
	my %old = map { $_->uri => $_ } $self->mirrors;
	foreach ( @{ $new->{mirrors} } ) {
		if ( $old{$_->uri} ) {
			$_ = $old{$_->uri};
		} else {
			$_->get;
		}
	}

	# Now overwrite ourself with the new one
	%$self = %$new;

	return 1;
}

# Select the "best" mirrors
sub select_mirrors {
	my $self   = shift;
	my $wanted = _POSINT(shift) || 3;

	# Check the mirrors
	$self->check_mirrors;

	# Start with the list of all live mirrors, and create
	# some interesting subsets.
	my @live    = sort { $a->lag <=> $b->lag } grep { $_->live } $self->mirrors;
	my @current = grep { $_->yaml->age < ONE_DAY } @live;
	my @ideal   = grep { $_->lag < 2       } @current;

	# If there are enough fast and up-to-date mirrors
	# (which should be common for many people) return them.
	if ( @ideal >= $wanted ) {
		return map { $_->uri } @ideal[0 .. $wanted];
	}

	# If there are enough up-to-date mirrors
	# (which should be common) return them.
	if ( @current >= $wanted ) {
		return map { $_->uri } @current[0 .. $wanted];
	}

	# Are there ANY that are up to date
	if ( @current ) {
		return map { $_->uri } @current;
	}

	# Something is weird, just use the master site
	return ( $self->uri );
}

1;

__END__

=pod

=head1 NAME

Mirror::YAML - Mirror Configuration and Auto-Discovery

=head1 DESCRIPTION



=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mirror-YAML>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<YAML::Tiny>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
