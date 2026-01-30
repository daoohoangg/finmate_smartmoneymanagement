# Finmate Smart Money Management

Welcome to the **Finmate Smart Money Management** project. This is an intelligent financial management system developed with **Flutter** (Frontend) and **Java Spring Boot** (Backend).

The application supports multiple platforms:
- **Web**
- **Windows (Desktop App)**
- **Android**

---

## Project Structure
- `finmate_smartmoneymanagement_flutter`: Frontend Source Code (Flutter).
- `finmate_smartmoneymanagement_be`: Backend Source Code (Spring Boot).

---

## 1. Frontend Setup (Flutter)

**Development Environment:** Android Studio (Recommended) or VS Code.

### Step 1: Environment Installation and Configuration
1.  **Install Git**: [Download Git](https://git-scm.com/downloads).
2.  **Install Flutter SDK**:
    - Download the Flutter SDK (Stable) for Windows here: [Flutter Windows Install](https://docs.flutter.dev/get-started/install/windows).
    - Extract the zip file to a directory (e.g., `C:\src\flutter`). **Note**: Do not install in `C:\Program Files` to avoid permission issues.
3.  **Configure Environment Variables (Path)**:
    - Type "env" in the Windows search bar -> Select **Edit the system environment variables**.
    - Click **Environment Variables**.
    - Under **User variables**, find **Path** -> **Edit** -> **New**.
    - Paste the path to the `bin` directory of Flutter (e.g., `C:\src\flutter\bin`) -> OK.
    - Open CMD or PowerShell and type `flutter doctor` to verify the installation.
4.  **Install Android Studio**:
    - Download Android Studio: [Download](https://developer.android.com/studio).
    - During installation, ensure **Android Virtual Device** is selected (if using an emulator).
    - Open Android Studio -> **Settings** (or **Plugins** on the welcome screen) -> Search for and install the **Flutter** plugin (this will also install the **Dart** plugin). Restart the IDE.

### Step 2: Project Setup
1.  Open Android Studio -> **Open** -> Select the `finmate_smartmoneymanagement_flutter` directory.
2.  If you see the message *Running 'flutter pub get'*, wait for it to finish. If not, open the **Terminal** tab in Android Studio and run:
    ```bash
    flutter pub get
    ```
    This command downloads all necessary libraries.
3.  **Run Configuration**:
    - **Android**: Open **Device Manager** -> Create a Virtual Device or connect a physical phone (enable USB Debugging).
    - **Windows**: Visual Studio (Desktop development with C++) is required if you want to build the Windows app (usually, testing on Android/Web is faster).
4.  **Run Application**: Select the device from the toolbar and click the **Run** (Play) button.

---

## 2. Backend Setup (Spring Boot)

**Development Environment:** IntelliJ IDEA.
**Requirement:** JDK 17.

### Step 1: Tools Installation
1.  **Install JDK 17**:
    - Download JDK 17 (Oracle OpenJDK or Amazon Corretto 17).
    - Install and configure the `JAVA_HOME` environment variable pointing to the JDK 17 installation directory.
2.  **Install IntelliJ IDEA**:
    - Download [IntelliJ IDEA](https://www.jetbrains.com/idea/download/) (Community is sufficient, or Ultimate if you have a license).

### Step 2: Project Setup
1.  Open IntelliJ IDEA -> **Open** -> Select the `finmate_smartmoneymanagement_be` directory.
2.  Wait for the IDE to index and load the project. Since the project uses **Gradle**, IntelliJ will automatically download dependencies. This may take a few minutes the first time.
    - Check SDK Configuration: File -> Project Structure -> Project -> Ensure **SDK** is set to version 17.
3.  **Database Connection**:
    - > **IMPORTANT**: Database connection logic and credentials have been hidden in the source code for security reasons.
    - If you need to run the Backend with a connection to the actual Database, please **contact the development team directly** to obtain the necessary information or configuration files.
4.  **Run Application**:
    - Find the main file of the application (Usually annotated with `@SpringBootApplication`).
    - Click the Run (Play) icon next to the `main` class or method.

---

## Contact
For any questions, please contact the Finmate development team for detailed support.
