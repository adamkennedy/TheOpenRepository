package Perl::Dist::WiX::Feature;

####################################################################
# Perl::Dist::WiX::Feature - Object representing <Feature> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.006;
use strict;
use warnings;
use Carp            qw( croak                        );
use Params::Util    qw( _INSTANCE _STRING _NONNEGINT );
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.11_07';
    @ISA = 'Perl::Dist::WiX::Misc';
}

#####################################################################
# Accessors:
#   features: Returns a reference to an array of features contained 
#     within this feature.
#   componentrefs: Returns a reference to an array of component 
#     references contained within this feature.
#
#  id, title, description, default, idefault, display, directory, absent, advertise, level:
#    See new.

use Object::Tiny qw{
    features
    componentrefs
    
    id
    title
    description
    default
    idefault
    display
    directory
    absent
    advertise
    level
};

#####################################################################
# Constructor for Feature
#
# Parameters: [pairs]
#   id: Id parameter to the <Feature> tag (required)
#   title: Title parameter to the <Feature> tag (required)
#   description: Description parameter to the <Feature> tag (required)
#   level: Level parameter to the <Feature> tag (required)
#   default: TypicalDefault parameter to the <Feature> tag
#   idefault: InstallDefault parameter to the <Feature> tag
#   display: Display parameter to the <Feature> tag
#   directory: ConfigurableDirectory parameter to the <Feature> tag
#   absent: Absent parameter to the <Feature> tag
#   advertise: AllowAdvertise parameter to the <Feature> tag
#
# See http://wix.sourceforge.net/manual-wix3/wix_xsd_feature.htm
#
# Defaults:
#   default     => 'install',
#   idefault    => 'local',
#   display     => 'expand',
#   directory   => 'INSTALLDIR',
#   absent      => 'disallow'
#   advertise   => 'no'


sub new {
    my $self = shift->SUPER::new(@_);

    # Check required parameters.
    unless (_STRING($self->id)) {
        croak 'Missing or invalid id parameter';
    }
    unless (_STRING($self->title)) {
        croak 'Missing or invalid title parameter';
    }
    unless (_STRING($self->description)) {
        croak 'Missing or invalid description parameter';
    }
    unless (defined _NONNEGINT($self->level)) {
        croak 'Missing or invalid level parameter';
    }

    my $default_settings = 0;
    
    # Set defaults
    unless (_STRING($self->default)) {
        $self->{default} = 'install';
        $default_settings++;
    }
    unless (_STRING($self->idefault)) {
        $self->{idefault} = 'local';
        $default_settings++;
    }
    unless (_STRING($self->display)) {
        $self->{display} = 'expand';
        $default_settings++;
    }
    unless (_STRING($self->directory)) {
        $self->{directory} = 'INSTALLDIR';
        $default_settings++;
    }
    unless (_STRING($self->absent)) {
        $self->{absent} = 'disallow';
        $default_settings++;
    }
    unless (_STRING($self->advertise)) {
        $self->{advertise} = 'no';
        $default_settings++;
    }

    $self->{default_settings} = $default_settings;

    # Set up empty arrayrefs
    $self->{features} = [];
    $self->{componentrefs} = [];
    
    return $self;
}

#####################################################################
# Main Methods

########################################
# add_feature
# Parameters:
#   $feature: [Feature object] Feature to add as a subfeature of this one.
# Returns:
#   Object being acted on (chainable)

sub add_feature {
    my ($self, $feature) = @_;
    
    unless (_INSTANCE($feature, 'Perl::Dist::WiX::Feature')) {
        croak 'Not adding valid feature';
    }
    
    push @{$self->features}, $feature;
    
    return $self;
}

########################################
# add_components
# Parameters:
#   @componentids: List of component ids to add to this feature.
# Returns:
#   Object being acted on (chainable)

sub add_components {
    my ($self, @componentids) = @_;
    
    push @{$self->componentrefs}, @componentids;
    
    return $self;
}

########################################
# search
# Parameters:
#   $id_to_find: Id of feature to find.
# Returns:
#   Feature object with given Id.

sub search {
    my ($self, $id_to_find) = @_;

    # Check parameters.
    unless (_IDENTIFIER($id_to_find)) {
        croak 'Missing or invalid id parameter';
    }

    my $id = $self->id;

    # Success!
    if ($id_to_find eq $self->id) {
        return $self;
    }
    
    # Check each of our branches.
    my $count = scalar @{$self->features};
    my $answer;
    foreach my $i (0 .. $count - 1) {
        $answer = $self->features->[$i]->search($id_to_find);
        if (defined $answer) {
            return $answer;
        }
    }
    
    # If we get here, we did not find a feature.
    return undef; 
}

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String representation of the <Feature> tag represented
#   by this object and the <Feature> and <ComponentRef> tags 
#   contained in this object.

sub as_string {
    my $self = shift;

    my $f_count = scalar @{$self->features};
    my $c_count = scalar @{$self->componentrefs};
    
    my ($string, $s);
    
    $string = q{<Feature Id='}  . $self->id
        . q{' Title='}          . $self->title
        . q{' Description='}    . $self->description
        . q{' Level='}          . $self->level
    ;

    my %hash = (
        advertise => $self->advertise,
        absent    => $self->absent,
        directory => $self->directory,
        display   => $self->display,
        idefault  => $self->idefault,
        default   => $self->default,
    );
    
    foreach my $key (keys %hash) {
        if (not defined $hash{$key}) {
            print "$key in feature $self->{id} is undefined.\n";
        }
    }
    
    if ($self->{default_settings} != 6) {
        $string .= 
              q{' AllowAdvertise='} . $self->advertise
            . q{' Absent='}         . $self->absent
            . q{' ConfigurableDirectory='}
                                    . $self->directory
            . q{' Display='}        . $self->display
            . q{' InstallDefault='} . $self->idefault
            . q{' TypicalDefault='} . $self->default
        ;
    }

# TODO: Allow condition subtags.
    
    if (($c_count == 0) and ($f_count == 0)) {
        $string .= qq{' />\n};
    } else {
        $string .= qq{'>\n};
        
        foreach my $i (0 .. $f_count - 1) {
            $s  .= $self->features->[$i]->as_string;
        }
        if (defined $s) {
            $string .= $self->indent(2, $s);
        }
        $string .= $self->_componentrefs_as_string;
        $string .= qq{\n};
        
        $string .= qq{</Feature>\n};
    }
        
    return $string;
}

sub _componentrefs_as_string {
    my $self = shift;

    my ($string, $ref);
    my $c_count = scalar @{$self->componentrefs};

    if ($c_count == 0) { 
        return q{};
    }
    
    foreach my $i (0 .. $c_count - 1) {
        $ref     = $self->componentrefs->[$i];
        $string .= qq{<ComponentRef Id='C_$ref' />\n};
    }
    
    return $self->indent(2, $string);
}

1;