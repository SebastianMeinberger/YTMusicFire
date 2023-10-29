PKGNAME := ytmusicfire
PROFILE_USERNAME := YTMusicFireUser
PREFIX = /usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/

# To add more extensions on install, add <extension-name>+<extension-id> to this string. The correct writing of the name can be found in the url of the corresponding mozilla addon page and the id can be found in the manifest (Which can be found in the xpi file. These are basically just jars).
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

# Set the standard configuration for sponsorblock. This is meant to enable autoskip on non music segments, but by changing the sponsorblock_default_conf.json you can setup any default conf.
activate_sponsorblock+sponsorBlocker@ajay.app:: create_profile
	sqlite3 $(DESTDIR)$(PREFIX)storage-sync-v2.sqlite "INSERT INTO storage_sync_data VALUES('sponsorBlocker@ajay.app','$(shell cat sponsorblock_default_conf.json)',0)"

# Set the neccesary vars in extension.json and addonStartup.json.lz4. Note that this rule is a double colon rule. When adding an additional double colon rule for a specific extension, the recepies of both are executed for that extension.
.PHONY: $(addprefix activate_, $(EXTENSIONS))
$(addprefix activate_, $(EXTENSIONS)):: activate_%: create_profile
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
	# Install files for hiding URL- and navbar
	install -Dm 660 userChrome.css $(DESTDIR)$(PREFIX)chrome/userChrome.css
	install -m 770 user.js $(DESTDIR)$(PREFIX)user.js
	# Install executable and desktop entry
	install -m 733 ytmusicfire $(DESTDIR)/usr/bin/ytmusicfire
	install -m 733 ytmusicfire.desktop $(DESTDIR)/usr/share/applications/ytmusic.desktop
