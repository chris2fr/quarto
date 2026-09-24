.PHONY: help test test-site check-version version bump release clean

BUMP := _extensions/base/scripts/bump-version.sh

help:
	@echo "make test           render everything in test/ (see test/Makefile)"
	@echo "make test-site      render test/site-demo (site-html)"
	@echo "make version        show the lockstep extension versions; fail if they differ"
	@echo "make bump V=X.Y.Z   set the lockstep extension versions"
	@echo "make release V=X.Y.Z bump, commit \"Version vX.Y.Z\" and tag vX.Y.Z (no push)"
	@echo "make clean          remove render artifacts from test/"

test:
	$(MAKE) -C test all

test-site:
	cd test/site-demo && quarto render

version check-version:
	@$(BUMP)

bump:
	@test -n "$(V)" || { echo "Usage: make bump V=X.Y.Z" >&2; exit 2; }
	@$(BUMP) $(V)

release:
	@test -n "$(V)" || { echo "Usage: make release V=X.Y.Z" >&2; exit 2; }
	@grep -q '^## v$(V)$$' CHANGELOG.md || { echo "CHANGELOG.md has no '## v$(V)' heading" >&2; exit 1; }
	@git diff --quiet && git diff --cached --quiet || { echo "Working tree has uncommitted changes to tracked files" >&2; exit 1; }
	@! git rev-parse -q --verify refs/tags/v$(V) >/dev/null || { echo "Tag v$(V) already exists" >&2; exit 1; }
	@$(BUMP) $(V)
	@git add CHANGELOG.md _extensions/*/_extension.yml
	git commit -m "Version v$(V)"
	git tag v$(V)
	@echo "Released v$(V) locally. Publish with: git push && git push origin v$(V)"

clean:
	-$(MAKE) -C test clean
