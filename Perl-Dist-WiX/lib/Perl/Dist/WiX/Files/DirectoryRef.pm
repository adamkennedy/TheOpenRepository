package Perl::Dist::WiX::Files::DirectoryRef;

use 5.006;
use strict;
use warnings;
use Carp                             qw{ croak confess cluck     };
use Params::Util                     qw{ _IDENTIFIER _STRING _INSTANCE };
use Perl::Dist::WiX::Base::Component qw{};
use Perl::Dist::WiX::Base::Entry     qw{};
use Perl::Dist::WiX::Misc            qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_04';
    @ISA = qw (Perl::Dist::WiX::Base::Component
               Perl::Dist::WiX::Base::Entry
               Perl::Dist::WiX::Misc
              );
}

use Object::Tiny qw{
    directory_object
};

sub new {
    my $self = shift->Perl::Dist::WiX::Base::Component::new(@_);
    
    if (not _INSTANCE($self->directory_object, 'Perl::Dist::WiX::Directory')) {
        croak 'Missing or invalid directory object';
    }

    if (not _STRING($self->sitename)) {
        croak 'Missing or invalid sitename';
    }
    
    $self->{directories} = [];
    $self->{files}       = [];
    
    return $self;
}

sub search {
    my ($self, $path_to_find) = @_;

    my $path = $self->directory_object->path;
    
    # Success!
    if ((defined $path) && ($path_to_find eq $path)) {
        return $self;
    }
    
    # Do we want to continue searching down this direction?
    my $subset = $path_to_find =~ m/\A\Q$path\E/;
    return undef if not $subset;
    
    # Check each of our branches.
    my $count = scalar @{$self->{directories}};
    my $answer;
    foreach my $i (0 .. $count - 1) {
        $answer = $self->{directories}->[$i]->search($path_to_find);
        if (defined $answer) {
            return $answer;
        }
    }
    
    # If we get here, we did not find a directory.
    return undef; 
}

sub add_directory {
    my ($self, $params_ref) = @_;
    
    # If we have a name, we create it under here.
    if (defined $params_ref->{name})
    {
        my $i = scalar @{$self->{directories}};
    
        $self->{directories}->[$i] = Perl::Dist::WiX::Directory->new(
            sitename => $self->sitename, 
            path => $params_ref->{path}, 
            name => $params_ref->{name}
        );
        return $self->{directories}->[$i];
    } else {
        confess q{Can't create intermediate directories.};
    }
}

# Are we a child of the directory object passed in?
# Returns false if the object is a "special".
sub is_child_of {
    my ($self, $directory_obj) = @_;
    
    my $path = $directory_obj->path;
    if (not defined $path) {
        return 0;
    }
    return ($self->directory_object->path =~ m{\A$path})
}

sub add_file {
    my ($self, @params) = @_;

    my $i = scalar @{$self->{files}};
    $self->{files}->[$i] = Perl::Dist::WiX::Files::Component->new(@params);
    return $self->{files}->[$i];
}

sub add_directory_path {
    my ($self, $path) = @_;

    if (substr($path, -1) eq '\\') {
        $path = substr($path, 0, -1);
    }

    if (! $self->directory_object->path =~ m{\A\Q$path\E}) {
        croak q{Can't add the directories required};
    }

    # Get list of directories to add.   
    my $path_to_remove = $self->directory_object->path;
    $path =~ s{\A\Q$path_to_remove\E\\}{};
    my @dirs = File::Spec->splitdir($path);
    
    # Get rid of empty entries at the beginning.
    while ($dirs[-1] eq q{}) {
        pop @dirs;
    }
    
    my $directory_obj = $self;
    my $path_create = $self->directory_object->path;
    my $name_create;
    while ($#dirs != -1) {
        $name_create = shift @dirs;
        $path_create = File::Spec->catdir($path_create, $name_create);
        
        $directory_obj = $directory_obj->add_directory({
            sitename => $self->sitename, 
            name => $name_create,
            path => $path_create
        });
    }
    
    return $directory_obj;
}

sub as_string {
    my $self = shift;
    my ($count, $answer, $string); 

    my $id = $self->directory_object->id;
    
    $answer = "<DirectoryRef Id='D_$id'>\n";
    
    $count = scalar @{$self->{directories}};
    foreach my $i (0 .. $count - 1) {
        $string .= $self->{directories}->[$i]->as_string;
    }
    
    $count = scalar @{$self->{files}};
    foreach my $i (0 .. $count - 1) {
        $string .= $self->{files}->[$i]->as_string;
    }
    
    $answer .= $self->indent(2, $string);
    $answer .= "\n</DirectoryRef>\n";

    return $answer;
}

sub get_component_array {
    my $self = shift;

    my @answer;
    my $count = scalar @{$self->{directories}};
    
    # Get the array for each descendant.
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{directories}->[$i]->get_component_array;
    }
    
    $count = scalar @{$self->{files}};
    
    # Get the array for each descendant.
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{files}->[$i]->id;
    }

    return @answer;
}

1;