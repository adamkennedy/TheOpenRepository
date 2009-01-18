package Perl::Dist::WiX::Filelist;

=pod

=head1 NAME

Perl::Dist::WiX::Filelist - File List routines for 4th generation Win32 Perl distribution builder

=head1 DESCRIPTION

This package provides for handling files lists for the experimental upgrade
to Perl::Dist based on Windows Install XML technology

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Carp                   qw( verbose croak confess );
use Params::Util           qw();
use IO::Dir                qw();
use File::Spec::Functions  qw( catdir catfile );
use List::MoreUtils        qw( indexes );

use vars qw($VERSION);
BEGIN {
	$VERSION = '0.11_04';
}

use Object::Tiny qw {
    files
    pos
};

sub new {
    my $self = shift->SUPER::new();

    $self->{files} = [];
    $self->{pos}   = 0;
    
    return $self;
}

sub clone {
    my $self = shift->SUPER::new();
    my $source = shift;
    
    $self->{files} = [];
    push @{$self->{files}}, @{$source->{files}};
    $self->{pos}   = 0;
    
    return $self;
}


# Reset iterator.
sub reset {
    my $self = shift;
    
    $self->{pos}   = 0;
    
    return $self;
}

# Clears file list.
sub clear {
    my $self = shift;
    
    $self->{files} = [];
    
    return $self;
}

# Reads in directory
sub readdir {
    my ($self, $dir) = @_;
    
    my $dir_object = IO::Dir->new($dir);
    if (!defined $dir_object) {
        croak "Error reading directory $dir: $!";        
    }
    
    my $file = $dir_object->read();
    
    while (defined $file) {
        if (($file ne q{.}) and ($file ne q{..})) {
            my $filespec = catfile($dir, $file);
            if (-d $filespec) {
                $self->readdir($filespec);
            } else {
                push @{$self->files}, $filespec;
            }
        }

        # Next one, please?
        $file = $dir_object->read();
    }

     return $self;
}

# Load loads the filelist from a file.
sub load_file {
    my ($self, $packlist) = @_; 

    my $fh = IO::File->new($packlist, 'r');
    if (not defined $fh)
    {
        croak "File Error: $!";
    }
    my @files = <$fh>;
    $fh->close;

    @{$self->files} = map { chomp $_; $_ } @files;
    
    return $self;
}

sub load_array {
    my ($self, @files) = @_;
    
    foreach my $file (@files) {
        next if -d $file;
        push @{$self->files}, $file;
    }

    return $self;
}

sub add_file {
    my ($self, $file) = @_;
    
    push @{$self->files}, $file;

    return $self;
}

## defined as: remove each filespec in $self that's in $subtrahend.
sub subtract {
    my ($self, $subtrahend) = @_;

    my @loc;
    my @files = @{$self->files};
    my @files2;
    my $f;
    
    foreach my $f (@{$subtrahend->files}) {
        @loc = indexes { $_ eq $f } @files;
        if (@loc) {
            delete @files[@loc];
            undef @loc;

            # 'compress' @files;
            undef @files2;
            while ($#files > -1) {
                $f = shift @files;
                push @files2, $f if defined($f);
            }
            @files = @files2; 
        }
    }

    $self->clear->load_array(@files);
    
    return $self;
}


sub add {
    my ($self, $term) = @_;

    push @{$self->files}, @{$term->files};

    return $self;
}

sub filter {
    my ($self, @re_list) = @_;
    
    my @loc;
    my @files = @{$self->files};
    my @files2;
    my $f;
    
    foreach my $re (@re_list) {
        my @loc = indexes { $_ =~ m/\A\Q$re\E/ } @files;
        if (@loc) {
            delete @files[@loc];
            undef @loc;

            # 'compress' @files;
            undef @files2;
            while ($#files > -1) {
                $f = shift @files;
                push @files2, $f if defined($f);
            }
            @files = @files2; 
        }
    }

    $self->clear->load_array(@files);
    
    return $self;    
}

sub as_string {
    my $self = shift;

    return join "\n", @{$self->files};
}

1;