use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warn;


use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
#
#sub test_data_file { catfile(qw(t 08_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

my $Dummy_Src = [
                 '[The Section]',
                 'The Variable=007'
                ];

subtest "common_vars" => sub {
  subtest 'new()' => sub {
    like(exception { Config::INI::RefVars->new(common_vars => 72) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => []) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => {
                                                               x => 'huhu',
                                                               y => {},
                                                               z => 23
                                                              }) },
         qr/'common_vars': value of 'y' is a ref, expected scalar/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => {
                                                               x      => 'huhu',
                                                               '=foo' => '',
                                                               z      => 23
                                                              }) },
         qr/'common_vars': variable '=foo': name is not permitted/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => {
                                                               x      => 'huhu',
                                                               ';foo' => '',
                                                               z      => 23
                                                              }) },
         qr/'common_vars': variable ';foo': name is not permitted/,
         "common_vars: the code died as expected");
  };

  subtest 'parse_ini()' => sub {
    my $obj = Config::INI::RefVars->new();

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => 72) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => []) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => {
                                                                        x => 'huhu',
                                                                        y => {},
                                                                        z => 23
                                                                       }) },
         qr/'common_vars': value of 'y' is a ref, expected scalar/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => {
                                                                        x      => 'huhu',
                                                                        '=foo' => '',
                                                                        z      => 23
                                                              }) },
         qr/'common_vars': variable '=foo': name is not permitted/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => {
                                                                        x      => 'huhu',
                                                                        ';foo' => '',
                                                                        z      => 23
                                                                       }) },
         qr/'common_vars': variable ';foo': name is not permitted/,
         "common_vars: the code died as expected");
  };
};


subtest "not_common" => sub {
  subtest 'new()' => sub {
    like(exception { Config::INI::RefVars->new(not_common => 72) },
         qr/'not_common': unexpected type: must be ARRAY or HASH ref/,
         "not_common: the code died as expected");

    like(exception { Config::INI::RefVars->new(not_common => ['a', undef, 'b']) },
         qr/'not_common': undefined value in array/,
         "not_common: the code died as expected");

    like(exception { Config::INI::RefVars->new(not_common => ['a', [], 'b']) },
         qr/'not_common': unexpected ref value in array/,
         "not_common: the code died as expected");
  };

  subtest 'parse_ini()' => sub {
    my $obj = Config::INI::RefVars->new();

    like(exception { $obj->parse_ini(src => $Dummy_Src, not_common => 72) },
         qr/'not_common': unexpected type: must be ARRAY or HASH ref/,
         "not_common: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, not_common => ['a', undef, 'b']) },
         qr/'not_common': undefined value in array/,
         "not_common: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, not_common => ['a', [], 'b']) },
         qr/'not_common': unexpected ref value in array/,
         "not_common: the code died as expected");
  };
};

subtest "separator (only possible in new())" => sub {
  my $dummy = "";
  like(exception { Config::INI::RefVars->new(separator => \$dummy) },
       qr/'separator': unexpected ref type, must be a scalar/,
       "separator: the code died as expected");

  like(exception { Config::INI::RefVars->new(separator => '=') },
       qr/'separator': invalid value. Allowed chars: [[:punct:]]+/,
       "separator: the code died as expected");
};


subtest "common_section" => sub {
  like(exception { Config::INI::RefVars->new(common_section => []) },
       qr/'common_section': must not be a reference/,
       "separator: the code died as expected");

  my $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => '[sec]', common_section => []) },
       qr/'common_section': must not be a reference/,
       "separator: the code died as expected");
};


subtest "src_name (only possible in parse_ini())" => sub {
  my $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => '[sec]', src_name => []) },
       qr/'src_name': must not be a reference/,
       "separator: the code died as expected");
};


subtest "src (only possible in (parse_ini())" => sub {
  my $dummy = "";
  my $obj = Config::INI::RefVars->new();

  like(exception { $obj->parse_ini() },
       qr/'src': missing mandatory argument/,
       "src: the code died as expected");

  like(exception { $obj->parse_ini(src => {}) },
       qr/'src': HASH: ref type not allowed/,
       "src: the code died as expected");

  like(exception { $obj->parse_ini(src => ['a=1', [], '[sec]']) },
       qr/'src': unexpected ref type in array/,
       "src: the code died as expected");
};


subtest "warning: common_vars" => sub {
  subtest "new()" => sub {
    my $obj;
    warning_like(sub {$obj = Config::INI::RefVars->new(common_vars => {a => 1,
                                                                       b => undef,
                                                                       c => 3})
                    },
                 qr/'common_vars': value 'b' is undef - treated as empty string/,
                 "'common_vars': the code printed the warning as expected");
    $obj->parse_ini(src => [ '[sec]' ]);
    is_deeply($obj->variables,
              {
               '__COMMON__' => {
                                'a' => '1',
                                'b' => '',
                                'c' => '3'
                               },
               'sec' => {
                         'a' => '1',
                         'b' => '',
                         'c' => '3'
                        }
              },
              'variables()');
  };

  subtest "parse_ini()" => sub {
    my $obj = Config::INI::RefVars->new();
    warning_like(sub {$obj->parse_ini(src         => [ '[sec]' ],
                                      common_vars => {a => 1,
                                                      b => undef,
                                                      c => 3})
                    },
                 qr/'common_vars': value 'b' is undef - treated as empty string/,
                 "'common_vars': the code printed the warning as expected");
    is_deeply($obj->variables,
              {
               '__COMMON__' => {
                                'a' => '1',
                                'b' => '',
                                'c' => '3'
                               },
               'sec' => {
                         'a' => '1',
                         'b' => '',
                         'c' => '3'
                        }
              },
              'variables()');
  }
};

#==================================================================================================
done_testing();
