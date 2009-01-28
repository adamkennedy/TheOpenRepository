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
    app_dir => 'c:\\test', 
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
                 'app_dir' => 'c:\\test'
               }, 'Perl::Dist::WiX::DirectoryTree' );

is_deeply( $tree, $tree_test_1, 'Object created correctly' );

# Test 4 (Test 5 at line 208)
              
my $string_test = '    <Directory Id=\'TARGETDIR\' Name=\'SourceDir\'>
      <Directory Id=\'D_App_Root\' Name=\'[INSTALLDIR]\'>
        <Directory Id=\'D_Perl\' Name=\'perl\'>
          <Directory Id=\'D_226714C2_4FE7_3E13_A8CD_4AECA493A891\' Name=\'bin\' />
          <Directory Id=\'D_0771F5A2_E78C_3A87_BA9B_B620D7EF801D\' Name=\'lib\'>
            <Directory Id=\'D_B5C62DCD_1159_3520_AF24_B0DDC0DB7B4E\' Name=\'Compress\' />
            <Directory Id=\'D_19F728A5_7E97_393A_A908_E6FFA4599FDE\' Name=\'CPAN\'>
              <Directory Id=\'D_150AEA8F_70A6_373F_897A_1FB013476475\' Name=\'API\' />
            </Directory>
            <Directory Id=\'D_E4CADB28_B6F1_3D6E_997A_831A9560B41F\' Name=\'Digest\'>
              <Directory Id=\'D_91A53F97_5598_3D39_AC5D_F9086C8890C3\' Name=\'MD5\' />
            </Directory>
            <Directory Id=\'D_D9B35910_AA20_33DA_A03D_15AEF231387D\' Name=\'ExtUtils\'>
              <Directory Id=\'D_B8909B28_D2CB_3C5E_BE93_4297183B15F3\' Name=\'CBuilder\'>
                <Directory Id=\'D_CC9CA1C5_F008_3B93_80F7_F36EE0F9E9FD\' Name=\'Platform\' />
              </Directory>
            </Directory>
            <Directory Id=\'D_4E9FB20F_95A0_3338_8F17_578A18A9E069\' Name=\'File\' />
            <Directory Id=\'D_0DB7D421_1C6B_39D6_BB8F_735744E56EE2\' Name=\'IO\'>
              <Directory Id=\'D_303DA090_5203_3909_ADEA_E140A327F783\' Name=\'Compress\'>
                <Directory Id=\'D_6FD5B45D_DE9F_30DC_AB00_B295755682FA\' Name=\'Adapter\' />
                <Directory Id=\'D_2E454F6F_C015_3AEF_AE14_4E263E26D5E0\' Name=\'Base\' />
                <Directory Id=\'D_45F36C9F_F143_3747_8F1A_6E883A95584F\' Name=\'Gzip\' />
                <Directory Id=\'D_94DFFE7C_BFD7_3671_9215_4F3955040AB6\' Name=\'Zip\' />
              </Directory>
              <Directory Id=\'D_E8D0A84C_085E_35C0_ACCC_3A737F038890\' Name=\'Uncompress\'>
                <Directory Id=\'D_5E3A74C4_FA9B_390D_985F_893180CBF049\' Name=\'Adapter\' />
              </Directory>
            </Directory>
            <Directory Id=\'D_BA1B90E4_CA72_3D67_8F81_BE2EC9667379\' Name=\'Math\'>
              <Directory Id=\'D_8C30DD5B_9A38_3595_9A4A_6D15C649EF47\' Name=\'BigInt\'>
                <Directory Id=\'D_C62EE46D_4134_3871_A579_EE80772B542E\' Name=\'FastCalc\' />
              </Directory>
            </Directory>
            <Directory Id=\'D_9D128CAB_C805_35B3_80DE_BCC74D9B18C0\' Name=\'Module\' />
            <Directory Id=\'D_3457B94D_E013_3F81_88E9_35C5CFA57F92\' Name=\'Test\' />
            <Directory Id=\'D_34F039B4_89BC_30E3_A5A9_34B40037EB6D\' Name=\'auto\'>
              <Directory Id=\'D_FFCEA462_B5F9_396D_88AD_C662EAB85721\' Name=\'Compress\' />
              <Directory Id=\'D_60FF52F4_7130_37CE_A50F_D26B75E074BD\' Name=\'Cwd\' />
              <Directory Id=\'D_01FF5FAB_5F8E_3369_B3AA_20D4395D51D1\' Name=\'Devel\' />
              <Directory Id=\'D_EDBBC989_D08A_3829_83F0_72D810401E6D\' Name=\'Digest\'>
                <Directory Id=\'D_82AF33BC_A346_3E56_A95C_7410AA4B3430\' Name=\'MD5\' />
              </Directory>
              <Directory Id=\'D_A0FE6AC0_44AF_39E4_B49C_DE76B704C013\' Name=\'Encode\' />
              <Directory Id=\'D_15E729EC_C5BF_3FA7_8F43_BFD548013873\' Name=\'Math\'>
                <Directory Id=\'D_DB1FE4D3_CF25_3993_9C1A_8F247C25197F\' Name=\'BigInt\'>
                  <Directory Id=\'D_60351E49_C426_3523_9CB2_0A71ECDCB1DD\' Name=\'FastCalc\' />
                </Directory>
              </Directory>
              <Directory Id=\'D_ADFBF2FE_A76A_3C05_8389_4EC03A63931D\' Name=\'PerlIO\' />
              <Directory Id=\'D_9B02F097_DB37_3C38_A839_EDC474CBA087\' Name=\'POSIX\' />
              <Directory Id=\'D_E723F059_3FD7_3D30_9E06_B70381275136\' Name=\'Time\' />
              <Directory Id=\'D_4826C7F9_09CC_379E_A241_28689B815CFF\' Name=\'share\' />
            </Directory>
          </Directory>
          <Directory Id=\'D_61C86B69_E8DF_34BA_8EE6_AB952A84E83F\' Name=\'site\'>
            <Directory Id=\'D_5352248B_E15C_36A5_9451_3117A96F42D8\' Name=\'lib\'>
              <Directory Id=\'D_EA3D10B3_8C39_3CD6_8106_4F2A1C331D23\' Name=\'Bundle\' />
              <Directory Id=\'D_F774DA5A_1A9C_3528_BB99_978861A60E2D\' Name=\'Compress\' />
              <Directory Id=\'D_31F13D4F_7B11_3043_9124_7D28D8D4A0C3\' Name=\'DBD\' />
              <Directory Id=\'D_CBCF6E21_6BAE_33AC_B8C9_DFC7B3106868\' Name=\'File\' />
              <Directory Id=\'D_304EE39C_C7A4_3096_A8AD_07B59ECBB3D5\' Name=\'HTML\' />
              <Directory Id=\'D_04CCCDBA_2BCF_33A9_B260_AF7C112A790E\' Name=\'IO\' />
              <Directory Id=\'D_A8C9E86E_CD80_3D58_B2F2_4832E3EBEDAD\' Name=\'LWP\' />
              <Directory Id=\'D_6EA69F29_DFA4_33B1_A4CF_6E2AA3C8CEAB\' Name=\'Math\' />
              <Directory Id=\'D_49085693_E88D_3D4A_BFE5_7DBC28D63E10\' Name=\'PAR\' />
              <Directory Id=\'D_E9101245_170C_3E04_B816_416DE081C03F\' Name=\'Term\' />
              <Directory Id=\'D_AECD900B_AC2C_3C07_9899_96454B7DFB9D\' Name=\'Test\' />
              <Directory Id=\'D_FB57F243_643D_3BD3_A8FB_E68D7EA0E9FB\' Name=\'Win32\' />
              <Directory Id=\'D_9D57212D_4847_3102_9FA9_89259497CB20\' Name=\'XML\' />
              <Directory Id=\'D_6D9C03D5_B041_3C7B_B6CD_F95F3B986D7B\' Name=\'auto\'>
                <Directory Id=\'D_BBFE98DE_746C_3C9F_B9D3_D789BEDB72BE\' Name=\'share\' />
                <Directory Id=\'D_56764A56_6248_3449_A4B0_B9A4A15DF5D2\' Name=\'Compress\'>
                  <Directory Id=\'D_CEA11F02_4448_391F_8E06_E2CFC3883655\' Name=\'Raw\' />
                </Directory>
                <Directory Id=\'D_C3368635_B44C_3089_A67E_BACC4E203DCE\' Name=\'Math\' />
                <Directory Id=\'D_6D1134CE_3970_3BD8_82CF_332FC61F4B40\' Name=\'Term\' />
                <Directory Id=\'D_21CB059D_089A_3C6B_815F_73F341933F43\' Name=\'Win32\' />
                <Directory Id=\'D_4BE6EA31_4235_3FA2_8954_6A7D0BC10753\' Name=\'XML\' />
              </Directory>
            </Directory>
          </Directory>
        </Directory>
        <Directory Id=\'D_Toolchain\' Name=\'c\'>
          <Directory Id=\'D_E7951DB0_3670_3141_B27D_82B6379A1904\' Name=\'bin\'>
            <Directory Id=\'D_AB8356A1_7A35_384D_BEFD_540DDAC1B712\' Name=\'startup\' />
          </Directory>
          <Directory Id=\'D_62A1622F_2B98_3C62_BF8C_7624BD39F8A0\' Name=\'include\'>
            <Directory Id=\'D_2EB09ABE_ABD0_3A5B_984C_1188CE67A1DF\' Name=\'c++\'>
              <Directory Id=\'D_747FEA5C_0351_33FC_B58C_CD52F33BA97C\' Name=\'3.4.5\'>
                <Directory Id=\'D_7B87D6D1_14D3_3B8D_AEFD_2AE5CF66E8CE\' Name=\'backward\' />
                <Directory Id=\'D_1BDC98D9_E0B0_3FC1_B3E0_27DB971F46C6\' Name=\'bits\' />
                <Directory Id=\'D_DCDE3775_CE83_3BC6_82E7_98238A11AEAC\' Name=\'debug\' />
                <Directory Id=\'D_12E80322_CF7D_36C5_8581_B600853B8861\' Name=\'ext\' />
                <Directory Id=\'D_DFF47235_0840_364B_8C8E_4F70233CD620\' Name=\'mingw32\'>
                  <Directory Id=\'D_C571B7DB_6EA8_3023_B048_8E0DB5418D04\' Name=\'bits\' />
                </Directory>
              </Directory>
            </Directory>
            <Directory Id=\'D_1882D24C_60A1_3AA4_A28C_67699862B29D\' Name=\'ddk\' />
            <Directory Id=\'D_799E7C3A_0BAC_35CB_B683_CE3846B873DD\' Name=\'gl\' />
            <Directory Id=\'D_521DF9CB_8AAE_3BA5_9C39_0DB97EB8CC4E\' Name=\'libxml\' />
            <Directory Id=\'D_A43300F4_1A69_3AAE_84EA_E540EE1E62A5\' Name=\'sys\' />
          </Directory>
          <Directory Id=\'D_1F37D408_4CF1_3347_85A9_CDB762981D87\' Name=\'lib\'>
            <Directory Id=\'D_83387D01_0432_3886_B959_D429B83C513A\' Name=\'debug\' />
            <Directory Id=\'D_C23B9704_4061_3BCF_AD06_54861E166CBA\' Name=\'gcc\'>
              <Directory Id=\'D_4B3EDA82_D137_3675_A64C_80E51B6036C7\' Name=\'mingw32\'>
                <Directory Id=\'D_74CB2FE8_F5F1_304A_86BD_36FD455CFB6C\' Name=\'3.4.5\'>
                  <Directory Id=\'D_D5AB2EDA_4C44_37B7_8FA8_6F5BF3E39CC7\' Name=\'include\' />
                  <Directory Id=\'D_C26AC4C0_CF1E_34EA_A9E4_3302CB7D6829\' Name=\'install-tools\'>
                    <Directory Id=\'D_A50C5F78_5156_3D6A_8D48_B6353F4852BD\' Name=\'include\' />
                  </Directory>
                </Directory>
              </Directory>
            </Directory>
          </Directory>
          <Directory Id=\'D_5F7950A1_CE06_3EA3_91B3_36AB475E55E6\' Name=\'libexec\'>
            <Directory Id=\'D_C3B1D355_F724_3030_B3EE_7E17D9D1469B\' Name=\'gcc\'>
              <Directory Id=\'D_B95420E6_BCE4_36F0_B9B1_D4B02B9CB627\' Name=\'mingw32\'>
                <Directory Id=\'D_2AD02341_566E_3714_8D44_A1A948AB0C3A\' Name=\'3.4.5\'>
                  <Directory Id=\'D_5AD17DCF_390D_3E49_B0E7_473FCD9C86D9\' Name=\'install-tools\' />
                </Directory>
              </Directory>
            </Directory>
          </Directory>
          <Directory Id=\'D_F912A172_D30E_36E7_BDAC_25615B2B5E16\' Name=\'mingw32\'>
            <Directory Id=\'D_A189758F_34E7_370F_A43C_EA46BCA6B3D7\' Name=\'bin\' />
            <Directory Id=\'D_1A8EE004_8346_3CAD_8235_744BA37E1C5C\' Name=\'lib\'>
              <Directory Id=\'D_3E24DE86_B16A_3011_8A11_0959F3EECEEE\' Name=\'ld-scripts\' />
            </Directory>
          </Directory>
          <Directory Id=\'D_1F2C0433_32FF_33F4_9C12_F1C67A1DEA54\' Name=\'share\'>
            <Directory Id=\'D_E5AFC90F_83E1_3F25_BFC0_B1BF19E9E7DE\' Name=\'locale\' />
          </Directory>
        </Directory>
        <Directory Id=\'D_License\' Name=\'licenses\'>
          <Directory Id=\'D_977F59D0_E7F7_366F_B13C_BC89552F128C\' Name=\'dmake\' />
          <Directory Id=\'D_E4AA909E_1F62_3290_B20B_2BAEC97B27FB\' Name=\'gcc\' />
          <Directory Id=\'D_9E7C617F_EF97_3904_99E7_3523638C41EA\' Name=\'mingw\' />
          <Directory Id=\'D_0607AA79_6734_3D85_B7FB_1C02FFD98184\' Name=\'perl\' />
          <Directory Id=\'D_A80C3022_7E7A_3763_9F1B_EE7FF718146C\' Name=\'pexports\' />
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

