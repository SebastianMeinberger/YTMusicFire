PKGNAME := ytmusicfire
PROFILE_USERNAME := YTMusicFireUser
DESTDIR :=
PROFILE_PATH :=

.PHONY: install
install: $(DESTDIR)
	install -d $(DESTDIR)/usr/share/$(PKGNAME)
	firefox -CreateProfile "$(PROFILE_USERNAME) $(DESTDIR)/usr/share/$(PKGNAME)/$(PROFILE_USERNAME)"
	install -D userChrome.css $(DESTDIR)/usr/share/$(PKGNAME)/$(PROFILE_USERNAME)/chrome/userChrome.css
