package PITA::Guest::Driver::Vmplayer;

=pod

=head1 NAME

PITA::Guest::Driver::Vmplayer - PITA Guest Driver for VMware Player images

=head1 DESCRIPTION

The author is an idiot

=cut

use strict;
use base 'PITA::Guest::Driver::Image';
use version      ();
use Carp         ();
use URI          ();
use File::Spec   ();
use File::Copy   ();
use File::Which  ();
use Config::Tiny ();
use IPC::Run3    ();
use PITA::XML    ();

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.01';
}


#####################################################################
# Constructor and Accessors

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    # Locate the vmplayer binary
    $self->{vmplayer_bin} = File::Which::which('vmplayer')
        unless $self->vmplayer_bin;
    unless ($self->vmplayer_bin) {
        Carp::croak("Cannot locate vmplayer, requires explicit param");
    }
    unless (-x $self->vmplayer_bin) {
        Carp::croak("Insufficient permissions to run vmplayer");
    }

    # Locate the mkisofs binary
    $self->{mkisofs_bin} = File::Which::which('mkisofs')
        unless $self->mkisofs_bin;
    unless ($self->mkisofs_bin) {
        Carp::croak("Cannot locate mkisofs, requires explicit param");
    }
    unless (-x $self->mkisofs_bin) {
        Carp::croak("Insufficient permissions to run mkisofs");
    }

    $self;
}

sub vmplayer_bin {
    $_[0]->{vmplayer_bin};
}

sub mkisofs_bin {
    $_[0]->{mkisofs_bin};
}


#####################################################################
# PITA::Guest::Driver::Image Methods

# Vmplayer uses a standard networking setup
sub support_server_addr {
    $_[0]->support_server
        ? shift->SUPER::support_server_addr
        : '127.0.0.1';
}

sub support_server_uri {
    URI->new( "http://192.168.88.2:51234/" );
}


#####################################################################
# PITA::Guest::Driver::Vmplayer Methods

sub execute_image {
    my $self = shift;
    my @cmd;

    # create iso image
    @cmd = ($self->mkisofs_bin,
            '-r',
            '-o', '/tmp/pita/pita.iso',
            $self->tempdir,
           );
    IPC::Run3::run3(\@cmd, \undef, \undef, \undef);

    # start vmplayer
    @cmd = ($self->vmplayer_bin,
            $self->image,
           );

    IPC::Run3::run3(\@cmd, \undef, \undef, \undef);

    1;
}


1;
