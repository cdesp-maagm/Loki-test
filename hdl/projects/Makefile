
DIRS=$(dir $(wildcard */Makefile))

%:
	for d in $(DIRS); do make -C $$d $@; done
