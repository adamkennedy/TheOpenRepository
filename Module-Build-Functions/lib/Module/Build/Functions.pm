package Module::Build::Functions;

#<<<
use     strict;
use     5.005;
use     vars        qw( $VERSION @EXPORT $AUTOLOAD );
use     Carp        qw( croak                      );
use     Exporter    qw( import                     );
use     English     qw( -no_match_vars             );
use     Config;
use     AutoLoader;
require Module::Build;
#>>>

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
  get_builder bundler functions_self_bundler
);

# The equivalent of "use warnings" pre-5.006.
local $WARNING = 1;

$VERSION = '0.001_005';

# Module implementation here
my %args;
my $object      = undef;
my $class       = undef;
my $mb_required = 0;
my $autoload    = 1;

# Set defaults.
if ( $Module::Build::VERSION >= 0.28 ) {
	$args{create_packlist} = 1;
	$mb_required = 0.28;
}

my $installdir_used = 0;
my $object_created  = 0;

my %FLAGS = (
	'build_class' => 0.28,
	'create_makefile_pl' => 0.19,
	'dist_abstract' => 0.20,
	'dist_name' => 0.11,
	'dist_version' => 0.11,
	'dist_version_from' => 0.11,
	'installdirs' => 0.19,
	'license' => 0.11,
);

my %ALIASES = (
	'test_requires' => 'build_requires',
	'abstract' => 'dist_abstract',
	'name' => 'module_name',
	'author' => 'dist_author',
	'version' => 'dist_version',
	'version_from' => 'dist_version_from',
	'extra_compiler_flag' => 'extra_compiler_flags',
	'extra_linker_flag' => 'extra_linker_flags',	
	'include_dir' => 'include_dirs',
	'pl_file' => 'PL_files',
	'pl_files' => 'PL_files',
	'PL_file' => 'PL_files',
	'pm_file' => 'pm_files',
	'pod_file' => 'pod_files',
	'xs_file' => 'xs_files',
	'test_file' => 'test_files',
	'script_file' => 'script_files',
);

my %BOOLEAN = (
	'create_packlist' => 0.28,
	'create_readme' => 0.22,
	'dynamic_config' => 0.07,
	'use_tap_harness' => 0.30,
	'sign' => 0.16,
	'recursive_test_files' => 0.28,
);

my %ARRAY = (
	'autosplit' => 0.04,
	'add_to_cleanup' => 0.19,
	'include_dirs' => 0.24,
);

my %HASH = (
	'configure_requires' => [0.30, 1],
	'build_requires' => [0.07, 1],
	'conflicts' => [0.07, 1],
	'recommends' => [0.08, 1],
	'requires' => [0.07, 1],
	'get_options' => [0.26, 0],
	'meta_add' => [0.28, 0],
	'meta_merge' => [0.28, 0],
	'pm_files' => [0.19, 0],
	'pod_files' => [0.19, 0],
	'xs_files' => [0.19, 0],
	'install_path' => [0.19, 0],
);

my @AUTOLOADED = (keys %HASH, keys %ARRAY, keys %BOOLEAN, keys %ALIASES, keys %FLAGS);
my @EXPORTED = qw(all_from abstract_from author_from license_from perl_version perl_version_from install_script install_as_core install_as_cpan install_as_site install_as_vendor WriteAll auto_install auto_bundle bundle bundle_deps auto_bundle_deps can_use can_run can_cc requires_external_bin requires_external_cc get_file check_nmake interactive release_testing automated_testing win32 winlike author_context install_share 
);

# helper functions:

sub _any {
    my $f = shift;
    return 0 if ! @_;
    for (@_) {
		return 1 if $f->();
    }
    return 0;
}

