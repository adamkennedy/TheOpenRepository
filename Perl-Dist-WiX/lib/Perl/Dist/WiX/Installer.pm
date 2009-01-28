package Perl::Dist::WiX::Installer;

=pod

=head1 NAME

Perl::Dist::WiX::Installer - WiX-specific routines.

=head1 DESCRIPTION

These are the routines that interact with the Windows Installer XML 
package, generate .wxs files, or are otherwise WiX specific.

=head1 METHODS

All public methods are listed in L<Perl::Dist::WiX>, since this is a 
superclass of that class.

=cut

# $Rev$ $Date$ $Author$
# $URL$

use 5.006;
use strict;
use warnings;
use Carp                     qw( croak                         );
use File::Spec::Functions    qw( catdir catfile rel2abs curdir );
use IO::File                 qw();
use IPC::Run3                qw();
use Params::Util             qw( _STRING _IDENTIFIER _ARRAY0   );
use URI                      qw();
require Perl::Dist::WiX::Misc;
require Perl::Dist::WiX::StartMenu;
require Perl::Dist::WiX::Environment;
require Perl::Dist::WiX::DirectoryTree;
require Perl::Dist::WiX::FeatureTree;


use vars qw{ $VERSION @ISA };
BEGIN {
    $VERSION = '0.11_07';
    @ISA = 'Perl::Dist::WiX::Misc'
}

=head2 Accessors

    $id = $dist->bin_candle; 

Accessors will return a portion of the internal state of the object.

=over 4

=item * output_dir

The location where the distribution files (*.msi, *.zip) 
will be written.

=item * source_dir

The location where the installation (Perl, MingW, erc.) 
will be written on this system.

=item * fragment_dir

The location where this object will write the information for WiX 
to process to create the MSI. A default is provided if this is not 
specified.

=item * bin_candle

Returns the location of candle.exe

=item * bin_light

Returns the location of light.exe.

=item * directories

Returns the L<Perl::Dist::WiX::DirectoryTree> object 
associated with this distribution.  Created by L</new>

=item * fragments

Returns a hashref containing the objects subclassed from 
L<Perl::Dist::WiX::Base::Fragment> associated with this distribution.
Created as the distribution's L</run> routine progresses.

=item * msi_feature_tree

Returns the parameter of the same name passed in 
from L</new>. Unused as of yet.

=item * msi_product_icon_id

Specifies the Id for the icon that is used in Add/Remove Programs for this MSI file.

=item * feature_tree_obj

Returns the Perl::Dist::WiX::FeatureTree object 
associated with this distribution.

=cut


use Object::Tiny qw{
    app_id
    app_name
    app_publisher
    app_publisher_url
    default_group_name
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
    msi_directory_tree_additions
};


sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->output_dir ) {
        $self->{output_dir} = rel2abs(
            curdir,
        );
    }
    
    unless ( defined _ARRAY0($self->msi_directory_tree_additions) ) {
        $self->{msi_directory_tree_additions} = [];
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
        sitename => $sitename,
        trace    => $self->{trace},
    )->initialize_tree(@{$self->{msi_directory_tree_additions}});

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
        croak("Failed to find the Program Files directory\n");
    }
    my $wix_dir  = catdir(  $ENV{PROGRAMFILES}, 'Windows Installer XML v3', 'bin' );
    my $wix_file = catfile( $wix_dir,           'light.exe' );
    unless ( -f $wix_file ) {
        croak("Failed to find the WiX light.exe program");
    }
    $self->{bin_light} = $wix_file;

    $wix_file = catfile( $wix_dir,           'candle.exe' );
    unless ( -f $wix_file ) {
        croak("Failed to find the WiX candle.exe program");
    }
    $self->{bin_candle} = $wix_file;

    return $self;
}

#####################################################################
# Accessor methods.
#
# These methods are for the convienence of the main template, or of
# the Perl::Dist::WiX class tree.

sub msi_product_icon_id {
    return undef;
    
    # TODO: Not implemented yet.
}

