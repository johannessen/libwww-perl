#!/usr/bin/perl -w

use strict;
use Test qw(plan ok);
plan tests => 37;

use HTTP::MessageParts;
use HTTP::Request::Common qw(POST);
use Data::Dump qw(dump);

my $m = HTTP::Message->new;

ok(ref($m->headers), "HTTP::Headers");
ok($m->headers_as_string, "");
ok($m->content, "");
ok($m->parent, undef);
ok(j($m->parts), "");
ok($m->as_string, "\n");

my $m_clone = $m->clone;
$m->push_header("Foo", 1);
$m->add_content("foo");

ok($m_clone->as_string, "\n");
ok($m->headers_as_string, "Foo: 1\n");
ok($m->header("Foo"), 1);
ok($m->as_string, "Foo: 1\n\nfoo");
ok(j($m->parts), "");

$m->content_type("message/foo");
$m->content(<<EOT);
H1: 1
H2: 2
  3
H3:  abc

FooBar
EOT

my @parts = $m->parts;
ok(@parts, 1);
my $m2 = $parts[0];
ok(ref($m2), "HTTP::Message");

ok($m2->header("h1"), 1);
ok($m2->header("h2"), "2\n  3");
ok($m2->header("h3"), " abc");
ok($m2->content, "FooBar\n");
ok($m2->as_string, $m->content);
ok(j($m2->parts), "");

$m = POST("http://www.example.com",
	  Content_Type => 'form-data',
	  Content => [ foo => 1, bar => 2 ]);
ok($m->content_type, "multipart/form-data");
@parts = $m->parts;
ok(@parts, 2);
ok($parts[0]->header("Content-Disposition"), 'form-data; name="foo"');
ok($parts[0]->content, 1);
ok($parts[1]->header("Content-Disposition"), 'form-data; name="bar"');
ok($parts[1]->content, 2);

$m = HTTP::Message->new;
$m->content_type("message/http");
$m->content(<<EOT);
GET / HTTP/1.0
Host: example.com

How is this?
EOT

@parts = $m->parts;
ok(@parts, 1);
ok($parts[0]->method, "GET");
ok($parts[0]->uri, "/");
ok($parts[0]->protocol, "HTTP/1.0");
ok($parts[0]->header("Host"), "example.com");
ok($parts[0]->content, "How is this?\n");

$m = HTTP::Message->new;
$m->content_type("message/http");
$m->content(<<EOT);
HTTP/1.1 200 OK
Content-Type : text/html

<H1>Hello world!</H1>
EOT

@parts = $m->parts;
ok(@parts, 1);
ok($parts[0]->code, 200);
ok($parts[0]->message, "OK");
ok($parts[0]->protocol, "HTTP/1.1");
ok($parts[0]->content_type, "text/html");
ok($parts[0]->content, "<H1>Hello world!</H1>\n");


sub j { join(":", @_) }