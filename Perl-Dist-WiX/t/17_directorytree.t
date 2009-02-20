#!/usr/bin/perl

use strict;
use Perl::Dist::WiX::DirectoryTree;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 11;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

# Test 1.

my $tree = Perl::Dist::WiX::DirectoryTree->new(
    app_dir => 'C:\\test', 
    app_name => 'Test Perl', 
    sitename => 'www.test.site.invalid',
    trace    => 0,
);
ok($tree, '->new returns true');

# Test 2. (Test 3 at line xx)
              
my $string_test = 
'    <Directory Id=\'TARGETDIR\' Name=\'SourceDir\'>
      <Directory Id=\'INSTALLDIR\'>
        <Directory Id=\'D_Perl\' Name=\'perl\'>
          <Directory Id=\'D_F717B51E_5E57_329A_83A3_527819908145\' Name=\'bin\' />
          <Directory Id=\'D_167768A4_449A_32CC_A0F4_3DCF273EDF69\' Name=\'lib\'>
            <Directory Id=\'D_A8C8FC6F_24E4_3756_9816_68E0C6AF697E\' Name=\'B\' />
            <Directory Id=\'D_1E4CE48B_D491_3830_8C63_EE79BB61800A\' Name=\'Compress\' />
            <Directory Id=\'D_8AF15C79_FA45_36B3_ABD8_B31D41B582AF\' Name=\'CPAN\'>
              <Directory Id=\'D_53747424_89F4_3095_82EF_4C1A8B35027F\' Name=\'API\' />
            </Directory>
            <Directory Id=\'D_EB3DFBB1_E121_3F57_936E_2781FB7977D5\' Name=\'Digest\' />
            <Directory Id=\'D_96781A12_24D3_3B0A_8731_39F011F3CEA1\' Name=\'ExtUtils\' />
            <Directory Id=\'D_32453E8B_BBCD_3F54_B2C1_813C273C0847\' Name=\'File\' />
            <Directory Id=\'D_79FC3F94_0468_3ECA_B18F_4C92F38990EC\' Name=\'IO\'>
              <Directory Id=\'D_E9641701_36CD_3592_AEC6_2E375354E244\' Name=\'Compress\' />
              <Directory Id=\'D_01D29F16_7FFE_3AC0_878C_482FB1D6B715\' Name=\'Uncompress\' />
            </Directory>
            <Directory Id=\'D_CE106BF1_5EE2_3816_9A2D_0F00286C6749\' Name=\'Module\'>
              <Directory Id=\'D_4EB1F21D_6BEF_3CD6_AF16_A13DE1410E56\' Name=\'Build\' />
            </Directory>
            <Directory Id=\'D_3E78F079_73DD_3DAA_912F_209CEC68903D\' Name=\'Pod\' />
            <Directory Id=\'D_13EF26F9_C8E9_3439_9DD2_CE1506EF2826\' Name=\'Test\' />
            <Directory Id=\'D_CF3A962C_7210_3ECB_AF74_B6CD04EB0C5A\' Name=\'Time\' />
            <Directory Id=\'D_E0D6BA76_D23F_3DB8_95B0_0127F8C4670F\' Name=\'autodie\' />
            <Directory Id=\'D_1EAEB13C_294E_3325_BC3B_135FE6E21463\' Name=\'auto\'>
              <Directory Id=\'D_FE794D95_EB30_343C_A8B4_35B8EC58F146\' Name=\'share\' />
              <Directory Id=\'D_67BDAD54_8AF2_3313_B99C_62A8AE59118E\' Name=\'Archive\' />
              <Directory Id=\'D_D418317F_43AB_3EB9_AE5D_B0C6801D54AD\' Name=\'B\' />
              <Directory Id=\'D_B5A75E38_F946_3B45_89F6_C763580585B6\' Name=\'Compress\' />
              <Directory Id=\'D_44A4B802_8C4F_35FB_A899_E94A0E835B7C\' Name=\'Devel\'>
                <Directory Id=\'D_763BE847_3480_39B3_81AF_EC866C9B46DE\' Name=\'PPPort\' />
              </Directory>
              <Directory Id=\'D_8779B820_38EA_39E6_B723_2A94D0359610\' Name=\'Digest\'>
                <Directory Id=\'D_AB05C8BB_D7D3_30E9_AC70_09DCA7E9B705\' Name=\'MD5\' />
              </Directory>
              <Directory Id=\'D_87731680_27B6_39F3_8156_750CE68BE417\' Name=\'Encode\'>
                <Directory Id=\'D_7D9F371B_5DC9_3BA8_A148_3885C3DB167C\' Name=\'Byte\' />
                <Directory Id=\'D_DBE15461_7C17_3426_A235_3D7A7D6A9DD2\' Name=\'CN\' />
                <Directory Id=\'D_F18DB581_11B6_341F_B653_5825F76EC2E8\' Name=\'EBCDIC\' />
                <Directory Id=\'D_EE0CC19C_2B95_3967_A183_5699A8815889\' Name=\'JP\' />
                <Directory Id=\'D_329F5F2D_8990_368F_AA1E_670658F71209\' Name=\'KR\' />
                <Directory Id=\'D_D8E83E39_387D_300D_873F_C81DC3871874\' Name=\'Symbol\' />
                <Directory Id=\'D_67467A7E_E234_395D_89A3_A5B4D9E9405E\' Name=\'TW\' />
                <Directory Id=\'D_4351BFE1_7138_371E_8C0C_1491FEA4D8DF\' Name=\'Unicode\' />
              </Directory>
              <Directory Id=\'D_0C3638AF_5BCC_37D3_A128_5353F6322FD1\' Name=\'ExtUtils\' />
              <Directory Id=\'D_79A9E7EF_8E16_3E54_880D_75096FE90E96\' Name=\'File\' />
              <Directory Id=\'D_CBE44A8D_DAD2_30E0_A434_529A1345BCA9\' Name=\'Filter\' />
              <Directory Id=\'D_42D6502C_6758_3EF4_A771_6D0781150666\' Name=\'IO\'>
                <Directory Id=\'D_CEEBEC0F_FA9A_3406_BF4C_E80F3824F8E3\' Name=\'Compress\' />
              </Directory>
              <Directory Id=\'D_CB17F5A3_6530_362E_A8D0_D3D42CB4794B\' Name=\'Math\'>
                <Directory Id=\'D_5CADB1DF_9C98_37E9_B078_3C4ED5736BED\' Name=\'BigInt\'>
                  <Directory Id=\'D_7DDFFBD5_6735_3BD7_8A1B_A84B3ABF564A\' Name=\'FastCalc\' />
                </Directory>
              </Directory>
              <Directory Id=\'D_013BF1EF_8EDD_3B67_A53E_F841AAE00C03\' Name=\'Module\'>
                <Directory Id=\'D_252B8C8E_439D_37FE_AE27_34E19B677429\' Name=\'Load\' />
              </Directory>
              <Directory Id=\'D_7E864D52_82FE_37C1_8FB4_BEDD92F5B4A5\' Name=\'PerlIO\' />
              <Directory Id=\'D_8118EEA5_28BA_3A98_8256_18639EE63293\' Name=\'Pod\' />
              <Directory Id=\'D_9D9FF976_F842_3CAB_A6C5_681CF3C41D95\' Name=\'POSIX\' />
              <Directory Id=\'D_A331F4A8_9F7F_3325_8123_AE7B2AD8A5FF\' Name=\'Test\'>
                <Directory Id=\'D_552D454D_23A7_34BD_9A9A_5DC892924D7B\' Name=\'Harness\' />
              </Directory>
              <Directory Id=\'D_6E122939_8649_3EFF_B6B7_0811B971F099\' Name=\'Text\' />
              <Directory Id=\'D_79722C1B_07DC_3CE4_BD64_694966C68444\' Name=\'threads\'>
                <Directory Id=\'D_959B7613_679A_3565_8CB3_9EE8AF8E9177\' Name=\'shared\' />
              </Directory>
              <Directory Id=\'D_853CDE42_1F58_3B81_9FC6_7DFB6A7986A3\' Name=\'Time\' />
            </Directory>
          </Directory>
          <Directory Id=\'D_1BEF246B_FCD9_34B0_ABAA_5D90D198E4C9\' Name=\'site\'>
            <Directory Id=\'D_B3D4AD98_92FD_3DCF_A3A5_26C8E2D252A3\' Name=\'lib\'>
              <Directory Id=\'D_50CB1D55_C1AE_35A4_BC21_DBC362C2A7A6\' Name=\'Compress\' />
              <Directory Id=\'D_59FAF411_602A_3066_846D_07E4A9B8EB69\' Name=\'File\' />
              <Directory Id=\'D_D71A609A_E8F8_3E89_81E6_14081EE0ECA2\' Name=\'HTML\' />
              <Directory Id=\'D_CC536878_B286_3AD4_90F6_B9BACB6B692D\' Name=\'IO\' />
              <Directory Id=\'D_93051433_B6F7_3599_97B2_700071DA0864\' Name=\'Term\' />
              <Directory Id=\'D_14F9992E_A451_3D44_AD43_D3A367B02031\' Name=\'Win32\' />
              <Directory Id=\'D_7212C99C_98FC_3CC2_B32B_986926035439\' Name=\'auto\'>
                <Directory Id=\'D_BC0402D3_9BD2_3987_B1B4_35EA398C6BEC\' Name=\'share\' />
                <Directory Id=\'D_245FDF54_DE1F_3B14_B45C_F591F12FF8FD\' Name=\'Compress\' />
                <Directory Id=\'D_CDC2E593_45F3_34EF_82A5_8E1B2F82B2AE\' Name=\'File\' />
                <Directory Id=\'D_27E957E3_1F26_3ADB_B1C5_BE6DD5336BF3\' Name=\'HTML\' />
                <Directory Id=\'D_337746D2_10AF_3567_8817_7B8A546783B8\' Name=\'IO\' />
                <Directory Id=\'D_EE6B1671_0C94_37EC_9C2E_84F5E42CA7BA\' Name=\'Term\' />
                <Directory Id=\'D_C0D9F7F3_8AA7_3A70_810C_FC5FC5F9AA56\' Name=\'Win32\' />
              </Directory>
            </Directory>
          </Directory>
        </Directory>
        <Directory Id=\'D_Toolchain\' Name=\'c\'>
          <Directory Id=\'D_F929E019_ED70_313B_BAFD_0F0F27FF0A4F\' Name=\'bin\'>
            <Directory Id=\'D_1871D525_EA82_3FCD_A1DD_6545613FA8A5\' Name=\'startup\' />
          </Directory>
          <Directory Id=\'D_990EBE17_4FDD_3330_B77D_CC1780785AD9\' Name=\'include\'>
            <Directory Id=\'D_4970DE0E_5BEC_34EA_BD37_9FE53647B20E\' Name=\'c++\'>
              <Directory Id=\'D_0BD3E815_B406_3420_8279_5C17C43D3968\' Name=\'3.4.5\'>
                <Directory Id=\'D_E6349AE4_B0D7_34C7_833A_5B1444369683\' Name=\'backward\' />
                <Directory Id=\'D_C3EB056B_8B9C_38F5_B80B_7AF310AB57B8\' Name=\'bits\' />
                <Directory Id=\'D_0BFD1700_7BDD_3E14_8878_BF46E4E1602C\' Name=\'debug\' />
                <Directory Id=\'D_2EB1CFBC_2688_3547_980A_96CB2B0BD574\' Name=\'ext\' />
                <Directory Id=\'D_F3F9A409_F0C0_378A_BFD7_8C06E94995AD\' Name=\'mingw32\'>
                  <Directory Id=\'D_7F04A259_CADA_3CFC_A0B6_B75567F48201\' Name=\'bits\' />
                </Directory>
              </Directory>
            </Directory>
            <Directory Id=\'D_25D1AF22_5FC8_3804_BBCD_75DE143DC68A\' Name=\'ddk\' />
            <Directory Id=\'D_04E8578B_77C2_3095_A0DB_209575994057\' Name=\'gl\' />
            <Directory Id=\'D_65264A85_B764_346C_8343_700812E06884\' Name=\'libxml\' />
            <Directory Id=\'D_95B154FE_05EE_3665_A1B4_9B055011A6A5\' Name=\'sys\' />
          </Directory>
          <Directory Id=\'D_14230B50_C0DC_36E3_8931_C28F934C84B5\' Name=\'lib\'>
            <Directory Id=\'D_E764ADB9_9647_3B6F_8A99_DED1898EF040\' Name=\'debug\' />
            <Directory Id=\'D_6B140931_6C1B_3379_A4F1_FB678B3C2544\' Name=\'gcc\'>
              <Directory Id=\'D_99F170D9_C69E_3361_A1F4_CA1869C0648E\' Name=\'mingw32\'>
                <Directory Id=\'D_27704913_5FF2_36A8_B225_BF1E47B48413\' Name=\'3.4.5\'>
                  <Directory Id=\'D_12AEE065_432E_3782_93D7_586F15D9129D\' Name=\'include\' />
                  <Directory Id=\'D_1C0767F2_565D_361B_B0E0_5BB83F2AE405\' Name=\'install-tools\'>
                    <Directory Id=\'D_AF11F1AA_EB14_3594_926E_F8BACEF36342\' Name=\'include\' />
                  </Directory>
                </Directory>
              </Directory>
            </Directory>
          </Directory>
          <Directory Id=\'D_DD294F22_4FBF_321A_80BB_4CBD1A25C9DE\' Name=\'libexec\'>
            <Directory Id=\'D_12545A33_2C38_3D6F_A2DA_267EE97FDE2F\' Name=\'gcc\'>
              <Directory Id=\'D_6E9B021B_04EE_3F14_A14C_919B80A6AC42\' Name=\'mingw32\'>
                <Directory Id=\'D_97FE211B_F98C_3285_A75B_6F981AA3A19A\' Name=\'3.4.5\'>
                  <Directory Id=\'D_870594AF_E302_36D9_AFE7_D999FA0DBBF6\' Name=\'install-tools\' />
                </Directory>
              </Directory>
            </Directory>
          </Directory>
          <Directory Id=\'D_2470DFE7_CB83_3A8E_8821_BE8F36A4DB79\' Name=\'mingw32\'>
            <Directory Id=\'D_4082B714_94AE_3055_A142_8AAC4D0F817A\' Name=\'bin\' />
            <Directory Id=\'D_5E14DB0D_DF32_3502_9ABD_8B4B164CDE1A\' Name=\'lib\'>
              <Directory Id=\'D_1733B110_8009_3A78_BBA9_3CD4327C357D\' Name=\'ld-scripts\' />
            </Directory>
          </Directory>
          <Directory Id=\'D_BF54B1C7_EF09_3458_B556_2B9279AD2BBD\' Name=\'share\'>
            <Directory Id=\'D_3AD5DB9D_61F5_3101_89F4_D4AD38190F21\' Name=\'locale\' />
          </Directory>
        </Directory>
        <Directory Id=\'D_License\' Name=\'licenses\'>
          <Directory Id=\'D_818D6C63_4B20_30FD_A5F0_019BE9408F83\' Name=\'dmake\' />
          <Directory Id=\'D_B8131B88_3ABA_3EE1_BF5C_E3E81E0539E4\' Name=\'gcc\' />
          <Directory Id=\'D_8D5645E4_03EC_3E0A_84A4_DA619495CFB5\' Name=\'mingw\' />
          <Directory Id=\'D_3C916D82_47FE_34CE_8BDD_C793099E8A68\' Name=\'perl\' />
          <Directory Id=\'D_4EAD5660_DA82_3DCB_A86A_D96BE1DF90FA\' Name=\'pexports\' />
        </Directory>
        <Directory Id=\'D_Cpan\' Name=\'cpan\' />
        <Directory Id=\'D_Win32\' Name=\'win32\' />
      </Directory>
      <Directory Id=\'ProgramMenuFolder\'>
        <Directory Id=\'D_App_Menu\' Name=\'Test Perl\' />
      </Directory>
    </Directory>';

