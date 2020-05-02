Imagine this was some documentation and we had an HTTP request right there in
the file. Why do I have to create a new buffer for it? That's just dumb lol!

```http
POST http://localhost:8000/post HTTP/1.1
Host: "localhost:8000"

I AM A READMEFILE HERE ME ROAR!
```

So let's execute this and see what happens:

```http
GET http://localhost:8000/get HTTP/1.1
Host: localhost:8000
```

Did it work?

```http
PATCH http://localhost:8000/patch HTTP/1.1
Host: "localhost:8000"

LOLOLOLOLOLOL
```

I hope so

Here is a picture of a cat:

![CAT!](https://i.imgur.com/DKUR9Tk.png)
