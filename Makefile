APP_PATH=/Applications/WeChat.app/Contents/MacOS
TMP_PATH=/tmp
APP_NAME=WeChat
BACKUP_NAME=WeChat.bak
FRAMEWORK_PATH=WeChatTweak.framework
FRAMEWORK_NAME=WeChatTweak
DYLIB_NAME=WeChatTweak.dylib

debug::
	DYLD_INSERT_LIBRARIES=${FRAMEWORK_PATH}/${FRAMEWORK_NAME} ${APP_PATH}/${APP_NAME} &

clean::
	rm -rf ${FRAMEWORK_PATH}

install::
	@echo "Makefile installation has been deprecated!!!"
	@echo "For more information: \033[33;32mhttps://github.com/Sunnyyoung/WeChatTweak-CLI\033[0m."

uninstall::
	@echo "Makefile installation has been deprecated!!!"
	@echo "For more information: \033[33;32mhttps://github.com/Sunnyyoung/WeChatTweak-CLI\033[0m."
