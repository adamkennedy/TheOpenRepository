package inc::Module::Build::Functions;

#<<<
use     strict;
use     5.005;
use     vars        qw( $VERSION @EXPORT $AUTOLOAD );
use     Carp        qw( croak                      );
use     English     qw( -no_match_vars             );
use     Exporter    qw( import                     );
use     Config;

require Module::Build;
#>>>

# The equivalent of "use warnings" pre-5.006.
local $WARNING = 1;
my %args;
my $object         = undef;
my $class          = undef;
my $mb_required    = 0;
my $autoload =       0;
my $object_created = 0;
my (%FLAGS, %ALIASES, %ARRAY, %HASH, @AUTOLOADED, @DEFINED);

BEGIN {
	$VERSION = '0.001_006';

	# Module implementation here

	# Set defaults.
	if ( $Module::Build::VERSION >= 0.28 ) {
		$args{create_packlist} = 1;
		$mb_required = 0.28;
	}

	%FLAGS = (
		'build_class'          => [ 0.28, 0 ],
		'create_makefile_pl'   => [ 0.19, 0 ],
		'dist_abstract'        => [ 0.20, 0 ],
		'dist_name'            => [ 0.11, 0 ],
		'dist_version'         => [ 0.11, 0 ],
		'dist_version_from'    => [ 0.11, 0 ],
		'installdirs'          => [ 0.19, 0 ],
		'license'              => [ 0.11, 0 ],
		'create_packlist'      => [ 0.28, 1 ],
		'create_readme'        => [ 0.22, 1 ],
		'create_license'       => [ 0.31, 1 ],
		'dynamic_config'       => [ 0.07, 1 ],
		'use_tap_harness'      => [ 0.30, 1 ],
		'sign'                 => [ 0.16, 1 ],
		'recursive_test_files' => [ 0.28, 1 ],
	);

	%ALIASES = (
		'test_requires'       => 'build_requires',
		'abstract'            => 'dist_abstract',
		'name'                => 'module_name',
		'author'              => 'dist_author',
		'version'             => 'dist_version',
		'version_from'        => 'dist_version_from',
		'extra_compiler_flag' => 'extra_compiler_flags',
		'extra_linker_flag'   => 'extra_linker_flags',
		'include_dir'         => 'include_dirs',
		'pl_file'             => 'PL_files',
		'pl_files'            => 'PL_files',
		'PL_file'             => 'PL_files',
		'pm_file'             => 'pm_files',
		'pod_file'            => 'pod_files',
		'xs_file'             => 'xs_files',
		'test_file'           => 'test_files',
		'script_file'         => 'script_files',
	);

	%ARRAY = (
		'autosplit'      => 0.04,
		'add_to_cleanup' => 0.19,
		'include_dirs'   => 0.24,
		'dist_author'    => 0.20,
	);

	%HASH = (
		'configure_requires' => [ 0.30, 1 ],
		'build_requires'     => [ 0.07, 1 ],
		'conflicts'          => [ 0.07, 1 ],
		'recommends'         => [ 0.08, 1 ],
		'requires'           => [ 0.07, 1 ],
		'get_options'        => [ 0.26, 0 ],
		'meta_add'           => [ 0.28, 0 ],
		'meta_merge'         => [ 0.28, 0 ],
		'pm_files'           => [ 0.19, 0 ],
		'pod_files'          => [ 0.19, 0 ],
		'xs_files'           => [ 0.19, 0 ],
		'install_path'       => [ 0.19, 0 ],
	);

	@AUTOLOADED = ( keys %HASH, keys %ARRAY, keys %ALIASES, keys %FLAGS );
	@DEFINED = qw(
	  all_from abstract_from author_from license_from perl_version
	  perl_version_from install_script install_as_core install_as_cpan
	  install_as_site install_as_vendor WriteAll auto_install auto_bundle
	  bundle bundle_deps auto_bundle_deps can_use can_run can_cc
	  requires_external_bin requires_external_cc get_file check_nmake
	  interactive release_testing automated_testing win32 winlike
	  author_context install_share auto_features extra_compiler_flags
	  extra_linker_flags module_name no_index PL_files script_files test_files
	  tap_harness_args subclass create_build_script get_builder
	  functions_self_bundler bundler
	);
	@EXPORT = ( @DEFINED, @AUTOLOADED );
	# print join ' ', 'Exported:', @EXPORT, "\n";
}

# The autoload handles 4 types of "similar" routines, for 45 names.
sub AUTOLOAD {
	my $full_sub = $AUTOLOAD;
	my ($sub) = $AUTOLOAD =~ m{\A.*::([^:]*)\z};

	if ( exists $ALIASES{$sub} ) {
		my $alias = $ALIASES{$sub};
		eval <<"END_OF_CODE";
sub $full_sub {
	$alias(\@_);
	return;
}
END_OF_CODE
		goto &$full_sub;
	}

	if ( exists $FLAGS{$sub} ) {
		my $version  = $FLAGS{$sub}[0];
		my $boolean1 = $FLAGS{$sub}[1] ? '|| 1' : q{};
		my $boolean2 = $FLAGS{$sub}[1] ? q{!!} : q{};
		eval <<"END_OF_CODE";
sub $full_sub {	
	my \$argument = shift $boolean1;
	\$args{$sub} = $boolean2 \$argument;
	_mb_required($version);
	return;
}
END_OF_CODE
		goto &$full_sub;
	} ## end if ( exists $FLAGS{$sub...

	if ( exists $ARRAY{$sub} ) {
#		_create_arrayref($sub);
		my $code = <<"END_OF_CODE";
sub $full_sub {
	my \$argument = shift;
	if ( 'ARRAY' eq ref \$argument ) {
		foreach my \$f ( \@{\$argument} ) {
			$sub(\$f);
		}
		return;
	}
	
	my \@array;
	if (exists \$args{$sub}) {
		\$args{$sub} = [ \@{ \$args{$sub} }, \$argument ];
	} else {
		\$args{$sub} = [ \$argument ];
	}
	_mb_required(\$ARRAY{$sub});
	return;
}
END_OF_CODE
		eval $code;
#		if ($EVAL_ERROR) {
#			print "$@\n";
#			exit;
#		} 
		goto &$full_sub;
	} ## end if ( exists $ARRAY{$sub...

	if ( exists $HASH{$sub} ) {
		_create_hashref($sub);
		my $version = $HASH{$sub}[0];
		my $default = $HASH{$sub}[1] ? '|| 0' : q{};
		eval <<"END_OF_CODE";
sub $full_sub {
	my \$argument1 = shift;
	my \$argument2 = shift $default;
	if ( 'HASH' eq ref \$argument1 ) {
		my ( \$k, \$v );
		while ( ( \$k, \$v ) = each \%{\$argument1} ) {
			$sub( \$k, \$v );
		}
		return;
	}

	\$args{$sub}{\$argument1} = \$argument2;
	_mb_required($version);
	return;
}
END_OF_CODE
		goto &$full_sub;
	} ## end if ( exists $HASH{$sub...

	if ( $autoload == 1 ) {
		$AutoLoader::AUTOLOAD = $full_sub;
		goto &AutoLoader::AUTOLOAD;
	} else {
		croak "$sub cannot be found";
	}
} ## end sub AUTOLOAD

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

sub _slurp_file {
	my $name = shift;
	my $file_handle;

	if ( $] < 5.006 ) { ## no critic(ProhibitPunctuationVars)
		require Symbol;
		$file_handle = Symbol::gensym();
		open $file_handle, "<$name" ## no critic(RequireBriefOpen)
		  or croak $OS_ERROR;
	} else {
		open $file_handle, '<', $name ## no critic(RequireBriefOpen)
		  or croak $OS_ERROR;
	}

	local $INPUT_RECORD_SEPARATOR = undef;   # enable localized slurp mode
	my $content = <$file_handle>;

	close $file_handle;
	return $content;
} ## end sub _slurp_file

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
		$object_created = 1;
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
		code  => $code
	);

	return;
} ## end sub functions_self_bundler


