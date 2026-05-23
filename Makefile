APP_NAME = Sysprite
BUILD_DIR = .build
CONFIG = release
BIN = $(BUILD_DIR)/$(CONFIG)/$(APP_NAME)
APP = $(BUILD_DIR)/$(APP_NAME).app
ICON = Resources/AppIcon.icns

.PHONY: all build app run install clean sprites icon test release-zip

all: app

build:
	swift build -c $(CONFIG)

test:
	swift test

sprites:
	swift scripts/generate_sprites.swift

icon:
	swift scripts/generate_icon.swift

$(ICON):
	$(MAKE) icon

app: build $(ICON)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	mkdir -p $(APP)/Contents/Resources
	cp Info.plist $(APP)/Contents/Info.plist
	cp $(BIN) $(APP)/Contents/MacOS/$(APP_NAME)
	cp $(ICON) $(APP)/Contents/Resources/AppIcon.icns
	@if [ -d Resources/Themes ]; then \
		cp -R Resources/Themes $(APP)/Contents/Resources/Themes; \
	fi
	codesign --force --deep --sign - $(APP) >/dev/null 2>&1 || true
	@echo "Built $(APP)"

run: app
	open $(APP)

install: app
	pkill -f "/Applications/$(APP_NAME).app" 2>/dev/null || true
	rm -rf /Applications/$(APP_NAME).app
	cp -R $(APP) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

release-zip: app
	cd $(BUILD_DIR) && rm -f $(APP_NAME).zip && zip -qry $(APP_NAME).zip $(APP_NAME).app
	@echo "Wrote $(BUILD_DIR)/$(APP_NAME).zip"

clean:
	rm -rf $(BUILD_DIR)
