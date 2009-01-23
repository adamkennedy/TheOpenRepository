package Perl::Dist::WiX::Installer;

=pod

=head1 NAME

Perl::Dist::WiX::Base::Component - Base class for <Component> tag.

=head1 DESCRIPTION

These are the routines that interact with the Windows Installer XML 
package, generate .wxs files, or are otherwise WiX specific.

=head1 METHODS

=head2 Accessors

Accessors take no parameters and return the item requested (listed below)

=cut

use 5.006;
use strict;
use warnings;
use Carp                           qw{ croak verbose };
use File::Spec::Functions          qw{ catdir catfile rel2abs curdir };
use IO::File                       qw();
use IPC::Run3                      qw();
use Params::Util                   qw{ _STRING _IDENTIFIER _ARRAY0};
use URI                            qw();
use Perl::Dist::WiX::StartMenu     qw();
use Perl::Dist::WiX::Environment   qw();
use Perl::Dist::WiX::DirectoryTree qw();
use Perl::Dist::WiX::FeatureTree   qw();


use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_06';
}

=pod

=over 4

=item *

app_id, app_name, app_publisher, app_publisher_url: 
Returns the parameter of the same 
name passed in to L</new>

=item *

default_group_name, default_item_name: Unknown as of yet.

=item *

output_dir, source_dir, fragment_dir: Unknown as of yet.

=item *

bin_candle, bin_light: Returns the location of candle.exe or light.exe.

=item *

directories: Returns the Perl::Dist::WiX::DirectoryTree object 
associated with this distribution.

=item *

fragments: Returns a hashref containing the objects subclassed from 
Perl::Dist::WiX::Base::Fragment associated with this distribution.

=item *

msi_feature_tree: Returns the parameter of the same name passed in 
from L</new>. Unused as of yet.

=item *

msi_banner_top, msi_banner_side, msi_help_url, msi_license_file, 
msi_readme_file, msi_product_icon: Returns the parameter of the 
same name passed in from L</new>.

=item *

feature_tree_obj: Returns the Perl::Dist::WiX::FeatureTree object 
associated with this distribution.

=back

    $id = $component->bin_candle; 

=cut


use Object::Tiny qw{
    app_id
    app_name
    app_publisher
    app_publisher_url
    default_group_name
    default_dir_name
    output_dir
    source_dir
    fragment_dir
    bin_candle
    bin_light
    directories
    fragments
    msi_feature_tree
    msi_banner_top
    msi_banner_side
    msi_help_url
    msi_debug
    msi_license_file
    msi_readme_file
    msi_product_icon
    feature_tree_obj
};


sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->output_dir ) {
        $self->{output_dir} = rel2abs(
            curdir,
        );
    }
    
    unless ( defined $self->default_group_name ) {
        $self->{default_group_name} = $self->app_name;
    }
    unless ( _STRING($self->msi_license_file) ) {
        $self->{msi_license_file} = catfile($self->dist_file, 'License.rtf');
    }
    # Check and default params
    unless ( _IDENTIFIER($self->app_id) ) {
        croak("Missing or invalid app_id param");
    }
    unless ( _STRING($self->app_name) ) {
        croak("Missing or invalid app_name param");
    }
    unless ( _STRING($self->app_ver_name) ) {
        croak("Missing or invalid app_ver_name param");
    }
    unless ( _STRING($self->app_publisher) ) {
        croak("Missing or invalid app_publisher param");
    }
    unless ( _STRING($self->app_publisher_url) ) {
        croak("Missing or invalid app_publisher_uri param");
    }
    unless ( _STRING($self->default_group_name) ) {
        croak("Missing or invalid default_group_name param");
    }
    unless ( _STRING($self->default_dir_name) ) {
        croak("Missing or invalid default_dir_name");
    }
    unless ( _STRING($self->output_dir) ) {
        croak("Missing or invalid output_dir param");
    }
    unless ( -d $self->output_dir ) {
        croak("The output_dir " . $self->output_dir . "directory does not exist");
    }
    unless ( -w $self->output_dir ) {
        croak("The output_dir directory is not writable");
    }
    unless ( _STRING($self->output_base_filename) ) {
        croak("Missing or invalid output_base_filename");
    }
    unless ( _STRING($self->source_dir) ) {
        croak("Missing or invalid source_dir param");
    }
    unless ( -d $self->source_dir ) {
        croak("The source_dir directory does not exist");
    }
    unless ( _STRING($self->fragment_dir) ) {
        croak("Missing or invalid fragment_dir param");
    }
    unless ( -d $self->fragment_dir ) {
        croak("The fragment_dir directory does not exist");
    }

    # Set element collections
    my $sitename = URI->new($self->app_publisher_url)->host;

    $self->{directories} = Perl::Dist::WiX::DirectoryTree->new(
        app_dir => $self->image_dir, 
        app_name => $self->app_name, 
        sitename => $sitename
    );

    $self->{fragments}    = {};
    $self->{fragments}->{Icons} = Perl::Dist::WiX::StartMenu->new(
        sitename  => $sitename,
        directory => 'D_App_Menu',
    );
    $self->{fragments}->{Environment} = Perl::Dist::WiX::Environment->new(
        sitename => $sitename,
        id       => 'Environment',
    );
    $self->{fragments}->{Win32Extras} = Perl::Dist::WiX::Files->new(
        sitename        => $sitename,
        directory_tree  => $self->directories,
        id              => 'Win32Extras',
    );
    
    # Find the light.exe and candle.exe programs
    unless ( $ENV{PROGRAMFILES} and -d $ENV{PROGRAMFILES} ) {
        die("Failed to find the Program Files directory\n");
    }
    my $wix_dir  = catdir(  $ENV{PROGRAMFILES}, 'Windows Installer XML v3', 'bin' );
    my $wix_file = catfile( $wix_dir,           'light.exe' );
    unless ( -f $wix_file ) {
        die("Failed to find the WiX light.exe program");
    }
    $self->{bin_light} = $wix_file;

    $wix_file = catfile( $wix_dir,           'candle.exe' );
    unless ( -f $wix_file ) {
        die("Failed to find the WiX candle.exe program");
    }
    $self->{bin_candle} = $wix_file;

    return $self;
}

