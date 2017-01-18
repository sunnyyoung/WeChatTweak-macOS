WECHATPATH=/Applications/WeChat.app/Contents/MacOS

build::
	clang -dynamiclib ./WeChatHook.m -fobjc-link-runtime -current_version 1.0 -compatibility_version 1.0 -o ./WeChatHook.dylib

debug::
	make build
	DYLD_INSERT_LIBRARIES=./WeChatHook.dylib ${WECHATPATH}/WeChat &

install::
	@if ! [[ $EUID -eq 0 ]]; then\
    	echo "This script should be run using sudo or as the root user.";\
    	exit 1;\
	fi
	@if ! [ -f "${WECHATPATH}/WeChat" ]; then\
		echo "Can not find the WeChat.";\
		exit 1;\
	fi
	@if ! [ -f "./WeChatHook.dylib" ]; then\
		echo "Can not find the dylib file, please build first.";\
		exit 1;\
	fi

	@cp ${WECHATPATH}/WeChat ${WECHATPATH}/WeChat.bak;
	@cp ./WeChatHook.dylib ${WECHATPATH}/WeChatHook.dylib;
	@./insert_dylib @executable_path/WeChatHook.dylib ${WECHATPATH}/WeChat ${WECHATPATH}/WeChat --all-yes;
	@echo "Install successed!";

uninstall::
	@if ! [[ $EUID -eq 0 ]]; then\
    	echo "This script should be run using sudo or as the root user.";\
    	exit 1;\
	fi
	@if ! [ -f "${WECHATPATH}/WeChat" ]; then\
		echo "Can not find the WeChat.";\
		exit 1;\
	fi
	@if ! [ -f "${WECHATPATH}/WeChat.bak" ]; then\
		echo "Can not find the WeChat backup file.";\
		exit 1;\
	fi

	@rm -rf ${WECHATPATH}/WeChatHook.dylib;
	@mv ${WECHATPATH}/WeChat.bak ${WECHATPATH}/WeChat;
	@echo "Uninstall successed";

clean::
	rm -rf ./WeChatHook.dylib
