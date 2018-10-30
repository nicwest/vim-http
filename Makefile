.PHONY: test setup httpbin

test:
	vim-themis/bin/themis --reporter dot test

setup:
	docker pull citizenstig/httpbin
	git clone git@github.com:thinca/vim-themis.git

httpbin:
	docker run -d=true -p 8000:8000 citizenstig/httpbin
