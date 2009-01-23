package Perl::Dist::WiX::FeatureTree;

####################################################################
# Perl::Dist::WiX::FeatureTree - Tree of MSI features.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.


use 5.006;
use strict;
use warnings;
use Carp                        qw{ croak confess verbose      };
use Params::Util                qw{ _IDENTIFIER _STRING };
use Scalar::Util                qw{ weaken };
use Perl::Dist::WiX::Feature    qw{};
use Perl::Dist::WiX::Misc    qw{};


use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Misc';
}

use Object::Tiny qw{
    features
};

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    print "Creating feature tree...\n";
    
    $self->{features} = [];
    weaken($self->{parent});
    if (defined $self->{parent}->{msi_feature_tree}) {
        croak "Complex feature tree Not implemented in Per::Dist::WiX $VERSION."; 
    } else {
        $self->features->[0] = Perl::Dist::WiX::Feature->new(
            id          => 'Complete', 
            title       => $self->{parent}->app_ver_name,
            description => 'The complete package.',
            level       => 1,
        );
        
        $self->features->[0]->add_components($self->{parent}->get_component_array);
    }

    return $self;
}

sub search {
    my ($self, $id_to_find) = @_;

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

    # Get the strings for each of our branches.
    my $count = scalar @{$self->features};
    my $answer;
    foreach my $i (0 .. $count - 1) {
        $answer .= $self->features->[$i]->as_string;
    }

    return $self->indent(4, $answer);
}

1;