# The autoload handles 5 types of "similar" routines, for 45 names.
sub AUTOLOAD {
	my $sub = $AUTOLOAD;

	if (_any {$sub eq $_} keys %ALIASES) {
		my $alias = $ALIASES{$sub};
		eval <<"END_OF_CODE";
sub $sub {
	$alias(\@_);
	return;
}
END_OF_CODE
		goto &$sub;
	}

	if (_any {$sub eq $_} keys %FLAGS) {
		my $version = $FLAGS{sub}[0]
		my $boolean1 = $FLAGS{sub}[1] ? '|| 1' : q{};
		my $boolean2 = $FLAGS{sub}[1] ? '!!' : q{};
		eval <<"END_OF_CODE";
sub $sub {	
	my \$argument = shift $boolean1;
	\$args{$sub} = $boolean2 \$argument;
	_mb_required($version);
	return;
}
END_OF_CODE
		goto &$sub;
	}
	
	if (_any {$sub eq $_} keys %FLAGS) {
		eval <<"END_OF_CODE";
sub $sub {	
	my \$argument = shift;
	\$args{$sub} = \$argument;
	_mb_required(\$FLAGS{$sub});
	return;
}
END_OF_CODE
		goto &$sub;
	}

	if (_any {$sub eq $_} keys %ARRAY) {
		_create_arrayref($sub);
		eval <<"END_OF_CODE";
sub $sub {
	my \$argument = shift;
	if ( 'ARRAY' eq ref \$argument ) {
		foreach my \$f ( \@{\$argument} ) {
			$sub(\$f);
		}
	}

	push \@{ \$args{$sub} }, \$argument;
	_mb_required(\$ARRAY{$sub});
	return;
}
END_OF_CODE
		goto &$sub;
	}

	if (_any {$sub eq $_} keys %HASH) {
		_create_hashref($sub);
		my $version = $HASH{sub}[0]
		my $default = $HASH{sub}[1] ? '|| 0' : q{};
		eval <<"END_OF_CODE";
sub $sub {
	my \$argument1 = shift;
	my \$argument2 = shift $default;
	if ( 'HASH' eq ref \$argument1 ) {
		my ( \$k, \$v );
		while ( ( \$k, \$v ) = each \%{\$argument1} ) {
			$sub( \$k, \$v );
		}
	}

	\$args{$sub}{\$argument1} = \$argument2;
	_mb_required($version);
	return;
}
END_OF_CODE
		goto &$sub;
	}

	if ( $autoload == 1 ) {
		$AutoLoader::AUTOLOAD = $sub;
		goto &AutoLoader::AUTOLOAD;
	} else {
		croak "$sub cannot be found";
	}
}

sub _mb_required {
	my $version = shift;
	if ( $version > $mb_required ) {
		$mb_required = $version;
	}
	return;
}

sub _installdir {
	return $Config{'sitelibexp'}   if ( $args{install_type} eq 'site' );
	return $Config{'privlibexp'}   if ( $args{install_type} eq 'perl' );
	return $Config{'vendorlibexp'} if ( $args{install_type} eq 'vendor' );
	croak 'Invalid install type';
}

sub _create_hashref {
	my $name = shift;
	unless ( exists $args{$name} ) {
		$args{$name} = {};
	}
	return;
}

sub _create_hashref_arrayref {
	my $name1 = shift;
	my $name2 = shift;
	unless ( exists $args{$name1}{$name2} ) {
		$args{$name1}{$name2} = [];
	}
	return;
}

sub _create_arrayref {
	my $name = shift;
	unless ( exists $args{$name} ) {
		$args{$name} = [];
	}
	return;
}

sub _slurp_file {
	my $name = shift;
	my $file_handle;
	
	if ($] >= 5.006) {
		require Symbol;
		$file_handle = Symbol::gensym();
		open $file_handle, "<$name" or croak $!;
	} else {
		open $file_handle, '<', $name or croak $!; 
	}
	
    local $/; # enable localized slurp mode
    my $content = <$file_handle>;
	
	close $file_handle;
	return $content;
}

# Module::Install syntax below.

sub all_from {
	my $file = shift;

	abstract_from($file);
	author_from($file);
	version_from($file);
	license_from($file);
	perl_version_from($file);
	return;
}

sub abstract_from {
	my $file = shift;

	require ExtUtils::MM_Unix;
	abstract(
		bless( { DISTNAME => $args{module_name} }, 'ExtUtils::MM_Unix' )
		  ->parse_abstract($file) );

	return;
}

sub author_from {
	croak 'author_from is not supported yet';
}

sub license_from {
	croak 'license_from is not supported yet';
}

sub perl_version {
	requires( 'perl', @_ );
	return;
}

sub perl_version_from {
	croak 'perl_version_from is not supported yet';
}

