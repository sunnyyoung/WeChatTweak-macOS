APP_PATH=/Applications/WeChat.app/Contents/MacOS
TMP_PATH=/tmp
APP_NAME=WeChat
BACKUP_NAME=WeChat.bak
FRAMEWORK_PATH=WeChatTweak.framework
FRAMEWORK_NAME=WeChatTweak
DYLIB_NAME=WeChatTweak.dylib

debug::
	DYLD_INSERT_LIBRARIES=${FRAMEWORK_PATH}/${FRAMEWORK_NAME} ${APP_PATH}/${APP_NAME} &

install::
	@xattr -rd com.apple.quarantine . ;
	@if ! [[ $EUID -eq 0 ]]; then\
    	echo "This script should be run using sudo or as the root user.";\
    	exit 1;\
	fi
	@if ! [ -f "${APP_PATH}/${APP_NAME}" ]; then\
		echo "Can not find the WeChat.";\
		exit 1;\
	fi
	@if ! [ -d "${FRAMEWORK_PATH}" ]; then\
		echo "Can not find the framework, please build first.";\
		echo "Or download the latest release zip: \033[33;32mhttps://github.com/Sunnyyoung/WeChatTweak-macOS/releases/latest\033[0m.";\
		exit 1;\
	fi
	@if [ -f "${APP_PATH}/${DYLIB_NAME}" ]; then\
		echo "You're using old version tweak, please uninstall first.";\
		exit 1;\
	fi
	@if [ -d "${APP_PATH}/${FRAMEWORK_PATH}" ]; then\
		rm -rf ${APP_PATH}/${FRAMEWORK_PATH};\
		cp -R ${FRAMEWORK_PATH} ${APP_PATH};\
		chmod -R 755 ${APP_PATH}/${FRAMEWORK_PATH};\
		echo "Framework found! Replace with new framework successfully!";\
	else \
		cp -R ${FRAMEWORK_PATH} ${APP_PATH};\
		chmod -R 755 ${APP_PATH}/${FRAMEWORK_PATH};\
		cp ${APP_PATH}/${APP_NAME} ${APP_PATH}/${BACKUP_NAME};\
		./insert_dylib @executable_path/${FRAMEWORK_PATH}/${FRAMEWORK_NAME} ${APP_PATH}/${APP_NAME} ${TMP_PATH}/${APP_NAME} --all-yes;\
		codesign --force --deep --sign - ${TMP_PATH}/${APP_NAME};\
		cp ${TMP_PATH}/${APP_NAME} ${APP_PATH}/${APP_NAME};\
		echo "Install successfully!";\
	fi

uninstall::
	@xattr -rd com.apple.quarantine . ;
	@if ! [[ $EUID -eq 0 ]]; then\
    	echo "This script should be run using sudo or as the root user.";\
    	exit 1;\
	fi
	@if ! [ -f "${APP_PATH}/${APP_NAME}" ]; then\
		echo "Can not find the WeChat.";\
		exit 1;\
	fi
	@if ! [ -f "${APP_PATH}/${BACKUP_NAME}" ]; then\
		echo "Can not find the WeChat backup file.";\
		exit 1;\
	fi

	@rm -rf ${APP_PATH}/${DYLIB_NAME};
	@rm -rf ${APP_PATH}/${FRAMEWORK_PATH};
	@mv ${APP_PATH}/${BACKUP_NAME} ${APP_PATH}/${APP_NAME};
	@echo "Uninstall successfully!";

clean::
	rm -rf ${FRAMEWORK_PATH}
