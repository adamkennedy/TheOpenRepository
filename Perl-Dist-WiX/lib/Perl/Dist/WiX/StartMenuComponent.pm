package Perl::Dist::WiX::StartMenuComponent;

=pod

=head1 NAME

Perl::Dist::WiX::Base::Component - A <Component> tag that contains a start menu <Shortcut>.

=head1 DESCRIPTION

This class 

Objects of this class are meant to be contained in a 
L<Perl::Dist::WiX::StartMenu> class, and created by methods of that 
class.

=head1 METHODS

=head2 Accessors

Accessors take no parameters and return the item requested (listed below)

=cut

# Startmenu components contain the entry, so there is no WiX::Entry sub class

use 5.006;
use strict;
use warnings;
use Carp                              qw{ croak               };
use Params::Util                      qw{ _IDENTIFIER _STRING };
use Data::UUID                        qw{ NameSpace_DNS       };
use Perl::Dist::WiX::Base::Component  qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_05';
    @ISA = 'Perl::Dist::WiX::Base::Component';
}

=pod

=over 4

=item *

name, description, target, working_dir: Returns the parameter 
of the same name passed in by L</new>

=back

    $name = $component->name; 

=cut

use Object::Tiny qw{
    name
    description
    target
    working_dir
};

#####################################################################
# Constructors for StartMenuComponent

sub new {
    my $self = shift->SUPER::new(@_);
    
    unless ( defined $self->guid ) {
        unless ( _STRING($self->sitename) ) {
            croak("Missing or invalid sitename param - cannot generate GUID without one");
        }
        unless ( _STRING($self->id) ) {
            croak("Missing or invalid id param - cannot generate GUID without one");
        }
        my $guidgen = Data::UUID->new();
        # Make our own namespace...
        my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
        #... then use it to create a GUID out of the filename.
        $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->id);
    }

    # Check params
    unless ( _STRING($self->name) ) {
        croak("Missing or invalid name param");
    }
    unless ( _STRING($self->description) ) {
        $self->{description} = $self->name;
    }
    unless ( _STRING($self->target) ) {
        croak("Missing or invalid target param");
    }
    unless ( _STRING($self->working_dir) ) {
        croak("Missing or invalid working_dir param");
    }

    return $self;
}


#####################################################################
# Main Methods

sub as_string {
    my $self = shift;
        
    my $answer = <<END_OF_XML;
<Component Id='C_S_$self->{id}' Guid='$self->{guid}'>
   <Shortcut Id="S_$self->{id}" 
             Name="$self->{name}"
             Description="$self->{description}"
             Target="$self->{target}"
             WorkingDirectory="$self->{working_dir}" />
</Component>
END_OF_XML
    
    return $answer;
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
