help:
	cat Makefile

run:
	ulimit -n 65536
	zig build run -Doptimize=ReleaseFast

build-bsd:
	zig build -Doptimize=ReleaseFast -Dtarget=x86_64-freebsd

deps:
	#zig fetch --save git+https://github.com/zigster64/http.zig#tardy-sse
	zig fetch --save git+https://github.com/karlseguin/http.zig

lowertimeout:
	# on mac, do this t drop the dead socket from 15s down to 1 second, to help with benchmarking
	sudo sysctl -w net.inet.tcp.msl=1000

loadtest:
	go run client/main.go
	#h2load -n 1000 -c 100 -m 100  http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D
	#siege -b -t 1m -c10 http://localhost:8081/hello?datastar=%7B%22delay%22%3A500%7D

hello:
	curl http://localhost:8081/hello?datastar=%7B%22delay%22%3A500%7D

clock:
	curl http://localhost:8081/clock

curl200:
	ulimit -n 65536
	@for i in $$(seq 1 200); do \
		curl -s -N http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D > /dev/null & \
	done; \
	wait

curl20k:
	ulimit -n 65536
	@for i in $$(seq 1 20000); do \
		curl -s -N http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D > /dev/null & \
	done; \
	wait
