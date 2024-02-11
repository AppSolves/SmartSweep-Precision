import 'package:flutter/foundation.dart';

void printLog(Object? text) {
  if (kDebugMode) print("\x1B[37m$text\x1B[0m");
}

void printError(Object? text) {
  if (kDebugMode) print("\x1B[31m$text\x1B[0m");
}

void printWarning(Object? text) {
  if (kDebugMode) print("\x1B[33m$text\x1B[0m");
}

void printSuccess(Object? text) {
  if (kDebugMode) print("\x1B[32m$text\x1B[0m");
}

void printInfo(Object? text) {
  if (kDebugMode) print("\x1B[34m$text\x1B[0m");
}

void printDebug(Object? text) {
  if (kDebugMode) print("\x1B[35m$text\x1B[0m");
}

void printVerbose(Object? text) {
  if (kDebugMode) print("\x1B[90m$text\x1B[0m");
}
