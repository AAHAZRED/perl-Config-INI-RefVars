use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

use Storable qw(dclone);

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


subtest "backup / restore" => sub {
  my $orig_common_section = "!all!";
  my $src = ['[sec]'];
  my $orig_expected = {
                       $orig_common_section => {
                                                'a' => '1',
                                                'b' => '2',
                                                'c' => '3',
                                                'd' => '4'
                                               },
                       'sec' => {
                                 'a' => '1',
                                 'b' => '2',
                                 'd' => '4'
                                }
                      };
  my $obj = Config::INI::RefVars->new(common_section => $orig_common_section,
                                      common_vars    => { a => 1,
                                                          b => 2,
                                                          c => 3,
                                                          d => 4
                                                        },
                                      not_common     => ['c']
                                     );
  is($obj->common_section, $orig_common_section, 'common_section() / after new()');

  subtest "parse_ini() without further args" => sub {
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), orig');
  };

  my $other_common_section = "COMMON SECTION";

  subtest "parse_ini() with common_section" => sub {
    my $expected = {
                    $other_common_section => dclone($orig_expected->{$orig_common_section}),
                    'sec'                 => dclone($orig_expected->{sec})
                   };
    $obj->parse_ini(src => $src, common_section => $other_common_section);
    is($obj->common_section, $orig_common_section, 'common_section() restored by parse_ini()');
    is_deeply($obj->variables, $expected, 'variables(), changed common section name');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };

  subtest "parse_ini() with common_vars" => sub {
    $obj->parse_ini(src => $src, common_vars => {c => "c-value", x => "x-value"});
    is_deeply($obj->variables,
              {
               '!all!' => {
                           'c' => 'c-value',
                           'x' => 'x-value'
                          },
               'sec' => {
                         'x' => 'x-value'
                        }
              },
              'variables(), changed common vars');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };

  subtest "parse_ini() with not_common" => sub {
    $obj->parse_ini(src => $src, not_common => [qw(a b)]);
    is_deeply($obj->variables,
              {
               '!all!' => {
                           'a' => '1',
                           'b' => '2',
                           'c' => '3',
                           'd' => '4'
                          },
               'sec' => {
                         'c' => '3',
                         'd' => '4'
                        }
              },
              'variables(), changed not common vars');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };

  subtest "parse_ini() with common_section,not_common,not_common" => sub {
    $obj->parse_ini(src => $src,
                    common_section => $other_common_section,
                    common_vars    => {c => "c-value", d => "d-value"},
                    not_common     => [qw(a b c)]);
    is_deeply($obj->variables,
              {
               'COMMON SECTION' => {
                                    'c' => 'c-value',
                                    'd' => 'd-value'
                                   },
               'sec' => {
                         'd' => 'd-value'
                        }
              },
              'variables(), changed common_section,not_common,not_common');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };
};

#==================================================================================================
done_testing();