sub install_script {
	croak 'install_script not supported yet';
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

sub WriteAll { ## no critic(Capitalization)
	my $answer = create_build_script();
	return $answer;
}

# Module::Install::AutoInstall

sub auto_install {
	croak 'auto_install is deprecated';
}

# Module::Install::Bundle

sub auto_bundle {
	croak 'auto_bundle is not supported yet';
}

sub bundle {
	my ( $name, $version ) = @_;

	croak 'bundle is not supported yet';
}

sub bundle_deps {
	my ( $name, $version ) = @_;

	croak 'bundle_deps is not supported yet';
}

sub auto_bundle_deps {
	croak 'auto_bundle_deps is not supported yet';
}

# Module::Install::Can

sub can_use {
	croak 'can_use is not supported yet';
}

sub can_run {
	croak 'can_run is not supported yet';
}

sub can_cc {
	croak 'can_cc is not supported yet';
}

# Module::Install::External

sub requires_external_bin {
	croak 'requires_external_bin is not supported yet';
}

sub requires_external_cc {
	croak 'requires_external_cc is not supported yet';
}

# Module::Install::Fetch

sub get_file {
	croak 'get_file is not supported yet';
}

# Module::Install::Win32

sub check_nmake {
	croak 'check_nmake is not supported yet';
}

# Module::Install::With

sub interactive {
	croak 'interactive is not supported yet';
}

sub release_testing {
	return !!$ENV{RELEASE_TESTING};
}

sub automated_testing {
	return !!$ENV{AUTOMATED_TESTING};
}

sub win32 {
	return !!( $OSNAME eq 'MSWin32' );
}

sub winlike {
	return !!( $OSNAME eq 'MSWin32' or $OSNAME eq 'cygwin' );
}

sub author_context {
	croak 'author_context is not supported yet';
}

# Module::Install::Share

sub install_share {
	my $dir  = @_ ? pop   : 'share';
	my $type = @_ ? shift : 'dist';

	unless ( defined $type and $type eq 'module' or $type eq 'dist' ) {
		croak "Illegal or invalid share dir type '$type'";
	}
	unless ( defined $dir and -d $dir ) {
		croak 'Illegal or missing directory install_share param';
	}

	my $installation_path;

	if ( $type eq 'dist' ) {
		croak 'Too many parameters to install_share' if @_;

		my $dist = $args{'dist_name'};

		$installation_path =
		  catdir( _installdir(), qw(auto share module), $dist );

	} else {
		my $module = $args{'module_name'};

		unless ( defined $module ) {
			croak "Missing or invalid module name '$module'";
		}

		$module =~ s/::/-/g;
		$installation_path =
		  catdir( _installdir(), qw(auto share module), $module );
	}

	install_path( $dir, $installation_path );

	# 99% of the time we don't want to index a shared dir
	no_index($dir);
	return;
} ## end sub install_share

# Module::Build syntax

sub _af_hashref {
	my $feature = shift;
	unless ( exists $args{auto_features} ) {
		$args{auto_features} = {};
	}
	unless ( exists $args{auto_features}{$feature} ) {
		$args{auto_features}{$feature} = {};
		$args{auto_features}{$feature}{requires} = {};
	}
	return;
}

sub auto_features {
	my $feature = shift;
	my $type    = shift;
	my $param1  = shift;
	my $param2  = shift;
	_af_hashref($type);

	if ( 'description' eq $type ) {
		$args{auto_features}{$feature}{description} = $param1;
	} elsif ( 'requires' eq $type ) {
		$args{auto_features}{$feature}{requires}{$param1} = $param2;
	} else {
		croak "Invalid type $type for auto_features";
	}
	_mb_required(0.26);
	return;
} ## end sub auto_features


sub dist_author {
	#TODO: Arrayref handling.
	my ($author) = shift;
	$args{'dist_author'} = $author;
	_mb_required(0.20);
	return;
}

sub extra_compiler_flags {
	my $flag = shift;
	if ( 'ARRAY' eq ref $flag ) {
		foreach my $f ( @{$flag} ) {
			extra_compiler_flags($f);
		}
	}

	if ( $flag =~ m{\s} ) {
		my @flags = split m{\s+}, $flag;
		foreach my $f (@flags) {
			extra_compiler_flags($f);
		}
	} else {
		_create_arrayref('extra_compiler_flags');
		push @{ $args{'extra_compiler_flags'} }, $flag;
	}
	_mb_required(0.19);
	return;
} ## end sub extra_compiler_flags

sub extra_linker_flags {
	my $flag = shift;
	if ( 'ARRAY' eq ref $flag ) {
		foreach my $f ( @{$flag} ) {
			extra_linker_flags($f);
		}
	}

	if ( $flag =~ m{\s} ) {
		my @flags = split m{\s+}, $flag;
		foreach my $f (@flags) {
			extra_linker_flags($f);
		}
	} else {
		_create_arrayref('extra_linker_flags');
		push @{ $args{'extra_linker_flags'} }, $flag;
	}
	_mb_required(0.19);
	return;
} ## end sub extra_linker_flags

sub module_name {
	my ($name) = shift;
	$args{'module_name'} = $name;
	unless ( exists $args{'dist_name'} ) {
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
	_create_hashref_arrayref( 'no_index', $type );
	push @{ $args{'no_index'}{$type} }, $name;
	_mb_required(0.28);
	return;
} ## end sub no_index

sub PL_files { ## no critic(Capitalization)
	my $pl_file = shift;
	my $pm_file = shift || [];
	if ( 'HASH' eq ref $pl_file ) {
		my ( $k, $v );
		while ( ( $k, $v ) = each %{$pl_file} ) {
			PL_files( $k, $v );
		}
	}

	_create_hashref('PL_files');
	$args{PL_files}{$pl_file} = $pm_file;
	_mb_required(0.06);
	return;
} ## end sub PL_files

sub script_files {
	my $file = shift;
	if ( 'ARRAY' eq ref $file ) {
		foreach my $f ( @{$file} ) {
			script_files($f);
		}
	}

	if ( -d $file ) {
		if ( exists $args{'script_files'} ) {
			if ( 'ARRAY' eq ref $args{'script_files'} ) {
				croak
				  "cannot add directory $file to a list of script_files";
			} else {
				croak
"attempt to overwrite string script_files with $file failed";
			}
		} else {
			$args{'script_files'} = $file;
		}
	} else {
		_create_arrayref('script_files');
		push @{ $args{'script_files'} }, $file;
	}
	_mb_required(0.18);
	return;
} ## end sub script_files

sub test_files {
	my $file = shift;
	if ( 'ARRAY' eq ref $file ) {
		foreach my $f ( @{$file} ) {
			test_files($f);
		}
	}

	if ( $file =~ /[*?]/ ) {
		if ( exists $args{'test_files'} ) {
			if ( 'ARRAY' eq ref $args{'test_files'} ) {
				croak 'cannot add a glob to a list of test_files';
			} else {
				croak 'attempt to overwrite string test_files failed';
			}
		} else {
			$args{'test_files'} = $file;
		}
	} else {
		_create_arrayref('test_files');
		push @{ $args{'test_files'} }, $file;
	}
	_mb_required(0.23);
	return;
} ## end sub test_files

sub tap_harness_args {
	my ($thargs) = shift;
	$args{'tap_harness_args'} = $thargs;
	use_tap_harness(1);
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
	unless ( defined $object ) {
		if ( defined $class ) {
			$object = $class->new(%args);
		} else {
			$object = Module::Build->new(%args);
		}
	}
	return $object;
}

sub functions_self_bundler {
	my $code = <<'END_OF_CODE';
sub ACTION_distmeta {
	my $self = shift;
	require Module::Build::Functions;
	Module::Build::Functions::bundler();
    $self->SUPER::ACTION_distmeta();
}
END_OF_CODE

	subclass(
		class => 'ModuleBuildFunctions::SelfBundler',
		code => $code
	);

	return;
}

1;                                     # Magic true value required at end of module

__END__

sub bundler {
	require File::Slurp;
	require File::Spec;
	require File::Path;
	File::Slurp->import(qw(read_file write_file));
	File::Path->import(qw(mkpath));
	my ( $fulldir, $file, $text, $outfile );
  DIRLOOP:

	foreach my $dir ( $Config{'sitelibexp'}, $Config{'vendorlibexp'},
		$Config{'privlibexp'} )
	{
		$fulldir = File::Spec->catdir( $dir, qw(Module Build) );
		$file = File::Spec->catfile( $fulldir, 'Functions.pm' );
		if ( -f $file ) {
			$text = read_file($file);
			$text =~ s/package [ ] Module/package inc::Module/msx;
			$text =~ s/use [ ]* AutoLoader;//msx;
			$text =~ s/my [ ] \$autoload [ ]* = [ ] 1/my \$autoload = 0/msx;
			$text =~ s/__END__.*/\n/ms;
			$text =~ s/__END__.*/\n/msx;			
			$fulldir = File::Spec->catdir(qw(inc Module Build));
			$outfile = File::Spec->catfile( $fulldir, 'Functions.pm' );
			mkpath( $fulldir, 0, 0644 );
			print "Writing $outfile\n";
			write_file( $outfile, $text );
			last DIRLOOP;
		} ## end if ( -f $file )
	} ## end foreach my $dir ( $Config{'sitelibexp'...
	return;
} ## end sub bundler
