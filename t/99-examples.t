use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
use File::Spec::Functions;

sub test_data_file { catfile(qw(t 99-data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "SYNOPSIS" => sub {
  my $my_ini_file = test_data_file('dummy.ini');

  my $ini_reader = Config::INI::RefVars->new();
  $ini_reader->parse_ini(src => $my_ini_file);
  my $variables = $ini_reader->variables;
  while (my ($section, $section_vars) = each(%$variables)) {
    isa_ok($section_vars, 'HASH');
  }
};

subtest "COMMENTS" => sub {
  my $obj = Config::INI::RefVars->new();
  my $src = [
             '[section]  ; My fancy section',
             '# This is a comment',
             '; This is also a comment',
             '    ;! a comment, but: avoid ";!" at the very beginning of a line!',
             'var = value ; this is not a comment but part of the value.',
            ];
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             section => {var => 'value ; this is not a comment but part of the value.'}
            },
            'variables()'
           );
};

subtest "HEADERS" => sub {
  my $obj = Config::INI::RefVars->new();
  my $src = [
             '[section]',
             '[]',
            ];

  $obj->parse_ini(src => $src);
  is_deeply($obj->sections, ['section', ''], 'sections()');
};


subtest "VARIABLES AND ASSIGNMENT OPERATORS" => sub {
  subtest ".=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var.=123',
               '[section 2]',
               'var.=123',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => 'abc123'},
               'section 2' => { var => '123'},
              },
              'variables()');
  };

  subtest "+=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var+=123',
               '[section 2]',
               'var+=123',
               '[section 3]',
               'var=abc',
               'var+=',
               '[section 4]',
               'var+=',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => 'abc 123'},
               'section 2' => { var => '123'},
               'section 3' => { var => 'abc '},
               'section 4' => { var => ''},
              },
              'variables()');
  };

  subtest ".>=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var.>=123',
               '[section 2]',
               'var.>=123',
               '[section 3]',
               'var.>=',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => '123abc'},
               'section 2' => { var => '123'},
               'section 3' => { var => ''},
              },
              'variables()');
  };

  subtest "+>=" => sub {
    my $obj = Config::INI::RefVars->new();
    my $src = [
               '[section 1]',
               'var=abc',
               'var+>=123',
               '[section 2]',
               'var+>=123',
               '[section 3]',
               'var=abc',
               'var+>=',
               '[section 4]',
               'var+>=',
              ];
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'section 1' => { var => '123 abc'},
               'section 2' => { var => '123'},
               'section 3' => { var => ' abc'},
               'section 4' => { var => ''},
              },
              'variables()');
  };
};


subtest "REFERENCING VARIABLES" => sub {
  my $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => [
                          '[sec1]',
                          'a=hello',
                          'b=world',
                          'c=$(a) $(b)',

                          '[sec2]',
                          'c=$(a) $(b)',
                          'a=hello',
                          'b=world',

                          '[sec3]',
                          'c:=$(a) $(b)',
                          'a=hello',
                          'b=world',
                         ]);
  is_deeply($obj->variables,
            {
             sec1 => {a => 'hello', b => 'world', c => 'hello world'},
             sec2 => {a => 'hello', b => 'world', c => 'hello world'},
             sec3 => {a => 'hello', b => 'world', c => ' '}
            },
            'variables()');

  my $src = <<'EOT';
  [sec]
   foo=the foo value
   var 1=fo
   var 2=o
   bar=$($(var 1)$(var 2))
EOT

  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             sec => {
                     'foo'   => 'the foo value',
                     'var 1' => 'fo',
                     'var 2' => 'o',
                     'bar'    => 'the foo value',
                    }
            },
            'variables()');

  $src = <<'EOT';
   [sec A]
   foo=Referencing a variable from section: $([sec B]bar)

   [sec B]
   bar=Referenced!
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'sec A' => {foo => 'Referencing a variable from section: Referenced!'},
             'sec B' => {bar => 'Referenced!'}
            },
            'variables()');

};


#==================================================================================================
done_testing();
