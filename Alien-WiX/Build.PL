use warnings;
use English '-no_match_vars';
use Module::Build 0.21;
	
die "OS unsupported" if ('MSWin32' ne $OSNAME);

my $class = Module::Build->subclass(
	class => 'ModuleBuildAlienWiX',
	code => q{
		sub ACTION_code {
            my $self = shift;
            my $install_dotnet = $self->notes('install_dotnet');
            my $install_wix = $self->notes('install_wix');
            my $WIX_URL = 'http://wix.sourceforge.net/releases/3.0.5207.0/Wix3.msi';
            my $NET20_URL = 'http://download.microsoft.com/download/0/8/c/08c19fa4-4c4f-4ffb-9d6c-150906578c9e/NetFx20SP1_x86.exe';
            my $ok;
            
            if ($install_dotnet) {
                print "Downloading and installing Microsoft .NET Framework 2.0 SP1.\n";
                $ok = $self->do_system("msiexec /i $NET20_URL /qb!");
                unless ($ok) {
                    die q{Couldn't install .NET Framework 2.0 SP1, stopped};
                } else {
                    $self->notes('install_dotnet' => 0);
                }
            }

            if ($install_wix) {
                print "Downloading and installing Windows Installer XML 3.0.5207.0.\n";
                $ok = $self->do_system("msiexec /i $WIX_URL /qb!");
                unless ($ok) {
                    die q{Couldn't install WiX, stopped};
                } else {
                    $self->notes('install_wix' => 0);
                }
            }
            
            $self->SUPER::ACTION_code();
        }
    }
);

my $builder = $class->new(
    module_name         => 'Alien::WiX',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
    dist_version_from   => 'lib/Alien/WiX.pm',
    configure_requires  => {
		'Win32API::Registry'
		                => '0.30',
		'Module::Build'
		                => '0.21',
	},
    build_requires  => {
		'Module::Build'
		                => '0.21',
	},
	requires            => {
		'perl'          => '5.006',
        'Test::More'    => '0',
		'Readonly'      => '1.03',
        'version'       => '0.76',
		'Win32API::Registry'
		                => '0.30',
		'Win32::TieRegistry'
		                => '0.25',
    },
	recommends          => {
		'Readonly::XS'  => '1.05',
	},
	create_makefile_pl  => 'passthrough',
    add_to_cleanup      => [ 'Alien-WiX-*' ],
);

eval { require Win32API::Registry; }
    or die q{I can't check whether WiX is installed without Win32API::Registry};
Win32API::Registry->import(0.30);
Win32API::Registry->import(':ALL');

$builder->notes('install_dotnet' => 0);
$builder->notes('install_wix' => 0);

my ($default, $answer, $installed, $key, $type, $data, $int_data, $version);
my $WIX30_REGISTRY_KEY = 'SOFTWARE\\Microsoft\\Windows Installer XML\\3.0';
my $NET20_REGISTRY_KEY = 'SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v2.0.50727';
my $WIX_VERSION = 5207;

$key = 1;
$installed = 0;
if (RegOpenKeyEx( regConstant('HKEY_LOCAL_MACHINE'), $NET20_REGISTRY_KEY, 0, regConstant('KEY_READ'), $key ))
{
	if (RegQueryValueEx( $key, 'Install', [], $type, $data, [] )) {
        $int_data = unpack 'L', $data;
    
		if ($int_data > 0) {
            print ".NET Framework 2.0 installed.\n\n";
			$installed = 1;
		}
	} 
    
    RegCloseKey( $key );
}

$answer = 0;

unless ($installed) {
	$answer = $builder->y_n('Install .NET Framework 2.0 SP1?', 'y');

	if ($answer) {
        $builder->notes('install_dotnet' => 1);
	} else {
		die q{Didn't install .NET Framework 2.0 SP1, stopped};
	}
}
	
$installed = 0;
$default = 'y';
$answer = 0;

if (RegOpenKeyEx( regConstant('HKEY_LOCAL_MACHINE'), $WIX30_REGISTRY_KEY, 0, regConstant('KEY_READ'), $key ))
{
	if (RegQueryValueEx( $key, 'ProductVersion', [], $type, $data, [] )) {
		if ($data =~ m/3.0.(\d+).0/) {
			$version = $1;
            print "Version of WiX installed: $data ($version)\n\n";
			if ($version >= $WIX_VERSION) {
				$installed = 1;
			} else {
				$default = 'n';
			}
		}
	}

    RegCloseKey( $key );
}


unless ($installed) {
	$answer = $builder->y_n('Install Windows Installer XML version 3.0.5207?', $default);

	if ($answer) {
        $builder->notes('install_wix' => 1);
	} else {
		die q{Didn't install WiX, stopped} if ($default eq 'y');
	}
}

$builder->create_build_script();
