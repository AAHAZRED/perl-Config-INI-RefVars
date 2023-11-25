use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

use File::Spec::Functions;


sub test_data_file { catfile(qw(t 02_data), $_[0]) }


#
# For heredocs containing INI data always use the single quote variant!
#


subtest 'predefined sections' => sub {
  is(Config::INI::RefVars::DFLT_COMMON_SECTION, "__COMMON__", "COMMON_SECTION default");
};

subtest 'before any parsing' => sub {
  my $obj = new_ok('Config::INI::RefVars');
  foreach my $meth (qw(sections
                       sections_h
                       variables
                       src_name
                       global
                       common_section)) {
    is($obj->$meth, undef, "$meth(): undef");
  }
};


subtest 'empty input' => sub {
  subtest "string that only contains a line break" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    is($obj->parse_ini(src => "\n"), $obj, "parse_ini() returns obj");
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "empty array" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    $obj->parse_ini(src => []);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "array containing an empty string" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    $obj->parse_ini(src => [""]);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "empty file" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    my $empty_file = test_data_file("empty_file.ini");
    note("Input: $empty_file");
    $obj->parse_ini(src => $empty_file);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj, $empty_file);
  };
  subtest "file containing only spaces" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    my $spaces_file = test_data_file("only_spaces.ini");
    note("Input: $spaces_file");
    $obj->parse_ini(src => $spaces_file);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj, $spaces_file);
  };
};


subtest 'only comments' => sub {
  subtest "string that only contains comments" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    $obj->parse_ini(src => "; [a section]\n#foo=bar\n");
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "array containing only comments" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    $obj->parse_ini(src => ["; [a section]",
                            ";foo=bar"]);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "file containing only comments" => sub {
    my $obj = new_ok('Config::INI::RefVars');
    my $only_comments = test_data_file("only_comments.ini");
    note("Input: $only_comments");
    $obj->parse_ini(src => $only_comments);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj, $only_comments);
  };
};

subtest "simple content / reuse" => sub {
  my $obj = new_ok('Config::INI::RefVars');
  subtest "string input" => sub {
    $obj->parse_ini(src => "[a section]\nfoo=bar\n");
    is_deeply($obj->sections,   ['a section'],      'sections()');
    is_deeply($obj->sections_h, {'a section' => 0}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {'a section' => {foo => 'bar'}},
              'variables(): empty hash');
    check_other($obj);
  };
  subtest "file input" => sub {
    my $file = test_data_file('simple_content.ini');
    $obj->parse_ini(src => $file);
    is_deeply($obj->sections, ['first section',
                               'second section',
                               'empty section'],
              'sections()');
    is_deeply($obj->sections_h, { 'first section'  => 0,
                                  'second section' => 1,
                                  'empty section'  => 2,
                                },
              'sections_h()');
    is_deeply($obj->variables,  {'first section'  => {var_1 => 'val_1',
                                                      var_2 => 'val_2'},
                                 'second section' => {this => 'that'},
                                 'empty section'  => {},
                                },
              'variables()');
    check_other($obj, $file);
  };
  subtest "file input (with and without newlines)" => sub {
    $obj->parse_ini(src => ["[sec-1]",
                            "a = a_val\n",
                            "b=#;;#",
                            "",
                            "  [  sec-2   ]\n",
                            "  var   =   val"
                           ]);
    is_deeply($obj->sections, [qw(sec-1 sec-2)], 'sections()');
    is_deeply($obj->sections_h, { 'sec-1' => 0,
                                  'sec-2' => 1
                                },
              'sections_h()');
    is_deeply($obj->variables,  { 'sec-1' => {a => 'a_val', b => '#;;#' },
                                  'sec-2' => {var => 'val'}
                                  },
              'variables()');
    check_other($obj);
  };
};


subtest "common section" => sub {
  my $obj = new_ok('Config::INI::RefVars');
  my $input = ["a=b",
               "[blah]",
               "A=B"];
  is($obj->parse_ini(src => $input), $obj, "parse_ini() returns obj");
  is_deeply($obj->sections, [Config::INI::RefVars::DFLT_COMMON_SECTION, "blah"],
            "sections(): default and empty section");
  is_deeply($obj->sections_h, { Config::INI::RefVars::DFLT_COMMON_SECTION => 0,
                                'blah'                                    => 1},
            'sections_h()');
  is_deeply($obj->variables,  { Config::INI::RefVars::DFLT_COMMON_SECTION => {a => 'b'},
                                'blah'                                    => {A => 'B',
                                                                              a => 'b'},
                              },
               'variables()');
  check_other($obj);
};


subtest "assignment operators and weird names" => sub {
  my $input = <<'EOT';
[#;.! ! =]

_=_underscore_

; start with a '.=' for a variable that is not yet defined
:+;-+*+!@^xy .= hel
:+;-+*+!@^xy.= lo
:+;-+*+!@^xy+= world

:+;-+*+!@^xy. = another variable

foo. = bar
foo.= baz

abc? = 123
abc?= 456
abc?= 789

my-var  = ld
my-var .>= or
my-var .>= w
my-var +>= hello
my-var +>= And again:
EOT
  my $obj = new_ok('Config::INI::RefVars');
  $obj->parse_ini(src => $input);
  is_deeply($obj->variables,
            {'#;.! ! =' => {
                            '_'             => '_underscore_',
                            ':+;-+*+!@^xy'  => 'hello world',
                            ':+;-+*+!@^xy.' => 'another variable',
                            'foo.'          => 'bar',
                            'foo'           => 'baz',
                            'abc?'          => '123',
                            'abc'           => '456',
                            'my-var'        => 'And again: hello world'
                           }
            },
            'variables()') or diag explain $obj->variables;

};


subtest "arguments" => sub {
  my $obj = new_ok('Config::INI::RefVars');
  my $input = ["a=b",
               "[]",
               "A+=",           # '+=' for a variable that does not yet exist
               "A=B"];
  subtest "clone + global (empty)" => sub {
    my $global = {};
    $obj->parse_ini(src => $input, global => $global);
    is($obj->global, $global, "global is not cloned");

    $obj->parse_ini(src => $input, global => $global, clone => 1);
    isnt($obj->global, $global, "global is cloned");
  };
};

#==================================================================================================
done_testing();


###################################################################################################

sub check_other {
  my $obj = shift;
  my $src_name = shift // "INI data";
  isa_ok($obj->global, 'HASH', 'global()');
  is($obj->common_section,  Config::INI::RefVars::DFLT_COMMON_SECTION, 'common_section()');
}
