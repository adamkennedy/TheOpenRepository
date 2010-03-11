#!/usr/bin/perl -w
# $File: /local/member/autrijus/Win32-Exe//t/1-basic.t $ $Author: autrijus $
# $Revision: #12 $ $Change: 3628 $ $DateTime: 2004-03-16T13:12:33.854545Z $

use strict;
use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../Parse-Binary/lib";
use Test::More tests => 21;

$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };
$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };

use_ok('Win32::Exe');

my $file = "$FindBin::Bin/par.exe";
ok(my $orig = Win32::Exe->read_file($file), 'read_file');

my $exe = Win32::Exe->new($file);
isa_ok($exe, 'Win32::Exe');
is($exe->dump, $orig, 'roundtrip');

is($exe->Subsystem, 'console', 'Subsystem');
$exe->SetSubsystem('windows');
is($exe->Subsystem, 'windows', 'SetSubsystem');
$exe->SetSubsystem('CONSOLE');
is($exe->Subsystem, 'console', 'SetSubsystem with uppercase string');

is_deeply(
    [map $_->Name, $exe->sections],
    [qw( .text .rdata .data .rsrc )],
    'sections'
);

$exe->refresh;
is($exe->dump, $orig, 'roundtrip after refresh');

my ($sections) = $exe->sections;
isa_ok($sections, 'Win32::Exe::Section');
$sections->refresh;
is($exe->dump, $orig, 'roundtrip after sections refresh');

my $rsrc = $exe->resource_section;
isa_ok($rsrc, 'Win32::Exe::Section::Resources');
$rsrc->refresh;
is($exe->dump, $orig, 'roundtrip after resources refresh');

is_deeply(
    [$rsrc->names],
    [
	'/#RT_GROUP_ICON/#1/#0',
	'/#RT_ICON/#1/#0',
	'/#RT_ICON/#2/#0',
	'/#RT_VERSION/#1/#0',
    ],
    'resource names'
);

my $group = $rsrc->first_object('GroupIcon');
is($group->PathName, '/#RT_GROUP_ICON/#1/#0', 'pathname');

my $version = $rsrc->first_object('Version');
is($version->info->[0], 'VS_VERSION_INFO', 'version->info');
is($version->get('FileVersion'), '0,0,0,0', 'version->get');

$version->set('FileVersion', '1,0,0,0');
is($version->get('FileVersion'), '1,0,0,0', 'version->set took effect');
$version->refresh;
is($version->get('FileVersion'), '1,0,0,0', 'version->set remains after refresh');

isnt(($exe->dump), $orig, 'dump changed after resources refresh');
$orig = $exe->dump;
is(($exe->dump), $orig, 'roundtrip after resource refresh');

1;
