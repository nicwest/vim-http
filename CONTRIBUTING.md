Contributing
============

All issues/pull requests are welcome.

That said, things that I'm unlikely to merge:

* Deviations from the various HTTP specs
  [rfc1945](https://tools.ietf.org/html/rfc1945)
  [rfc7230-7235](https://tools.ietf.org/html/rfc7230)
  [rfc7540](https://tools.ietf.org/html/rfc7540).
  The idea is that a request should be able to be piped into a connection to a
  web server (for example via telnet or openssl) and for the server to
  recognise the request.

* Binding things to keyboard shortcuts by default or with some kind of global
  flag. People to should be making their own decisions about where they bind
  things and/or if they need to bind stuff at all. I'm happy to merge
  suggestions into the README.

Tests
-----

The integration test use [httpbin](https://httpbin.org/), and assumes it
running locally. I use a 
[docker container](https://github.com/citizen-stig/dockerhttpbin):

```
docker pull citizenstig/httpbin
docker run -d=true -p 8000:8000 citizenstig/httpbin
```

To run the tests pull the 
[themis test suite](https://github.com/thinca/vim-themis) 
(you don't have to install it but you can if you want). I normally just dump it
in the plugin directory.

```
git clone git@github.com:thinca/vim-themis.git
./vim-themis/bin/themis --reporter dot test
```

The test responses use a VERY hacked together parsing to match against what
can be a somewhat dynamic set of headers etc.

Basically it will match anything inside a pair of `%%`:


```
"User-Agent": "curl/%% '[123.]\+' %%"
```

Would match 

```
"User-Agent": "curl/1.2.3"
```

But not

```
"User-Agent": "curl/4.5.6"
```

Or

```
"User-Agent": "curl/latest"
```
