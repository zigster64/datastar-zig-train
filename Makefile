help:
	cat Makefile

run:
	zig build run

deps:
	zig fetch --save git+https://github.com/zigster64/http.zig#tardy-sse

loadtest:
	#h2load -n 1000 -c 100 -m 100  http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D
	h2load -n 100 -c 100 -m 100  http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D

curl:
	curl http://localhost:8081/hello?datastar=%7B%22delay%22%3A500%7D

curl200:
	@for i in $$(seq 1 200); do \
		curl -s -N http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D > /dev/null & \
	done; \
	wait

curl20k:
	@for i in $$(seq 1 20000); do \
		curl -s -N http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D > /dev/null & \
	done; \
	wait
