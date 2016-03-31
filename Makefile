
# LUAVER should be 5.1 for luajit, which is the default
# To use *real* lua, change LUAVER to current lua version and modify mycroft.lua to refer to the correct version
LUAVER=5.1
MODULE_INSTALL_PATH=/usr/share/lua/${LUAVER}/mycroft

build:
	echo "Nothing to do"

install: install_main install_doc install_vim install_module_lookup

test: mycroft.lua
	./mycroft.lua -t

mycroft.1: makeman.sh
	./makeman.sh > mycroft.1

install_man: mycroft.1
	mkdir -p /usr/share/man/man1/
	cp mycroft.1 /usr/share/man/man1/

install_doc: install_man
	mkdir -p /usr/share/doc/mycroft
	cp *.md /usr/share/doc/mycroft

install_vim: mycroft.vim
	mkdir -p /usr/share/vim/vim74/
	cp mycroft.vim /usr/share/vim/vim74/
	echo "au BufNewFile,BufRead *.myc set syntax=mycroft" >> ~/.vimrc
	touch install_vim

install_module: mycBuiltins.lua mycCore.lua mycErr.lua mycNet.lua mycParse.lua mycPretty.lua mycTests.lua mycType.lua hash.lua init.lua
	mkdir -p ${MODULE_INSTALL_PATH}
	cp mycBuiltins.lua ${MODULE_INSTALL_PATH}/
	cp mycCore.lua ${MODULE_INSTALL_PATH}/
	cp mycErr.lua ${MODULE_INSTALL_PATH}/
	cp mycNet.lua ${MODULE_INSTALL_PATH}/
	cp mycParse.lua ${MODULE_INSTALL_PATH}/
	cp mycPretty.lua ${MODULE_INSTALL_PATH}/
	cp mycTests.lua ${MODULE_INSTALL_PATH}/
	cp mycType.lua ${MODULE_INSTALL_PATH}/
	cp hash.lua ${MODULE_INSTALL_PATH}/
	cp init.lua ${MODULE_INSTALL_PATH}/

install_main: install_module mycroft.lua
	cp mycroft.lua /usr/bin/mycroft

install_module_lookup:
	mkdir -p /usr/share/mycroft
	cp test.myc /usr/share/mycroft/
	cp mycroftBase.myc /usr/share/mycroft/