# Test 6 (Test 7 at line 1561)

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
                'path' => 'c:\\test\\perl\\bin',
                'trace' => 0,
                'special' => 0,
                'guid' => '226714C2-4FE7-3E13-A8CD-4AECA493A891',
                'id' => '226714C2_4FE7_3E13_A8CD_4AECA493A891'
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
                    'path' => 'c:\\test\\perl\\lib\\Compress',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'B5C62DCD-1159-3520-AF24-B0DDC0DB7B4E',
                    'id' => 'B5C62DCD_1159_3520_AF24_B0DDC0DB7B4E'
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
                        'path' => 'c:\\test\\perl\\lib\\CPAN\\API',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '150AEA8F-70A6-373F-897A-1FB013476475',
                        'id' => '150AEA8F_70A6_373F_897A_1FB013476475'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'CPAN',
                    'path' => 'c:\\test\\perl\\lib\\CPAN',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '19F728A5-7E97-393A-A908-E6FFA4599FDE',
                    'id' => '19F728A5_7E97_393A_A908_E6FFA4599FDE'
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
                        'path' => 'c:\\test\\perl\\lib\\Digest\\MD5',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '91A53F97-5598-3D39-AC5D-F9086C8890C3',
                        'id' => '91A53F97_5598_3D39_AC5D_F9086C8890C3'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Digest',
                    'path' => 'c:\\test\\perl\\lib\\Digest',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'E4CADB28-B6F1-3D6E-997A-831A9560B41F',
                    'id' => 'E4CADB28_B6F1_3D6E_997A_831A9560B41F'
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
                            'path' => 'c:\\test\\perl\\lib\\ExtUtils\\CBuilder\\Platform',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'CC9CA1C5-F008-3B93-80F7-F36EE0F9E9FD',
                            'id' => 'CC9CA1C5_F008_3B93_80F7_F36EE0F9E9FD'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'CBuilder',
                        'path' => 'c:\\test\\perl\\lib\\ExtUtils\\CBuilder',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'B8909B28-D2CB-3C5E-BE93-4297183B15F3',
                        'id' => 'B8909B28_D2CB_3C5E_BE93_4297183B15F3'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'ExtUtils',
                    'path' => 'c:\\test\\perl\\lib\\ExtUtils',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'D9B35910-AA20-33DA-A03D-15AEF231387D',
                    'id' => 'D9B35910_AA20_33DA_A03D_15AEF231387D'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'File',
                    'path' => 'c:\\test\\perl\\lib\\File',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '4E9FB20F-95A0-3338-8F17-578A18A9E069',
                    'id' => '4E9FB20F_95A0_3338_8F17_578A18A9E069'
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
                            'path' => 'c:\\test\\perl\\lib\\IO\\Compress\\Adapter',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '6FD5B45D-DE9F-30DC-AB00-B295755682FA',
                            'id' => '6FD5B45D_DE9F_30DC_AB00_B295755682FA'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Base',
                            'path' => 'c:\\test\\perl\\lib\\IO\\Compress\\Base',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '2E454F6F-C015-3AEF-AE14-4E263E26D5E0',
                            'id' => '2E454F6F_C015_3AEF_AE14_4E263E26D5E0'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Gzip',
                            'path' => 'c:\\test\\perl\\lib\\IO\\Compress\\Gzip',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '45F36C9F-F143-3747-8F1A-6E883A95584F',
                            'id' => '45F36C9F_F143_3747_8F1A_6E883A95584F'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Zip',
                            'path' => 'c:\\test\\perl\\lib\\IO\\Compress\\Zip',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '94DFFE7C-BFD7-3671-9215-4F3955040AB6',
                            'id' => '94DFFE7C_BFD7_3671_9215_4F3955040AB6'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Compress',
                        'path' => 'c:\\test\\perl\\lib\\IO\\Compress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '303DA090-5203-3909-ADEA-E140A327F783',
                        'id' => '303DA090_5203_3909_ADEA_E140A327F783'
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
                            'path' => 'c:\\test\\perl\\lib\\IO\\Uncompress\\Adapter',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '5E3A74C4-FA9B-390D-985F-893180CBF049',
                            'id' => '5E3A74C4_FA9B_390D_985F_893180CBF049'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Uncompress',
                        'path' => 'c:\\test\\perl\\lib\\IO\\Uncompress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'E8D0A84C-085E-35C0-ACCC-3A737F038890',
                        'id' => 'E8D0A84C_085E_35C0_ACCC_3A737F038890'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'IO',
                    'path' => 'c:\\test\\perl\\lib\\IO',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '0DB7D421-1C6B-39D6-BB8F-735744E56EE2',
                    'id' => '0DB7D421_1C6B_39D6_BB8F_735744E56EE2'
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
                            'path' => 'c:\\test\\perl\\lib\\Math\\BigInt\\FastCalc',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'C62EE46D-4134-3871-A579-EE80772B542E',
                            'id' => 'C62EE46D_4134_3871_A579_EE80772B542E'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'BigInt',
                        'path' => 'c:\\test\\perl\\lib\\Math\\BigInt',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '8C30DD5B-9A38-3595-9A4A-6D15C649EF47',
                        'id' => '8C30DD5B_9A38_3595_9A4A_6D15C649EF47'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Math',
                    'path' => 'c:\\test\\perl\\lib\\Math',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'BA1B90E4-CA72-3D67-8F81-BE2EC9667379',
                    'id' => 'BA1B90E4_CA72_3D67_8F81_BE2EC9667379'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Module',
                    'path' => 'c:\\test\\perl\\lib\\Module',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '9D128CAB-C805-35B3-80DE-BCC74D9B18C0',
                    'id' => '9D128CAB_C805_35B3_80DE_BCC74D9B18C0'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'Test',
                    'path' => 'c:\\test\\perl\\lib\\Test',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '3457B94D-E013-3F81-88E9-35C5CFA57F92',
                    'id' => '3457B94D_E013_3F81_88E9_35C5CFA57F92'
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
                        'path' => 'c:\\test\\perl\\lib\\auto\\Compress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'FFCEA462-B5F9-396D-88AD-C662EAB85721',
                        'id' => 'FFCEA462_B5F9_396D_88AD_C662EAB85721'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Cwd',
                        'path' => 'c:\\test\\perl\\lib\\auto\\Cwd',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '60FF52F4-7130-37CE-A50F-D26B75E074BD',
                        'id' => '60FF52F4_7130_37CE_A50F_D26B75E074BD'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Devel',
                        'path' => 'c:\\test\\perl\\lib\\auto\\Devel',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '01FF5FAB-5F8E-3369-B3AA-20D4395D51D1',
                        'id' => '01FF5FAB_5F8E_3369_B3AA_20D4395D51D1'
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
                            'path' => 'c:\\test\\perl\\lib\\auto\\Digest\\MD5',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '82AF33BC-A346-3E56-A95C-7410AA4B3430',
                            'id' => '82AF33BC_A346_3E56_A95C_7410AA4B3430'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Digest',
                        'path' => 'c:\\test\\perl\\lib\\auto\\Digest',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'EDBBC989-D08A-3829-83F0-72D810401E6D',
                        'id' => 'EDBBC989_D08A_3829_83F0_72D810401E6D'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Encode',
                        'path' => 'c:\\test\\perl\\lib\\auto\\Encode',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'A0FE6AC0-44AF-39E4-B49C-DE76B704C013',
                        'id' => 'A0FE6AC0_44AF_39E4_B49C_DE76B704C013'
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
                                'path' => 'c:\\test\\perl\\lib\\auto\\Math\\BigInt\\FastCalc',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '60351E49-C426-3523-9CB2-0A71ECDCB1DD',
                                'id' => '60351E49_C426_3523_9CB2_0A71ECDCB1DD'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => 'BigInt',
                            'path' => 'c:\\test\\perl\\lib\\auto\\Math\\BigInt',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'DB1FE4D3-CF25-3993-9C1A-8F247C25197F',
                            'id' => 'DB1FE4D3_CF25_3993_9C1A_8F247C25197F'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Math',
                        'path' => 'c:\\test\\perl\\lib\\auto\\Math',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '15E729EC-C5BF-3FA7-8F43-BFD548013873',
                        'id' => '15E729EC_C5BF_3FA7_8F43_BFD548013873'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'PerlIO',
                        'path' => 'c:\\test\\perl\\lib\\auto\\PerlIO',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'ADFBF2FE-A76A-3C05-8389-4EC03A63931D',
                        'id' => 'ADFBF2FE_A76A_3C05_8389_4EC03A63931D'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'POSIX',
                        'path' => 'c:\\test\\perl\\lib\\auto\\POSIX',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '9B02F097-DB37-3C38-A839-EDC474CBA087',
                        'id' => '9B02F097_DB37_3C38_A839_EDC474CBA087'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Time',
                        'path' => 'c:\\test\\perl\\lib\\auto\\Time',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'E723F059-3FD7-3D30-9E06-B70381275136',
                        'id' => 'E723F059_3FD7_3D30_9E06_B70381275136'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'share',
                        'path' => 'c:\\test\\perl\\lib\\auto\\share',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '4826C7F9-09CC-379E-A241-28689B815CFF',
                        'id' => '4826C7F9_09CC_379E_A241_28689B815CFF'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'auto',
                    'path' => 'c:\\test\\perl\\lib\\auto',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '34F039B4-89BC-30E3-A5A9-34B40037EB6D',
                    'id' => '34F039B4_89BC_30E3_A5A9_34B40037EB6D'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'lib',
                'path' => 'c:\\test\\perl\\lib',
                'trace' => 0,
                'special' => 0,
                'guid' => '0771F5A2-E78C-3A87-BA9B-B620D7EF801D',
                'id' => '0771F5A2_E78C_3A87_BA9B_B620D7EF801D'
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
                        'path' => 'c:\\test\\perl\\site\\lib\\Bundle',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'EA3D10B3-8C39-3CD6-8106-4F2A1C331D23',
                        'id' => 'EA3D10B3_8C39_3CD6_8106_4F2A1C331D23'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Compress',
                        'path' => 'c:\\test\\perl\\site\\lib\\Compress',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'F774DA5A-1A9C-3528-BB99-978861A60E2D',
                        'id' => 'F774DA5A_1A9C_3528_BB99_978861A60E2D'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'DBD',
                        'path' => 'c:\\test\\perl\\site\\lib\\DBD',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '31F13D4F-7B11-3043-9124-7D28D8D4A0C3',
                        'id' => '31F13D4F_7B11_3043_9124_7D28D8D4A0C3'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'File',
                        'path' => 'c:\\test\\perl\\site\\lib\\File',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'CBCF6E21-6BAE-33AC-B8C9-DFC7B3106868',
                        'id' => 'CBCF6E21_6BAE_33AC_B8C9_DFC7B3106868'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'HTML',
                        'path' => 'c:\\test\\perl\\site\\lib\\HTML',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '304EE39C-C7A4-3096-A8AD-07B59ECBB3D5',
                        'id' => '304EE39C_C7A4_3096_A8AD_07B59ECBB3D5'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'IO',
                        'path' => 'c:\\test\\perl\\site\\lib\\IO',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '04CCCDBA-2BCF-33A9-B260-AF7C112A790E',
                        'id' => '04CCCDBA_2BCF_33A9_B260_AF7C112A790E'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'LWP',
                        'path' => 'c:\\test\\perl\\site\\lib\\LWP',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'A8C9E86E-CD80-3D58-B2F2-4832E3EBEDAD',
                        'id' => 'A8C9E86E_CD80_3D58_B2F2_4832E3EBEDAD'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Math',
                        'path' => 'c:\\test\\perl\\site\\lib\\Math',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '6EA69F29-DFA4-33B1-A4CF-6E2AA3C8CEAB',
                        'id' => '6EA69F29_DFA4_33B1_A4CF_6E2AA3C8CEAB'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'PAR',
                        'path' => 'c:\\test\\perl\\site\\lib\\PAR',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '49085693-E88D-3D4A-BFE5-7DBC28D63E10',
                        'id' => '49085693_E88D_3D4A_BFE5_7DBC28D63E10'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Term',
                        'path' => 'c:\\test\\perl\\site\\lib\\Term',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'E9101245-170C-3E04-B816-416DE081C03F',
                        'id' => 'E9101245_170C_3E04_B816_416DE081C03F'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Test',
                        'path' => 'c:\\test\\perl\\site\\lib\\Test',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'AECD900B-AC2C-3C07-9899-96454B7DFB9D',
                        'id' => 'AECD900B_AC2C_3C07_9899_96454B7DFB9D'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'Win32',
                        'path' => 'c:\\test\\perl\\site\\lib\\Win32',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'FB57F243-643D-3BD3-A8FB-E68D7EA0E9FB',
                        'id' => 'FB57F243_643D_3BD3_A8FB_E68D7EA0E9FB'
                      }, 'Perl::Dist::WiX::Directory' ),
                      bless( {
                        'sitename' => 'www.test.site.invalid',
                        'directories' => [],
                        'files' => [],
                        'entries' => [],
                        'name' => 'XML',
                        'path' => 'c:\\test\\perl\\site\\lib\\XML',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '9D57212D-4847-3102-9FA9-89259497CB20',
                        'id' => '9D57212D_4847_3102_9FA9_89259497CB20'
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
                            'path' => 'c:\\test\\perl\\site\\lib\\auto\\share',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'BBFE98DE-746C-3C9F-B9D3-D789BEDB72BE',
                            'id' => 'BBFE98DE_746C_3C9F_B9D3_D789BEDB72BE'
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
                                'path' => 'c:\\test\\perl\\site\\lib\\auto\\Compress\\Raw',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => 'CEA11F02-4448-391F-8E06-E2CFC3883655',
                                'id' => 'CEA11F02_4448_391F_8E06_E2CFC3883655'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Compress',
                            'path' => 'c:\\test\\perl\\site\\lib\\auto\\Compress',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '56764A56-6248-3449-A4B0-B9A4A15DF5D2',
                            'id' => '56764A56_6248_3449_A4B0_B9A4A15DF5D2'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Math',
                            'path' => 'c:\\test\\perl\\site\\lib\\auto\\Math',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'C3368635-B44C-3089-A67E-BACC4E203DCE',
                            'id' => 'C3368635_B44C_3089_A67E_BACC4E203DCE'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Term',
                            'path' => 'c:\\test\\perl\\site\\lib\\auto\\Term',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '6D1134CE-3970-3BD8-82CF-332FC61F4B40',
                            'id' => '6D1134CE_3970_3BD8_82CF_332FC61F4B40'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'Win32',
                            'path' => 'c:\\test\\perl\\site\\lib\\auto\\Win32',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '21CB059D-089A-3C6B-815F-73F341933F43',
                            'id' => '21CB059D_089A_3C6B_815F_73F341933F43'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'XML',
                            'path' => 'c:\\test\\perl\\site\\lib\\auto\\XML',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '4BE6EA31-4235-3FA2-8954-6A7D0BC10753',
                            'id' => '4BE6EA31_4235_3FA2_8954_6A7D0BC10753'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'auto',
                        'path' => 'c:\\test\\perl\\site\\lib\\auto',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '6D9C03D5-B041-3C7B-B6CD-F95F3B986D7B',
                        'id' => '6D9C03D5_B041_3C7B_B6CD_F95F3B986D7B'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'lib',
                    'path' => 'c:\\test\\perl\\site\\lib',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '5352248B-E15C-36A5-9451-3117A96F42D8',
                    'id' => '5352248B_E15C_36A5_9451_3117A96F42D8'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'site',
                'path' => 'c:\\test\\perl\\site',
                'trace' => 0,
                'special' => 0,
                'guid' => '61C86B69-E8DF-34BA-8EE6-AB952A84E83F',
                'id' => '61C86B69_E8DF_34BA_8EE6_AB952A84E83F'
              }, 'Perl::Dist::WiX::Directory' )
            ],
            'files' => [],
            'entries' => [],
            'name' => 'perl',
            'path' => 'c:\\test\\perl',
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
                    'path' => 'c:\\test\\c\\bin\\startup',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'AB8356A1-7A35-384D-BEFD-540DDAC1B712',
                    'id' => 'AB8356A1_7A35_384D_BEFD_540DDAC1B712'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'bin',
                'path' => 'c:\\test\\c\\bin',
                'trace' => 0,
                'special' => 0,
                'guid' => 'E7951DB0-3670-3141-B27D-82B6379A1904',
                'id' => 'E7951DB0_3670_3141_B27D_82B6379A1904'
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
                            'path' => 'c:\\test\\c\\include\\c++\\3.4.5\\backward',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '7B87D6D1-14D3-3B8D-AEFD-2AE5CF66E8CE',
                            'id' => '7B87D6D1_14D3_3B8D_AEFD_2AE5CF66E8CE'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'bits',
                            'path' => 'c:\\test\\c\\include\\c++\\3.4.5\\bits',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '1BDC98D9-E0B0-3FC1-B3E0-27DB971F46C6',
                            'id' => '1BDC98D9_E0B0_3FC1_B3E0_27DB971F46C6'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'debug',
                            'path' => 'c:\\test\\c\\include\\c++\\3.4.5\\debug',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'DCDE3775-CE83-3BC6-82E7-98238A11AEAC',
                            'id' => 'DCDE3775_CE83_3BC6_82E7_98238A11AEAC'
                          }, 'Perl::Dist::WiX::Directory' ),
                          bless( {
                            'sitename' => 'www.test.site.invalid',
                            'directories' => [],
                            'files' => [],
                            'entries' => [],
                            'name' => 'ext',
                            'path' => 'c:\\test\\c\\include\\c++\\3.4.5\\ext',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '12E80322-CF7D-36C5-8581-B600853B8861',
                            'id' => '12E80322_CF7D_36C5_8581_B600853B8861'
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
                                'path' => 'c:\\test\\c\\include\\c++\\3.4.5\\mingw32\\bits',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => 'C571B7DB-6EA8-3023-B048-8E0DB5418D04',
                                'id' => 'C571B7DB_6EA8_3023_B048_8E0DB5418D04'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => 'mingw32',
                            'path' => 'c:\\test\\c\\include\\c++\\3.4.5\\mingw32',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => 'DFF47235-0840-364B-8C8E-4F70233CD620',
                            'id' => 'DFF47235_0840_364B_8C8E_4F70233CD620'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => '3.4.5',
                        'path' => 'c:\\test\\c\\include\\c++\\3.4.5',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '747FEA5C-0351-33FC-B58C-CD52F33BA97C',
                        'id' => '747FEA5C_0351_33FC_B58C_CD52F33BA97C'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'c++',
                    'path' => 'c:\\test\\c\\include\\c++',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '2EB09ABE-ABD0-3A5B-984C-1188CE67A1DF',
                    'id' => '2EB09ABE_ABD0_3A5B_984C_1188CE67A1DF'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'ddk',
                    'path' => 'c:\\test\\c\\include\\ddk',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '1882D24C-60A1-3AA4-A28C-67699862B29D',
                    'id' => '1882D24C_60A1_3AA4_A28C_67699862B29D'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'gl',
                    'path' => 'c:\\test\\c\\include\\gl',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '799E7C3A-0BAC-35CB-B683-CE3846B873DD',
                    'id' => '799E7C3A_0BAC_35CB_B683_CE3846B873DD'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'libxml',
                    'path' => 'c:\\test\\c\\include\\libxml',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '521DF9CB-8AAE-3BA5-9C39-0DB97EB8CC4E',
                    'id' => '521DF9CB_8AAE_3BA5_9C39_0DB97EB8CC4E'
                  }, 'Perl::Dist::WiX::Directory' ),
                  bless( {
                    'sitename' => 'www.test.site.invalid',
                    'directories' => [],
                    'files' => [],
                    'entries' => [],
                    'name' => 'sys',
                    'path' => 'c:\\test\\c\\include\\sys',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'A43300F4-1A69-3AAE-84EA-E540EE1E62A5',
                    'id' => 'A43300F4_1A69_3AAE_84EA_E540EE1E62A5'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'include',
                'path' => 'c:\\test\\c\\include',
                'trace' => 0,
                'special' => 0,
                'guid' => '62A1622F-2B98-3C62-BF8C-7624BD39F8A0',
                'id' => '62A1622F_2B98_3C62_BF8C_7624BD39F8A0'
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
                    'path' => 'c:\\test\\c\\lib\\debug',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '83387D01-0432-3886-B959-D429B83C513A',
                    'id' => '83387D01_0432_3886_B959_D429B83C513A'
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
                                'path' => 'c:\\test\\c\\lib\\gcc\\mingw32\\3.4.5\\include',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => 'D5AB2EDA-4C44-37B7-8FA8-6F5BF3E39CC7',
                                'id' => 'D5AB2EDA_4C44_37B7_8FA8_6F5BF3E39CC7'
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
                                    'path' => 'c:\\test\\c\\lib\\gcc\\mingw32\\3.4.5\\install-tools\\include',
                                    'trace' => 0,
                                    'special' => 0,
                                    'guid' => 'A50C5F78-5156-3D6A-8D48-B6353F4852BD',
                                    'id' => 'A50C5F78_5156_3D6A_8D48_B6353F4852BD'
                                  }, 'Perl::Dist::WiX::Directory' )
                                ],
                                'files' => [],
                                'entries' => [],
                                'name' => 'install-tools',
                                'path' => 'c:\\test\\c\\lib\\gcc\\mingw32\\3.4.5\\install-tools',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => 'C26AC4C0-CF1E-34EA-A9E4-3302CB7D6829',
                                'id' => 'C26AC4C0_CF1E_34EA_A9E4_3302CB7D6829'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => '3.4.5',
                            'path' => 'c:\\test\\c\\lib\\gcc\\mingw32\\3.4.5',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '74CB2FE8-F5F1-304A-86BD-36FD455CFB6C',
                            'id' => '74CB2FE8_F5F1_304A_86BD_36FD455CFB6C'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'mingw32',
                        'path' => 'c:\\test\\c\\lib\\gcc\\mingw32',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '4B3EDA82-D137-3675-A64C-80E51B6036C7',
                        'id' => '4B3EDA82_D137_3675_A64C_80E51B6036C7'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'gcc',
                    'path' => 'c:\\test\\c\\lib\\gcc',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'C23B9704-4061-3BCF-AD06-54861E166CBA',
                    'id' => 'C23B9704_4061_3BCF_AD06_54861E166CBA'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'lib',
                'path' => 'c:\\test\\c\\lib',
                'trace' => 0,
                'special' => 0,
                'guid' => '1F37D408-4CF1-3347-85A9-CDB762981D87',
                'id' => '1F37D408_4CF1_3347_85A9_CDB762981D87'
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
                                'path' => 'c:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
                                'trace' => 0,
                                'special' => 0,
                                'guid' => '5AD17DCF-390D-3E49-B0E7-473FCD9C86D9',
                                'id' => '5AD17DCF_390D_3E49_B0E7_473FCD9C86D9'
                              }, 'Perl::Dist::WiX::Directory' )
                            ],
                            'files' => [],
                            'entries' => [],
                            'name' => '3.4.5',
                            'path' => 'c:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5',
                            'trace' => 0,
                            'special' => 0,
                            'guid' => '2AD02341-566E-3714-8D44-A1A948AB0C3A',
                            'id' => '2AD02341_566E_3714_8D44_A1A948AB0C3A'
                          }, 'Perl::Dist::WiX::Directory' )
                        ],
                        'files' => [],
                        'entries' => [],
                        'name' => 'mingw32',
                        'path' => 'c:\\test\\c\\libexec\\gcc\\mingw32',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => 'B95420E6-BCE4-36F0-B9B1-D4B02B9CB627',
                        'id' => 'B95420E6_BCE4_36F0_B9B1_D4B02B9CB627'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'gcc',
                    'path' => 'c:\\test\\c\\libexec\\gcc',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'C3B1D355-F724-3030-B3EE-7E17D9D1469B',
                    'id' => 'C3B1D355_F724_3030_B3EE_7E17D9D1469B'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'libexec',
                'path' => 'c:\\test\\c\\libexec',
                'trace' => 0,
                'special' => 0,
                'guid' => '5F7950A1-CE06-3EA3-91B3-36AB475E55E6',
                'id' => '5F7950A1_CE06_3EA3_91B3_36AB475E55E6'
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
                    'path' => 'c:\\test\\c\\mingw32\\bin',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'A189758F-34E7-370F-A43C-EA46BCA6B3D7',
                    'id' => 'A189758F_34E7_370F_A43C_EA46BCA6B3D7'
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
                        'path' => 'c:\\test\\c\\mingw32\\lib\\ld-scripts',
                        'trace' => 0,
                        'special' => 0,
                        'guid' => '3E24DE86-B16A-3011-8A11-0959F3EECEEE',
                        'id' => '3E24DE86_B16A_3011_8A11_0959F3EECEEE'
                      }, 'Perl::Dist::WiX::Directory' )
                    ],
                    'files' => [],
                    'entries' => [],
                    'name' => 'lib',
                    'path' => 'c:\\test\\c\\mingw32\\lib',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => '1A8EE004-8346-3CAD-8235-744BA37E1C5C',
                    'id' => '1A8EE004_8346_3CAD_8235_744BA37E1C5C'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'mingw32',
                'path' => 'c:\\test\\c\\mingw32',
                'trace' => 0,
                'special' => 0,
                'guid' => 'F912A172-D30E-36E7-BDAC-25615B2B5E16',
                'id' => 'F912A172_D30E_36E7_BDAC_25615B2B5E16'
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
                    'path' => 'c:\\test\\c\\share\\locale',
                    'trace' => 0,
                    'special' => 0,
                    'guid' => 'E5AFC90F-83E1-3F25-BFC0-B1BF19E9E7DE',
                    'id' => 'E5AFC90F_83E1_3F25_BFC0_B1BF19E9E7DE'
                  }, 'Perl::Dist::WiX::Directory' )
                ],
                'files' => [],
                'entries' => [],
                'name' => 'share',
                'path' => 'c:\\test\\c\\share',
                'trace' => 0,
                'special' => 0,
                'guid' => '1F2C0433-32FF-33F4-9C12-F1C67A1DEA54',
                'id' => '1F2C0433_32FF_33F4_9C12_F1C67A1DEA54'
              }, 'Perl::Dist::WiX::Directory' )
            ],
            'files' => [],
            'entries' => [],
            'name' => 'c',
            'path' => 'c:\\test\\c',
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
                'path' => 'c:\\test\\licenses\\dmake',
                'trace' => 0,
                'special' => 0,
                'guid' => '977F59D0-E7F7-366F-B13C-BC89552F128C',
                'id' => '977F59D0_E7F7_366F_B13C_BC89552F128C'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'gcc',
                'path' => 'c:\\test\\licenses\\gcc',
                'trace' => 0,
                'special' => 0,
                'guid' => 'E4AA909E-1F62-3290-B20B-2BAEC97B27FB',
                'id' => 'E4AA909E_1F62_3290_B20B_2BAEC97B27FB'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'mingw',
                'path' => 'c:\\test\\licenses\\mingw',
                'trace' => 0,
                'special' => 0,
                'guid' => '9E7C617F-EF97-3904-99E7-3523638C41EA',
                'id' => '9E7C617F_EF97_3904_99E7_3523638C41EA'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'perl',
                'path' => 'c:\\test\\licenses\\perl',
                'trace' => 0,
                'special' => 0,
                'guid' => '0607AA79-6734-3D85-B7FB-1C02FFD98184',
                'id' => '0607AA79_6734_3D85_B7FB_1C02FFD98184'
              }, 'Perl::Dist::WiX::Directory' ),
              bless( {
                'sitename' => 'www.test.site.invalid',
                'directories' => [],
                'files' => [],
                'entries' => [],
                'name' => 'pexports',
                'path' => 'c:\\test\\licenses\\pexports',
                'trace' => 0,
                'special' => 0,
                'guid' => 'A80C3022-7E7A-3763-9F1B-EE7FF718146C',
                'id' => 'A80C3022_7E7A_3763_9F1B_EE7FF718146C'
              }, 'Perl::Dist::WiX::Directory' )
            ],
            'files' => [],
            'entries' => [],
            'name' => 'licenses',
            'path' => 'c:\\test\\licenses',
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
            'path' => 'c:\\test\\cpan',
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
            'path' => 'c:\\test\\win32',
            'trace' => 0,
            'special' => 0,
            'id' => 'Win32'
          }, 'Perl::Dist::WiX::Directory' )
        ],
        'files' => [],
        'entries' => [],
        'name' => '[INSTALLDIR]',
        'path' => 'c:\\test',
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
  'app_dir' => 'c:\\test'
}, 'Perl::Dist::WiX::DirectoryTree' );