=item * app_ver_name

Returns the application name with the version appended to it.

=cut

# Default the versioned name to an unversioned name
sub app_ver_name {
    $_[0]->{app_ver_name} or
    $_[0]->app_name;
}

=item * output_base_filename

Returns the base filename that is used to create distributions.

=cut

# Default the output filename to the id plus the current date
sub output_base_filename {
    $_[0]->{output_base_filename} or
    $_[0]->app_id . '-' . $_[0]->output_date_string;
}

=item * output_date_string

Returns a stringified date in YYYYMMDD format for the use of other 
routines.

=cut

# Convenience method
sub output_date_string {
    my @t = localtime;
    return sprintf( "%04d%02d%02d", $t[5] + 1900, $t[4] + 1, $t[3] );
}

=item * msi_ui_type

Returns the UI type that the MSI needs to use.

=cut

# For template
sub msi_ui_type {
    my $self = shift;
    return (defined $self->msi_feature_tree) ? 'FeatureTree' : 'Minimal';
}

=item * msi_product_id

Returns the Id for the MSI's <Product> tag.

See http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm

=back

=cut

# For template
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

=item * msi_product_id

Returns the Id for the MSI's <Upgrade> tag.

See http://wix.sourceforge.net/manual-wix3/wix_xsd_upgrade.htm

=cut

# For template
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

=item * msi_perl_version

Returns the Version attribute for the MSI's <Product> tag.

See http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm

=cut

# For template.
# MSI versions are 3 part, not 4, with the maximum version being 255.255.65535
sub msi_perl_version {
    my $self = shift;
    
    # Ger perl version arrayref.
    my $ver = {
		588  => [5, 8, 8],
		589  => [5, 8, 9],
		5100 => [5, 10, 0],
	}->{$self->perl_version} || [0, 0, 0];

    # Merge build number with last part of perl version.
    $ver->[2] = ($ver->[2] << 8) + $self->build_number;
    
    return join '.', @{$ver};
    
}

=item * get_component_array

Returns the Version attribute for the MSI's <Product> tag.

See http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm

=back

=cut

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

    $self->trace_line(2, "Compiling $filename...\n");
    $self->compile_wxs($filename, $wixobj)
        or croak("WiX could not compile $filename");

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
    
    my $input_wixobj = catfile(
        $self->fragment_dir, $self->app_name . '.wixobj'
    );

    # Compile the .wixobj files"
    $self->trace_line( 1, "Linking $output_msi...\n");
    my $out;
    my $cmd = [
        $self->bin_light, 
        '-sice:47',                # Gets rid of ICE47 warning.
        '-out', $output_msi,       # TODO: Get rid of hard coding below.
        '-ext', 'C:\\Program Files\\Windows Installer XML v3\\bin\\WixUIExtension.dll',
        $input_wixobj,
        $input_wixouts,
    ];
    my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );
    
    unless ( -f $output_msi ) {
        $self->trace_line( 0, "$out");
        croak "Failed to find $output_msi";
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

=head2 add_file({source => $filename, fragment => $fragment_name})

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

=head2 insert_fragment($id, $files_ref)

Adds the list of files C<$files_ref> to the fragment named by C<$id>.

=cut


sub insert_fragment {
    my ($self, $id, $files_ref) = @_;

    $self->trace_line(2, "Adding fragment $id...\n");
    
    foreach my $key (keys %{$self->{fragments}}) {
        $self->{fragments}->{$key}->check_duplicates($files_ref);
    }
    
    my $fragment = 
        Perl::Dist::WiX::Files->new(
            id => $id, 
            sitename => URI->new($self->app_publisher_url)->host,
            directory_tree => $self->directories,
            trace => $self->{trace},
        )->add_files(@{$files_ref});

    $self->{fragments}->{$id} = $fragment;
    
    return $fragment;
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

No support of any kind is provided for this module.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno::Script>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell

Copyright 2008-2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut