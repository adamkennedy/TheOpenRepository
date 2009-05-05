package inc::Module::Build::Functions;

use strict;
use Carp     qw(croak );
use Exporter qw(import);
use Config;
use Module::Build;


use vars     qw( $VERSION @EXPORT $AUTOLOAD );
@EXPORT = qw(
  name all_from abstract abstract_from author author_from version 
  version_from license license_from perl_version perl_version_from 
  recommends requires test_requires configure_requires install_script
  no_index installdirs install_as_core install_as_cpan install_as_site
  install_as_vendor WriteAll auto_install auto_bundle bundle bundle_deps
  auto_bundle_deps can_use can_run can_cc requires_external_bin 
  requires_external_cc get_file check_nmake interactive release_testing 
  automated_testing win32 winlike author_context install_share
  add_to_cleanup auto_features autosplit build_class build_requires 
  create_packlist c_source conflicts create_makefile_pl create_readme 
  dist_abstract dist_author dist_name dist_version dist_version_from 
  dynamic_config extra_compiler_flags extra_linker_flags get_options 
  include_dirs install_path meta_add meta_merge module_name 
  PL_files pm_files pod_files recommends recursive_test_files requires 
  script_files sign test_files use_tap_harness tap_harness_args xs_files 
  subclass create_build_script include_dir no_index xs_file PL_file pm_file
  get_builder bundler
);

# Module implementation here
my %args = { };
my $object = undef;
my $class = undef;
my $mb_required = 0;
my $autoload = 0;

# Set defaults.
if ($Module::Build::VERSION >= 0.28) {
	$args{create_packlist} = 1;
	$mb_required = 0.28;
}

my $installdir_used = 0;
my $object_created = 0;

# helper functions:

sub AUTOLOAD {
	my $sub = $AUTOLOAD;
    if ($autoload == 1) {
		$AutoLoader::AUTOLOAD = $sub;
		goto &AutoLoader::AUTOLOAD;
	} else {
		croak "$sub cannot be found";
	}
}

sub _mb_required {
	my $version = shift;
	if ($version > $mb_required) {
		$mb_required = $version;
	}
}

sub _installdir {
	return $Config{'sitelibexp'} if ($args{install_type} eq 'site');
	return $Config{'privlibexp'} if ($args{install_type} eq 'perl');
	return $Config{'vendorlibexp'} if ($args{install_type} eq 'vendor');
	croak 'Invalid install type';
	return undef;
}

sub _create_hashref {
	my $name = shift;
	unless (exists $args{$name}) {
		$args{$name} = {};
	}
	return;
}

sub _create_hashref_arrayref {
	my $name1 = shift;
	my $name2 = shift;
	unless (exists $args{$name1}{$name2}) {
		$args{$name1}{$name2} = [];
	}
	return;
}

sub _create_arrayref {
	my $name = shift;
	unless (exists $args{$name}) {
		$args{$name} = [];
	}
	return;
}

# Module::Install syntax below.

sub name {
	module_name(@_);
	return;	
}

sub all_from {
	my $file = shift;

	abstract_from($file);
	author_from($file);
	version_from($file);
	license_from($file);
	perl_version_from($file);
	return;
}

sub abstract {
	dist_abstract(@_);
	return;
}

sub abstract_from {
	my $file = shift;
	
	require ExtUtils::MM_Unix;
	abstract(
		bless(
			{ DISTNAME => $args{module_name} },
			'ExtUtils::MM_Unix'
		)->parse_abstract($file)
	 );

	return;
}

sub author {
	dist_author(@_);
	return;
}

sub author_from {
	croak 'author_from is not supported yet';
	return;
}

sub version {
	dist_version(@_);
	return;
}

sub version_from {
	dist_version_from(@_);
	return;
}

# license

sub license_from {
	croak 'license_from is not supported yet';
	return;
}

sub perl_version {
	croak 'perl_version is not supported yet';
	return;
}

sub perl_version_from {
	croak 'perl_version_from is not supported yet';
	return;
}

sub test_requires {
	build_requires(@_);
	return;
}

sub configure_requires { # 0.2808_01
	my $module = shift;
	my $version = shift || 0;
	
	_create_hashref('configure_requires');
	$args{configure_requires}{$module} = $version;
	_mb_required(0.30);
	return;
}

sub install_script {
	croak 'install_script not supported yet';
	return;
}

sub install_as_core {
	return installdirs('perl');
}

sub install_as_cpan {
	return installdirs('site'); 
}

sub install_as_site {
	return installdirs('site');
}

sub install_as_vendor {
	return installdirs('vendor');
}

sub WriteAll {
	my $answer = create_build_script();
	return $answer;
}

# Module::Install::AutoInstall

sub auto_install {
	croak 'auto_install is deprecated';
	return;
}

# Module::Install::Bundle

sub auto_bundle {
	croak 'auto_bundle is not supported yet';
	return;
}

sub bundle {
	my ($name, $version) = @_;
	
	croak 'bundle is not supported yet';
	return;
}

sub bundle_deps {
	my ($name, $version) = @_;

	croak 'bundle_deps is not supported yet';
	return;
}

sub auto_bundle_deps {
	croak 'auto_bundle_deps is not supported yet';
	return;
}

# Module::Install::Can

sub can_use {
	croak 'can_use is not supported yet';
	return;
}

sub can_run {
	croak 'can_run is not supported yet';
	return;
}

sub can_cc {
	croak 'can_cc is not supported yet';
	return;
}

# Module::Install::External

sub requires_external_bin {
	croak 'requires_external_bin is not supported yet';
	return;
}

sub requires_external_cc {
	croak 'requires_external_cc is not supported yet';
	return;
}

# Module::Install::Fetch

sub get_file {
	croak 'get_file is not supported yet';
	return;
}

# Module::Install::Win32

sub check_nmake {
	croak 'check_nmake is not supported yet';
	return;
}

# Module::Install::With

sub interactive {
	croak 'interactive is not supported yet';
	return;
}

sub release_testing {
	return !! $ENV{RELEASE_TESTING};
}

sub automated_testing {
	return !! $ENV{AUTOMATED_TESTING};
}

sub win32 {
	return !! ($^O eq 'MSWin32');
}

sub winlike {
	return !! ($^O eq 'MSWin32' or $^O eq 'cygwin');
}

sub author_context {
	croak 'author_context is not supported yet';
	return;
}

# Module::Install::Share

sub install_share {
	my $dir  = @_ ? pop   : 'share';
	my $type = @_ ? shift : 'dist';

	unless ( defined $type and $type eq 'module' or $type eq 'dist' ) {
		croak "Illegal or invalid share dir type '$type'";
	}
	unless ( defined $dir and -d $dir ) {
		croak "Illegal or missing directory install_share param";
	}
	
	my $installation_path;
	
	if ( $type eq 'dist' ) {
		croak "Too many parameters to install_share" if @_;

		my $dist = $args{'dist_name'};
		
		$installation_path = catdir( _installdir() , qw(auto share module), $dist);
		
	} else {
		my $module = shift || $args{'module_name'};
		
		unless ( defined $module ) {
			die "Missing or invalid module name '$module'";
		}

		$module =~ s/::/-/g;
		$installation_path = catdir( _installdir() , qw(auto share module), $module);
	}

	install_path($dir, $installation_path);

	# 99% of the time we don't want to index a shared dir
	no_index( $dir );
	return;
}
	
# Module::Build syntax

# SAME: license recommends requires no_index

sub add_to_cleanup {
	my $filespec = shift;
	if ('ARRAY' eq ref $filespec) {
		foreach my $f (@{$filespec}) {
			add_to_cleanup($f);
		}
	}

	_create_arrayref('add_to_cleanup');
	push @{$args{add_to_cleanup}}, $filespec;
	_mb_required(0.19);
	return;
}

sub auto_features { # 0.26
	croak 'auto_features is not supported yet';
	return;
}

sub autosplit {
	my $file = shift;
	if ('ARRAY' eq ref $file) {
		foreach my $f (@{$file}) {
			autosplit($f);
		}
	}

	_create_arrayref('autosplit');
	push @{$args{autosplit}}, $file;
	_mb_required(0.04);
	return;
}

sub build_class { # 0.28
	my $class = shift;	
	$args{build_class} = $class;
	_mb_required(0.04);
	return;
}

# this is test_requires in Module::Install.
sub build_requires {
	my $module = shift;
	my $version = shift || 0;
	if ('HASH' eq ref $module) {
		my ($k, $v);
		while (($k, $v) = each %{$module}) {
			build_requires($k, $v);
		}
	}
	
	_create_hashref('build_requires');
	$args{build_requires}{$module} = $version;
	_mb_required(0.07);
	return;
}

sub create_packlist {
	my $boolean = shift;
	$args{create_packlist} = !! $boolean;
	_mb_required(0.28);
	return;
}

sub c_source {
	my $dir = shift;	
	$args{c_source} = $dir;
	_mb_required(0.04);
	return;
}

sub conflicts {
	my $module = shift;
	my $version = shift || 0;
	if ('HASH' eq ref $module) {
		my ($k, $v);
		while (($k, $v) = each %{$module}) {
			conflicts($k, $v);
		}
	}
	
	_create_hashref('conflicts');
	$args{conflicts}{$module} = $version;
	_mb_required(0.07);
	return;
}

sub create_makefile_pl {
	my $makefile_type = shift;
	$args{'create_makefile_pl'} = $makefile_type;
	_mb_required(0.19);
	return;
}

sub create_readme {
	my $boolean = shift;
	$args{create_readme} = !! $boolean;
	_mb_required(0.22);
	return;
}

sub dist_abstract {
	my $abstract = shift;
	$args{dist_abstract} = $abstract;
	_mb_required(0.20);
	return;
}

sub dist_author {
	my ($author) = shift;
	$args{'dist_author'} = $author;
	_mb_required(0.20);
	return;
}

sub dist_name {
	my ($version) = shift;
	$args{'dist_name'} = $version;
	_mb_required(0.11);
	return;
}

sub dist_version {
	my ($version) = shift;
	$args{'dist_version'} = $version;
	_mb_required(0.11);
	return;
}

sub dist_version_from {
	my ($file) = shift;
	$args{'dist_version_from'} = $file;
	_mb_required(0.11);
	return;
}

sub dynamic_config {
	my $boolean = shift;
	$args{dynamic_config} = !! $boolean;
	_mb_required(0.07);
	return;
}

sub extra_compiler_flags { # 0.19
	croak 'extra_compiler_flags is not supported yet';
	return;
}

sub extra_linker_flags { # 0.19
	croak 'extra_linker_flags is not supported yet';
	return;
}

sub get_options { # 0.26
	croak 'get_options is not supported yet';
	return;
}

# Alias for include_dirs
sub include_dir {
	include_dirs(@_);
	return;
}

sub include_dirs {
	my $dir = shift;
	if ('ARRAY' eq ref $dir) {
		foreach my $f (@{$dir}) {
			include_dirs($f);
		}
	}
	
	_create_arrayref('include_dirs');
	push @{$args{include_dirs}}, $dir;
	_mb_required(0.24);
	return;
}

sub install_path { 
	my $type = shift;
	my $dir = shift;
	if ('HASH' eq ref $type) {
		my ($k, $v);
		while (($k, $v) = each %{$type}) {
			install_path($k, $v);
		}
	}

	_create_hashref('install_path');
	$args{install_path}{$type} = $dir;
	_mb_required(0.19);
	return;
}

sub installdirs { 
	my ($type) = shift;
	$args{'installdirs'} = $type;
	_mb_required(0.19);
	return;
}

sub license {
	my ($license) = shift;
	$args{'license'} = $license;
	_mb_required(0.11);
	return;
}

sub meta_add {
	my $option = shift;
	my $value = shift;
	if ('HASH' eq ref $option) {
		my ($k, $v);
		while (($k, $v) = each %{$option}) {
			meta_add($k, $v);
		}
	}
	
	_create_hashref('meta_add');
	$args{meta_add}{$option} = $value;
	_mb_required(0.28);
	return;
}

sub meta_merge {
	my $option = shift;
	my $value = shift;
	if ('HASH' eq ref $option) {
		my ($k, $v);
		while (($k, $v) = each %{$option}) {
			meta_merge($k, $v);
		}
	}

	_create_hashref('meta_merge');
	$args{meta_merge}{$option} = $value;
	_mb_required(0.28);
	return;
}

sub module_name {
	my ($name) = shift;
	$args{'module_name'} = $name;
	unless (exists $args{'dist_name'}) {
		my $dist_name = $name;
		$dist_name =~ s/::/-/g;
		dist_name($dist_name);
	}
	_mb_required(0.03);
	return;
}

sub no_index {
	my $name = pop;
    my $type = shift || 'directory';
	# TODO: compatibility code.
	
	_create_hashref('no_index');
	_create_hashref_arrayref('no_index', $type);
	push @{$args{'no_index'}{$type}}, $name;
	_mb_required(0.28);
	return;
}

# Alias for PL_files.
sub PL_file {
	PL_files(@_);
	return;
}

sub PL_files {
	my $PL_file = shift;
	my $pm_file = shift || [];
	if ('HASH' eq ref $PL_file) {
		my ($k, $v);
		while (($k, $v) = each %{$PL_file}) {
			PL_files($k, $v);
		}
	}
	
	_create_hashref('PL_files');
	$args{PL_files}{$PL_file} = $pm_file;
	_mb_required(0.06);
	return;
}

# Alias for pm_files.
sub pm_file {
	pm_files(@_);
	return;
}

sub pm_files {
	my $pm_file = shift;
	my $location = shift;
	if ('HASH' eq ref $pm_file) {
		my ($k, $v);
		while (($k, $v) = each %{$pm_file}) {
			pm_files($k, $v);
		}
	}

	_create_hashref('pm_files');
	$args{pm_files}{$pm_file} = $location;
	_mb_required(0.19);
	return;
}

# Alias for pod_files.
sub pod_file {
	pod_files(@_);
	return;
}

sub pod_files { 
	my $pod_file = shift;
	my $location = shift;
	if ('HASH' eq ref $pod_file) {
		my ($k, $v);
		while (($k, $v) = each %{$pod_file}) {
			pod_files($k, $v);
		}
	}

	_create_hashref('pod_files');
	$args{pod_files}{$pod_file} = $location;
	_mb_required(0.19);
	return;
}

sub recommends { 
	my $module = shift;
	my $version = shift || 0;
	if ('HASH' eq ref $module) {
		my ($k, $v);
		while (($k, $v) = each %{$module}) {
			recommends($k, $v);
		}
	}
	
	_create_hashref('recommends');
	$args{recommends}{$module} = $version;
	_mb_required(0.08);
	return;
}

sub recursive_test_files {
	my $boolean = shift;
	$args{recursive_test_files} = !! $boolean;
	_mb_required(0.28);
	return;
}

sub requires { 
	my $module = shift;
	my $version = shift || 0;
	if ('HASH' eq ref $module) {
		my ($k, $v);
		while (($k, $v) = each %{$module}) {
			requires($k, $v);
		}
	}
	
	_create_hashref('requires');
	$args{requires}{$module} = $version;
	_mb_required(0.07);
	return;
}

sub script_file {
	script_files(@_);
	return;
}

