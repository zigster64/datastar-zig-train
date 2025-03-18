all:
	find src -name '.env' -o -name '*.zig' -o -name '*.html' | entr zig build -freference-trace=11 run
