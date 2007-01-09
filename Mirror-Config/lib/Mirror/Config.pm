package Mirror::Config;

use 5.005;
use strict;
use Params::Util '_STRING';
use YAML::Tiny   ();
use URI          ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Wrapper for the YAML::Tiny methods

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	if ( _STRING($self->{source}) ) {
		$self->{source} = URI->new($self->{source});
	}
	return $self;
}

sub read {
	my $class = shift;
	my $yaml  = YAML::Tiny->read( @_ );
	$class->new( %$yaml );
}

sub read_string {
	my $class = shift;
	my $yaml  = YAML::Tiny->read_string( @_ );
	$class->new( %$yaml );
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
# Mirror::Config Methods

sub name {
	$_[0]->{name};
}

sub source {
	$_[0]->{source};
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
