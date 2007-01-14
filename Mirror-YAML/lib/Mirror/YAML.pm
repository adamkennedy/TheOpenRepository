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

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
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

sub benchmark {
	$_[0]->{benchmark};
}

sub mirrors {
	@{ $_[0]->{mirrors} };
}





#####################################################################
# Main Methods

sub get_all {
	my $self = shift;
	foreach my $mirror ( $self->mirrors ) {
		$mirror->get;
	}
	return 1;
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
