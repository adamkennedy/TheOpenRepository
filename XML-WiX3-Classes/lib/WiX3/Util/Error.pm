package WiX3::Util::Error;

use strict;
use warnings;

use version; our $VERSION = version->new('0.004')->numify;
use WiX3::Exceptions;

sub new {
    my ( $self, @args ) = @_;
    return $self->_create_error_carpmess( @args );
}

sub create_error_croak {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args );
}

sub create_error_confess {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args, longmess => 1 );
}

sub _create_error_carpmess {
    my ( $self, %args ) = @_;

#	require Data::Dumper;
#	print STDERR Data::Dumper->new([\%args])->Indent(1)->Dump();

    my $carp_level = 3 + ( $args{depth} || 1 );

    my @args = exists $args{message} ? $args{message} : ();
	my $info = join '', @args;
	
	my $longmess = exists $args{longmess} ? !! $args{longmess} : 0;
	
	WiX3::Exception::Caught->throw(
		message => 'Moose',
		info => $info,
		longmess => $longmess
	);
	
	return;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Moose::Error::Default - L<Carp> based error generation for Moose.

=head1 DESCRIPTION

This class implements L<Carp> based error generation.

The default behavior is like L<Moose::Error::Confess>.

=head1 METHODS

=over 4

=item new @args

Create a new error. Delegates to C<create_error_confess>.

=item create_error_confess @args

=item create_error_croak @args

Creates a new errors string of the specified style.

=back

=cut


