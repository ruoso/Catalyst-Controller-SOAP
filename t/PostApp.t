use Test::More tests => 14;
use File::Spec::Functions;
use HTTP::Response;
use IPC::Open3;
use Symbol;

my $response;

$response = soap_xml_post
  ('/ws/hello',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );

like($response->content, qr/Hello World/, 'Document Literal correct response: '.$response->content);
# diag("/ws/hello: ".$response->content);

$response = soap_xml_post
  ('/ws2',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><hello>World</hello></Body></Envelope>'
  );
like($response->content, qr/Hello World/, 'RPC Literal Correct response: '.$response->content);
# diag("/ws2: ".$response->content);

$response = soap_xml_post
  ('/ws/foo',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );
like($response->content, qr/\<foo\>\<bar\>\<baz\>Hello World\!\<\/baz\>\<\/bar\>\<\/foo\>/, 'Literal response: '.$response->content);
# diag("/wsl/foo: ".$response->content);

$response = soap_xml_post
  ('/withwsdl/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <Body>
        <GreetingSpecifier xmlns="http://example.com/hello">
          <who>World</who>
          <greeting>Hello</greeting>
          <count>1</count>
        </GreetingSpecifier>
      </Body>
    </Envelope>'
  );
like($response->content, qr/greeting\>1 Hello World\!\<\//, 'Literal response: '.$response->content);
# diag("/withwsdl/Greet: ".$response->content);


$response = soap_xml_post
  ('/withwsdl/doclw',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><GreetingSpecifier xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting><count>2</count></GreetingSpecifier></Body></Envelope>'
  );
like($response->content, qr/greeting\>2 Hello World\!\<\//, ' Document/Literal Wrapped response: '.$response->content);
# diag("/withwsdl/doclw: ".$response->content);

$response = soap_xml_post
  ('/withwsdl2/Greet','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Greet xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting><count>3</count></Greet></Body></Envelope>
  ');
like($response->content, qr/greeting[^>]+\>3 Hello World\!Math::BigInt\<\//, 'RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

$response = soap_xml_post
  ('/withwsdl2/Greet','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
         <Body>
            <Greet xmlns="http://example.com/hello">
               <who>World</who>
               <greeting>Hello</greeting>
               <count>4</count>
            </Greet>
         </Body>
    </Envelope>
  ');
ok($response->content =~ /greeting[^>]+\>4 Hello World\!Math::BigInt\<\//, 'RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

$response = soap_xml_post
  ('/withwsdl/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><GreetingSpecifier xmlns="http://example.com/hello"><name>World</name><greeting>Hello</greeting></GreetingSpecifier></Body></Envelope>'
  );
like($response->content, qr/Fault/, 'Fault on malformed body for Document-Literal: '.$response->content);
# diag("/withwsdl/Greet: ".$response->content);

$response = soap_xml_post
  ('/ws/bar',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );
like($response->content, qr/Fault/, 'Fault for uncaugh exception: '.$response->content);
# diag("/ws/bar: ".$response->content);

$response = soap_xml_post
  ('/hello/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <Body>
        <GreetingSpecifier xmlns="http://example.com/hello">
          <who>World</who>
          <greeting>Hello</greeting>
        </GreetingSpecifier>
      </Body>
    </Envelope>'
  );
like($response->content, qr/greeting\>Hello World\!\<\//, ' using WSDLPort response: '.$response->content);
# diag("/withwsdl/Greet: ".$response->content);

$response = soap_xml_post
  ('/hello/Shout',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
      <Body>
        <GreetingSpecifier xmlns="http://example.com/hello">
          <who>World</who>
          <greeting>Hello</greeting>
        </GreetingSpecifier>
      </Body>
    </Envelope>'
  );
like($response->content, qr/greeting\>HELLO WORLD\!\!\<\//, ' using WSDLPort response: '.$response->content);
# diag("/withwsdl/Shout: ".$response->content);


$response = soap_xml_post
  ('/rpcliteral','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Greet xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting></Greet></Body></Envelope>
  ');
like($response->content, qr/greeting[^>]+\>Hello World\!\<\//, ' WSDLPort RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

$response = soap_xml_post
  ('/rpcliteral','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Shout xmlns="http://example.com/hello"><who>World</who><greeting>Hello</greeting></Shout></Body></Envelope>
  ');
like($response->content, qr/greeting[^>]+\>HELLO WORLD\!\<\//, ' WSDLPort RPC Literal response: '.$response->content);
# diag("/withwsdl2/Greet: ".$response->content);

# provoke a SOAP Fault
$response = soap_xml_post
  ('/ws/hello','');
my $soapfault = 'SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Body><SOAP-ENV:Fault><faultcode>SOAP-ENV:Client'; 
ok($response->content =~ /$soapfault/ , ' SOAP Fault response: '.$response->content);

sub soap_xml_post {
    my $path = shift;
    my $content = shift;

    local %ENV;
    $ENV{REMOTE_ADDR} ='127.0.0.1';
    $ENV{CONTENT_LENGTH} = length $content;
    $ENV{CONTENT_TYPE} ='application/soap+xml';
    $ENV{SCRIPT_NAME} = $path;
    $ENV{QUERY_STRING} = '';
    $ENV{CATALYST_DEBUG} = 0;
    $ENV{REQUEST_METHOD} ='POST';
    $ENV{SERVER_PORT} ='80';
    $ENV{SERVER_NAME} ='pitombeira';
    $ENV{HTTP_SOAPAction} = 'http://example.com/actions/Greet';    

    my ($writer, $reader, $error) = map { gensym() } 1..3;
    my $pid = open3($writer, $reader, $error,
                    $^X, (map { '-I'.$_ } @INC),
                    catfile(qw(t PostApp script postapp_cgi.pl)));

    print {$writer} $content;
    close $content;

    my $response_str = join '', <$reader>;
    map { warn '# '.$_ } <$error>;

    close $reader;
    close $error;
    waitpid $pid, 0;
    return HTTP::Response->parse($response_str);
}

1;
