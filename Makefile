ifeq ($(RUST_TARGET),)
	TARGET :=
	RELEASE_SUFFIX :=
else
	TARGET := $(RUST_TARGET)
	RELEASE_SUFFIX := -$(TARGET)
	export CARGO_BUILD_TARGET = $(RUST_TARGET)
endif

PROJECT_NAME := xh

VERSION := $(subst $\",,$(word 3,$(shell grep -m1 "^version" Cargo.toml)))
RELEASE := $(PROJECT_NAME)-$(VERSION)$(RELEASE_SUFFIX)

DIST_DIR := dist
RELEASE_DIR := $(DIST_DIR)/$(RELEASE)
MANUAL_DIR := $(RELEASE_DIR)/man
COMPLETIONS_DIR := $(RELEASE_DIR)/completions

BINARY := target/$(TARGET)/release/$(PROJECT_NAME)
MANUAL := doc/$(PROJECT_NAME).1
COMPLETIONS := $(addprefix completions/,_xh xh.bash xh.fish xh.elv xh.nu)

RELEASE_BINARY := $(RELEASE_DIR)/$(PROJECT_NAME)
RELEASE_MANUAL := $(MANUAL_DIR)/$(notdir $(MANUAL))
RELEASE_COMPLETIONS := $(addprefix $(COMPLETIONS_DIR)/,$(notdir $(COMPLETIONS)))

ARTIFACT := $(RELEASE).tar.xz

.PHONY: all
all: $(ARTIFACT)

.PHONY: doc
doc: clean-doc $(MANUAL) $(COMPLETIONS)

.PHONY: clean-doc
clean-doc:
	$(RM) $(MANUAL) $(COMPLETIONS)

$(BINARY):
	cargo build --locked --release

$(MANUAL):
	cargo run --all-features -- --generate man > $@

$(COMPLETIONS) &:
	cargo run --all-features -- --generate complete-zsh > completions/_xh
	cargo run --all-features -- --generate complete-bash > completions/xh.bash
	cargo run --all-features -- --generate complete-fish > completions/xh.fish
	cargo run --all-features -- --generate complete-elvish > completions/xh.elv
	cargo run --all-features -- --generate complete-nushell > completions/xh.nu

$(DIST_DIR) $(RELEASE_DIR) $(MANUAL_DIR) $(COMPLETIONS_DIR):
	mkdir -p $@

$(RELEASE_BINARY): $(BINARY) | $(RELEASE_DIR)
	cp -f $< $@
$(RELEASE_MANUAL): $(MANUAL) | $(MANUAL_DIR)
	cp -f $< $@
$(RELEASE_COMPLETIONS): $(COMPLETIONS) | $(COMPLETIONS_DIR)
	cp -f $< $@

$(ARTIFACT): $(RELEASE_BINARY) $(RELEASE_MANUAL) $(RELEASE_COMPLETIONS)
	tar -C $(DIST_DIR) -Jcvf $@ $(RELEASE)

.PHONY: clean
clean:
	$(RM) -r $(ARTIFACT) $(DIST_DIR)
