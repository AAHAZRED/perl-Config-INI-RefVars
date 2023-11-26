use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

#use File::Spec::Functions;
#
#sub test_data_file { catfile(qw(t 05_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#


my $obj = Config::INI::RefVars->new;

subtest "basic" => sub {
  subtest "first examples, with and without arg 'common_section'" => sub {
    my $src = [
               'a=1',
               '',
               '[sec A]',
               '',
               '[sec B]',
               'a += huhu',
               '',
               '[sec C]',
               'a=27'
              ];

    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               '__COMMON__' => {
                                'a' => '1'
                               },
               'sec A' => {
                           'a' => '1'
                          },
               'sec B' => {
                           'a' => '1 huhu'
                          },
               'sec C' => {
                           'a' => '27'
                          }
              },
              'variables()');

    $obj->parse_ini(src => $src, common_section => 'COM_SEC');
    is_deeply($obj->variables,
              {
               'COM_SEC' => {
                             'a' => '1'
                            },
               'sec A' => {
                           'a' => '1'
                          },
               'sec B' => {
                           'a' => '1 huhu'
                          },
               'sec C' => {
                           'a' => '27'
                          }
              },
              'variables()');

    $obj->parse_ini(src => $src, common_section => '');
    is_deeply($obj->variables,
              {
               ''      => {
                             'a' => '1'
                          },
               'sec A' => {
                           'a' => '1'
                          },
               'sec B' => {
                           'a' => '1 huhu'
                          },
               'sec C' => {
                           'a' => '27'
                          }
              },
              'variables()');
  };

  subtest 'with $(=) and explicite [__COMMON__]' => sub {
    my $src = [
               '[__COMMON__]',
               'theVar = Section: $(=)',
               '',
               '[A]',
               '',
               '[B]',
               'a var=$([A]theVar), not $([C]sec)',
               '[C]',
               'sec=$(=)'
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'A' => {
                       'theVar' => 'Section: A'
                      },
               'B' => {
                       'a var' => 'Section: A, not C',
                       'theVar' => 'Section: B'
                      },
               'C' => {
                       'theVar' => 'Section: C',
                       'sec'    => 'C'
                      },
               '__COMMON__' => {
                                'theVar' => 'Section: __COMMON__'
                               }
              },
              'variables()');
  };
};


#==================================================================================================
done_testing();

