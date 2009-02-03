package Perl::Dist::WiX::Icons;

####################################################################
# Perl::Dist::WiX::Icons - Object that represents a list of <Icon> tags.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev: 5108 $ $Date: 2009-01-29 17:12:36 -0700 (Thu, 29 Jan 2009) $ $Author: csjewell@cpan.org $
# $URL: http://svn.ali.as/cpan/trunk/Perl-Dist-WiX/lib/Perl/Dist/WiX/EnvironmentEntry.pm $

use 5.006;
use strict;
use warnings;
use Carp                   qw( croak     );
use Params::Util           qw( _STRING   );
use File::Spec::Functions  qw( splitpath );
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.13_01';
    @ISA = 'Perl::Dist::WiX::Misc';
}

#####################################################################
# Accessors:
#   see new.

use Object::Tiny qw{
    icons
};

#####################################################################
# Constructors for Icons
#
# Parameters: [none]

sub new {
    my $self = shift->SUPER::new(@_);

    # Initialize our icons area.
    $self->{icons} = [];
    
    return $self;
}


#####################################################################
# Main Methods

########################################
# add_icon
# Parameters:
#   pathname_icon: Path of icon.
#   pathname_target: Path of icon's target.
# Returns:
#   Id of icon.

sub add_icon {
    my ($self, $pathname_icon, $pathname_target) = @_;
    
    # Check parameters
    unless (defined $pathname_target) {
        $pathname_target = 'Perl.msi';
    }
    unless (defined _STRING($pathname_target)) {
        croak "Invalid pathname_target parameter";
    }
    unless (defined _STRING($pathname_icon)) {
        croak "Invalid pathname_icon parameter";
    }

    # Find the type of target.
    my ($target_type) = $pathname_target =~ m(\A.*[.](.+)\z);
    $self->trace_line(0, "Adding icon $pathname_icon with target type $target_type.\n");
    
    # If we have an icon already, return it.
    my $icon = $self->search_icon($pathname_icon, $target_type);
    if (defined $icon) { return $icon; }
    
    # Get Id made.
    my (undef, undef, $filename_icon) = splitpath($pathname_icon);
    my $id =  substr($filename_icon, 0, -4);
    $id    =~ s/[^A-Za-z0-9]/_/g; # Substitute _ for anything non-alphanumeric.
    $id   .=  ".$target_type";
    
    # Add icon to our list.
    push @{$self->{icons}}, { file => $pathname_icon, target_type => $target_type, id => $id };

    return $id;
}

########################################
# search_icon
# Parameters:
#   pathname_icon: Path of icon to search for.
#   target_type: Target type to search for.
# Returns:
#   Id of icon.

sub search_icon {
    my ($self, $pathname_icon, $target_type) = @_;

    # Check parameters
    unless (defined $target_type) {
        $target_type = 'msi';
    }
    unless (defined _STRING($target_type)) {
        croak "Invalid target_type parameter";
    }
    unless (defined _STRING($pathname_icon)) {
        croak "Invalid pathname_icon parameter";
    }

    if (0 == scalar @{$self->{icons}}) { return undef; }
    
    # Print each icon
    foreach my $icon (@{$self->{icons}}) {
        if (($icon->{file} eq $pathname_icon) and ($icon->{file} eq $target_type)) {
            return $icon->{id};
        }
    }

    return undef;
}


########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Icon> tags defined by this object.

sub as_string {
    my $self = shift;
    my $answer;
    
    # Short-circuit
    if (0 == scalar @{$self->{icons}}) { return q{}; }

    # Print each icon
    foreach my $icon ($self->{icons}) {
        $answer .= "<Icon Id='I_$icon->{id}' SourceFile='$icon->{file}' />\n"
    }
    
    return $answer;
}

1;
