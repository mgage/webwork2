#!/usr/bin/perl -w

#
use XMLRPC::Lite;
  my $soap = XMLRPC::Lite
   # -> proxy('https://math.webwork.rochester.edu/mod_xmlrpc/');
   # -> proxy('https://demo.webwork.rochester.edu:/mod_xmlrpc/');
   -> proxy('http://localhost/mod_xmlrpc/');
 print STDERR "intiating transport. Object created is ", $soap,"\n";   
	
  my $result = eval{  $result = $soap->call("WebworkXMLRPC.hi");
  };
  if ($@) {
	  print STDERR "failure |$@| \n";
  }
  print STDERR "return result is ", $result//"undef","\n";
  print STDERR "return value  is ", $result->result,"\n"; 
  
  unless ($result->fault) {
    print $result->result(),"\n";
  } else {
    print join ', ',
      $result->faultcode,
      $result->faultstring;
  }
