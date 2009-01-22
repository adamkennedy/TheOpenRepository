package Perl::Dist::WiX::EnvironmentEntry;

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

use 5.006;
use strict;
use warnings;
use Carp                          qw{ croak               };
use Params::Util                  qw{ _IDENTIFIER _STRING };
use Data::UUID                    qw{ NameSpace_DNS       };
use Perl::Dist::WiX::Base::Entry  qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Entry';
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
    id
};

#####################################################################
# Constructors for StartMenuComponent

sub new {
    my $self = shift->SUPER::new(@_);

    unless ( _STRING($self->id) ) {
        croak("Missing or invalid id param");
    }

    # Check params
    unless ( _STRING($self->{name}) ) {
        croak("Missing or invalid name param");
    }
    unless ( _STRING($self->{value}) ) {
        croak("Missing or invalid value param");
    }
    unless ( _STRING($self->{action}) ) {
        $self->{action} = 'set';
    }
    unless ( _STRING($self->{part}) ) {
        $self->{part} = 'all';
    }
    unless ( _STRING($self->{permanent}) ) {
        $self->{permanent} = 'all';
    }

    return $self;
}


#####################################################################
# Main Methods

sub as_string {
    my $self = shift;
        
    my $answer = <<END_OF_XML;
   <Environment Id='E_$self->{id}' Name='$self->{name}' Value='$self->{value}' 
      System='yes' Permanent='$self->{permanent}' Action='$self->{action}' Part='$self->{part}' />
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
