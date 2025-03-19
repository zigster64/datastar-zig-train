all:
	find src -name '.env' -o -name '*.zig' -o -name '*.html' | entr zig build -freference-trace=11 run

run:
	zig build run

curl:
	curl http://localhost:8081/hello?datastar=%7B%22delay%22%3A500%7D

hammer200:
	@for i in $$(seq 1 200); do \
		curl http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D > /dev/null & \
	done; \
	wait

hammer20k:
	@for i in $$(seq 1 20000); do \
		curl http://localhost:8081/hello?datastar=%7B%22delay%22%3A1200%7D > /dev/null & \
	done; \
	wait
