package Perl::Dist::WiX::Filelist;

####################################################################
# Perl::Dist::WiX::Filelist - This package provides for handling 
# files lists for Perl::Dist::WiX.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.008;
use strict;
use warnings;
use Carp                   qw( croak                        );
use File::Spec::Functions  qw( catdir catfile               );
use List::MoreUtils        qw( indexes                      );
use Params::Util           qw( _INSTANCE _STRING _NONNEGINT );
use IO::Dir                qw();
use IO::File               qw();
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );
BEGIN {
	$VERSION = '0.13_01';
    @ISA = 'Perl::Dist::WiX::Misc';
}

#####################################################################
# Accessors:
#   files: Returns the list of files as an arrayref. 

use Object::Tiny qw {
    files
};

#####################################################################
# Constructors for Filelist
#

########################################
# new
# Parameters:
#   None.

sub new {
    my $self = shift->SUPER::new();

    # Initialize files area.
    $self->{files} = [];
    
    # Set defaults and check parameters
    if (not defined $self->{trace}) {
        $self->{trace} = 0;
    }
    if (not defined _NONNEGINT($self->{trace})) {
        croak "Invalid trace parameter";
    }
    
    
    
    return $self;
}

########################################
# clone
# Parameters:
#   $source: [Filelist object] Object to copy.

sub clone {
    my $self = shift->SUPER::new();
    my $source = shift;

    # Check parameters
    unless (_INSTANCE($source, 'Perl::Dist::WiX::Filelist')) {
        croak 'Missing or invalid source parameter';
    }

    # Add filelist passed in.
    $self->{files} = [];
    push @{$self->{files}}, @{$source->{files}};
    
    return $self;
}

#####################################################################
# Main Methods

########################################
# count
# Parameters:
#   None.
# Returns:
#   Number of files in this object 

sub count { my $self = shift; return scalar @{$self->{files}} + 1; }

########################################
# clear
# Parameters:
#   None.
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Clears this filelist.

sub clear { $_[0]->{files} = []; return $_[0]; }

########################################
# readdir($dir)
# Parameters:
#   $dir: Directory containing a files and subdirectories to add to this filelist. 
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Adds the files in $dir to our filelist.

sub readdir {
    my ($self, $dir) = @_;

    # Check parameters.
    unless (_STRING($dir)) {
        croak 'Missing or invalid dir parameter';
    }
    unless (-d $dir) {
        croak '$dir is not a directory';
    }

    # Open directory.
    my $dir_object = IO::Dir->new($dir);
    if (!defined $dir_object) {
        croak "Error reading directory $dir: $!";        
    }
    
    # Read a file from the directory.
    my $file = $dir_object->read();
    
    while (defined $file) {
        # Check to make sure it isn't . or ..
        if (($file ne q{.}) and ($file ne q{..})) {
            
            # Check for another directory.
            my $filespec = catfile($dir, $file);
            if (-d $filespec) {
                # Read this directory.
                $self->readdir($filespec);
            } else {
                # Add the file!
                push @{$self->files}, $filespec;
            }
        }

        # Next one, please?
        $file = $dir_object->read();
    }

     return $self;
}

########################################
# load_file($packlist)
# Parameters:
#   $packlist: File containing a list of files to add to this filelist. 
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Adds the files listed in the file in $packlist to our filelist.

sub load_file {
    my ($self, $packlist) = @_; 

    # Check parameters.
    unless (_STRING($packlist)) {
        croak 'Missing or invalid packlist parameter';
    }
    unless (-r $packlist) {
        croak '$packlist cannot be read';
    }
    
    # Read ,packlist file.
    my $fh = IO::File->new($packlist, 'r');
    if (not defined $fh)
    {
        croak "File Error: $!";
    }
    my @files = <$fh>;
    $fh->close;

    # Insert list of files read into this object. Chomp on the way.
    @{$self->files} = map { chomp $_; $_ } @files;
    
    return $self;
}

########################################
# load_array(@files)
# Parameters:
#   @files: Files to add to this filelist. 
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Adds the files listed in @files to our filelist.

sub load_array {
    my ($self, @files) = @_;
    
    # Add each file in the array - if it is a file.
    foreach my $file (@files) {
        next if not -f $file;
        push @{$self->files}, $file;
    }

    return $self;
}

