package Perl::Dist::WiX::Feature;

use 5.006;
use strict;
use warnings;
use Carp                        qw{ croak verbose                };
use Params::Util                qw{ _CLASSISA _STRING _NONNEGINT };
use Perl::Dist::WiX::Misc       qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Misc';
}

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

=pod

        $self->features->[0] = Perl::Dist::WiX::Feature->new(
            id          => 'Complete', 
            title       => $parent->app_ver_name,
            description => 'The complete package.',
#            default     => 'install',          # TypicalDefault
#            idefault    => 'local',            # InstallDefault
#            display     => 'expand',           
#            directory   => 'INSTALLDIR',       # ConfigurableDirectory
#            absent      => 'disallow'
#            advertise   => 'no'                # Allowadvertise
            level       => 1,
        );

=cut


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
    unless (_NONNEGINT($self->level)) {
        croak 'Missing or invalid level parameter';
    }

    $self->{default_settings} = 0;
    
    # Set defaults
    unless (_STRING($self->default)) {
        $self->{default} = 'install';
        $self->{default_settings}++;
    }
    unless (_STRING($self->idefault)) {
        $self->{display} = 'local';
        $self->{default_settings}++;
    }
    unless (_STRING($self->display)) {
        $self->{display} = 'expand';
        $self->{default_settings}++;
    }
    unless (_STRING($self->directory)) {
        $self->{directory} = 'INSTALLDIR';
        $self->{default_settings}++;
    }
    unless (_STRING($self->absent)) {
        $self->{absent} = 'disallow';
        $self->{default_settings}++;
    }
    unless (_STRING($self->advertise)) {
        $self->{advertise} = 'no';
        $self->{default_settings}++;
    }

    # Set up empty arrayrefs
    $self->{features} = [];
    $self->{componentrefs} = [];
    
    return $self;
}

sub add_feature {
    my ($self, $feature) = @_;
    
    unless (_CLASSISA($feature, 'Perl::Dist::WiX::Fragment')) {
        croak 'Not adding valid feature';
    }
    
    push @{$self->features}, $feature;
    
    return $self;
}

sub add_components {
    my ($self, @componentids) = @_;
    
    push @{$self->componentrefs}, @componentids;
    
    return $self;
}

sub search {
    my ($self, $id_to_find) = @_;

    unless (_STRING($id_to_find)) {
        croak 'Missing or invalid id to find';
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
        $string .= $self->indent(2, $s);
        $string .= $self->_componentrefs_as_string;
        $string .= qq{\n}
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
        $string .= qq{<ComponentRef Id='$ref' />\n};
    }
    
    return $self->indent(2, $string);
}

1;