is_deeply($tree, $tree_test_2, 'Initializes itself correctly');

# Tests 7-10 are successful finds.

# Test 7 (Test 8 at line 1586)

my $dir = $tree->search_dir(
    path_to_find => 'c:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
    exact => 1,
    descend => 1,
);

my $dir_test_1 = bless( {
  'sitename' => 'www.test.site.invalid',
  'directories' => [],
  'files' => [],
  'entries' => [],
  'name' => 'install-tools',
  'path' => 'c:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools',
  'trace' => 0,
  'special' => 0,
  'guid' => '5AD17DCF-390D-3E49-B0E7-473FCD9C86D9',
  'id' => '5AD17DCF_390D_3E49_B0E7_473FCD9C86D9'
}, 'Perl::Dist::WiX::Directory' );

is_deeply($dir, $dir_test_1, 'Successful search, descend=1 exact=1');

# Test 8 (Test 9 at line 1608)

$dir = $tree->search_dir(
    path_to_find => 'c:\\test\\win32',
    exact => 1,
    descend => 0,
);

my $dir_test_2 = bless( {
  'sitename' => 'www.test.site.invalid',
  'directories' => [],
  'files' => [],
  'entries' => [],
  'name' => 'win32',
  'path' => 'c:\\test\\win32',
  'trace' => 0,
  'special' => 0,
  'id' => 'Win32'
}, 'Perl::Dist::WiX::Directory' );