sub msi_product_icon_id {
    return undef;
}

# Default the versioned name to an unversioned name
sub app_ver_name {
    $_[0]->{app_ver_name} or
    $_[0]->app_name;
}

# Default the output filename to the id plus the current date
sub output_base_filename {
    $_[0]->{output_base_filename} or
    $_[0]->app_id . '-' . $_[0]->output_date_string;
}

# Convenience method
sub output_date_string {
    my @t = localtime;
    return sprintf( "%04d%02d%02d", $t[5] + 1900, $t[4] + 1, $t[3] );
}

sub msi_ui_type {
    my $self = shift;
    return (defined $self->msi_feature_tree) ? 'FeatureTree' : 'Minimal';
}

sub msi_product_id {
    my $self = shift;

    my $sitename = URI->new($self->app_publisher_url)->host;
    
    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $sitename);
    #... then use it to create a GUID out of the ID.
    my $guid = uc $guidgen->create_from_name_str($uuid, $self->app_ver_name);

    return $guid;
}

sub msi_upgrade_code {
    my $self = shift;

    my $upgrade_ver = $self->app_name
		. ($self->portable ? ' Portable' : '')
		. ' ' . $self->perl_version_human;

    my $sitename = URI->new($self->app_publisher_url)->host;
    
    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $sitename);
    #... then use it to create a GUID out of the ID.
    my $guid = uc $guidgen->create_from_name_str($uuid, $upgrade_ver);

    return $guid;
}

sub msi_perl_version {
    my $self = shift;
    
    my $ver = {
		588  => [5, 8, 8],
		589  => [5, 8, 9],
		5100 => [5, 10, 0],
	}->{$self->perl_version} || 0;

    $ver->[2] = ($ver->[2] << 8) + $self->build_number;
    
    return join '.', @{$ver};
    
}

sub get_component_array {
    my $self = shift;

    my @answer;
    foreach my $key (keys %{$self->fragments}) {
        push @answer, $self->fragments->{$key}->get_component_array;
    }
    
    return @answer;
}

#####################################################################
# Main Methods

=pod

=cut

sub compile_wxs {
    my ($self, $filename, $wixobj) = @_;
    my @files = @_;
    
    # Compile the .wxs file
    my $cmd = [
        $self->bin_candle,
        '-out', $wixobj,
        $filename,
        
    ];
    my $rv = IPC::Run3::run3( $cmd, \undef, \undef, \undef );

    return $rv;
}

