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
		plan tests => 14;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

# Tests 1-2.

my $tree = Perl::Dist::WiX::DirectoryTree->new(
    app_dir => 'C:\\test', 
    app_name => 'Test Perl', 
    sitename => 'www.test.site.invalid',
    trace    => 0,
);
ok($tree, '->new returns true');
is($Perl::Dist::WiX::DirectoryTree::VERSION, '0.11_07', 'Version correct');

# Test 3. (Test 4 at line 51)

my $tree_test_1 = bless( {
                 'trace' => 0,
                 'sitename' => 'www.test.site.invalid',
                 'app_name' => 'Test Perl',
                 'root' => bless( {
                                    'sitename' => 'www.test.site.invalid',
                                    'directories' => [],
                                    'files' => [],
                                    'entries' => [],
                                    'name' => 'SourceDir',
                                    'trace' => 0,
                                    'special' => 1,
                                    'id' => 'TARGETDIR'
                                  }, 'Perl::Dist::WiX::Directory' ),
                 'app_dir' => 'C:\\test'
               }, 'Perl::Dist::WiX::DirectoryTree' );

is_deeply( $tree, $tree_test_1, 'Object created correctly' );

# Test 4 (Test 5 at line 209)
              
my $string_test = 
'    <Directory Id=\'TARGETDIR\' Name=\'SourceDir\'>
      <Directory Id=\'D_App_Root\' Name=\'[INSTALLDIR]\'>
        <Directory Id=\'D_Perl\' Name=\'perl\'>
          <Directory Id=\'D_F717B51E_5E57_329A_83A3_527819908145\' Name=\'bin\' />
          <Directory Id=\'D_167768A4_449A_32CC_A0F4_3DCF273EDF69\' Name=\'lib\'>
            <Directory Id=\'D_1E4CE48B_D491_3830_8C63_EE79BB61800A\' Name=\'Compress\' />
            <Directory Id=\'D_8AF15C79_FA45_36B3_ABD8_B31D41B582AF\' Name=\'CPAN\'>
              <Directory Id=\'D_53747424_89F4_3095_82EF_4C1A8B35027F\' Name=\'API\' />
            </Directory>
            <Directory Id=\'D_EB3DFBB1_E121_3F57_936E_2781FB7977D5\' Name=\'Digest\'>
              <Directory Id=\'D_60F63516_AF1B_3DEE_BAFC_8B43C0619806\' Name=\'MD5\' />
            </Directory>
            <Directory Id=\'D_96781A12_24D3_3B0A_8731_39F011F3CEA1\' Name=\'ExtUtils\'>
              <Directory Id=\'D_074C5720_D8E1_37DF_839D_F358DB19EE01\' Name=\'CBuilder\'>
                <Directory Id=\'D_C65C6ABA_1CBA_3F37_931D_4821BFDCDE13\' Name=\'Platform\' />
              </Directory>
            </Directory>
            <Directory Id=\'D_32453E8B_BBCD_3F54_B2C1_813C273C0847\' Name=\'File\' />
            <Directory Id=\'D_79FC3F94_0468_3ECA_B18F_4C92F38990EC\' Name=\'IO\'>
              <Directory Id=\'D_E9641701_36CD_3592_AEC6_2E375354E244\' Name=\'Compress\'>
                <Directory Id=\'D_F6F6D72B_FAE4_3BD9_8A47_99A62B194A88\' Name=\'Adapter\' />
                <Directory Id=\'D_3B3CB2F5_DA31_3A29_AD85_88D17BBC6C88\' Name=\'Base\' />
                <Directory Id=\'D_2A6EF8AC_29D0_3A7E_BD75_7D71CEDBE38A\' Name=\'Gzip\' />
                <Directory Id=\'D_98CE0D83_E820_31F1_A3ED_06AFD0393235\' Name=\'Zip\' />
              </Directory>
              <Directory Id=\'D_01D29F16_7FFE_3AC0_878C_482FB1D6B715\' Name=\'Uncompress\'>
                <Directory Id=\'D_9CDC0948_2798_3C94_9D64_C32246AEAA2B\' Name=\'Adapter\' />
              </Directory>
            </Directory>
            <Directory Id=\'D_27461A25_5034_3D89_AD5D_50A5E3CD5BA9\' Name=\'Math\'>
              <Directory Id=\'D_4FF80E77_1B9F_3235_99FE_55B711F7CAD1\' Name=\'BigInt\'>
                <Directory Id=\'D_71733DFA_C41E_33B7_A5F6_BA0A24B561A3\' Name=\'FastCalc\' />
              </Directory>
            </Directory>
            <Directory Id=\'D_CE106BF1_5EE2_3816_9A2D_0F00286C6749\' Name=\'Module\' />
            <Directory Id=\'D_13EF26F9_C8E9_3439_9DD2_CE1506EF2826\' Name=\'Test\' />
            <Directory Id=\'D_1EAEB13C_294E_3325_BC3B_135FE6E21463\' Name=\'auto\'>
              <Directory Id=\'D_B5A75E38_F946_3B45_89F6_C763580585B6\' Name=\'Compress\' />
              <Directory Id=\'D_DA94853F_4398_35C1_A18E_1A5B9D5E4893\' Name=\'Cwd\' />
              <Directory Id=\'D_44A4B802_8C4F_35FB_A899_E94A0E835B7C\' Name=\'Devel\' />
              <Directory Id=\'D_8779B820_38EA_39E6_B723_2A94D0359610\' Name=\'Digest\'>
                <Directory Id=\'D_AB05C8BB_D7D3_30E9_AC70_09DCA7E9B705\' Name=\'MD5\' />
              </Directory>
              <Directory Id=\'D_87731680_27B6_39F3_8156_750CE68BE417\' Name=\'Encode\' />
              <Directory Id=\'D_CB17F5A3_6530_362E_A8D0_D3D42CB4794B\' Name=\'Math\'>
                <Directory Id=\'D_5CADB1DF_9C98_37E9_B078_3C4ED5736BED\' Name=\'BigInt\'>
                  <Directory Id=\'D_7DDFFBD5_6735_3BD7_8A1B_A84B3ABF564A\' Name=\'FastCalc\' />
                </Directory>
              </Directory>
              <Directory Id=\'D_7E864D52_82FE_37C1_8FB4_BEDD92F5B4A5\' Name=\'PerlIO\' />
              <Directory Id=\'D_9D9FF976_F842_3CAB_A6C5_681CF3C41D95\' Name=\'POSIX\' />
              <Directory Id=\'D_853CDE42_1F58_3B81_9FC6_7DFB6A7986A3\' Name=\'Time\' />
              <Directory Id=\'D_FE794D95_EB30_343C_A8B4_35B8EC58F146\' Name=\'share\' />
            </Directory>
          </Directory>
          <Directory Id=\'D_1BEF246B_FCD9_34B0_ABAA_5D90D198E4C9\' Name=\'site\'>
            <Directory Id=\'D_B3D4AD98_92FD_3DCF_A3A5_26C8E2D252A3\' Name=\'lib\'>
              <Directory Id=\'D_D797137C_CBFF_386F_ADB3_666F9830DCA8\' Name=\'Bundle\' />
              <Directory Id=\'D_50CB1D55_C1AE_35A4_BC21_DBC362C2A7A6\' Name=\'Compress\' />
              <Directory Id=\'D_C108793B_2141_3D01_A59F_82357A983698\' Name=\'DBD\' />
              <Directory Id=\'D_59FAF411_602A_3066_846D_07E4A9B8EB69\' Name=\'File\' />
              <Directory Id=\'D_D71A609A_E8F8_3E89_81E6_14081EE0ECA2\' Name=\'HTML\' />
              <Directory Id=\'D_CC536878_B286_3AD4_90F6_B9BACB6B692D\' Name=\'IO\' />
              <Directory Id=\'D_E28DFF76_91BB_3EBB_8864_CD132FDD077E\' Name=\'LWP\' />
              <Directory Id=\'D_496E3E7C_A119_3614_8097_8AE576E025F0\' Name=\'Math\' />
              <Directory Id=\'D_0551B560_2A5A_32E4_855E_EBE43EC34DF8\' Name=\'PAR\' />
              <Directory Id=\'D_93051433_B6F7_3599_97B2_700071DA0864\' Name=\'Term\' />
              <Directory Id=\'D_BEE4F0BB_54AB_335D_AB1B_7D44249D1696\' Name=\'Test\' />
              <Directory Id=\'D_14F9992E_A451_3D44_AD43_D3A367B02031\' Name=\'Win32\' />
              <Directory Id=\'D_633BBECE_77D7_30F6_9034_D39655638882\' Name=\'XML\' />
              <Directory Id=\'D_7212C99C_98FC_3CC2_B32B_986926035439\' Name=\'auto\'>
                <Directory Id=\'D_BC0402D3_9BD2_3987_B1B4_35EA398C6BEC\' Name=\'share\' />
                <Directory Id=\'D_245FDF54_DE1F_3B14_B45C_F591F12FF8FD\' Name=\'Compress\'>
                  <Directory Id=\'D_4054B239_62D0_3344_BA98_6DA544EBC8A6\' Name=\'Raw\' />
                </Directory>
                <Directory Id=\'D_6CE1EA06_9D83_3B72_B68C_375CB454C284\' Name=\'Math\' />
                <Directory Id=\'D_EE6B1671_0C94_37EC_9C2E_84F5E42CA7BA\' Name=\'Term\' />
                <Directory Id=\'D_C0D9F7F3_8AA7_3A70_810C_FC5FC5F9AA56\' Name=\'Win32\' />
                <Directory Id=\'D_D2B863DE_1257_3C2A_A516_6406CEE125A0\' Name=\'XML\' />
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
      <Directory Id=\'D_ProgramMenuFolder\'>
        <Directory Id=\'D_App_Menu\' Name=\'Test Perl\' />
      </Directory>
    </Directory>';

