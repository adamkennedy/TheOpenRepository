package Mirror::Config;

use 5.005;
use YAML::Tiny;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Wrapper for the YAML::Tiny methods

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub read {
	my $class = shift;
	my $yaml  = YAML::Tiny->read( @_ );
	my $self  = $yaml->[0];
	bless $self, $class;
	return $self;
}

sub read_string {
	my $class = shift;
	my $yaml  = YAML::Tiny->read_string( @_ );
	my $self  = $yaml->[0];
	bless $self, $class;
	return $self;
}

sub write {
	my $self = shift;
	my $hash = { %$self };
	my $yaml = YAML::Tiny->new( $hash );
	return $yaml->write( @_ );
}

sub write_string {
	my $self = shift;
	my $hash = { %$self };
	my $yaml = YAML::Tiny->new( $hash );
	return $yaml->write_string( @_ );
}





#####################################################################
# Mirror::Config Methods

sub name {
	$_[0]->{name};
}

1;

__END__

=pod

=head1 NAME

Mirror Configuration Object

=head1 DESCRIPTION

blah

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mirror-Config>

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
