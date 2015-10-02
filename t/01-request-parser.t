use v6;
use Test;

use HTTP::Parser;

# no headers
my ($result, $env) = parse-http-request("GET / HTTP/1.0\r\n\r\n".encode('ascii'));
is $result, 18;
is $env<REQUEST_METHOD>, "GET";
is $env<PATH_INFO>, "/";
is $env<SERVER_PROTOCOL>, "HTTP/1.0";

# headers
{
    my ($result, $env) = parse-http-request("GET / HTTP/1.1\r\ncontent-type: text/html\r\n\r\n".encode('ascii'));
    is $result, 43;
    is $env<REQUEST_METHOD>, "GET";
    is $env<PATH_INFO>, "/";
    is $env<SERVER_PROTOCOL>, "HTTP/1.1";
    is $env<CONTENT_TYPE>, "text/html";
}

# query
{
    my ($result, $env) = parse-http-request("GET /foo?bar=3 HTTP/1.1\r\n\r\n".encode('ascii'));
    is $result, 27;
    is $env<REQUEST_METHOD>, "GET";
    is $env<PATH_INFO>, "/foo";
    is $env<QUERY_STRING>, "bar=3";
}

my @cases = (
    ("GET /foo%2A%2c?bar=3 HTTP/1.1\r\n\r\n", [
        33, {
            REQUEST_METHOD => 'GET',
            PATH_INFO => '/foo*,',
            QUERY_STRING => 'bar=3',
            SERVER_PROTOCOL => 'HTTP/1.1',
        }
    ])
);

for @cases -> $req, $expected {
    is-deeply [parse-http-request($req.encode('ascii'))], $expected, $req.subst(/\r/, '\\r', :g).subst(/\n/, '\\n', :g);
}

# incomplete
{
    my ($result, $env) = parse-http-request("GET / HTTP/1.0\r\n".encode('ascii'));
    is $result, -1;
}

# illegal
{
    my ($result, $env) = parse-http-request("mattn\r\n\r\n".encode('ascii'));
    is $result, -2;
}

done-testing;
