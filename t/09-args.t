use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
#
#sub test_data_file { catfile(qw(t 09-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "use all args of new()" => sub {
  my $obj = Config::INI::RefVars->new(common_section => "COMMON!",
                                      common_vars    => { '#hash' => 'maria',
                                                          'f~27'  => 42,
                                                          'foo'   => 'sec:$(=)'
                                                        },
                                      not_common     => ['#hash'],
                                      separator      => '/'
                                     );
  subtest "simple tests" => sub {
    my $src = [
               '[sec-A]',
               '[sec-B]'
              ];
    subtest "parse_ini() - no further args" => sub {
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables,
                {
                 'COMMON!' => {
                               '#hash' => 'maria',
                               'f~27' => '42',
                               'foo' => 'sec:COMMON!'
                              },
                 'sec-A' => {
                             'f~27' => '42',
                             'foo' => 'sec:sec-A'
                            },
                 'sec-B' => {
                             'f~27' => '42',
                             'foo' => 'sec:sec-B'
                            }
                },
                'variables()');
    };
    subtest "parse_ini() - cancel out not_common" => sub {
      $obj->parse_ini(src => $src, not_common => []);
      is_deeply($obj->variables,
                {
                 'COMMON!' => {
                               '#hash' => 'maria',
                               'f~27' => '42',
                               'foo' => 'sec:COMMON!'
                              },
                 'sec-A' => {
                             '#hash' => 'maria',
                             'f~27' => '42',
                             'foo' => 'sec:sec-A'
                            },
                 'sec-B' => {
                             '#hash' => 'maria',
                             'f~27' => '42',
                             'foo' => 'sec:sec-B'
                            }
                },
                'variables()');
    };
    subtest "overwrite common_section, common_vars, not_common " => sub {
      $obj->parse_ini(src => $src,
                      common_section => 'HUHU',
                      common_vars    => {a => 1, b => 2, c => 3},
                      not_common     => ['a']
                     );
      is_deeply($obj->variables,
                {
                 'HUHU' => {
                            'a' => '1',
                            'b' => '2',
                            'c' => '3'
                           },
                 'sec-A' => {
                             'b' => '2',
                             'c' => '3'
                            },
                 'sec-B' => {
                             'b' => '2',
                             'c' => '3'
                            }
                },
                'variables()');
    };
    subtest "REUSE: parse_ini() - no further args" => sub {
      $obj->parse_ini(src => $src);
      is_deeply($obj->variables,
                {
                 'COMMON!' => {
                               '#hash' => 'maria',
                               'f~27' => '42',
                               'foo' => 'sec:COMMON!'
                              },
                 'sec-A' => {
                             'f~27' => '42',
                             'foo' => 'sec:sec-A'
                            },
                 'sec-B' => {
                             'f~27' => '42',
                             'foo' => 'sec:sec-B'
                            }
                },
                'variables()');
    };
  };
  subtest "common vars in INI src, with and without cleanup" => sub {
    my $src = [
               'foo = override!',
               'additional= yet another common var!',
               '[sec-A]',
               'a var=$(12=ab)',
               '[sec-B]',
              ];
    $obj->parse_ini(src        => $src,
                    common_vars => { '#hash' => 'other value',
                                     '12=ab' => 42,
                                     'foo'   => 'sec:$(=)',
                                     '#foo'  => 'foo with hash'
                                   }
                   );
    is_deeply($obj->variables,
              {
               'COMMON!' => {
                             '#foo' => 'foo with hash',
                             '#hash' => 'other value',
                             'additional' => 'yet another common var!',
                             'foo' => 'override!'
                            },
               'sec-A' => {
                           '#foo' => 'foo with hash',
                           'a var' => '42',
                           'additional' => 'yet another common var!',
                           'foo' => 'override!'
                          },
               'sec-B' => {
                           '#foo' => 'foo with hash',
                           'additional' => 'yet another common var!',
                           'foo' => 'override!'
                          }
              },
              'variables()');

    $obj->parse_ini(src        => $src,
                    common_vars => { '#hash' => 'other value',
                                     '12=ab' => 42,
                                     'foo'   => 'sec:$(=)',
                                     '#foo'  => 'foo with hash'
                                   },
                    cleanup => 0
                   );
    is_deeply($obj->variables,
              {
               'COMMON!' => {
                             '#foo' => 'foo with hash',
                             '#hash' => 'other value',
                             '12=ab' => '42',
                             '=' => 'COMMON!',
                             '=:' => '/',
                             '=INIname' => 'INI data',
                             'additional' => 'yet another common var!',
                             'foo' => 'override!'
                            },
               'sec-A' => {
                           '#foo' => 'foo with hash',
                           '12=ab' => '42',
                           '=' => 'sec-A',
                           '=:' => '/',
                           '=INIname' => 'INI data',
                           'a var' => '42',
                           'additional' => 'yet another common var!',
                           'foo' => 'override!'
                          },
               'sec-B' => {
                           '#foo' => 'foo with hash',
                           '12=ab' => '42',
                           '=' => 'sec-B',
                           '=:' => '/',
                           '=INIname' => 'INI data',
                           'additional' => 'yet another common var!',
                           'foo' => 'override!'
                          }

              },
              'variables(), cleanup => 0');

  };
};

#==================================================================================================
done_testing();
