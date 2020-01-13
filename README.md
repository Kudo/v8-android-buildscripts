[![npm version](https://badge.fury.io/js/v8-android.svg)](https://badge.fury.io/js/v8-android)
[![CircleCI](https://circleci.com/gh/Kudo/v8-android-buildscripts.svg?style=svg)](https://circleci.com/gh/Kudo/v8-android-buildscripts)

# V8 build scripts for React Native Android

The aim of this project is to support V8 runtime for React Native.

## Integrate prebuilt V8 library

We publish prebuilt V8 shared libraries at npm.
[https://www.npmjs.com/package/v8-android](https://www.npmjs.com/package/v8-android)

This makes upgrade V8 from React Native easier and is pretty much like what [jsc-android-buildscripts](https://github.com/react-native-community/jsc-android-buildscripts) did.

To integrate with React Native, please check [react-native-v8](https://github.com/Kudo/react-native-v8).


## V8 Feature Flags

#### V8 comes in 4 flavours
 - v8 lite mode (memory optimized)
 - v8 lite mode + no intl (memory optimized + smaller size)
 - v8 JIT (performance optimized)
 - v8 JIT + no intl (performance optimized + smaller size)

#### Features
1. Single libv8.so file.
2. Support i18n and JavaScript [Intl](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl).
3. V8 Lite mode (JIT-less mode) https://v8.dev/blog/v8-lite
4. Build by Android official NDK r19c which prevent potential ABI incompatible issue to integrate with React Native.

## Build Guides

### Prerequisites

* Ubuntu 18.04
* git + python + nodejs + npm + wget + yarn

### Build steps

```sh
# Checkout V8 code and install necessary packages
yarn setup

# Build
yarn start
```

Could further check real build steps for CircleCI from [CircleCI Config](https://github.com/Kudo/v8-android-buildscripts/blob/master/.circleci/config.yml).
