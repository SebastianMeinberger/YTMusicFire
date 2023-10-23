PKGNAME := ytmusicfire
PROFILE_USERNAME := YTMusicFireUser
PREFIX = /usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/

EXTENSIONS := ublock-origin+uBlock0@raymondhill.net sponsorblock+sponsorBlocker@ajay.app
define EXTENSIONS_NAME
$(firstword $(subst +, ,$(1)))
endef
define EXTENSIONS_ID
$(lastword $(subst +, ,$(1)))
endef

_FETCH_PATHS = $(foreach extension,$(EXTENSIONS),$(call EXTENSIONS_NAME, $(extension)))
FETCH_PATHS = $(patsubst %,extensions/%.xpi,$(_FETCH_PATHS))

extensions/%.xpi:
	install -d extensions
	cd extensions &&\
	wget https://addons.mozilla.org/firefox/downloads/latest/$*/$*.xpi
		
.PHONY: fetch_extensions
fetch_extensions: $(FETCH_PATHS)	

.PHONY: install_extenions
install_extensions: $(DESTDIR) fetch_extensions
	$(foreach extension, $(EXTENSIONS),\
		install -D extensions/$(call EXTENSIONS_NAME, $(extension)).xpi $(DESTDIR)$(PREFIX)extensions/$(call EXTENSIONS_ID, $(extension)).xpi;\
	)

.PHONY: activate_extensions
activate_extensions: $(DESTDIR) install_extensions
	# First let firefox create all profile data. This is unfortunatly not done in CreateProfile but only on first startup. But the upside is, that this will disable the firefox post-install instructions, since the profile was already used one time after this runs.
	/bin/bash WaitForFfFiles.sh $(DESTDIR) $(PREFIX) 
	# Set active true for uBlock
	jq '.addons |= map (select(.id == "uBlock0@raymondhill.net").active |= true)' $(DESTDIR)$(PREFIX)extensions.json > tmp
	# Set userDisabled false for uBlock
	jq '.addons |= map (select(.id == "uBlock0@raymondhill.net")."userDisabled" |= false)' tmp > $(DESTDIR)$(PREFIX)extensions.json
	# Enable uBlock in addonStartup
	python3 mozlz4a.py -d $(DESTDIR)$(PREFIX)addonStartup.json.lz4 | jq '."app-profile".addons."uBlock0@raymondhill.net".enabled |= true' > tmp
	python3 mozlz4a.py tmp > $(DESTDIR)$(PREFIX)addonStartup.json.lz4

.PHONY: install
install: $(DESTDIR) activate_extensions
	# Hide URL bar and navbar
	install -D userChrome.css $(DESTDIR)$(PREFIX)chrome/userChrome.css
	install user.js $(DESTDIR)$(PREFIX)user.js
	# Install desktop entry
	install -D ytmusic.desktop $(DESTDIR)/usr/share/applications/ytmusic.desktop
