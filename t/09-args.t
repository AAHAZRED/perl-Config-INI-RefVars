use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
#
#sub test_data_file { catfile(qw(t 08_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "use all args of new()" => sub {
  my $obj = Config::INI::RefVars->new(common_section => "COMMON!",
                                      common_vars    => { '#hash' => 'maria',
                                                          'f=27'  => 42,
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
                               'f=27' => '42',
                               'foo' => 'sec:COMMON!'
                              },
                 'sec-A' => {
                             'f=27' => '42',
                             'foo' => 'sec:sec-A'
                            },
                 'sec-B' => {
                             'f=27' => '42',
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
                               'f=27' => '42',
                               'foo' => 'sec:COMMON!'
                              },
                 'sec-A' => {
                             '#hash' => 'maria',
                             'f=27' => '42',
                             'foo' => 'sec:sec-A'
                            },
                 'sec-B' => {
                             '#hash' => 'maria',
                             'f=27' => '42',
                             'foo' => 'sec:sec-B'
                            }
                },
                'variables()') or diag explain $obj->variables;
    };
  };
};

  #==================================================================================================
done_testing();
