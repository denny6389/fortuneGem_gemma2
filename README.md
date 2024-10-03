# fortuneGem_gemma2
## Google Machine Learning Bootcamp Gemma Sprint

This project has been tested on iPhone 13 Pro running iOS 17.5.
This app might not work on Android, and mobile emulators are not supported.

## Instructions

### 1. Generate the `fortunegem.bin` File
- Open the `fortuneGem_gemma2b.ipynb` file and run all cells.
- The notebook will generate a `fortunegem.bin` file.
- Once generated, place the `fortunegem.bin` file into the `Flutter/assets` folder of this project.

### 2. Set Up Flutter
- Ensure that you are on the Flutter **master** channel:
  ```bash
  flutter channel master
  flutter upgrade
- Opt-in to the native assets experiment by running:
  ```bash
  flutter config --enable-native-assets

### 3. Run the Project
- To run the app, use the following commands:
  ```bash
  flutter pub get
  flutter run


### 4. Troubleshooting
- If the app does not run correctly, try the following steps:
  ```bash
  flutter upgrade
  flutter clean
  flutter pub get
