use Test::More tests => 13;
use File::Spec::Functions qw(catdir catfile);
use Module::Build::Functions;
use Module::Build;
use Cwd;
use Capture::Tiny qw(capture);

my $original_dir = cwd();

chdir(catdir(qw(t MBF-test)));
(undef, undef) = capture { bundler(); };
ok(-e catfile(qw(inc Module Build Functions.pm)), 'bundler() works correctly');

(undef, undef) = capture { system($^X, 'Build.PL'); };

ok(-e '_build', 'Build.PL appeared to execute correctly');
ok(-e catfile(qw(_build lib ModuleBuildFunctions SelfBundler.pm)), 'Build.PL appeared to create the self-bundler');

my $build = Module::Build->current();

my $test1 = {
    'Module::Build' => '0.31'
};

is_deeply($build->configure_requires(), $test1, 'Version of Module::Build is found correctly');

my $test2 = [ 
	'Curtis Jewell <csjewell@cpan.org>',
    'Curtis Jewell <perl@csjewell.fastmail.us>'
];

is_deeply($build->dist_author(), $test2, 'dist_author is correct (multiple)');

my $test3 = [qw(PL support pm xs pod script share share_d1 share_d2)];

is_deeply($build->build_elements(), $test3, 'build_elements list is correct');

my $test4 = {
	'perl' => '5.005',
	'File::Slurp' => 0,
};

is_deeply($build->requires(), $test4, 'requires list is correct');

my $test5 = {
	'Test::More' => 0,
	'Test::Compile' => 0,
	'Module::Build' => '0.31'
};

is_deeply($build->build_requires(), $test5, 'build_requires list is correct');

my $test6 = bless( {
	'original' => '0.001_006',
	'alpha' => 1,
	'version' => [ 0, 1, 6 ],
  }, 'Module::Build::Version' );

is_deeply($build->dist_version(), $test6, 'dist_version_from works');

my @test7 = $build->cleanup();
my $got7 = ['MBF-Test-*'];

is_deeply(\@test7, $got7, 'add_to_cleanup is correct');

is($build->license(), 'perl', 'license is correct');

is($build->create_makefile_pl(), 'passthrough', 'create_makefile_pl is correct');

fail('install_share does not work quite correctly yet. I need to find out why.');

# Cleanup
(undef, undef) = capture { $build->dispatch('realclean'); };
unlink(catfile(qw(inc Module Build Functions.pm)));
rmdir(catdir(qw(inc Module Build)));
rmdir(catdir(qw(inc Module)));
rmdir(catdir(qw(inc .author)));
rmdir('inc');
unlink('Build.bat') if -e 'Build.bat';
unlink('Build.com') if -e 'Build.com';

chdir($original_dir);