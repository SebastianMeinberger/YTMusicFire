PKGNAME := ytmusicfire
PROFILE_USERNAME := YTMusicFireUser
PREFIX = /usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/

# To add more extensions on install, add <extension-name>+<extension-id> to this string. The id can be found in the manifest.
EXTENSIONS := ublock-origin+uBlock0@raymondhill.net sponsorblock+sponsorBlocker@ajay.app
define EXTENSIONS_NAME
$(firstword $(subst +, ,$(1)))
endef
define EXTENSIONS_ID
$(lastword $(subst +, ,$(1)))
endef

extensions/%.xpi:
	install -d extensions
	cd extensions &&\
	wget https://addons.mozilla.org/firefox/downloads/latest/$*/$*.xpi

# Install the extension to DESTDIR+PREFIX, fetch it if neccesarry.
.PHONY: $(addprefix install_,$(EXTENSIONS))
.SECONDEXPANSION:
$(addprefix install_, $(EXTENSIONS)): install_%: extensions/$$(call EXTENSIONS_NAME, %).xpi
	install -D extensions/$(call EXTENSIONS_NAME, $*).xpi $(DESTDIR)$(PREFIX)extensions/$(call EXTENSIONS_ID, $*).xpi

# Before the files for the profile are created, all extensions need to be installed, otherwise the corresponding vars in extensions.json and addonStartup.json.lz4 will be missing
.PHONY: create_profile
create_profile: $(addprefix install_,$(EXTENSIONS))
	/bin/bash WaitForFfFiles.sh $(DESTDIR) $(PREFIX)

# Set the neccesary vars in extension.json and addonStartup.json.lz4
.PHONY: $(addprefix activate_, $(EXTENSIONS))
$(addprefix activate_, $(EXTENSIONS)): activate_%: create_profile
	# Set active true
	jq '.addons |= map (select(.id == "$(call EXTENSIONS_ID, $*)").active |= true)' $(DESTDIR)$(PREFIX)extensions.json > $*_tmp
	# Set userDisabled false
	jq '.addons |= map (select(.id == "$(call EXTENSIONS_ID, $*)")."userDisabled" |= false)' $*_tmp > $(DESTDIR)$(PREFIX)extensions.json
	# Enable extension in addonStartup
	python3 mozlz4a.py -d $(DESTDIR)$(PREFIX)addonStartup.json.lz4 | jq '."app-profile".addons."$(call EXTENSIONS_ID, $*)".enabled |= true' > $*_tmp
	python3 mozlz4a.py $*_tmp > $(DESTDIR)$(PREFIX)addonStartup.json.lz4
	rm $*_tmp


.PHONY: install
install: $(DESTDIR) $(addprefix activate_,$(EXTENSIONS))
	# Hide URL bar and navbar
	install -D userChrome.css $(DESTDIR)$(PREFIX)chrome/userChrome.css
	install user.js $(DESTDIR)$(PREFIX)user.js
	# Install desktop entry
	install -D ytmusic.desktop $(DESTDIR)/usr/share/applications/ytmusic.desktop
