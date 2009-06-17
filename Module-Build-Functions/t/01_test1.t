use Test::More tests => 6;
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

my $test1 = [ 
	'Curtis Jewell <csjewell@cpan.org>',
    'Curtis Jewell <perl@csjewell.fastmail.us>'
];

is_deeply($build->dist_author(), $test1, 'multiple dist_author executions work.');

my $test2 = {
    'Module::Build' => '0.31'
};

is_deeply($build->configure_requires(), $test2, 'Version of Module::Build is found correctly');

my $test3 = [qw(PL support pm xs pod script share share_d1 share_d2)];

is_deeply($build->build_elements(), $test3, 'build_elements list is correct');

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