sub write_msi {
    my $self = shift;
    my @files = @_;

    $self->{feature_tree_obj} = Perl::Dist::WiX::FeatureTree->new(
        parent => $self
    );
    
    # Write out the .wxs file
    my $content  = $self->as_string;
    $content =~ s{\r\n}{\n}g;     # CRLF -> LF
    $content =~ s{\n[ \t]*?\n[ \t]*?\n}{\n\n}g;   # Convert triple-spacing with horizontal
                                                  # whitespace to double-spacing...
    my $filename = catfile($self->fragment_dir, $self->app_name . q{.wxs});
    my $fh = IO::File->new($filename, 'w');
    $fh->print($content);
    $fh->close;

    my $wixobj = catfile($self->fragment_dir, $self->app_name . q{.wixobj});

    print "Compiling $filename...\n";
    $self->compile_wxs($filename, $wixobj)
        or die "WiX could not compile $filename";

    unless ( -f $wixobj ) {
        croak("Failed to find $wixobj (probably compilation error in $filename)");
    }


        
    my $msi_file = $self->link_msi;
    
    return $msi_file;
}

sub link_msi {
    my ($self) = @_;

    # Get the name of the msi file to generate
    my $output_msi = catfile(
        $self->output_dir,
        $self->output_base_filename . '.msi',
    );
    
    my $input_wixouts = catfile(
        $self->fragment_dir, '*.wixout'
    );

    # Compile the .wixobj files"
    print "Linking $output_msi...\n";
    my $cmd = [
        $self->bin_light, 
        '-out', $output_msi,       # TODO: Get rid of hard coding.
        '-ext', 'C:\\Program Files\\Windows Installer XML v3\\bin\\WixUIExtension.dll',
        $input_wixouts,
    ];
    my $rv = IPC::Run3::run3( $cmd, \undef, \undef, \undef );
    
    unless ( -f $output_msi ) {
        croak("Failed to find $output_msi");
    }

    return $output_msi;
}

=head2 add_wix_path

Creates entries (adds them to the Reg_Environment fragment) to add 
the accumulated path, lib or include entries to the environment 
upon installation. 

    $self = $self->add_wix_path;

=cut

sub add_wix_path {
	my $self = shift;

    foreach my $value (map { catdir( '[APPLICATIONROOTDIRECTORY]', $_ ) } @{$self->env_path}) {
        $self->add_env('PATH', $value, 1);
    }

    return $self;
}

=head2 add_env($name, $value[, $append])

Adds the contents of $value to the environment variable $name 
(or appends to it, if $append is true) upon installation (by 
adding it to the Reg_Environment fragment.)

$name and $value are required. 

=cut

sub add_env {
    my ($self, $name, $value, $append) = @_;
    
    unless (defined $append) {
        $append = 0;
    }

    unless (_STRING($name)) {
        croak 'Invalid or missing name parameter';
    }

    unless (_STRING($value)) {
        croak 'Invalid or missing value parameter';
    }
    
    my $num = scalar @{$self->{fragments}->{Environment}->{entries}};
    
    $self->{fragments}->{Environment}->add_entry(
        id         => "Env_$num",        
        name       => $name,
        value      => $value,
        action     => 'set',
        part       => $append ? 'last' : 'all',
    );

    return $self;
}

=head2 add_file(source => $filename, fragment => $fragment_name)

Adds the file C<$filename> to the fragment named by C<$fragment_name>.

Both parameters are required, and the file and fragment must both exist. 

=cut

sub add_file {
    my ($self, %params) = @_;

    unless (_STRING($params{source})) {
        croak 'Invalid or missing source parameter';
    }

    unless (-f $params{source}) {
        croak "File $params{source} does not exist";
    }
    
    unless (_IDENTIFIER($params{fragment})) {
        croak 'Invalid or missing fragment parameter';
    }
    
    unless (defined $self->{fragments}->{$params{fragment}}) {
        croak "Fragment $params{fragment} not defined";
    }
    
    $self->{fragments}->{$params{fragment}}->add_file($params{source});
    
    return $self;
}

#####################################################################
# Serialization

=head2 as_string

Loads the main .wxs file template, using this object, and returns 
it as a string.

    $wxs = $self->as_string;

=cut

sub as_string {
    my $self = shift;

    my $tt = new Template({
        INCLUDE_PATH => $self->dist_dir,
        EVAL_PERL    => 1,
    }) || croak($Template::ERROR . "\n");

    my $answer;
    my $vars = { dist => $self };
    
    $tt->process('Main.wxs.tt', $vars, \$answer) || croak($tt->error() . "\n");

    # Combine it all
    return $answer;
}

1;

=pod

=head1 SUPPORT

No support of any kind is provided for this module

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno::Script>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell, Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut