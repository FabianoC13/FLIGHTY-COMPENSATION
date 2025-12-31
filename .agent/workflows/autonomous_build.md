---
description: Build the iOS app autonomously and fix code-level errors.
---
# Autonomous Build & Fix Workflow

Follow this procedure after every significant code change or when requested to build.

1. **Build Command**
   Run the following command to build the project for the iPhone 17 Pro simulator and capture the output:
   ```bash
   xcodebuild -project FlightCompensation.xcodeproj -scheme FlightCompensation -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build > build.log 2>&1
   ```

2. **Analyze Output**
   - Read `build.log`.
   - Check for `** BUILD SUCCEEDED **`.
   - If succeeded, stop.

3. **Error Handling**
   - If the build failed, analyze the errors in `build.log`.
   - **Ignore**: Signing, provisioning, certificate, and SDK environment errors.
   - **Fix**: Code-level errors (syntax, missing types, wrong arguments, etc.).
   - Apply fixes using `replace_file_content` or other editing tools.

4. **Loop**
   - After applying fixes, **restart at Step 1**.
   - Continue until the build succeeds or only non-code errors remain.
