package Perl::Dist::WiX::Installer;

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
use Perl::Dist::WiX::Registry      qw();
use Perl::Dist::WiX::DirectoryTree qw();

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_05';
}

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
};

=pod

=for documentation

app_id
app_name
app_publisher
app_publisher_url	
default_group_name
default_dir_name
output_dir 			$ENV{TEMP}\output - where logs are kept.
source_dir
fragment_dir    	$ENV{TEMP}\output\fragments - where WiX fragments and files are stored.
object_dir          $ENV{TEMP}\output\wixobj    - where .wixobj files are stored
bin_candle			Location of WiX compiler
bin_light			Location of WiX linker.
directories         Perl::Dist::WiX::DirectoryTree object.
=cut

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
        sitename => $sitename,
    );
    $self->{fragments}->{Reg_Environment} = Perl::Dist::WiX::Registry->new(
        sitename => $sitename,
        id       => 'Reg_Environment',
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

sub fragments {
    return %{ $_[0]->{fragments} };
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
    
    # Write out the .wxs file
    my $content  = $self->as_string;
    my $filename = catfile($self->fragments_dir, $self->app_name . q{.wxs});
    my $fh = IO::File->new($filename, 'w');
    $fh->print($content);
    $fh->close;

    my $wixobj = catfile($self->object_dir, $self->app_name . q{.wixobj});

    my $rv = compile_wxs($filename, $wixobj);
 
    my $msi_file = $self->link_msi($wixobj, @files);
    
    return $msi_file;
}

sub link_msi {
    my ($self, $wixout, @files) = @_;

    # Get the name of the msi file to generate
    my $output_msi = catfile(
        $self->output_dir,
        $self->output_base_filename . '.msi',
    );

    # Compile the .wixobj files
    my $cmd = [
        $self->bin_light, 
        '-out', $output_msi,
        $wixout,
        @files
    ];
    my $rv = IPC::Run3::run3( $cmd, \undef, \undef, \undef );
    
    unless ( -f $output_msi ) {
        croak("Failed to find $output_msi");
    }

    return $output_msi;
}

=head2 wix_{path, lib, include}

Creates entries (adds them to the Reg_Environment fragment) to add 
the accumulated path, lib or include entries to the environment 
upon installation. 

    $self = $self->wix_path->wix_lib->wix_include;
    
or

    $self->wix_path;
    $self->wix_lib;
    $self->wix_include;
        

=cut

sub wix_path {
	my $self = shift;
    return $self->_append_path('PATH', $self->env_path);
}

sub wix_lib {
	my $self = shift;
    return $self->_append_env('LIB', $self->env_lib);
}

sub wix_include {
	my $self = shift;
    return $self->_append_env('INCLUDE', $self->env_include);
}

sub _append_env {
    my ($self, $name, $values_ref) = @_;

    unless (_STRING($name)) {
        croak q{Invalid or missing name parameter.};
    }

    unless (_ARRAY0($values_ref)) {
        croak q{Can't dereference second parameter.};
    }
    
	my $value = join ';', map { catdir( '[APPLICATIONROOTDIRECTORY]', @$_ ) } @{$values_ref};

    $self->add_env($name, $value, 1);
    
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
    
    $self->{fragments}->{Reg_Environment}->add_key(
        key        => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        id         => 'Reg_Environment',
        sitename   => URI->new($self->app_publisher_url)->host,
        name       => $name,
        value      => $value,
        action     => $append ? 'append' : 'write',
        value_type => 'expandable',
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

    my $tt = new Template({
        INCLUDE_PATH => '/usr/local/templates',
        EVAL_PERL    => 1,
    }) || croak($Template::ERROR . "\n");

    my $answer;
    
    $tt->process('Main.wxs.tt', , \$answer) || Carp::Croak($tt->error() . "\n");

    ###############
    
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