use inc::Module::Install 0.82;

all_from      'lib/ADAMK/Changes.pm';
requires      'Object::Tiny'                => '1.03';
requires      'DateTime'                    => '0.4501';
requires      'DateTime::Format::DateParse' => '0.04';
test_requires 'Test::More'                  => '0.47';
test_requires 'File::Spec'                  => '0.80';

WriteAll;

__END__

use inc::Module::Install::DSL 0.82;

name          ADAMK-Changes
all_from      lib/ADAMK/Changes.pm
requires_from Object::Tiny 1.03
test_requires Test::More   0.47
test_requires File::Spec   0.80
