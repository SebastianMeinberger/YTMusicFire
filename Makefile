PKGNAME := ytmusicfire
PROFILE_USERNAME := YTMusicFireUser
PREFIX = /usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/

.PHONY: fetch_extensions
fetch_extensions:
	install -d extensions
	cd extensions &&\
	wget https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/uBlock.xpi

.PHONY: activate_extensions
activate_extensions: $(DESTDIR)
	# Set active true for uBlock
	jq '.addons |= map (select(.id == "uBlock0@raymondhill.net").active |= true)' $(DESTDIR)$(PREFIX)extensions.json > tmp
	# Set userDisabled false for uBlock
	jq '.addons |= map (select(.id == "uBlock0@raymondhill.net")."userDisabled" |= false)' tmp > $(DESTDIR)$(PREFIX)extensions.json
	# Enable uBlock in addonStartup
	python3 mozlz4a.py -d $(DESTDIR)$(PREFIX)addonStartup.json.lz4 | jq '."app-profile".addons."uBlock0@raymondhill.net".enabled |= true' > tmp
	python3 mozlz4a.py tmp > $(DESTDIR)$(PREFIX)addonStartup.json.lz4

.PHONY: install
install: $(DESTDIR)
	install -d $(DESTDIR)/usr/share/$(PKGNAME)
#	Profile creation
	firefox -CreateProfile "$(PROFILE_USERNAME) $(DESTDIR)/usr/share/$(PKGNAME)/$(PROFILE_USERNAME)"
#	Hide URL bar and navbar
	install -D userChrome.css $(DESTDIR)/usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/chrome/userChrome.css
	install user.js $(DESTDIR)/usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/user.js
#	Install extensions
	install -D extensions/uBlock.xpi $(DESTDIR)/usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/extensions/uBlock0@raymondhill.net.xpi
