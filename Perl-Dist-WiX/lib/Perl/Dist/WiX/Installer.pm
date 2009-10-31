package Perl::Dist::WiX::Installer;

=pod

=head1 NAME

Perl::Dist::WiX::Installer - WiX-specific routines.

=head1 VERSION

This document describes Perl::Dist::WiX::Installer version 1.000.

=head1 DESCRIPTION

These are the routines that interact with the Windows Installer XML 
package, generate .wxs files, or are otherwise WiX specific.

=head1 METHODS

Many public methods are listed in L<Perl::Dist::WiX|Perl::Dist::WiX>, 
since this is a superclass of that class.

=cut

use 5.008001;
use strict;
use warnings;
use Alien::WiX qw( :ALL );
use File::Spec::Functions qw( catdir catfile rel2abs curdir );
use Params::Util qw( _STRING _IDENTIFIER _ARRAY0 _ARRAY _INSTANCE );
use English qw( -no_match_vars );
use IO::File qw();
use IPC::Run3 qw();
use URI qw();
require Perl::Dist::WiX::Exceptions;
require Perl::Dist::WiX::DirectoryTree2;
require Perl::Dist::WiX::FeatureTree2;
require Perl::Dist::WiX::Fragment::CreateFolder;
require Perl::Dist::WiX::Fragment::Files;
require Perl::Dist::WiX::Fragment::Environment;
require Perl::Dist::WiX::Fragment::StartMenu;
require Perl::Dist::WiX::IconArray;

our $VERSION = '1.100_001';
$VERSION =~ s/_//;

=head2 Accessors

	$id = $dist->output_dir; 

Accessors will return a portion of the internal state of the object.

=over 4

=item * output_dir

The location where the distribution files (*.msi, *.zip) 
will be written.

=item * source_dir

See the L<image_dir|Perl::Dist::WiX/image_dir> accessor in 
L<Perl::Dist::WiX|Perl::Dist::WiX>.

=item * fragment_dir

The location where this object will write the information for WiX 
to process to create the MSI. A default is provided if this is not 
specified.

=item * directories

Returns the L<Perl::Dist::WiX::DirectoryTree|Perl::Dist::WiX::DirectoryTree> 
object associated with this distribution.  Created by L</new>

=item * fragments

Returns a hashref containing the objects subclassed from 
L<Perl::Dist::WiX::Base::Fragment|Perl::Dist::WiX::Base::Fragment> 
associated with this distribution. Created as the distribution's 
L</run> routine progresses.

=item * msi_feature_tree

Returns the parameter of the same name passed in 
from L</new>. Unused as of yet.

=item * msi_product_icon_id

Specifies the Id for the icon that is used in Add/Remove Programs for 
this MSI file.

=item * feature_tree_obj

Returns the L<Perl::Dist::WiX::FeatureTree|Perl::Dist::WiX::FeatureTree> 
object associated with this distribution.

=cut

use Object::Tiny qw{
  app_id
  app_name
  app_publisher
  app_publisher_url
  default_group_name
  output_dir
  fragment_dir
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
  sitename
  icons
  pdw_version
  pdw_class
};

sub _check_string_parameter {
	my ( $self, $string, $name ) = @_;

	unless ( _STRING($string) ) {
		PDWiX::Parameter->throw(
			parameter => $name,
			where     => '::Installer->new'
		);
	}

	return;
} ## end sub _check_string_parameter

sub trace_line {
	my $self = shift;

	return $self->{misc}->trace_line(@_);
}

#####################################################################
# Accessor methods.
#
# These methods are for the convienence of the main template, or of
# the Perl::Dist::WiX class tree.

=item * msi_product_icon_id

Returns the product icon to use in the main template.

=cut

sub msi_product_icon_id {
	my $self = shift;

	# Get the icon ID if we can.
	if ( defined $self->msi_product_icon() ) {
		return 'I_' . $self->icons()->search_icon( $self->msi_product_icon );
	} else {
		return undef;
	}
} ## end sub msi_product_icon_id

=item * app_ver_name

Returns the application name with the version appended to it.

=cut

