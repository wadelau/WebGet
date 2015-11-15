# WebGet
An emulating tool for HTTP(S)

##What:
WebGet: An emulating tool for http requests in command line.

In coding or programming for web and networking, developers are compelled to debug the commnunications between clients and servers. Usually these happen by HTTP(S). WebGet is created to meet this purpose.....

By: Zhenxing Liu, Wade lau

It features include support for HTTP/1.1, HTTPS and defined User-Agent, and so on. 
However webget is not designed to do something which wget(-R/wget) could do in some environments. 
Webget is trying to replace telnet(-R/telnet) by grouping a set of comands to be sent from a client to a server. 

## Usage: 
After download from the link below and compile it, execute like:

shell> ./webget 

Usage: ./webget SOME_KIND_URL

e.g.

./webget /servicelist.jsp 

or 

./webget http://wap.ufqi.com/servicelist.jsp 

or 

./webget wap.ufqi.com/servicelist.jsp 

or 

./webget 172.24.100.4/servicelist.jsp 
