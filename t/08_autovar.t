use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

use File::Spec::Functions;

sub test_data_file { catfile(qw(t 08_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "not from file" => sub {
  my $expected = {
                  'section 1' => {
                                  '1a' => 'INI data',
                                  '1b' => '',
                                  '1c' => '',
                                  '1d' => '/',
                                  '1e' => 'section 1',
                                  '1f' => '',
                                  '1g' => '  ',
                                  '2a' => 'INI data',
                                  '2b' => '',
                                  '2c' => '',
                                  '2d' => '/',
                                  '2e' => 'section 2',
                                  '2f' => '',
                                  '2g' => '  ',
                                  '3a' => '',
                                  '3b' => '',
                                  '3c' => '',
                                  '3d' => '',
                                  '3e' => '',
                                  '3f' => '',
                                  '3g' => ''
                                 },
                  'section 2' => {}
                 };
    subtest "default regex" => sub {
      my $obj = Config::INI::RefVars->new();
      my $src = [
                 '[section 1]',
                 '1a=$(=INIname)',
                 '1b=$(=INIfile)',
                 '1c=$(=INIdir)',
                 '1d=$(=:)',
                 '1e=$(=)',
                 '1f=$()',
                 '1g=$(  )',

                 '2a=$([section 2]=INIname)',
                 '2b=$([section 2]=INIfile)',
                 '2c=$([section 2]=INIdir)',
                 '2d=$([section 2]=:)',
                 '2e=$([section 2]=)',
                 '2f=$([section 2]x)',
                 '2g=$([section 2]  )',

                 '3a=$([section 3]=INIname)',
                 '3b=$([section 3]=INIfile)',
                 '3c=$([section 3]=INIdir)',
                 '3d=$([section 3]=:)',
                 '3e=$([section 3]=)',
                 '3f=$([section 3])',
                 '3g=$([section 3]  )',

                 '[section 2]',
                ];
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables, $expected, 'variables()');
    };
};

#==================================================================================================
done_testing();
