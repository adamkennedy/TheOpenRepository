package Perl::Dist::WiX::Base::Fragment;

=pod

=head1 NAME

Perl::Dist::WiX::Base::Fragment - Base class for <Fragment> tag.

=head1 DESCRIPTION

This is a base class for classes that create <Fragment> tags.  It 
is meant to be subclassed, as opposed to creating objects of this 
class directly.

=head1 METHODS

=head2 Accessors

Accessors take no parameters and return the item requested (listed below)

=cut

use 5.006;
use strict;
use warnings;
use Carp                  qw{ croak verbose     };
use Params::Util          qw{ _CLASSISA _STRING };
use Perl::Dist::WiX::Misc qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Misc';
}

=pod

=over 4

=item id, directory

Returns the parameter of the same name passed in to L</new>.

=back

    $id = $self->id;

=cut

use Object::Tiny qw{
    id
    directory
};

#####################################################################
# Constructors for Fragment

=head2 new

The B<new> method creates a new fragment object.

It is meant to be overriden by other classes.  Parameters partially 
handled by this class are listed below.

=head2 Parameters

=over 4

=item id

The C<Id> attribute of the component.

=item directory

The C<Id> attribute of the <DirectoryRef> tag within this component.

=back

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    
    unless ( defined $self->directory ) {
        $self->{directory} = 'TARGETDIR';
    }
    
    unless ( _STRING($self->id) ) {
        croak 'Missing or invalid id parameter';
    }
    
    $self->{components} = [];
    
    return $self;
}

=head2 add_component

The B<add_component> method adds a new tag (represented by a subclass of 
L<Perl::Dist::WiX::Base::Component>) within this fragment.

This method can be chained.

    my $fragment = $fragment->add_component(
        Perl::Dist::WiX::Base::Component->new(...)
    );

=cut

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

=head2 as_string

The B<as_string> method converts the component tags within this object  
into strings by calling their own L<Perl::Dist::WiX::Base::Component/"as_string($spaces)"|as_string>
methods and indenting them appropriately.

    my $string = $fragment->as_string;

=cut


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

=head1 SUPPORT

No support of any kind is provided for this module

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::WiX|Perl::Dist::WiX>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