########################################
# add_file($file)
# Parameters:
#   $file: File to add to this filelist. 
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Adds the file listed in $file to our filelist.

sub add_file {
    my ($self, $file) = @_;

    # Check parameters.
    unless (_STRING($file)) {
        croak 'Missing or invalid dir parameter';
    }
    
    push @{$self->files}, $file;

    return $self;
}

########################################
# subtract($subtrahend)
# Parameters:
#   $subtrahend: [Filelist object] A filelist to remove from this one. 
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Removes the files listed in $subtrahend from our filelist.

sub subtract {
    my ($self, $subtrahend) = @_;

    # Check parameters
    unless (_INSTANCE($subtrahend, 'Perl::Dist::WiX::Filelist')) {
        croak 'Missing or invalid subtrahend parameter';
    }
    
    # Define variables.
    my @loc;
    my @files = @{$self->files};
    my @files2;
    my $f;
    
    # For each file on the list passed in...
    foreach my $f (@{$subtrahend->files}) {
    
        # Find if it is in us.
        @loc = indexes { $_ eq $f } @files;
        if (@loc) {
            if ($#loc > 1) {
                print "[*] Subtracting more than one file with one entry [$f]:\n";
                foreach my $loc (@loc) {
                    print '[*] ' . $loc . q{ } . $files[$loc] . "\n";
                }
            }
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

    # Reload ourselves.
    return $self->clear->load_array(@files);
}

########################################
# add($term)
# Parameters:
#   $term: [Filelist object] A filelist to add to this one. 
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Adds the files listed in $term to our filelist.

sub add {
    my ($self, $term) = @_;

    # Check parameters
    unless (_INSTANCE($term, 'Perl::Dist::WiX::Filelist')) {
        croak 'Missing or invalid subtrahend parameter';
    }

    push @{$self->files}, @{$term->files};

    return $self;
}

########################################
# move($from, $to)
# Parameters:
#   $from: the file or directory that has been moved on disk. 
#   $to: The location being moved to.
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Substitutes $to for $from in the filelist.

sub move {
    my ($self, $from, $to) = @_;

    # Check parameters.
    unless (_STRING($from)) {
        croak 'Missing or invalid from parameter';
    }
    unless (_STRING($to)) {
        croak 'Missing or invalid to parameter';
    }
    
    # Find which files need moved.
    my @loc = indexes { $_ =~ m/\A\Q$from\E\z/ } @{$self->files};
    if (@loc) {
        foreach my $loc (@loc) {
            # "move" them.
            $self->files->[$loc] = $to;
        }
    }

    return $self;    
}

########################################
# move_dir($from, $to)
# Parameters:
#   $from: the file or directory that has been moved on disk. 
#   $to: The location being moved to.
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Substitutes $to for $from in the filelist.

sub move_dir {
    my ($self, $from, $to) = @_;

    # Check parameters.
    unless (_STRING($from)) {
        croak 'Missing or invalid from parameter';
    }
    unless (_STRING($to)) {
        croak 'Missing or invalid to parameter';
    }
    
    # Find which files need moved.
    my @loc = indexes { "$_\\" =~ m(\A\Q$from\E\\) } @{$self->files};
    my $to_file;
    if (@loc) {
        foreach my $loc (@loc) {
            # "move" them.
            $self->files->[$loc] =~ s(\A\Q$from\E)($to);
        }
    }

    return $self;
}


########################################
# filter($re_list)
# Parameters:
#   $re_list: Arrayref of strings to use as regular 
#     expressions of filenames to filter out.
# Returns:
#   Object being acted upon (chainable) 
# Action:
#   Removes files satisfying the filters in @re_list
#   from the object.

sub filter {
    my ($self, $re_list) = @_;

    # Define variables to use.
    my @files = @{$self->files};
    
    # Filtering out values that match the regular expressions.
    foreach my $re (@{$re_list}) {
        $self->trace_line(2, "Filtering on $re\n");
        @files = grep { not ($_ =~ m/\A\Q$re\E/) } @files; 
    }
    
    $self->clear->load_array(@files);
    
    return $self;  
}

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   List of filenames in this object joined 
#   by newlines for debugging purposes.

sub as_string {
    my $self = shift;

    return join "\n", @{$self->files};
}

1;
