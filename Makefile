SHELL:=/bin/bash -eo pipefail
.PHONY: $(PHONY)
.FORCE:
$(FORCE): .FORCE

.PHONY: all
all: dl szintek

dl: temak.tsv
	./dlall.sh

szintek: dl temak.tsv
	while read line; do \
		name="$@/`echo "$$line" | cut -d$$'\t' -f2`/`echo "$$line" | cut -d$$'\t' -f3`"; \
		target="`dirname "$$name" | sed 's#[^/][^/]*#..#g'`/$</`echo "$$line" | cut -d$$'\t' -f3`"; \
		echo "$$line"; \
		mkdir -p "`dirname "$$name"`"; \
		ln -s "$$target" "$$name"; \
	done < <(tail -n +2 temak.tsv)
