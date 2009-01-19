package Perl::Dist::WiX::Base::Component;

=pod

=head1 NAME

Perl::Dist::WiX::Base::Component - Base class for <Component> tag.

=head1 DESCRIPTION

This is a base class for classes that create <Component> tags.  It 
is meant to be subclassed, as opposed to creating objects of this 
class directly.

=head1 METHODS

=head2 Accessors

Accessors take no parameters and return the item requested (listed below)

=cut

use 5.006;
use strict;
use warnings;
use Carp                  qw( croak             );
use Params::Util          qw( _CLASSISA _STRING _NONNEGINT );
use Data::UUID            qw( NameSpace_DNS     );
use Perl::Dist::WiX::Misc qw();

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_05';
    @ISA = 'Perl::Dist::WiX::Misc';
}

=pod

=over 4

=item *

id: Returns the C<id> parameter passed in by L</new>

=item *

guid: Returns the guid generated.

=item *

sitename: Returns the C<sitename> parameter passed in by L</new>

=back

    $id = $component->guid; 

=cut

use Object::Tiny qw{
    id
    guid
    sitename
};

#####################################################################
# Constructors for Component

=head2 new

The B<new> method creates a new component object.

It is meant to be overriden by other classes.  Parameters partially 
handled by this class are listed below.

=head2 Parameters

=over 4

=item *

id: The C<Id> attribute of the component.

=item *

sitename: The sitename that this installer is going to be uploaded to.  Used 
to generate a GUID for the component.

=item *

guid: The C<Guid> attribute of the component.

=back

=cut
  
sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    
    $self->{entries} = [];
    
    return $self;
}

=head2 add_entry

The B<add_entry> method adds a new tag (represented by a subclass of 
L<Perl::Dist::WiX::Base::Entry>) within this component.

This method can be chained.

    my $component = $component->add_entry(Perl::Dist::WiX::Base::Entry->new(...));

=cut

sub add_entry {
    my ($self, $entry) = @_;
    
    if (not defined _CLASSISA(ref $entry, 'Perl::Dist::WiX::Base::Entry')) {
        croak 'Not adding a valid component';
    }
    
    # getting the number of items in the array referred to by $self->{entries}
    my $i = scalar @{$self->{entries}};
    
    $self->{entries}->[$i] = $entry;
    
    return $self;
}

=head2 create_guid_from_id

The B<create_guid_from_id> method creates a GUID for this component based 
on the id of the component and the sitename passed in and stores it in 
$component->guid.

This is meant to be called by subclass constructors.

    $component->as_string(2);

=cut

sub create_guid_from_id {
    my $self = shift;

    unless ( _STRING($self->sitename) ) {
        croak("Missing or invalid sitename param - cannot generate GUID without one");
    }
    unless ( _STRING($self->id) ) {
        croak("Missing or invalid id param - cannot generate GUID without one");
    }
    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
    #... then use it to create a GUID out of the ID.
    $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->id);
    
    return $self;
}

=head2 as_string($spaces)

The B<as_string> method converts the entry tags within this object  
into strings by calling their own L<Perl::Dist::WiX::Base::Entry/as_string|as_string>
methods and indenting them by $spaces spaces.

This is meant to be called by a subclass method.

    my $string = $component->as_string(2);

=cut

sub as_string {
    my ($self) = shift;
    my $spaces = shift;

    return q{} if (scalar @{$self->{entries}} == 0); 
    
    unless (_NONNEGINT($spaces)) {
        croak 'Calling as_spaces improperly (most likely, not calling derived method)';
    }
    
    # getting the number of items in the array referred to by $self->{entries}
    my $count = scalar @{$self->{entries}};
    my $string;
    my $s;

    foreach my $i (0 .. $count - 1) {
        $s = $self->{entries}->[$i]->as_string;
        $string .= $self->indent($spaces, $s);
        $string .= "\n";
    }

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
