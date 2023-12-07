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
  my $obj = Config::INI::RefVars->new(tocopy_section => "TOCOPY!",
                                      tocopy_vars    => { '#hash' => 'maria',
                                                          'f~27'  => 42,
                                                          'foo'   => 'sec:$(=)'
                                                        },
                                      not_tocopy     => ['#hash'],
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
                 'TOCOPY!' => {
                               '#hash' => 'maria',
                               'f~27' => '42',
                               'foo' => 'sec:TOCOPY!'
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
    subtest "parse_ini() - cancel out not_tocopy" => sub {
      $obj->parse_ini(src => $src, not_tocopy => []);
      is_deeply($obj->variables,
                {
                 'TOCOPY!' => {
                               '#hash' => 'maria',
                               'f~27' => '42',
                               'foo' => 'sec:TOCOPY!'
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
    subtest "overwrite tocopy_section, tocopy_vars, not_tocopy " => sub {
      $obj->parse_ini(src => $src,
                      tocopy_section => 'HUHU',
                      tocopy_vars    => {a => 1, b => 2, c => 3},
                      not_tocopy     => ['a']
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
                 'TOCOPY!' => {
                               '#hash' => 'maria',
                               'f~27' => '42',
                               'foo' => 'sec:TOCOPY!'
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
  subtest "tocopy vars in INI src, with and without cleanup" => sub {
    my $src = [
               'foo = override!',
               'additional= yet another tocopy var!',
               '[sec-A]',
               'a var=$(12=ab)',
               '[sec-B]',
              ];
    $obj->parse_ini(src        => $src,
                    tocopy_vars => { '#hash' => 'other value',
                                     '12=ab' => 42,
                                     'foo'   => 'sec:$(=)',
                                     '#foo'  => 'foo with hash'
                                   }
                   );
    is_deeply($obj->variables,
              {
               'TOCOPY!' => {
                             '#foo' => 'foo with hash',
                             '#hash' => 'other value',
                             'additional' => 'yet another tocopy var!',
                             'foo' => 'override!'
                            },
               'sec-A' => {
                           '#foo' => 'foo with hash',
                           'a var' => '42',
                           'additional' => 'yet another tocopy var!',
                           'foo' => 'override!'
                          },
               'sec-B' => {
                           '#foo' => 'foo with hash',
                           'additional' => 'yet another tocopy var!',
                           'foo' => 'override!'
                          }
              },
              'variables()');

    $obj->parse_ini(src        => $src,
                    tocopy_vars => { '#hash' => 'other value',
                                     '12=ab' => 42,
                                     'foo'   => 'sec:$(=)',
                                     '#foo'  => 'foo with hash'
                                   },
                    cleanup => 0
                   );
    is_deeply($obj->variables,
              {
               'TOCOPY!' => {
                             '#foo' => 'foo with hash',
                             '#hash' => 'other value',
                             '12=ab' => '42',
                             '=' => 'TOCOPY!',
                             '=:' => '/',
                             '=srcname' => 'INI data',
                             'additional' => 'yet another tocopy var!',
                             'foo' => 'override!'
                            },
               'sec-A' => {
                           '#foo' => 'foo with hash',
                           '12=ab' => '42',
                           '=' => 'sec-A',
                           '=:' => '/',
                           '=srcname' => 'INI data',
                           'a var' => '42',
                           'additional' => 'yet another tocopy var!',
                           'foo' => 'override!'
                          },
               'sec-B' => {
                           '#foo' => 'foo with hash',
                           '12=ab' => '42',
                           '=' => 'sec-B',
                           '=:' => '/',
                           '=srcname' => 'INI data',
                           'additional' => 'yet another tocopy var!',
                           'foo' => 'override!'
                          }

              },
              'variables(), cleanup => 0');

  };
};


subtest "backup / restore" => sub {
  my $orig_tocopy_section = "!all!";
  my $src = ['[sec]'];
  my $orig_expected = {
                       $orig_tocopy_section => {
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
  my $obj = Config::INI::RefVars->new(tocopy_section => $orig_tocopy_section,
                                      tocopy_vars    => { a => 1,
                                                          b => 2,
                                                          c => 3,
                                                          d => 4
                                                        },
                                      not_tocopy     => ['c']
                                     );
  is($obj->tocopy_section, $orig_tocopy_section, 'tocopy_section() / after new()');

  subtest "parse_ini() without further args" => sub {
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), orig');
  };

  my $other_tocopy_section = "TOCOPY SECTION";

  subtest "parse_ini() with tocopy_section" => sub {
    my $expected = {
                    $other_tocopy_section => dclone($orig_expected->{$orig_tocopy_section}),
                    'sec'                 => dclone($orig_expected->{sec})
                   };
    $obj->parse_ini(src => $src, tocopy_section => $other_tocopy_section);
    is($obj->tocopy_section, $orig_tocopy_section, 'tocopy_section() restored by parse_ini()');
    is_deeply($obj->variables, $expected, 'variables(), changed tocopy section name');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };

  subtest "parse_ini() with tocopy_vars" => sub {
    $obj->parse_ini(src => $src, tocopy_vars => {c => "c-value", x => "x-value"});
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
              'variables(), changed tocopy vars');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };

  subtest "parse_ini() with not_tocopy" => sub {
    $obj->parse_ini(src => $src, not_tocopy => [qw(a b)]);
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
              'variables(), changed not tocopy vars');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };

  subtest "parse_ini() with tocopy_section,not_tocopy,not_tocopy" => sub {
    $obj->parse_ini(src => $src,
                    tocopy_section => $other_tocopy_section,
                    tocopy_vars    => {c => "c-value", d => "d-value"},
                    not_tocopy     => [qw(a b c)]);
    is_deeply($obj->variables,
              {
               'TOCOPY SECTION' => {
                                    'c' => 'c-value',
                                    'd' => 'd-value'
                                   },
               'sec' => {
                         'd' => 'd-value'
                        }
              },
              'variables(), changed tocopy_section,not_tocopy,not_tocopy');

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables, $orig_expected, 'variables(), back to orig');
  };
};

#==================================================================================================
done_testing();
