use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

subtest 'substr needs 2 or 3 arguments' => sub {
  my $ini_0 = <<'INI';
[sec]
x := $(=& substr)
INI

  my $ok = eval {
    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini_0);
    1;
  };

  ok(!$ok, 'substr with 0 args dies');
  like($@, qr/\bsubstr: expected 2 or 3 arguments\b/, '0 args error message');

  my $ini_1 = <<'INI';
[sec]
x := $(=& substr, abcdef)
INI

  $ok = eval {
    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini_1);
    1;
  };

  ok(!$ok, 'substr with 1 arg dies');
  like($@, qr/\bsubstr: expected 2 or 3 arguments\b/, '1 arg error message');

  my $ini_4 = <<'INI';
[sec]
x := $(=& substr, abcdef, 1, 2, 3)
INI

  $ok = eval {
    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini_4);
    1;
  };

  ok(!$ok, 'substr with 4 args dies');
  like($@, qr/\bsubstr: expected 2 or 3 arguments\b/, '4 args error message');
};

subtest 'substr numeric warnings are converted to clean errors' => sub {
  my $ini_offset = <<'INI';
[sec]
x := $(=& substr, abcdef, a)
INI

  my $ok = eval {
    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini_offset);
    1;
  };

  ok(!$ok, 'substr with non-numeric offset dies');
  like($@, qr/^substr: .*isn't numeric in substr/, 'offset warning converted to substr error');
  unlike($@, qr/\sat\s+\S+\s+line\s+\d+/, 'offset error has no file/line tail');

  my $ini_length = <<'INI';
[sec]
x := $(=& substr, abcdef, 1, b)
INI

  $ok = eval {
    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini_length);
    1;
  };

  ok(!$ok, 'substr with non-numeric length dies');
  like($@, qr/^substr: .*isn't numeric in substr/, 'length warning converted to substr error');
  unlike($@, qr/\sat\s+\S+\s+line\s+\d+/, 'length error has no file/line tail');
};

#==================================================================================================
done_testing();
