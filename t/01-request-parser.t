use v6;
use Test;

use HTTP::Parser;

my @cases =
    ["GET / HTTP/1.0\r\n\r\n", [
        18, {
            :PATH-INFO("/"),
            :QUERY-STRING(""),
            :REQUEST-METHOD("GET"),
            :SERVER-PROTOCOL("HTTP/1.0"),
            :REQUEST-URI</>,
            :SCRIPT-NAME(''),
        }
    ]],
    ["\r\nGET / HTTP/1.0\r\n\r\n", [ # pre-header blank lines are allowed (RFC 2616 4.1)
        20, {
            :PATH-INFO("/"),
            :QUERY-STRING(""),
            :REQUEST-METHOD("GET"),
            :SERVER-PROTOCOL("HTTP/1.0"),
            :REQUEST-URI</>,
            :SCRIPT-NAME(''),
        }
    ]],
    ["GET / HTTP/1.1\r\ncontent-type: text/html\r\n\r\n", [
        43, {
            :CONTENT-TYPE("text/html"),
            :PATH-INFO("/"),
            :QUERY-STRING(""),
            :REQUEST-METHOD("GET"),
            :SERVER-PROTOCOL("HTTP/1.1"),
            :REQUEST-URI</>,
            :SCRIPT-NAME(''),
        }
    ]],
    ["GET /foo?bar=3 HTTP/1.1\r\n\r\n", [
        27, {
            :PATH-INFO("/foo"),
            :QUERY-STRING("bar=3"),
            :REQUEST-METHOD("GET"),
            :SERVER-PROTOCOL("HTTP/1.1"),
            :REQUEST-URI</foo?bar=3>,
            :SCRIPT-NAME(''),
        }
    ]],
    ["GET /foo%2A%2c?bar=3 HTTP/1.1\r\n\r\n", [
        33, {
            REQUEST-METHOD => 'GET',
            PATH-INFO => '/foo*,',
            QUERY-STRING => 'bar=3',
            SERVER-PROTOCOL => 'HTTP/1.1',
            :REQUEST-URI</foo%2A%2c?bar=3>,
            :SCRIPT-NAME(''),
        }
    ]],
    ["GET / HTTP/1.0\r\n", [
        -1, Nil
    ]],
    ["GET / HTTP/1.0\r\nhogehoge\r\n\r\n", [
        -2, Nil
    ]],
    ["mattn\r\n\r\n", [
        -2, Nil
    ]],
;

for @cases {
    my ($req, $expected) = @($_);
    is-deeply [parse-http-request($req.encode('ascii'))], $expected, $req.subst(/\r/, '\\r', :g).subst(/\n/, '\\n', :g);
}

done-testing;