sub script_files {
	my $file = shift;
	if ('ARRAY' eq ref $file) {
		foreach my $f (@{$file}) {
			script_files($f);
		}
	}
		
	if (-d $file) {
		if (exists $args{'script_files'}) {
			if ('ARRAY' eq ref $args{'script_files'}) {
				croak "cannot add directory $file to a list of script_files";
			} else {
				croak "attempt to overwrite string script_files with $file failed";
			}
		} else {
			$args{'script_files'} = $file;
		}
	} else {
		_create_arrayref('script_files');
		push @{$args{'script_files'}}, $file;
	}
	_mb_required(0.18);
	return;
}

sub sign {
	my $boolean = shift;
	$args{sign} = !! $boolean;
	_mb_required(0.16);
	return;
}

sub test_file {
	test_files(@_);
	return;
}
sub test_files {
	my $file = shift;
	if ('ARRAY' eq ref $file) {
		foreach my $f (@{$file}) {
			test_files($f);
		}
	}

	if ($file =~ /[*?]/) {
		if (exists $args{'test_files'}) {
			if ('ARRAY' eq ref $args{'test_files'}) {
				croak 'cannot add a glob to a list of test_files';
			} else {
				croak 'attempt to overwrite string test_files failed';
			}
		} else {
			$args{'test_files'} = $file;
		}
	} else {
		_create_arrayref('test_files');
		push @{$args{'test_files'}}, $file;
	}
	_mb_required(0.23);
	return;
}

sub use_tap_harness {
	my $boolean = shift || 1;
	$args{use_tap_harness} = !! $boolean;
	_mb_required(0.30);
	return;
}

sub tap_harness_args {
	my ($thargs) = shift;
	$args{'tap_harness_args'} = $thargs;
	use_tap_harness(1);
	return;
}

# Alias for xs_files.
sub xs_file {
	xs_files(@_);
	return;
}

sub xs_files {
	my $xs_file = shift;
	my $location = shift;
	if ('HASH' eq ref $xs_file) {
		my ($k, $v);
		while (($k, $v) = each %{$xs_file}) {
			pm_files($k, $v);
		}
	}
	
	_create_hashref('xs_files');
	$args{xs_files}{$xs_file} = $location;
	_mb_required(0.19);
	return;
}
	
sub subclass {
	$class = Module::Build->subclass(@_);
	return;
}

sub create_build_script {
	get_builder();
	$object->create_build_script;
	return $object;
}

# Required to get a builder for later use.
sub get_builder {
	unless (defined $object) {
		if (defined $class) {
			$object = $class->new(%args);
		} else {
			$object = Module::Build->new(%args);
		}
	}
	return $object;
}

1; # Magic true value required at end of module

__END__

sub bundler {
	require File::Slurp;
	require File::Spec;
	require File::Path;
	File::Slurp->import(qw(read_file write_file));
	File::Path->import(qw(mkpath));
	my ($fulldir, $file, $text, $outfile);
  DIRLOOP:
	foreach my $dir ( $Config{'sitelibexp'}, $Config{'vendorlibexp'}, $Config{'privlibexp'} ) {
		$fulldir = File::Spec->catdir($dir, qw(Module Build));
		$file = File::Spec->catfile($fulldir, 'Functions.pm');
		if (-f $file) {
			$text = read_file($file);
			$text =~ s/package [ ] Module/package inc::Module/msx;
			$text =~ s/use [ ] AutoLoader;//msx;
			$text =~ s/my [ ] \$autoload [ ] = [ ] 1/my \$autoload = 0/msx;
			$fulldir = File::Spec->catdir(qw(inc Module Build));
			$outfile = File::Spec->catfile($fulldir, 'Functions.pm');
			mkpath($fulldir, 0, 0644);
			print "Writing $outfile\n";
			write_file($outfile, $text);
			last DIRLOOP;
		}
	}
	return;
}