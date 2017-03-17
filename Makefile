WECHATPATH=/Applications/WeChat.app/Contents/MacOS
DYLIBFILE=WeChatTweak.dylib

build::
	clang -dynamiclib ./WeChatTweak.m -fobjc-link-runtime -current_version 1.0 -compatibility_version 1.0 -o ./${DYLIBFILE}

debug::
	make clean
	make build
	DYLD_INSERT_LIBRARIES=./${DYLIBFILE} ${WECHATPATH}/WeChat &

install::
	@if ! [[ $EUID -eq 0 ]]; then\
    	echo "This script should be run using sudo or as the root user.";\
    	exit 1;\
	fi
	@if ! [ -f "${WECHATPATH}/WeChat" ]; then\
		echo "Can not find the WeChat.";\
		exit 1;\
	fi
	@if ! [ -f "./${DYLIBFILE}" ]; then\
		echo "Can not find the dylib file, please build first.";\
		exit 1;\
	fi

	@cp ${WECHATPATH}/WeChat ${WECHATPATH}/WeChat.bak;
	@cp ./${DYLIBFILE} ${WECHATPATH}/${DYLIBFILE};
	@./insert_dylib @executable_path/${DYLIBFILE} ${WECHATPATH}/WeChat ${WECHATPATH}/WeChat --all-yes;
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

	@rm -rf ${WECHATPATH}/${DYLIBFILE};
	@mv ${WECHATPATH}/WeChat.bak ${WECHATPATH}/WeChat;
	@echo "Uninstall successed";

clean::
	rm -rf ./${DYLIBFILE}
