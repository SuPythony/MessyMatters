# MessyMatters

A client for the IIIT-H mess portal.

Download the [APK](https://drive.google.com/file/d/1yzwqQg-rcHknhTTDIBunSNs7p9K1NtFo/view?usp=sharing)

## Setup

1. Ensure that Flutter is setup and installed on your computer.
2. Download the source code.
3. Connect a mobile device to your computer or start an emulator.
4. Run `flutter pub get` and `flutter run` in the project directory.
5. To build an APK, run `flutter build apk --release` in the project directory.

## Project Structure

1. All the main source files are in the [lib](https://github.com/SuPythony/MessyMatters/tree/main/lib) directory.
2. The `auth_check` page is the first page opened when the app is launched. It checks whether an auth key is saved and whether the saved auth key is valid or not. Based on this it directs the user to the `onboarding` or `home` page.
3. The `onboarding` page allows users to enter their auth key. They can either scan the QR code or enter it manually.
4. The `home` page has navigation options to all the other pages and shows users their upcoming or ongoing registration.
5. The `menu` page displays the selected day's menu. Users can select a date and view the respective menu.
6. The `reg` page is where all the registrations happen. Users can view and manage their registrations, as well as see the status of previous meals. They can also provide feedback on availed meals.
7. On the `settings` page, users can update their preferences as well as change their auth key.
8. The [pages](https://github.com/SuPythony/MessyMatters/tree/main/lib/pages) directory contains the all the pages of the app.
9. The [components](https://github.com/SuPythony/MessyMatters/tree/main/lib/components) directory contains components common across all pages.

## Assumptions

1. If the user has cancelled a meal, to re-register at a different mess, they have to uncancel and then change the mess.
2. The user needs to be connected to the campus network.
