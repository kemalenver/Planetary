#!/bin/sh
# Copy OneSignal framework from source packages to PackageFrameworks
ONESIGNAL_SOURCE="${BUILD_DIR}/../../SourcePackages/artifacts/onesignal-xcframework/OneSignalFramework/OneSignalFramework.xcframework"

if [ -d "${ONESIGNAL_SOURCE}" ]; then
    echo "Found OneSignal at: ${ONESIGNAL_SOURCE}"
    
    # Create PackageFrameworks directory
    mkdir -p "${BUILT_PRODUCTS_DIR}/PackageFrameworks"
    
    # Extract the correct slice from xcframework for current architecture
    if [ "${PLATFORM_NAME}" == "iphoneos" ]; then
        FRAMEWORK_PATH="${ONESIGNAL_SOURCE}/ios-arm64/OneSignalFramework.framework"
    else
        FRAMEWORK_PATH="${ONESIGNAL_SOURCE}/ios-arm64_x86_64-simulator/OneSignalFramework.framework"
    fi
    
    echo "Copying from: ${FRAMEWORK_PATH}"
    echo "Copying to: ${BUILT_PRODUCTS_DIR}/PackageFrameworks/"
    
    cp -R "${FRAMEWORK_PATH}" "${BUILT_PRODUCTS_DIR}/PackageFrameworks/"
    
    # Also copy to app bundle
    mkdir -p "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
    cp -R "${FRAMEWORK_PATH}" "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/"
    
    # Code sign
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements --timestamp=none "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/OneSignalFramework.framework"
    
    echo "OneSignal framework copied and signed successfully"
else
    echo "ERROR: OneSignal framework not found at ${ONESIGNAL_SOURCE}"
fi

