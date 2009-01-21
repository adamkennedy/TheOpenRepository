package Perl::Dist::WiX::Directory;

use 5.006;
use strict;
use warnings;
use Carp                              qw{ croak confess                  };
use Params::Util                      qw{ _IDENTIFIER _STRING _NONNEGINT };
use Data::UUID                        qw{ NameSpace_DNS                  };
use File::Spec                        qw{};
use Perl::Dist::WiX::Base::Component  qw{};
use Perl::Dist::WiX::Base::Entry      qw{};
use Perl::Dist::WiX::Files::Component qw{};
use Perl::Dist::WiX::Misc             qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_05';
    @ISA = qw (Perl::Dist::WiX::Base::Component
               Perl::Dist::WiX::Base::Entry
               Perl::Dist::WiX::Misc
              );
}

use Object::Tiny qw{
    name
    path
    special
};

sub new {
    my $self = shift->Perl::Dist::WiX::Base::Component::new(@_);
    
    if (not defined _NONNEGINT($self->special)) {
        $self->{special} = 0;
    }
    
    if (($self->special == 0) && (not _STRING($self->path))) {
    require Data::Dumper;
    
    my $dump = Data::Dumper->new([$self], [qw(*self)]);
    print $dump->Indent(1)->Dump();
        
        croak 'Missing or invalid path';
    }
    
    if ((not defined _STRING($self->guid)) && (not defined _STRING($self->id))) {
        $self->create_guid_from_path;
        $self->{id} = $self->{guid};
        $self->{id} =~ s{-}{_}g;
    }
    
    $self->{directories} = [];
    $self->{files}       = [];
    
    return $self;
}

sub search {
    my ($self, $path_to_find) = @_;

    my $path = $self->path;

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

sub add_directories_id {
    my ($self, @params) = @_;
    
    # We need id, name pairs passed in. 
    if ($#params % 2 != 1) {     # The test is weird, but $#params is one less than the actual count.
        croak ('Odd number of parameters to add_directories_id');
    }
    
    # Add each individual id and name.
    my ($id, $name);
    while ($#params > 0) {
        $id   = shift @params;
        $name = shift @params;
        if ($name =~ m{\\}) {
            $self->add_directory({id => $id, path => $name});
        } else {
            $self->add_directory({id => $id, path => $self->path . '\\' . $name, name => $name});
        }
    }
}

sub add_directories_init {
    my ($self, $sitename, @params) = @_;
    
    my $name;
    while ($#params >= 0) {
        $name = shift @params;
        $self->add_directory({
            sitename => $sitename, 
            path => $self->path . '\\' . $name
        });
    }
    
    return 1;
}

sub add_directory_path {
    my ($self, $path) = @_;

    if (substr($path, -1) eq '\\') {
        $path = substr($path, 0, -1);
    }
    
    if (! $self->path =~ m{\A\Q$path\E}) {
        croak q{Can't add the directories required};
    }

    # Get list of directories to add.   
    my $path_to_remove = $self->path;
    $path =~ s{\A\Q$path_to_remove\E\\}{};
    my @dirs = File::Spec->splitdir($path);
    
    # Get rid of empty entries at the beginning.
    while ($dirs[-1] eq q{}) {
        pop @dirs;
    }
    
    my $directory_obj = $self;
    my $path_create = $self->path;
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


sub add_directory {
    my ($self, $params_ref) = @_;
    
    # If we have a name or a special code, we create it under here.
    if ((defined $params_ref->{name}) || (defined $params_ref->{special})) {
        my $i = scalar @{$self->{directories}};
        $self->{directories}->[$i] = Perl::Dist::WiX::Directory->new(%{$params_ref});
        return $self->{directories}->[$i];
    } else {
        my $path = $params_ref->{path};
        
        # Find the directory object where we want to create this directory.
        my ($volume, $directories, undef) = File::Spec->splitpath( $path, 1 );
        my @dirs = File::Spec->splitdir($directories);
        my $name = pop @dirs; # to eliminate the last directory.
        $directories = File::Spec->catdir(@dirs);
        my $directory = $self->search(File::Spec->catpath($volume, $directories, q{}));
        if (not defined $directory) {
            confess q{Can't create intermediate directories.};
        }
        
        # Add the directory there.
        $params_ref->{name} = $name;
        $directory->add_directory($params_ref);
        return $directory;
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
    return ($self->path =~ m{\A$path})
}

sub add_file {
    my ($self, @params) = @_;

    my $i = scalar @{$self->{files}};
    $self->{files}->[$i] = Perl::Dist::WiX::Files::Component->new(@params);
    return $self->{files}->[$i];
}

sub create_guid_from_path {
    my $self = shift;

    unless ( _STRING($self->sitename) ) {
        croak("Missing or invalid sitename param - cannot generate GUID without one");
    }
    unless ( _STRING($self->path) ) {
        croak("Missing or invalid id param - cannot generate GUID without one");
    }
    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
    #... then use it to create a GUID out of the path.
    $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->path);
    
    return 1;
}

sub get_component_array {
    my $self = shift;
    
    my $count = scalar @{$self->{directories}};
    my @answer;
    my $id;

    # Get the array for each descendant.
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{directories}->[$i]->get_component_array;
    }

    $count = scalar @{$self->{files}};
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{files}->[$i]->id;
    }

    return @answer;
}

sub as_string {
    my $self = shift;
    my ($count, $answer, $string); 
    
    $count = scalar @{$self->{directories}};
    foreach my $i (0 .. $count - 1) {
        $string .= $self->{directories}->[$i]->as_string;
    }
    
    $count = scalar @{$self->{files}};
    foreach my $i (0 .. $count - 1) {
        $string .= $self->{files}->[$i]->as_string;
    }

    if (defined $string) {
        if ($self->special == 2) {
            $answer = "<Directory Id='D_$self->{id}'>\n";
            $answer .= $self->indent(2, $string);
            $answer .= "\n</Directory>\n";
        } else {
            $answer = "<Directory Id='D_$self->{id}' Name='$self->{name}'>\n";
            $answer .= $self->indent(2, $string);
            $answer .= "\n</Directory>\n";
        }
    } else {
        if ($self->special == 2) {
            $answer = "<Directory Id='$self->{id}' />\n";
        } else {
            $answer = "<Directory Id='$self->{id}' Name='$self->{name}' />\n";
        }
    }

    return $answer;
}

1;
