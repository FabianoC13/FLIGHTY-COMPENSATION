# Copilot Instructions for FlightCompensation Project

## Autonomous Build & Fix Workflow

Follow this procedure after every significant code change or when requested to build.

### 1. Build Command
Run the following command to build the project for the iPhone 17 Pro simulator and capture the output:
```bash
cd "/Users/fabiano/Documents/FLIGHTY COMPENSATION" && xcodebuild -project FlightCompensation.xcodeproj -scheme FlightCompensation -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build > build.log 2>&1
```

### 2. Analyze Output
- Read `build.log`.
- Check for `** BUILD SUCCEEDED **`.
- If succeeded, stop.

### 3. Error Handling
- If the build failed, analyze the errors in `build.log`.
- **Ignore**: Signing, provisioning, certificate, and SDK environment errors.
- **Fix**: Code-level errors (syntax, missing types, wrong arguments, etc.).
- Apply fixes using editing tools.

### 4. Loop
- After applying fixes, **restart at Step 1**.
- Continue until the build succeeds or only non-code errors remain.

---

## Adding New Swift Files to the Project

When creating a new `.swift` file, it must be added to `project.pbxproj` in **4 places**:

1. **PBXBuildFile section** - Add compilation reference
2. **PBXFileReference section** - Add file reference  
3. **PBXGroup children** - Add to appropriate folder group
4. **PBXSourcesBuildPhase** - Add to Sources build phase

Use unique 24-character hex IDs for new entries.

---

## Project Structure

- **Views**: `FlightCompensation/Views/`
- **Models**: `FlightCompensation/Models/`
- **Services**: `FlightCompensation/Services/`
- **ViewModels**: `FlightCompensation/ViewModels/`
- **Utilities**: `FlightCompensation/Utilities/`
