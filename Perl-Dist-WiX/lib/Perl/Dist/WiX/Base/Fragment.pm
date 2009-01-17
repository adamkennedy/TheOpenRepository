package Perl::Dist::WiX::Base::Fragment;

use 5.006;
use strict;
use warnings;
use Carp                  qw{ croak verbose     };
use Params::Util          qw{ _CLASSISA _STRING };
use Perl::Dist::WiX::Misc qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_03';
    @ISA = 'Perl::Dist::WiX::Misc';
}

use Object::Tiny qw{
    id
    directory
    sitename
};

#####################################################################
# Constructors for Fragment

sub new {
    my $self = shift->SUPER::new(@_);
    
    unless ( defined $self->directory ) {
        $self->{directory} = 'TARGETDIR';
    }
    
    unless ( _STRING($self->sitename) ) {
        croak('Missing or invalid sitename parameter - cannot generate GUID without one');
    }
    
    $self->{components} = [];
    
    return $self;
}

sub add_component {
    my ($self, $component) = @_;
    
    if (not defined _CLASSISA(ref $component, 'Perl::Dist::WiX::Base::Component')) {
        croak 'Not adding a valid component';
    }
    
    # getting the number of items in the array referred to by $self->{components}
    my $i = scalar @{$self->{components}};
    $self->{components}->[$i] = $component;
    
    return $self;
}

sub as_string {
    my ($self) = shift;
    
    # getting the number of items in the array referred to by $self->{components}
    my $count = scalar @{$self->{components}};
    my $string;
    my $s;
    
    $string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$self->{id}'>
    <DirectoryRef Id='$self->{directory}'>
EOF

    foreach my $i (0 .. $count - 1) {
        $s = $self->{components}->[$i]->as_string;
        chomp $s;
        $string .= $self->indent(6, $s);
        $string .= "\n";
    }
    
    $string .= <<'EOF';
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

    return $string;
}

1;