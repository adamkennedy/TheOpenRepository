package Perl::Dist::WiX::Role::NonURLAsset;

# Convenience role for Perl::Dist::WiX assets

use 5.008001;
use Moose::Role;
use File::Spec::Functions qw( rel2abs catdir catfile );
use MooseX::Types::Moose qw( Str );
use Params::Util qw( _INSTANCE );
use English qw( -no_match_vars );
require File::List::Object;
require File::ShareDir;
require File::Spec::Unix;
require Perl::Dist::WiX::Exceptions;
require URI;
require URI::file;

our $VERSION = '1.100_001';
$VERSION =~ s/_//sm;

has parent => (
	is       => 'ro',
	isa      => 'Perl::Dist::WiX',
	reader   => '_get_parent',
	weak_ref => 1,
	handles  => {
		'_get_image_dir',   => 'image_dir',
		'_get_download_dir' => 'download_dir',
		'_get_output_dir'   => 'output_dir',
		'_get_modules_dir'  => 'modules_dir',
		'_get_license_dir'  => 'license_dir',
		'_get_build_dir'    => 'build_dir',
		'_get_dist_dir'     => 'dist_dir',
		'_get_cpan'         => 'cpan',
		'_get_bin_perl'     => 'bin_perl',
		'_get_wix_dist_dir' => 'wix_dist_dir',
		'_get_icons'        => '_icons',
		'_get_pv_human'     => 'perl_version_human',
		'_module_fix'       => '_module_fix',
		'_trace_line'       => 'trace_line',
		'_mirror'           => '_mirror',
		'_run3'             => '_run3',
		'_filters'          => '_filters',
		'_add_icon'         => 'add_icon',
		'_dll_to_a'         => '_dll_to_a',
		'_copy'             => '_copy',
		'_extract'          => '_extract',
		'_extract_filemap'  => '_extract_filemap',
		'_insert_fragment'  => 'insert_fragment',
		'_pushd'            => '_pushd',
		'_perl'             => '_perl',
		'_patch_file'       => 'patch_file',
		'_build'            => '_build',
		'_make'             => '_make',
		'_add_to_distributions_installed' =>
		  '_add_to_distributions_installed',
	},
	required => 1,
);

# An asset knows how to install itself.
requires 'install';

sub cpan {

	WiX3::Exception::Unimplemented->throw(
		'Perl::Dist::WiX::Role::Asset->cpan');

	return;
}

sub _search_packlist {
	my ( $self, $module ) = @_;

	# We don't use the error until later, if needed.
	my $error = <<"EOF";
No .packlist found for $module.

Please set packlist => 0 when calling install_distribution or 
install_module for this module.  If this is in an install_modules 
list, please take it out of the list, creating two lists if need 
be, and create an install_module call for this module with 
packlist => 0.
EOF
	chomp $error;

	my $image_dir   = $self->_get_image_dir();
	my @module_dirs = split /::/ms, $module;
	my @dirs        = (
		catdir( $image_dir, qw{perl vendor lib auto}, @module_dirs ),
		catdir( $image_dir, qw{perl site   lib auto}, @module_dirs ),
		catdir( $image_dir, qw{perl        lib auto}, @module_dirs ),
	);

	my $packlist;
  DIR:
	foreach my $dir (@dirs) {
		$packlist = catfile( $dir, '.packlist' );
		last DIR if -r $packlist;
	}

	my $filelist;
	if ( -r $packlist ) {
		$filelist =
		  File::List::Object->new()->load_file($packlist)
		  ->add_file($packlist);
	} else {

		my $output = catfile( $self->_get_output_dir, 'debug.out' );

		# Trying to use the output to make an array.
		$self->_trace_line( 3,
			"Attempting to use debug.out file to make filelist\n" );

		my $fh = IO::File->new( $output, 'r' );
		if ( not defined $fh ) {
			PDWiX->throw("Error reading output file $output: $OS_ERROR");
		}
		my @output_list = <$fh>;
		$fh->close();

		my @files_list =
		  map { ## no critic 'ProhibitComplexMappings'
			my $t = $_;
			chomp $t;
			( $t =~ / \A Installing [ ] (.*) \z /msx ) ? ($1) : ();
		  } @output_list;

		if ( $#files_list == 0 ) {
			PDWiX->throw($error);
		} else {
			$self->_trace_line( 4, "Adding files:\n" );
			$self->_trace_line( 4, q{  } . join "\n  ", @files_list );
			$filelist = File::List::Object->new()->load_array(@files_list);
		}
	} ## end else [ if ( -r $packlist ) ]

	return $filelist->filter( $self->_filters );
} ## end sub _search_packlist

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Role::NonURLAsset - Role for assets that do not require URL's.

=head1 SYNOPSIS

	# Since this is a role, it is composed into classes that use it.
  
=head1 DESCRIPTION

B<Perl::Dist::WiX::Role::NonURLAsset> is a role that provides methods,
attributes, and error checking for assets to be installed in a 
L<Perl::Dist::WiX>-based Perl distribution.

=head1 ATTRIBUTES

Attributes of this role also become parameters to the new() constructor for 
classes that use this role.

=head2 parent

This is the L<Perl::Dist::WiX> object that uses an asset object that uses 
this role.  The Perl::Dist::WiX object handles a number of private methods 
for the asset object.

It is required, and has no default, so an error will be thrown if it is not 
given.

=head1 METHODS

=head2 cpan

The C<cpan> routine is a stub, as it is not used, and will throw an error.

It will be removed in the future.

=head2 install

This role requires that classes that use it implement an C<install> method
that installs the asset.

It does not provide the method itself.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
