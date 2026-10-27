import {
  Button as SwiftButton,
  Host,
  Rectangle,
  RNHostView,
  ScrollView,
  Text as SwiftText,
  VStack,
} from '@expo/ui/swift-ui';
import {
  Animation,
  animation,
  background,
  buttonStyle,
  clipShape,
  font,
  foregroundStyle,
  frame,
  lineLimit,
  padding,
} from '@expo/ui/swift-ui/modifiers';
import { useEffect, useRef, useState } from 'react';
import { Button, Image, LayoutChangeEvent, Pressable, StyleSheet, Text, View } from 'react-native';

// Repro for https://github.com/expo/expo/issues/52396
// Two copies of the same card sit in SwiftUI frames whose width animates between 200 and 360
// points over 0.8 s. The SwiftUI card (top) should be the control; the React Native card
// hosted in RNHostView (bottom) should resize the same way.
