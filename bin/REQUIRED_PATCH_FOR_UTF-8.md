* The following patch to XMLRPC/Lite.pm is required in order to have utf8 data handled correctly when being transported by the html2xmlrpc procedures. See webwork2 issue #967



This patch replaces line 55 of /usr/share/perl5/XMLRPC/Lite.pm which originally was:

     base64 => [10, sub {$_[0] =~ /[^\x09\x0a\x0d\x20-\x7f]/}, 'as_base64'],

with the following replacement line:

     base64 => [10, sub {$_[0] =~ /[^\x09\x0a\x0d\x20-\x7f]/ && !utf8::is_utf8($_[0])}, 'as_base64'],
     
     
