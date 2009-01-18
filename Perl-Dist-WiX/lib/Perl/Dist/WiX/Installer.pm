package Perl::Dist::WiX::Installer;

use 5.006;
use strict;
use warnings;
use Carp                       qw{ croak };
use File::Spec                 ();
use IO::File                   ();
use IPC::Run3                  ();
use Params::Util               qw{ _STRING _IDENTIFIER };

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_04';
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

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->output_dir ) {
        $self->{output_dir} = File::Spec->rel2abs(
            File::Spec->curdir,
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
    $self->{fragments}    = [];

    # Find the light.exe and candle.exe programs
    unless ( $ENV{PROGRAMFILES} and -d $ENV{PROGRAMFILES} ) {
        die("Failed to find the Program Files directory\n");
    }
    my $wix_dir  = File::Spec->catdir(  $ENV{PROGRAMFILES}, 'Windows Installer XML v3', 'bin' );
    my $wix_file = File::Spec->catfile( $wix_dir,           'light.exe' );
    unless ( -f $wix_file ) {
        die("Failed to find the WiX light.exe program");
    }
    $self->{bin_light} = $wix_file;

    $wix_file = File::Spec->catfile( $wix_dir,           'candle.exe' );
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
    return @{ $_[0]->{fragments} };
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

    retirn $rv;
}

sub write_msi {
    my $self = shift;
    my @files = @_;
    
    # Write out the .wxs file
    my $content  = $self->as_string;
    my $filename = File::Spec::catfile($self->fragments_dir, $self->app_name . q{.wxs});
    my $fh = new IO::File $filename, 'w';
    $fh->print($content);
    $fh->close;

    my $wixobj = File::Spec::catfile($self->object_dir, $self->app_name . q{.wixobj});

    my $rv = compile_wxs($filename, $wixobj);
 
    my $msi_file = $self->link_msi($wixobj, @files);
    
    return $msi_file;
}

sub link_msi {
    my ($self, $wixout, @files) = @_;

    # Get the name of the msi file to generate
    my $output_msi = File::Spec->catfile(
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

#####################################################################
# Serialization

sub as_string {

    my $tt = new Template({
        INCLUDE_PATH => '/usr/local/templates',
        EVAL_PERL    => 1,
    }) || Carp::croak($Template::ERROR . "\n");

    my $answer;
    
    $tt->process('Main.wxs.tt', , \$answer) || Carp::Croak($tt->error() . "\n");

    ###############
    
    # Combine it all
    return $answer;
}

1;