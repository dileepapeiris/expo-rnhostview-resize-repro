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

const PHOTO = require('./assets/icon.png');
const TITLE = 'Card title';
const BODY =
  'Card body text. It is long enough to wrap across several lines, so a change in width reflows it.';

function SwiftUICard() {
  return (
    <VStack alignment="leading" spacing={8} modifiers={[padding({ all: 12 })]}>
      <SwiftText modifiers={[font({ textStyle: 'caption', weight: 'semibold' }), foregroundStyle('secondary')]}>
        SWIFTUI (CONTROL)
      </SwiftText>
      <Rectangle
        modifiers={[
          frame({ maxWidth: Infinity, minHeight: 80, maxHeight: 80 }),
          foregroundStyle('#8e8e93'),
          clipShape('roundedRectangle', 12),
        ]}
      />
      <SwiftText modifiers={[font({ textStyle: 'headline' }), lineLimit(2)]}>{TITLE}</SwiftText>
      <SwiftText modifiers={[font({ textStyle: 'subheadline' }), foregroundStyle('secondary')]}>{BODY}</SwiftText>
      <SwiftButton onPress={() => {}} modifiers={[buttonStyle('borderedProminent')]}>
        <SwiftText modifiers={[frame({ maxWidth: Infinity })]}>Button</SwiftText>
      </SwiftButton>
    </VStack>
  );
}

function ReactNativeCard({ onLayout }: { onLayout: (e: LayoutChangeEvent) => void }) {
  return (
    <View style={styles.card} onLayout={onLayout}>
      <Text style={styles.label}>REACT NATIVE IN RNHostView</Text>
      <Image source={PHOTO} style={styles.photo} resizeMode="cover" />
      <Text style={styles.title} numberOfLines={2}>
        {TITLE}
      </Text>
      <Text style={styles.body}>{BODY}</Text>
      <Pressable style={styles.button} onPress={() => {}}>
        <Text style={styles.buttonText}>Button</Text>
      </Pressable>
    </View>
  );
}

const t0 = Date.now();

export default function App() {
  const [wide, setWide] = useState(false);
  const toggledAt = useRef(0);
  const width = wide ? 360 : 200;
  const resize = [
    frame({ width, height: 260 }),
    background('#f2f2f7'),
    animation(Animation.easeInOut({ duration: 0.8 }), wide),
  ];
