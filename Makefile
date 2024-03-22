debug::
	xcodebuild build \
		-workspace WeChatTweak.xcworkspace \
		-scheme WeChatTweak \
		-configuration Debug
	DYLD_INSERT_LIBRARIES=WeChatTweak.framework/WeChatTweak /Applications/WeChat.app/Contents/MacOS/WeChat &

release::
	xcodebuild archive \
		-workspace WeChatTweak.xcworkspace \
		-scheme WeChatTweak \
		-destination 'generic/platform=macOS' \
		-archivePath WeChatTweak.xcarchive

clean::
	rm -rf WeChatTweak.xcarchive WeChatTweak.framework

install::
	@echo "Makefile installation has been deprecated!!!"
	@echo "For more information: \033[33;32mhttps://github.com/sunnyyoung/WeChatTweak-CLI\033[0m."

uninstall::
	@echo "Makefile installation has been deprecated!!!"
	@echo "For more information: \033[33;32mhttps://github.com/sunnyyoung/WeChatTweak-CLI\033[0m."