# Default the versioned name to an unversioned name
sub app_ver_name {
	return $_[0]->{app_ver_name}
	  or $_[0]->app_name();
}

=item * output_base_filename

Returns the base filename that is used to create distributions.

=cut

# Default the output filename to the id plus the current date
sub output_base_filename {
	return $_[0]->{output_base_filename}
	  or $_[0]->app_id() . q{-} . $_[0]->output_date_string();
}

=item * output_date_string

Returns a stringified date in YYYYMMDD format for the use of other 
routines.

=cut

# Convenience method
sub output_date_string {
	my @t = localtime;
	return sprintf '%04d%02d%02d', $t[5] + 1900, $t[4] + 1, $t[3];
}

=item * msi_ui_type

Returns the UI type that the MSI needs to use.

=cut

# For template
sub msi_ui_type {
	my $self = shift;
	return ( defined $self->msi_feature_tree() ) ? 'FeatureTree' : 'Minimal';
}

=item * msi_platform_string

Returns the Platform attribute to the MSI's Package tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_package.htm>

=cut

# For template
sub msi_platform_string {
	my $self = shift;
	return ( 64 == $self->bits() ) ? 'x64' : 'x86';
}

=item * msi_product_id

Returns the Id for the MSI's <Product> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template
sub msi_product_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $product_name =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable ' : q{ } )
	  . $self->app_publisher_url()
	  . q{ ver. }
	  . $self->msi_perl_version();

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($product_name);

	return $guid;
} ## end sub msi_product_id

=item * msm_product_id

Returns the Id for the <Product> tag for the MSI's merge module.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template
sub msm_product_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $product_name =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable ' : q{ } )
	  . $self->app_publisher_url()
	  . q{ ver. }
	  . $self->msi_perl_version()
	  . q{ merge module.};

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($product_name);
	$guid =~ s/-/_/g;

	return $guid;
} ## end sub msi_product_id


=item * msi_upgrade_code

Returns the Id for the MSI's <Upgrade> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_upgrade.htm>

=cut

# For template
sub msi_upgrade_code {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $upgrade_ver =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable' : q{} ) . q{ }
	  . $self->app_publisher_url();

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($upgrade_ver);

	return $guid;
} ## end sub msi_upgrade_code

=item * msm_package_id

Returns the Id for the MSI's <Package> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_package.htm>

=cut

# For template
sub msm_package_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $upgrade_ver =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable' : q{} ) . q{ }
	  . $self->app_publisher_url()
	  . q{ merge module.};

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($upgrade_ver);
	
	return $guid;
} ## end sub msi_upgrade_code


=item * msi_perl_version

Returns the Version attribute for the MSI's <Product> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template.
# MSI versions are 3 part, not 4, with the maximum version being 255.255.65535
sub msi_perl_version {
	my $self = shift;

	# Get perl version arrayref.
	my $ver = {
		589  => [ 5, 8,  9 ],
		5100 => [ 5, 10, 0 ],
		5101 => [ 5, 10, 1 ],
	  }->{ $self->perl_version }
	  || [ 0, 0, 0 ];

	# Merge build number with last part of perl version.
	$ver->[2] = ( $ver->[2] << 8 ) + $self->build_number();

	return join q{.}, @{$ver};

} ## end sub msi_perl_version

=item * perl_config_myuname

Returns the value to be used for perl -V:myuname, which is in this pattern:

	Win32 app_id 5.10.0.1.beta_1 #1 Mon Jun 15 23:11:00 2009 i386
	
(the .beta_X is ommitted if the beta_number accessor is not set.)

=cut

# For template.
# MSI versions are 3 part, not 4, with the maximum version being 255.255.65535
sub perl_config_myuname {
	my $self = shift;

	my $version = $self->perl_version_human() . q{.} . $self->build_number();
	if ( $self->beta_number() > 0 ) {
		$version .= '.beta_' . $self->beta_number();
	}

	my $bits = (64 == $self->bits()) ? 'x86_64' : 'i386';
	
	return join q{ }, 'Win32', $self->app_id(), $version, '#1',
	  $self->build_start_time(), 'i386';

} ## end sub perl_config_myuname

