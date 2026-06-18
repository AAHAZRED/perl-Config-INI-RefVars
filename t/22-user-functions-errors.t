use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

sub dies_like {
  my ($name, $ini, $re) = @_;

  my $ok = eval {
    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini);
    1;
  };

  ok(!$ok, "$name dies");
  like($@, $re, "$name error message");
}

subtest 'unknown user functions' => sub {
  dies_like(
    'unknown unqualified function',
    <<'INI',
[sec]
x = $(=# does_not_exist)
INI
    qr/unknown function 'does_not_exist'/,
  );

  dies_like(
    'unknown qualified function in existing section',
    <<'INI',
[other]
known #= ok

[sec]
x = $(=# [other]does_not_exist)
INI
    qr/unknown function '\[other\]does_not_exist'/,
  );

  dies_like(
    'unknown qualified function in missing section',
    <<'INI',
[sec]
x = $(=# [missing]does_not_exist)
INI
    qr/unknown function '\[missing\]does_not_exist'/,
  );
};

subtest 'qualified user function calls' => sub {
  my $ini = <<'INI';
fmt #= GLOBAL:$(1)

[a]
fmt #= A:$(1)

[b]
fmt #= B:$(1)
x = $(=# fmt,x)
y = $(=# [a]fmt,y)
z = $(=# [__TOCOPY__]fmt,z)
INI

  my $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => $ini);

  my $vars = $obj->variables();

  is($vars->{b}{x}, 'B:x', 'unqualified call uses local function');
  is($vars->{b}{y}, 'A:y', 'qualified call uses function from explicit section');
  is($vars->{b}{z}, 'GLOBAL:z', 'qualified call can use tocopy function');
};

subtest 'qualified call does not fall back to builtin' => sub {
  dies_like(
    'qualified builtin fallback is not allowed',
    <<'INI',
[sec]
x = $(=# [sec]concat,a,b)
INI
    qr/unknown function '\[sec\]concat'/,
  );
};

subtest 'malformed and empty calls' => sub {
  dies_like(
    'empty user function call',
    <<'INI',
[sec]
x = $(=#)
INI
    qr/empty function call/,
  );

  dies_like(
    'blank user function call',
    <<'INI',
[sec]
x = $(=#    )
INI
    qr/empty function call/,
  );

  dies_like(
    'empty qualified function basename',
    <<'INI',
[sec]
x = $(=# [sec])
INI
    qr/unknown function '\[sec\]'/,
  );
};

subtest 'recursive user functions die cleanly' => sub {
  dies_like(
    'direct recursive function',
    <<'INI',
rec #= $(=# rec)

[sec]
x = $(=# rec)
INI
    qr/recursive function '\[__TOCOPY__\]#=rec' calls itself/,
  );

  dies_like(
    'indirect recursive function',
    <<'INI',
a #= $(=# b)
b #= $(=# a)

[sec]
x = $(=# a)
INI
    qr/recursive function '\[__TOCOPY__\]#=a' calls itself/,
  );

  dies_like(
    'section-local recursive function',
    <<'INI',
[sec]
rec #= $(=# rec)
x = $(=# rec)
INI
    qr/recursive function '\[sec\]#=rec' calls itself/,
  );
};

subtest 'recursive user functions restore temporary parameters' => sub {
  my $ini = <<'INI';
rec #= $(1)$(=# rec,$(1))
ok  #= $(1):$(2)

[sec]
1 = original-1
2 = original-2
bad = $(=# rec,x)
good = $(=# ok,a,b)
INI

  my $obj = Config::INI::RefVars->new();

  my $ok = eval {
    $obj->parse_ini(src => $ini);
    1;
  };

  ok(!$ok, 'recursive function dies');
  like($@, qr/recursive function '\[__TOCOPY__\]#=rec' calls itself/, 'clean recursive function error');

  my $ini_after = <<'INI';
ok #= $(1):$(2)

[sec]
1 = original-1
2 = original-2
good = $(=# ok,a,b)
check = $(1):$(2)
INI

  $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => $ini_after);

  my $vars = $obj->variables();

  is($vars->{sec}{good}, 'a:b', 'function still works after recursion error in new object');
  is($vars->{sec}{check}, 'original-1:original-2', 'numeric variables are not left polluted');
};

done_testing();

