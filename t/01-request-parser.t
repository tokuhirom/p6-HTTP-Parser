use v6;
use Test;

use HTTP::Parser;

# no headers
my ($result, $env) = parse-http-request("GET / HTTP/1.0\r\n\r\n".encode('ascii'));
is $result, 18;
is $env<REQUEST_METHOD>, "GET";
is $env<PATH_INFO>, "/";

# headers
{
    my ($result, $env) = parse-http-request("GET / HTTP/1.0\r\ncontent-type: text/html\r\n\r\n".encode('ascii'));
    is $result, 43;
    is $env<REQUEST_METHOD>, "GET";
    is $env<PATH_INFO>, "/";
    is $env<CONTENT_TYPE>, "text/html";
}

# incomplete
{
    my ($result, $env) = parse-http-request("GET / HTTP/1.0\r\n".encode('ascii'));
    is $result, -1;
}

done-testing;