is_deeply($dir, $dir_test_2, 'Successful search, descend=0 exact=1');

# Test 9

$dir = $tree->search_dir(
    path_to_find => 'c:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
    exact => 0,
    descend => 1,
);

is_deeply($dir, $dir_test_1, 'Successful search, descend=1 exact=0');

# Test 10

$dir = $tree->search_dir(
    path_to_find => 'c:\\test\\win32\\x',
    exact => 0,
    descend => 0,
);

is_deeply($dir, $dir_test_2, 'Successful search, descend=0 exact=0');

# Tests 11-14 are unsuccessful searches

# Test 11

$dir = $tree->search_dir(
    path_to_find => 'c:\\test\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
    exact => 1,
    descend => 1,
);

ok((not defined $dir), 'Unsuccessful search, descend=1 exact=1');

# Test 12

$dir = $tree->search_dir(
    path_to_find => 'c:\\test\\win32\\x',
    exact => 1,
    descend => 0,
);

ok((not defined $dir), 'Unsuccessful search, descend=1 exact=0');

# Test 13

$dir = $tree->search_dir(
    path_to_find => 'c:\\xtest\\c\\libexec\\gcc\\mingw32\\3.4.5\\install-tools\\x',
    exact => 0,
    descend => 1,
);

ok((not defined $dir), 'Unsuccessful search, descend=0 exact=1');

# Test 14

$dir = $tree->search_dir(
    path_to_find => 'c:\\xtest\\win33',
    exact => 0,
    descend => 0,
);

ok((not defined $dir), 'Unsuccessful search, descend=0 exact=0');