my $string = $tree->as_string;

is($string, q{}, 'Stringifies correctly when uninitialized');    

# Test 5

$tree->initialize_tree; $string = $tree->as_string;

is($string, $string_test, 'Stringifies correctly once initialized');    

# Test 6 (Test 7 at line 1562)

my $tree_test_2 = bless( {
  'trace' => 0,
  'sitename' => 'www.test.site.invalid',
  'app_name' => 'Test Perl',
  'root' => bless( {
    'sitename' => 'www.test.site.invalid',
    'directories' => [
      bless( {
        'sitename' => 'www.test.site.invalid',
        'directories' => [
          bless( {
            'sitename' => 'www.test.site.invalid',
            'directories' => [
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'bin',
                'path' => 'C:\\test\\perl\\bin',
                'trace' => 0,
                'special' => 0,
                'guid' => 'F717B51E-5E57-329A-83A3-527819908145',
                'id' => 'F717B51E_5E57_329A_83A3_527819908145'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Compress',
                    'path' => 'C:\\test\\perl\\lib\\Compress',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '1E4CE48B-D491-3830-8C63-EE79BB61800A',
                    'id' => '1E4CE48B_D491_3830_8C63_EE79BB61800A'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'API',
                        'path' => 'C:\\test\\perl\\lib\\CPAN\\API',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '53747424-89F4-3095-82EF-4C1A8B35027F',
                        'id' => '53747424_89F4_3095_82EF_4C1A8B35027F'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'CPAN',
                    'path' => 'C:\\test\\perl\\lib\\CPAN',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '8AF15C79-FA45-36B3-ABD8-B31D41B582AF',
                    'id' => '8AF15C79_FA45_36B3_ABD8_B31D41B582AF'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'MD5',
                        'path' => 'C:\\test\\perl\\lib\\Digest\\MD5',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '60F63516-AF1B-3DEE-BAFC-8B43C0619806',
                        'id' => '60F63516_AF1B_3DEE_BAFC_8B43C0619806'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Digest',
                    'path' => 'C:\\test\\perl\\lib\\Digest',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'EB3DFBB1-E121-3F57-936E-2781FB7977D5',
                    'id' => 'EB3DFBB1_E121_3F57_936E_2781FB7977D5'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Platform',
                            'path' => 'C:\\test\\perl\\lib\\ExtUtils\\CBuilder\\Platform',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'C65C6ABA-1CBA-3F37-931D-4821BFDCDE13',
                            'id' => 'C65C6ABA_1CBA_3F37_931D_4821BFDCDE13'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'CBuilder',
                        'path' => 'C:\\test\\perl\\lib\\ExtUtils\\CBuilder',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '074C5720-D8E1-37DF-839D-F358DB19EE01',
                        'id' => '074C5720_D8E1_37DF_839D_F358DB19EE01'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'ExtUtils',
                    'path' => 'C:\\test\\perl\\lib\\ExtUtils',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '96781A12-24D3-3B0A-8731-39F011F3CEA1',
                    'id' => '96781A12_24D3_3B0A_8731_39F011F3CEA1'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'File',
                    'path' => 'C:\\test\\perl\\lib\\File',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '32453E8B-BBCD-3F54-B2C1-813C273C0847',
                    'id' => '32453E8B_BBCD_3F54_B2C1_813C273C0847'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Adapter',
                            'path' => 'C:\\test\\perl\\lib\\IO\\Compress\\Adapter',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'F6F6D72B-FAE4-3BD9-8A47-99A62B194A88',
                            'id' => 'F6F6D72B_FAE4_3BD9_8A47_99A62B194A88'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Base',
                            'path' => 'C:\\test\\perl\\lib\\IO\\Compress\\Base',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '3B3CB2F5-DA31-3A29-AD85-88D17BBC6C88',
                            'id' => '3B3CB2F5_DA31_3A29_AD85_88D17BBC6C88'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Gzip',
                            'path' => 'C:\\test\\perl\\lib\\IO\\Compress\\Gzip',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '2A6EF8AC-29D0-3A7E-BD75-7D71CEDBE38A',
                            'id' => '2A6EF8AC_29D0_3A7E_BD75_7D71CEDBE38A'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Zip',
                            'path' => 'C:\\test\\perl\\lib\\IO\\Compress\\Zip',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '98CE0D83-E820-31F1-A3ED-06AFD0393235',
                            'id' => '98CE0D83_E820_31F1_A3ED_06AFD0393235'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Compress',
                        'path' => 'C:\\test\\perl\\lib\\IO\\Compress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'E9641701-36CD-3592-AEC6-2E375354E244',
                        'id' => 'E9641701_36CD_3592_AEC6_2E375354E244'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Adapter',
                            'path' => 'C:\\test\\perl\\lib\\IO\\Uncompress\\Adapter',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '9CDC0948-2798-3C94-9D64-C32246AEAA2B',
                            'id' => '9CDC0948_2798_3C94_9D64_C32246AEAA2B'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Uncompress',
                        'path' => 'C:\\test\\perl\\lib\\IO\\Uncompress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '01D29F16-7FFE-3AC0-878C-482FB1D6B715',
                        'id' => '01D29F16_7FFE_3AC0_878C_482FB1D6B715'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'IO',
                    'path' => 'C:\\test\\perl\\lib\\IO',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '79FC3F94-0468-3ECA-B18F-4C92F38990EC',
                    'id' => '79FC3F94_0468_3ECA_B18F_4C92F38990EC'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'FastCalc',
                            'path' => 'C:\\test\\perl\\lib\\Math\\BigInt\\FastCalc',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '71733DFA-C41E-33B7-A5F6-BA0A24B561A3',
                            'id' => '71733DFA_C41E_33B7_A5F6_BA0A24B561A3'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'BigInt',
                        'path' => 'C:\\test\\perl\\lib\\Math\\BigInt',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '4FF80E77-1B9F-3235-99FE-55B711F7CAD1',
                        'id' => '4FF80E77_1B9F_3235_99FE_55B711F7CAD1'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Math',
                    'path' => 'C:\\test\\perl\\lib\\Math',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '27461A25-5034-3D89-AD5D-50A5E3CD5BA9',
                    'id' => '27461A25_5034_3D89_AD5D_50A5E3CD5BA9'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Module',
                    'path' => 'C:\\test\\perl\\lib\\Module',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'CE106BF1-5EE2-3816-9A2D-0F00286C6749',
                    'id' => 'CE106BF1_5EE2_3816_9A2D_0F00286C6749'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Test',
                    'path' => 'C:\\test\\perl\\lib\\Test',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '13EF26F9-C8E9-3439-9DD2-CE1506EF2826',
                    'id' => '13EF26F9_C8E9_3439_9DD2_CE1506EF2826'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Compress',
                        'path' => 'C:\\test\\perl\\lib\\auto\\Compress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'B5A75E38-F946-3B45-89F6-C763580585B6',
                        'id' => 'B5A75E38_F946_3B45_89F6_C763580585B6'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Cwd',
                        'path' => 'C:\\test\\perl\\lib\\auto\\Cwd',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'DA94853F-4398-35C1-A18E-1A5B9D5E4893',
                        'id' => 'DA94853F_4398_35C1_A18E_1A5B9D5E4893'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Devel',
                        'path' => 'C:\\test\\perl\\lib\\auto\\Devel',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '44A4B802-8C4F-35FB-A899-E94A0E835B7C',
                        'id' => '44A4B802_8C4F_35FB_A899_E94A0E835B7C'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'MD5',
                            'path' => 'C:\\test\\perl\\lib\\auto\\Digest\\MD5',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'AB05C8BB-D7D3-30E9-AC70-09DCA7E9B705',
                            'id' => 'AB05C8BB_D7D3_30E9_AC70_09DCA7E9B705'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Digest',
                        'path' => 'C:\\test\\perl\\lib\\auto\\Digest',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '8779B820-38EA-39E6-B723-2A94D0359610',
                        'id' => '8779B820_38EA_39E6_B723_2A94D0359610'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Encode',
                        'path' => 'C:\\test\\perl\\lib\\auto\\Encode',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '87731680-27B6-39F3-8156-750CE68BE417',
                        'id' => '87731680_27B6_39F3_8156_750CE68BE417'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [
                              bless( {
                                'sitename' => 'www.test.site.invalid',
                                'directories' => [],
                                'files' => [],
                                'entries' => [],
                                'name' => 'FastCalc',
                                'path' => 'C:\\test\\perl\\lib\\auto\\Math\\BigInt\\FastCalc',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '7DDFFBD5-6735-3BD7-8A1B-A84B3ABF564A',
                                'id' => '7DDFFBD5_6735_3BD7_8A1B_A84B3ABF564A'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => 'BigInt',
                            'path' => 'C:\\test\\perl\\lib\\auto\\Math\\BigInt',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '5CADB1DF-9C98-37E9-B078-3C4ED5736BED',
                            'id' => '5CADB1DF_9C98_37E9_B078_3C4ED5736BED'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Math',
                        'path' => 'C:\\test\\perl\\lib\\auto\\Math',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'CB17F5A3-6530-362E-A8D0-D3D42CB4794B',
                        'id' => 'CB17F5A3_6530_362E_A8D0_D3D42CB4794B'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'PerlIO',
                        'path' => 'C:\\test\\perl\\lib\\auto\\PerlIO',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '7E864D52-82FE-37C1-8FB4-BEDD92F5B4A5',
                        'id' => '7E864D52_82FE_37C1_8FB4_BEDD92F5B4A5'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'POSIX',
                        'path' => 'C:\\test\\perl\\lib\\auto\\POSIX',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '9D9FF976-F842-3CAB-A6C5-681CF3C41D95',
                        'id' => '9D9FF976_F842_3CAB_A6C5_681CF3C41D95'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Time',
                        'path' => 'C:\\test\\perl\\lib\\auto\\Time',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '853CDE42-1F58-3B81-9FC6-7DFB6A7986A3',
                        'id' => '853CDE42_1F58_3B81_9FC6_7DFB6A7986A3'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'share',
                        'path' => 'C:\\test\\perl\\lib\\auto\\share',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'FE794D95-EB30-343C-A8B4-35B8EC58F146',
                        'id' => 'FE794D95_EB30_343C_A8B4_35B8EC58F146'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'auto',
                    'path' => 'C:\\test\\perl\\lib\\auto',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '1EAEB13C-294E-3325-BC3B-135FE6E21463',
                    'id' => '1EAEB13C_294E_3325_BC3B_135FE6E21463'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'lib',
                'path' => 'C:\\test\\perl\\lib',
                'trace' => 0,
                'special' => 0,
                'guid' => '167768A4-449A-32CC-A0F4-3DCF273EDF69',
                'id' => '167768A4_449A_32CC_A0F4_3DCF273EDF69'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Bundle',
                        'path' => 'C:\\test\\perl\\site\\lib\\Bundle',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'D797137C-CBFF-386F-ADB3-666F9830DCA8',
                        'id' => 'D797137C_CBFF_386F_ADB3_666F9830DCA8'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Compress',
                        'path' => 'C:\\test\\perl\\site\\lib\\Compress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '50CB1D55-C1AE-35A4-BC21-DBC362C2A7A6',
                        'id' => '50CB1D55_C1AE_35A4_BC21_DBC362C2A7A6'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'DBD',
                        'path' => 'C:\\test\\perl\\site\\lib\\DBD',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'C108793B-2141-3D01-A59F-82357A983698',
                        'id' => 'C108793B_2141_3D01_A59F_82357A983698'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'File',
                        'path' => 'C:\\test\\perl\\site\\lib\\File',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '59FAF411-602A-3066-846D-07E4A9B8EB69',
                        'id' => '59FAF411_602A_3066_846D_07E4A9B8EB69'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'HTML',
                        'path' => 'C:\\test\\perl\\site\\lib\\HTML',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'D71A609A-E8F8-3E89-81E6-14081EE0ECA2',
                        'id' => 'D71A609A_E8F8_3E89_81E6_14081EE0ECA2'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'IO',
                        'path' => 'C:\\test\\perl\\site\\lib\\IO',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'CC536878-B286-3AD4-90F6-B9BACB6B692D',
                        'id' => 'CC536878_B286_3AD4_90F6_B9BACB6B692D'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'LWP',
                        'path' => 'C:\\test\\perl\\site\\lib\\LWP',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'E28DFF76-91BB-3EBB-8864-CD132FDD077E',
                        'id' => 'E28DFF76_91BB_3EBB_8864_CD132FDD077E'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Math',
                        'path' => 'C:\\test\\perl\\site\\lib\\Math',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '496E3E7C-A119-3614-8097-8AE576E025F0',
                        'id' => '496E3E7C_A119_3614_8097_8AE576E025F0'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'PAR',
                        'path' => 'C:\\test\\perl\\site\\lib\\PAR',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '0551B560-2A5A-32E4-855E-EBE43EC34DF8',
                        'id' => '0551B560_2A5A_32E4_855E_EBE43EC34DF8'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Term',
                        'path' => 'C:\\test\\perl\\site\\lib\\Term',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '93051433-B6F7-3599-97B2-700071DA0864',
                        'id' => '93051433_B6F7_3599_97B2_700071DA0864'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Test',
                        'path' => 'C:\\test\\perl\\site\\lib\\Test',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'BEE4F0BB-54AB-335D-AB1B-7D44249D1696',
                        'id' => 'BEE4F0BB_54AB_335D_AB1B_7D44249D1696'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Win32',
                        'path' => 'C:\\test\\perl\\site\\lib\\Win32',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '14F9992E-A451-3D44-AD43-D3A367B02031',
                        'id' => '14F9992E_A451_3D44_AD43_D3A367B02031'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'XML',
                        'path' => 'C:\\test\\perl\\site\\lib\\XML',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '633BBECE-77D7-30F6-9034-D39655638882',
                        'id' => '633BBECE_77D7_30F6_9034_D39655638882'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'share',
                            'path' => 'C:\\test\\perl\\site\\lib\\auto\\share',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'BC0402D3-9BD2-3987-B1B4-35EA398C6BEC',
                            'id' => 'BC0402D3_9BD2_3987_B1B4_35EA398C6BEC'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [
                              bless( {
                                'sitename' => 'www.test.site.invalid',
                                'directories' => [],
                                'files' => [],
                                'entries' => [],
                                'name' => 'Raw',
                                'path' => 'C:\\test\\perl\\site\\lib\\auto\\Compress\\Raw',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '4054B239-62D0-3344-BA98-6DA544EBC8A6',
                                'id' => '4054B239_62D0_3344_BA98_6DA544EBC8A6'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Compress',
                            'path' => 'C:\\test\\perl\\site\\lib\\auto\\Compress',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '245FDF54-DE1F-3B14-B45C-F591F12FF8FD',
                            'id' => '245FDF54_DE1F_3B14_B45C_F591F12FF8FD'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Math',
                            'path' => 'C:\\test\\perl\\site\\lib\\auto\\Math',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '6CE1EA06-9D83-3B72-B68C-375CB454C284',
                            'id' => '6CE1EA06_9D83_3B72_B68C_375CB454C284'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Term',
                            'path' => 'C:\\test\\perl\\site\\lib\\auto\\Term',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'EE6B1671-0C94-37EC-9C2E-84F5E42CA7BA',
                            'id' => 'EE6B1671_0C94_37EC_9C2E_84F5E42CA7BA'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Win32',
                            'path' => 'C:\\test\\perl\\site\\lib\\auto\\Win32',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'C0D9F7F3-8AA7-3A70-810C-FC5FC5F9AA56',
                            'id' => 'C0D9F7F3_8AA7_3A70_810C_FC5FC5F9AA56'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'XML',
                            'path' => 'C:\\test\\perl\\site\\lib\\auto\\XML',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'D2B863DE-1257-3C2A-A516-6406CEE125A0',
                            'id' => 'D2B863DE_1257_3C2A_A516_6406CEE125A0'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'auto',
                        'path' => 'C:\\test\\perl\\site\\lib\\auto',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '7212C99C-98FC-3CC2-B32B-986926035439',
                        'id' => '7212C99C_98FC_3CC2_B32B_986926035439'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'lib',
                    'path' => 'C:\\test\\perl\\site\\lib',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'B3D4AD98-92FD-3DCF-A3A5-26C8E2D252A3',
                    'id' => 'B3D4AD98_92FD_3DCF_A3A5_26C8E2D252A3'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'site',
                'path' => 'C:\\test\\perl\\site',
                'trace' => 0,
                'special' => 0,
                'guid' => '1BEF246B-FCD9-34B0-ABAA-5D90D198E4C9',
                'id' => '1BEF246B_FCD9_34B0_ABAA_5D90D198E4C9'
              }, 'Perl::Dist::WiX::Directory' )
            ],
            'files' => [],
            'entries' => [],
            'name' => 'perl',
            'path' => 'C:\\test\\perl',
            'trace' => 0,
            'special' => 0,
            'id' => 'Perl'
          }, 'Perl::Dist::WiX::Directory' ),
          bless( {
            'sitename' => 'www.test.site.invalid',
            'directories' => [
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'startup',
                    'path' => 'C:\\test\\c\\bin\\startup',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '1871D525-EA82-3FCD-A1DD-6545613FA8A5',
                    'id' => '1871D525_EA82_3FCD_A1DD_6545613FA8A5'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'bin',
                'path' => 'C:\\test\\c\\bin',
                'trace' => 0,
                'special' => 0,
                'guid' => 'F929E019-ED70-313B-BAFD-0F0F27FF0A4F',
                'id' => 'F929E019_ED70_313B_BAFD_0F0F27FF0A4F'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'backward',
                            'path' => 'C:\\test\\c\\include\\c++\\3.4.5\\backward',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'E6349AE4-B0D7-34C7-833A-5B1444369683',
                            'id' => 'E6349AE4_B0D7_34C7_833A_5B1444369683'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'bits',
                            'path' => 'C:\\test\\c\\include\\c++\\3.4.5\\bits',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'C3EB056B-8B9C-38F5-B80B-7AF310AB57B8',
                            'id' => 'C3EB056B_8B9C_38F5_B80B_7AF310AB57B8'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'debug',
                            'path' => 'C:\\test\\c\\include\\c++\\3.4.5\\debug',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '0BFD1700-7BDD-3E14-8878-BF46E4E1602C',
                            'id' => '0BFD1700_7BDD_3E14_8878_BF46E4E1602C'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'ext',
                            'path' => 'C:\\test\\c\\include\\c++\\3.4.5\\ext',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '2EB1CFBC-2688-3547-980A-96CB2B0BD574',
                            'id' => '2EB1CFBC_2688_3547_980A_96CB2B0BD574'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [
                              bless( {
                                'sitename' => 'www.test.site.invalid',
                                'directories' => [],
                                'files' => [],
                                'entries' => [],
                                'name' => 'bits',
                                'path' => 'C:\\test\\c\\include\\c++\\3.4.5\\mingw32\\bits',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '7F04A259-CADA-3CFC-A0B6-B75567F48201',
                                'id' => '7F04A259_CADA_3CFC_A0B6_B75567F48201'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => 'mingw32',
                            'path' => 'C:\\test\\c\\include\\c++\\3.4.5\\mingw32',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'F3F9A409-F0C0-378A-BFD7-8C06E94995AD',
                            'id' => 'F3F9A409_F0C0_378A_BFD7_8C06E94995AD'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => '3.4.5',
                        'path' => 'C:\\test\\c\\include\\c++\\3.4.5',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '0BD3E815-B406-3420-8279-5C17C43D3968',
                        'id' => '0BD3E815_B406_3420_8279_5C17C43D3968'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'c++',
                    'path' => 'C:\\test\\c\\include\\c++',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '4970DE0E-5BEC-34EA-BD37-9FE53647B20E',
                    'id' => '4970DE0E_5BEC_34EA_BD37_9FE53647B20E'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'ddk',
                    'path' => 'C:\\test\\c\\include\\ddk',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '25D1AF22-5FC8-3804-BBCD-75DE143DC68A',
                    'id' => '25D1AF22_5FC8_3804_BBCD_75DE143DC68A'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'gl',
                    'path' => 'C:\\test\\c\\include\\gl',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '04E8578B-77C2-3095-A0DB-209575994057',
                    'id' => '04E8578B_77C2_3095_A0DB_209575994057'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'libxml',
                    'path' => 'C:\\test\\c\\include\\libxml',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '65264A85-B764-346C-8343-700812E06884',
                    'id' => '65264A85_B764_346C_8343_700812E06884'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'sys',
                    'path' => 'C:\\test\\c\\include\\sys',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '95B154FE-05EE-3665-A1B4-9B055011A6A5',
                    'id' => '95B154FE_05EE_3665_A1B4_9B055011A6A5'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'include',
                'path' => 'C:\\test\\c\\include',
                'trace' => 0,
                'special' => 0,
                'guid' => '990EBE17-4FDD-3330-B77D-CC1780785AD9',
                'id' => '990EBE17_4FDD_3330_B77D_CC1780785AD9'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'debug',
                    'path' => 'C:\\test\\c\\lib\\debug',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'E764ADB9-9647-3B6F-8A99-DED1898EF040',
                    'id' => 'E764ADB9_9647_3B6F_8A99_DED1898EF040'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [
                              bless( {
                                'sitename' => 'www.test.site.invalid',
                                'directories' => [],
                                'files' => [],
                                'entries' => [],
                                'name' => 'include',
                                'path' => 'C:\\test\\c\\lib\\gcc\\mingw32\\3.4.5\\include',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '12AEE065-432E-3782-93D7-586F15D9129D',
                                'id' => '12AEE065_432E_3782_93D7_586F15D9129D'
                              }, 'Perl::Dist::WiX::Directory' ),
                              bless( {
                                'sitename' => 'www.test.site.invalid',
                                'directories' => [
                                  bless( {
                                    'sitename' => 'www.test.site.invalid',
                                    'directories' => [],
                                    'files' => [],
                                    'entries' => [],
                                    'name' => 'include',
                                    'path' => 'C:\\test\\c\\lib\\gcc\\mingw32\\3.4.5\\install-tools\\include',
                                    'trace' => 0,
                                    'special' => 0,
                                    'guid' => 'AF11F1AA-EB14-3594-926E-F8BACEF36342',
                                    'id' => 'AF11F1AA_EB14_3594_926E_F8BACEF36342'
                                  }, 'Perl::Dist::WiX::Directory' )
                                ],
                                'files' => [],
                                'entries' => [],
                                'name' => 'install-tools',
                                'path' => 'C:\\test\\c\\lib\\gcc\\mingw32\\3.4.5\\install-tools',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '1C0767F2-565D-361B-B0E0-5BB83F2AE405',
                                'id' => '1C0767F2_565D_361B_B0E0_5BB83F2AE405'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => '3.4.5',
                            'path' => 'C:\\test\\c\\lib\\gcc\\mingw32\\3.4.5',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '27704913-5FF2-36A8-B225-BF1E47B48413',
                            'id' => '27704913_5FF2_36A8_B225_BF1E47B48413'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'mingw32',
                        'path' => 'C:\\test\\c\\lib\\gcc\\mingw32',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '99F170D9-C69E-3361-A1F4-CA1869C0648E',
                        'id' => '99F170D9_C69E_3361_A1F4_CA1869C0648E'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'gcc',
                    'path' => 'C:\\test\\c\\lib\\gcc',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '6B140931-6C1B-3379-A4F1-FB678B3C2544',
                    'id' => '6B140931_6C1B_3379_A4F1_FB678B3C2544'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'lib',
                'path' => 'C:\\test\\c\\lib',
                'trace' => 0,
                'special' => 0,
                'guid' => '14230B50-C0DC-36E3-8931-C28F934C84B5',
                'id' => '14230B50_C0DC_36E3_8931_C28F934C84B5'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [
                              bless( {
                                'sitename' => 'www.test.site.invalid',
                                'directories' => [],
                                'files' => [],
                                'entries' => [],
                                'name' => 'install-tools',
                                'path' => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '870594AF-E302-36D9-AFE7-D999FA0DBBF6',
                                'id' => '870594AF_E302_36D9_AFE7_D999FA0DBBF6'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => '3.4.5',
                            'path' => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '97FE211B-F98C-3285-A75B-6F981AA3A19A',
                            'id' => '97FE211B_F98C_3285_A75B_6F981AA3A19A'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'mingw32',
                        'path' => 'C:\\test\\c\\libexec\\gcc\\mingw32',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '6E9B021B-04EE-3F14-A14C-919B80A6AC42',
                        'id' => '6E9B021B_04EE_3F14_A14C_919B80A6AC42'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'gcc',
                    'path' => 'C:\\test\\c\\libexec\\gcc',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '12545A33-2C38-3D6F-A2DA-267EE97FDE2F',
                    'id' => '12545A33_2C38_3D6F_A2DA_267EE97FDE2F'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'libexec',
                'path' => 'C:\\test\\c\\libexec',
                'trace' => 0,
                'special' => 0,
                'guid' => 'DD294F22-4FBF-321A-80BB-4CBD1A25C9DE',
                'id' => 'DD294F22_4FBF_321A_80BB_4CBD1A25C9DE'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'bin',
                    'path' => 'C:\\test\\c\\mingw32\\bin',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '4082B714-94AE-3055-A142-8AAC4D0F817A',
                    'id' => '4082B714_94AE_3055_A142_8AAC4D0F817A'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'ld-scripts',
                        'path' => 'C:\\test\\c\\mingw32\\lib\\ld-scripts',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '1733B110-8009-3A78-BBA9-3CD4327C357D',
                        'id' => '1733B110_8009_3A78_BBA9_3CD4327C357D'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'lib',
                    'path' => 'C:\\test\\c\\mingw32\\lib',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '5E14DB0D-DF32-3502-9ABD-8B4B164CDE1A',
                    'id' => '5E14DB0D_DF32_3502_9ABD_8B4B164CDE1A'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'mingw32',
                'path' => 'C:\\test\\c\\mingw32',
                'trace' => 0,
                'special' => 0,
                'guid' => '2470DFE7-CB83-3A8E-8821-BE8F36A4DB79',
                'id' => '2470DFE7_CB83_3A8E_8821_BE8F36A4DB79'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'locale',
                    'path' => 'C:\\test\\c\\share\\locale',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '3AD5DB9D-61F5-3101-89F4-D4AD38190F21',
                    'id' => '3AD5DB9D_61F5_3101_89F4_D4AD38190F21'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'share',
                'path' => 'C:\\test\\c\\share',
                'trace' => 0,
                'special' => 0,
                'guid' => 'BF54B1C7-EF09-3458-B556-2B9279AD2BBD',
                'id' => 'BF54B1C7_EF09_3458_B556_2B9279AD2BBD'
              }, 'Perl::Dist::WiX::Directory' )
            ],
            'files' => [],
            'entries' => [],
            'name' => 'c',
            'path' => 'C:\\test\\c',
            'trace' => 0,
            'special' => 0,
            'id' => 'Toolchain'
          }, 'Perl::Dist::WiX::Directory' ),
          bless( {
            'sitename' => 'www.test.site.invalid',
            'directories' => [
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'dmake',
                'path' => 'C:\\test\\licenses\\dmake',
                'trace' => 0,
                'special' => 0,
                'guid' => '818D6C63-4B20-30FD-A5F0-019BE9408F83',
                'id' => '818D6C63_4B20_30FD_A5F0_019BE9408F83'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'gcc',
                'path' => 'C:\\test\\licenses\\gcc',
                'trace' => 0,
                'special' => 0,
                'guid' => 'B8131B88-3ABA-3EE1-BF5C-E3E81E0539E4',
                'id' => 'B8131B88_3ABA_3EE1_BF5C_E3E81E0539E4'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'mingw',
                'path' => 'C:\\test\\licenses\\mingw',
                'trace' => 0,
                'special' => 0,
                'guid' => '8D5645E4-03EC-3E0A-84A4-DA619495CFB5',
                'id' => '8D5645E4_03EC_3E0A_84A4_DA619495CFB5'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'perl',
                'path' => 'C:\\test\\licenses\\perl',
                'trace' => 0,
                'special' => 0,
                'guid' => '3C916D82-47FE-34CE-8BDD-C793099E8A68',
                'id' => '3C916D82_47FE_34CE_8BDD_C793099E8A68'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'pexports',
                'path' => 'C:\\test\\licenses\\pexports',
                'trace' => 0,
                'special' => 0,
                'guid' => '4EAD5660-DA82-3DCB-A86A-D96BE1DF90FA',
                'id' => '4EAD5660_DA82_3DCB_A86A_D96BE1DF90FA'
              }, 'Perl::Dist::WiX::Directory' )
            ],
            'files' => [],
            'entries' => [],
            'name' => 'licenses',
            'path' => 'C:\\test\\licenses',
            'trace' => 0,
            'special' => 0,
            'id' => 'License'
          }, 'Perl::Dist::WiX::Directory' ),
          bless( {
            'sitename' => 'www.test.site.invalid',
            'directories' => [],
            'files' => [],
            'entries' => [],
            'name' => 'cpan',
            'path' => 'C:\\test\\cpan',
            'trace' => 0,
            'special' => 0,
            'id' => 'Cpan'
          }, 'Perl::Dist::WiX::Directory' ),
          bless( {
            'sitename' => 'www.test.site.invalid',
            'directories' => [],
            'files' => [],
            'entries' => [],
            'name' => 'win32',
            'path' => 'C:\\test\\win32',
            'trace' => 0,
            'special' => 0,
            'id' => 'Win32'
          }, 'Perl::Dist::WiX::Directory' )
        ],
        'files' => [],
        'entries' => [],
        'name' => '[INSTALLDIR]',
        'path' => 'C:\\test',
        'trace' => 0,
        'special' => 0,
        'id' => 'App_Root'
      }, 'Perl::Dist::WiX::Directory' ),
      bless( {
        'trace' => 0,
        'sitename' => 'www.test.site.invalid',
        'special' => 2,
        'directories' => [
          bless( {
            'sitename' => 'www.test.site.invalid',
            'directories' => [],
            'files' => [],
            'entries' => [],
            'name' => 'Test Perl',
            'trace' => 0,
            'special' => 1,
            'id' => 'App_Menu'
          }, 'Perl::Dist::WiX::Directory' )
        ],
        'files' => [],
        'entries' => [],
        'id' => 'ProgramMenuFolder'
      }, 'Perl::Dist::WiX::Directory' )
    ],
    'files' => [],
    'entries' => [],
    'name' => 'SourceDir',
    'trace' => 0,
    'special' => 1,
    'id' => 'TARGETDIR'
  }, 'Perl::Dist::WiX::Directory' ),
  'app_dir' => 'C:\\test'
}, 'Perl::Dist::WiX::DirectoryTree' );

is_deeply($tree, $tree_test_2, 'Initializes itself correctly');

# Tests 7-10 are successful finds.

# Test 7 (Test 8 at line 1587)

my $dir = $tree->search_dir(
    path_to_find => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
    exact => 1,
    descend => 1,
);

my $dir_test_1 = bless( {
  'sitename' => 'www.test.site.invalid',
  'directories' => [],
  'files' => [],
  'entries' => [],
  'name' => 'install-tools',
  'path' => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
  'trace' => 0,
  'special' => 0,
  'guid' => '870594AF-E302-36D9-AFE7-D999FA0DBBF6',
  'id' => '870594AF_E302_36D9_AFE7_D999FA0DBBF6'
}, 'Perl::Dist::WiX::Directory' );

is_deeply($dir, $dir_test_1, 'Successful search, descend=1 exact=1');

# Test 8 (Test 9 at line 1609)

$dir = $tree->search_dir(
    path_to_find => 'C:\\test\\win32',
    exact => 1,
    descend => 0,
);

my $dir_test_2 = bless( {
  'sitename' => 'www.test.site.invalid',
  'directories' => [],
  'files' => [],
  'entries' => [],
  'name' => 'win32',
  'path' => 'C:\\test\\win32',
  'trace' => 0,
  'special' => 0,
  'id' => 'Win32'
}, 'Perl::Dist::WiX::Directory' );

is_deeply($dir, $dir_test_2, 'Successful search, descend=0 exact=1');

# Test 9

$dir = $tree->search_dir(
    path_to_find => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
    exact => 0,
    descend => 1,
);

is_deeply($dir, $dir_test_1, 'Successful search, descend=1 exact=0');

# Test 10

$dir = $tree->search_dir(
    path_to_find => 'C:\\test\\win32\\x',
    exact => 0,
    descend => 0,
);

is_deeply($dir, $dir_test_2, 'Successful search, descend=0 exact=0');

# Tests 11-14 are unsuccessful searches

# Test 11

$dir = $tree->search_dir(
    path_to_find => 'C:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
    exact => 1,
    descend => 1,
);

ok((not defined $dir), 'Unsuccessful search, descend=1 exact=1');

# Test 12

$dir = $tree->search_dir(
    path_to_find => 'C:\\test\\win32\\x',
    exact => 1,
    descend => 0,
);

ok((not defined $dir), 'Unsuccessful search, descend=1 exact=0');

# Test 13

$dir = $tree->search_dir(
    path_to_find => 'C:\\xtest\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
    exact => 0,
    descend => 1,
);

ok((not defined $dir), 'Unsuccessful search, descend=0 exact=1');

# Test 14

$dir = $tree->search_dir(
    path_to_find => 'C:\\xtest\\win33',
    exact => 0,
    descend => 0,
);

ok((not defined $dir), 'Unsuccessful search, descend=0 exact=0');

