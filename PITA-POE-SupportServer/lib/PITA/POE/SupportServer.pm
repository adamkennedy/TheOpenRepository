package PITA::POE::SupportServer;

use strict;
use warnings;

use Carp qw( croak );
use POE qw( Component::Server::HTTP Wheel::Run );

use base qw( Process );

our $VERSION = '0.01';


sub new {
    my $package = shift;

    croak "new() only accepts an equal number of parameters" unless ( @_ % 2 );

    my %opt = @_;
    my $hr = {};

    croak "execute must be an array ref"
        unless ( $opt{execute} && ref( $opt{execute} } eq 'ARRAY' );
    $hr->{execute} = delete $opt{execute};

    croak "http_mirrors must be a hash ref of image paths to local paths"
        unless ( $opt{http_mirrors} && ref( $opt{http_mirrors} ) eq 'HASH' );
    $hr->{http_mirrors} = delete $opt{http_mirrors};
    
    $hr->{http_local_addr} = delete $opt{http_local_addr} || '127.0.0.1';
    $hr->{http_local_port} = delete $opt{http_local_port} || 80;
    
    $hr->{http_result} = delete $opt{http_result} || '/result.xml';
    $hr->{http_startup_timeout} = delete $opt{http_startup_timeout} || 30;
    $hr->{http_activity_timeout} = delete $opt{http_activity_timeout} || 3600;
    $hr->{http_shutdown_timeout} = delete $opt{http_shutdown_timeout} || 10;

    croak "unknown parameters: ".join( ',',keys %opt ) if ( keys %opt );
    
    bless( $hr, $package );
}

sub prepare {

}

sub run {

}

sub http_result {

}

1;

__END__

=head1 NAME

PITA::POE::SupportServer

=head1 SYNOPSIS

  use PITA::POE::SupportServer;

  my $server = PITA::POE::SupportServer->new(
          execute => [
                  '/usr/bin/qemu',
                  '-snapshot',
                  '-hda',
                  '/var/pita/image/ba312bb13f.img',
                  ],
          http_local_addr => '127.0.0.1',
          http_local_port => 80,
          http_mirrors => {
                  '/cpan' => '/var/cache/minicpan',
                  },
          http_result => '/result.xml',
          http_startup_timeout => 30,
          http_activity_timeout => 3600,
          http_shutdown_timeout => 10,
          ) or die "Failed to create support server";
  
  $server->prepare
          or die "Failed to prepare support server";
  
  $server->run
          or die "Failed to run support server";
  
  my $result_file = $server->http_result('/result.xml')
          or die "Guest Image execution failed";

=head1 ABSTRACT

=head1 DESCRIPTION

=head1 METHODS

=head2 EXPORT

Nothing.

=head1 AUTHORS

David Davis E<lt>xantus@cpan.orgE<gt>, Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<PITA>, L<POE>, L<Process>, L<http://ali.as/>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 David Davis. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

