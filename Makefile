
_build/default/main.exe: $(wildcard *.ml) jbuild
	jbuilder build main.exe

.PHONY: build
build: _build/default/main.exe

.PHONY: clean
clean:
	$(RM) -r ./_build
	$(RM) ./libfalconn-wrapper.so
	$(RM) ./test

.PHONY: run
run: build libfalconn-wrapper.so
	./_build/default/main.exe
	
.PHONY: build-falconn
build-falconn:
	(cd ./submodules/falconn/; make run_all_cpp_tests)

libfalconn-wrapper.so: falconn-wrapper.cpp
	g++ -shared -fPIC -std=c++14 -Wall -O3 -march=native $< -o $@ -I ./submodules/falconn/src/include -I ./submodules/falconn/external/eigen -pthread