my $string = $tree->as_string;

is($string, q{}, 'Stringifies correctly when uninitialized');    

# Test 4

$tree->initialize_tree; $string = $tree->as_string;

is($string, $string_test, 'Stringifies correctly once initialized');    

# Tests 4-7 are successful finds.

my @tests_1 = (
    [
        {
            path_to_find => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
            exact => 1,
            descend => 1,
        },
        'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
        'descend=1 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\test\\win32',
            exact => 1,
            descend => 0,
        },
        'C:\\test\\win32',
        'descend=0 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
            exact => 0,
            descend => 1,
        },
        'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
        'descend=1 exact=0'
    ],
    [
        {
            path_to_find => 'C:\\test\\win32\\x',
            exact => 0,
            descend => 0,
        },
        'C:\\test\\win32',
        'descend=0 exact=0'
    ],
);

foreach my $test (@tests_1)
{
    my $dir = $tree->search_dir(%{$test->[0]});
    is($dir->get_path, $test->[1], "Successful search, $test->[2]");
}

my @tests_2 = (
    [
        {
            path_to_find => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
            exact => 1,
            descend => 1,
        },
        'descend=1 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\test\\win32\\x',
            exact => 1,
            descend => 0,
        },
        'descend=0 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\xtest\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
            exact => 0,
            descend => 1,
        },
        'descend=1 exact=0'
    ],
    [
        {
            path_to_find => 'C:\\xtest\\win33',
            exact => 0,
            descend => 0,
        },
        'descend=0 exact=0'
    ],
);

foreach my $test (@tests_2)
{
    my $dir = $tree->search_dir(%{$test->[0]});
    ok((not defined $dir), "Unsuccessful search, $test->[1]");
}