=item * get_component_array

Returns the array of <Component Id>'s required.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_component.htm>, 
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_componentref.htm>

=back

=cut

sub get_component_array {
	my $self = shift;

	print "Running get_component_array...\n";
	my @answer;
	foreach my $key ( keys %{ $self->fragments } ) {
		push @answer, $self->fragments->{$key}->get_componentref_array();
	}

	return @answer;
}

#####################################################################
# Main Methods

=head2 compile_wxs($filename, $wixobj)

Compiles a .wxs file (specified by $filename) into a .wixobj file 
(specified by $wixobj.)  Both parameters are required.

	$self = $self->compile_wxs("Perl.wxs", "Perl.wixobj");

=cut

sub compile_wxs {
	my ( $self, $filename, $wixobj ) = @_;
	my @files = @_;

	# Check parameters.
	unless ( _STRING($filename) ) {
		PDWiX::Parameter->throw(
			parameter => 'filename',
			where     => '::Installer->compile_wxs'
		);
	}
	unless ( _STRING($wixobj) ) {
		PDWiX::Parameter->throw(
			parameter => 'wixobj',
			where     => '::Installer->compile_wxs'
		);
	}
	unless ( -r $filename ) {
		PDWiX->throw("$filename does not exist or is not readable");
	}

	# Compile the .wxs file
	my $cmd = [
		wix_bin_candle(),
		'-out', $wixobj,
		$filename,

	];
	my $out;
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	if ( ( not -f $wixobj ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw( "Failed to find $wixobj (probably "
			  . "compilation error in $filename)" );
	}


	return $rv;
} ## end sub compile_wxs

=pod

=head2 write_msi

  $self->write_msi;

The C<write_msi> method is used to generate the compiled installer
executable. It creates the entire installation file tree, and then
executes WiX to create the final executable.

This method should only be called after all installation phases have
been completed and all of the files for the distribution are in place.

The executable file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_msi {
	my $self = shift;

	my $dir = $self->fragment_dir;
	my ( $fragment, $fragment_name, $fragment_string );
	my ( $filename_in, $filename_out );
	my $fh;
	my @files;

	$self->trace_line( 1, "Generating msi\n" );

  FRAGMENT:

	# Write out .wxs files for all the fragments and compile them.
	foreach my $key ( keys %{ $self->{fragments} } ) {
		$fragment        = $self->{fragments}->{$key};
		$fragment_string = $fragment->as_string;
		next
		  if ( ( not defined $fragment_string )
			or ( $fragment_string eq q{} ) );
		$fragment_name = $fragment->get_id;
		$filename_in   = catfile( $dir, $fragment_name . q{.wxs} );
		$filename_out  = catfile( $dir, $fragment_name . q{.wixout} );
		$fh            = IO::File->new( $filename_in, 'w' );

		if ( not defined $fh ) {
			PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
			);
		}
		$fh->print($fragment_string);
		$fh->close;
		$self->trace_line( 2, "Compiling $filename_in\n" );
		$self->compile_wxs( $filename_in, $filename_out )
		  or PDWiX->throw("WiX could not compile $filename_in");

		unless ( -f $filename_out ) {
			PDWiX->throw( "Failed to find $filename_out (probably "
				  . "compilation error in $filename_in)" );
		}

		push @files, $filename_out;
	} ## end foreach my $key ( keys %{ $self...})

	# Generate feature tree.
	$self->{feature_tree_obj} =
	  Perl::Dist::WiX::FeatureTree2->new( parent => $self, );

	# Write out the .wxs file
	my $content = $self->as_string('Main.wxs.tt');
	$content =~ s{\r\n}{\n}msg;        # CRLF -> LF
	$filename_in =
	  catfile( $self->fragment_dir, $self->app_name . q{.wxs} );

	if ( -f $filename_in ) {

		# Had a collision. Yell and scream.
		PDWiX->throw(
			"Could not write out $filename_in: File already exists.");
	}
	$filename_out =
	  catfile( $self->fragment_dir, $self->app_name . q{.wixobj} );
	$fh = IO::File->new( $filename_in, 'w' );

	if ( not defined $fh ) {
		PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($content);
	$fh->close;

	# Compile the main .wxs
	$self->trace_line( 2, "Compiling $filename_in\n" );
	$self->compile_wxs( $filename_in, $filename_out )
	  or PDWiX->throw("WiX could not compile $filename_in");
	unless ( -f $filename_out ) {
		PDWiX->throw( "Failed to find $filename_out (probably "
			  . "compilation error in $filename_in)" );
	}

# Start linking the msi.

# TODO: Take out the stop here.
	PDWiX->throw("Debugging stop");

	# Get the parameters for the msi linking.
	my $output_msi =
	  catfile( $self->output_dir, $self->output_base_filename . '.msi', );
	my $input_wixouts = catfile( $self->fragment_dir, '*.wixout' );
	my $input_wixobj =
	  catfile( $self->fragment_dir, $self->app_name . '.wixobj' );

	# Link the .wixobj files
	$self->trace_line( 1, "Linking $output_msi\n" );
	my $out;
	my $cmd = [
		wix_bin_light(),
		'-sice:ICE38',                 # Gets rid of ICE38 warning.
		'-sice:ICE43',                 # Gets rid of ICE43 warning.
		'-sice:ICE47',                 # Gets rid of ICE47 warning.
		                               # (Too many components in one
		                               # feature for Win9X)
#		'-sice:ICE48',                 # Gets rid of ICE48 warning.
		                               # (Hard-coded installation location)

#		'-v',                          # Verbose for the moment.
		'-out', $output_msi,
		'-ext', wix_lib_wixui(),
		$input_wixobj,
		$input_wixouts,
	];
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	$self->trace_line( 1, $out );

	# Did everything get done correctly?
	if ( ( not -f $output_msi ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw(
			"Failed to find $output_msi (probably compilation error)");
	}

	return $output_msi;
} ## end sub write_msi

=pod

=head2 write_msm

  $self->write_msm;

The C<write_msm> method is used to generate the compiled merge module
used in the installer. It creates the entire installation file tree, and then
executes WiX to create the merge module.

This method should only be called after all installation phases that 
install perl modules have been completed and all of the files for the 
merge module are in place.

The merge module file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_msm {
	my $self = shift;

	my $dir = $self->fragment_dir;
	my ( $fragment, $fragment_name, $fragment_string );
	my ( $filename_in, $filename_out );
	my $fh;
	my @files;

	$self->trace_line( 1, "Generating msm\n" );

	# Add the path in.
	foreach my $value ( map { '[INSTALLDIR]' . catdir( @{$_} ) }
		@{ $self->env_path } )
	{
		$self->add_env( 'PATH', $value, 1 );
	}

  FRAGMENT:

	# Write out .wxs files for all the fragments and compile them.
	foreach my $key ( keys %{ $self->{fragments} } ) {
		$fragment        = $self->{fragments}->{$key};
		$fragment_string = $fragment->as_string;
		next
		  if ( ( not defined $fragment_string )
			or ( $fragment_string eq q{} ) );
		$fragment_name = $fragment->get_id;
		$filename_in   = catfile( $dir, $fragment_name . q{.wxs} );
		$filename_out  = catfile( $dir, $fragment_name . q{.wixout} );
		$fh            = IO::File->new( $filename_in, 'w' );

		if ( not defined $fh ) {
			PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
			);
		}
		$fh->print($fragment_string);
		$fh->close;
		$self->trace_line( 2, "Compiling $filename_in\n" );
		$self->compile_wxs( $filename_in, $filename_out )
		  or PDWiX->throw("WiX could not compile $filename_in");

		unless ( -f $filename_out ) {
			PDWiX->throw( "Failed to find $filename_out (probably "
				  . "compilation error in $filename_in)" );
		}

		push @files, $filename_out;
	} ## end foreach my $key ( keys %{ $self...})

	# Generate feature tree.
	$self->{feature_tree_obj} =
	  Perl::Dist::WiX::FeatureTree2->new( parent => $self, );

	# Write out the .wxs file
	my $content = $self->as_string('Merge-Module.wxs.tt');
	$content =~ s{\r\n}{\n}msg;        # CRLF -> LF
	$filename_in =
	  catfile( $self->fragment_dir, $self->app_name . q{.wxs} );

	if ( -f $filename_in ) {

		# Had a collision. Yell and scream.
		PDWiX->throw(
			"Could not write out $filename_in: File already exists.");
	}
	$filename_out =
	  catfile( $self->fragment_dir, $self->app_name . q{.wixobj} );
	$fh = IO::File->new( $filename_in, 'w' );

	if ( not defined $fh ) {
		PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($content);
	$fh->close;

	# Compile the main .wxs
	$self->trace_line( 2, "Compiling $filename_in\n" );
	$self->compile_wxs( $filename_in, $filename_out )
	  or PDWiX->throw("WiX could not compile $filename_in");
	unless ( -f $filename_out ) {
		PDWiX->throw( "Failed to find $filename_out (probably "
			  . "compilation error in $filename_in)" );
	}

# Start linking the merge module.

	# Get the parameters for the msi linking.
	my $output_msm =
	  catfile( $self->output_dir, $self->output_base_filename . '.msm', );
	my $input_wixouts = catfile( $self->fragment_dir, '*.wixout' );
	my $input_wixobj =
	  catfile( $self->fragment_dir, $self->app_name . '.wixobj' );

	# Link the .wixobj files
	$self->trace_line( 1, "Linking $output_msm\n" );
	my $out;
	my $cmd = [
		wix_bin_light(),
#		'-sice:ICE38',                 # Gets rid of ICE38 warning.
#		'-sice:ICE43',                 # Gets rid of ICE43 warning.
#		'-sice:ICE47',                 # Gets rid of ICE47 warning.
		                               # (Too many components in one
		                               # feature for Win9X)
#		'-sice:ICE48',                 # Gets rid of ICE48 warning.
		                               # (Hard-coded installation location)

#		'-v',                          # Verbose for the moment.
		'-out', $output_msm,
		'-ext', wix_lib_wixui(),
		$input_wixobj,
		$input_wixouts,
	];
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	$self->trace_line( 1, $out );

	# Did everything get done correctly?
	if ( ( not -f $output_msm ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw(
			"Failed to find $output_msm (probably compilation error)");
	}

	return $output_msm;
} ## end sub write_msm

=pod

=head2 add_env($name, $value I<[, $append]>)

Adds the contents of $value to the environment variable $name 
(or appends to it, if $append is true) upon installation (by 
adding it to the Reg_Environment fragment.)

$name and $value are required. 

=cut

sub add_env {
	my ( $self, $name, $value, $append ) = @_;

	unless ( defined $append ) {
		$append = 0;
	}

	unless ( _STRING($name) ) {
		PDWiX::Parameter->throw(
			parameter => 'name',
			where     => '::Installer->add_env'
		);
	}

	unless ( _STRING($value) ) {
		PDWiX::Parameter->throw(
			parameter => 'value',
			where     => '::Installer->add_env'
		);
	}

	my $num = $self->{fragments}->{Environment}->get_entries_count();

	$self->{fragments}->{Environment}->add_entry(
		id     => "Env_$num",
		name   => $name,
		value  => $value,
		action => 'set',
		part   => $append ? 'last' : 'all',
	);

	return $self;
} ## end sub add_env

=head2 add_file({source => $filename, fragment => $fragment_name})

Adds the file C<$filename> to the fragment named by C<$fragment_name>.

Both parameters are required, and the file and fragment must both exist. 

=cut

sub add_file {
	my ( $self, %params ) = @_;

	unless ( _STRING( $params{source} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'source',
			where     => '::Installer->add_file'
		);
	}

	unless ( -f $params{source} ) {
		PDWiX->throw("File $params{source} does not exist");
	}

	unless ( _IDENTIFIER( $params{fragment} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'fragment',
			where     => '::Installer->add_file'
		);
	}

	unless ( defined $self->{fragments}->{ $params{fragment} } ) {
		PDWiX->throw("Fragment $params{fragment} does not exist");
	}

	$self->{fragments}->{ $params{fragment} }->add_file( $params{source} );

	return $self;
} ## end sub add_file

=head2 insert_fragment($id, $files_ref)

Adds the list of files C<$files_ref> to the fragment named by C<$id>.

The fragment is created by this routine, so this can only be done once.

This B<MUST> be done for each set of files to be installed in an MSI.

=cut

sub insert_fragment {
	my ( $self, $id, $files_obj, $overwritable ) = @_;

	# Check parameters.
	unless ( _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::Installer->insert_fragment'
		);
	}
	unless ( _INSTANCE( $files_obj, 'File::List::Object' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'files_obj',
			where     => '::Installer->insert_fragment'
		);
	}

	defined $overwritable or $overwritable = 0;

	$self->trace_line( 2, "Adding fragment $id...\n" );

  FRAGMENT:
	foreach my $frag ( keys %{ $self->{fragments} } ) {
		next FRAGMENT
		  if not $self->{fragments}->{$frag}
			  ->isa('Perl::Dist::WiX::Fragment::Files');
		$self->{fragments}->{$frag}->check_duplicates($files_obj);
	}

	my $fragment = Perl::Dist::WiX::Fragment::Files->new(
		id            => $id,
		files         => $files_obj,
		can_overwrite => $overwritable,
	);

	$self->{fragments}->{$id} = $fragment;

	return $fragment;
} ## end sub insert_fragment

=head2 add_to_fragment($id, $files_ref)

Adds the list of files C<$files_ref> to the fragment named by C<$id>.

The fragment must already exist.

=cut

sub add_to_fragment {
	my ( $self, $id, $files_ref ) = @_;

	# Check parameters.
	unless ( _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::Installer->add_to_fragment'
		);
	}
	unless ( _ARRAY($files_ref) ) {
		PDWiX::Parameter->throw(
			parameter => 'files_ref',
			where     => '::Installer->add_to_fragment'
		);
	}

	if ( not exists $self->{fragments}->{$id} ) {
		PDWiX->throw("Fragment $id does not exist");
	}

	my @files = @{$files_ref};

	my $files_obj = File::List::Object->new()->add_files(@files);

	foreach my $key ( keys %{ $self->{fragments} } ) {
		$self->{fragments}->{$key}->check_duplicates($files_obj);
	}

	my $fragment = $self->{fragments}->{$id}->add_files(@files);

	return $fragment;
} ## end sub add_to_fragment


#####################################################################
# Serialization

=head2 as_string

Loads the file template passed in as the parameter, using this object, 
and returns it as a string.

	# Loads up the merge module template.
	$wxs = $self->as_string('Merge-Module.wxs.tt');

	# Loads up the main template
	$wxs = $self->as_string('Main.wxs.tt');

=cut

sub as_string {
	my $self = shift;
	my $template_file = shift;

	my $tt = Template->new( {
			INCLUDE_PATH => [ $self->dist_dir, $self->wix_dist_dir, ],
			EVAL_PERL    => 1,
		} )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => Template->error(),
	  );

	my $answer;
	my $vars = {
		dist => $self,
		directory_tree =>
		  Perl::Dist::WiX::DirectoryTree2->instance()->as_string(),
	};

	$tt->process( $template_file, $vars, \$answer )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => $tt->error() );
#<<<
	# Delete empty lines.
	## no critic(ProhibitComplexRegexes)
	$answer =~ s{(?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])
                            # Replace a linebreak, 
							# (within parentheses is = to \R for 5.8)
				 \s*?       # any whitespace we may be able to catch,
				 (?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])}        
				            # and a second linebreak
				{\r\n}msgx; # With one Windows linebreak.
#>>>

	# Combine it all
	return $answer;
} ## end sub as_string

1;

__END__

=pod

=head1 DIAGNOSTICS

See Perl::Dist::WiX's L<DIAGNOSTICS section|Perl::Dist::WiX/DIAGNOSTICS> for 
details, as all diagnostics from this module are listed there.

=head1 SUPPORT

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::Inno::Script|Perl::Dist::Inno::Script>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

Copyright 2008-2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
