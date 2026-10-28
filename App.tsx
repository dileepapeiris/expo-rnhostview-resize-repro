import {
  ArrangementView,
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
  arrangementViewStyle,
  background,
  buttonStyle,
  clipShape,
  font,
  foregroundStyle,
  frame,
  lineLimit,
  padding,
  splitArrangementLayoutSize,
} from '@expo/ui/swift-ui/modifiers';
import { useEffect, useRef, useState } from 'react';
import {
  Button,
  Image,
  LayoutChangeEvent,
  Pressable,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';

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
  // Screen 2 of the issue: on the iPhone Duo's inner display (landscape, 1,000+ pt wide)
  // the two cards are the two sides of an ArrangementView, which animates at each fold.
  // The wide inner display picks the ArrangementView screen, the outer display the width screen,
  // until a button picks one by hand.
  const { width: windowWidth } = useWindowDimensions();
  const [chosenScreen, setScreen] = useState<'width' | 'arrangement' | null>(null);
  const screen = chosenScreen ?? (windowWidth >= 600 ? 'arrangement' : 'width');
  const [wide, setWide] = useState(false);
  // Only an animated toggle changes this key, so an instant toggle changes the width without animation.
  const [animKey, setAnimKey] = useState(0);
  const toggledAt = useRef(0);
  const layoutsSinceToggle = useRef(0);
  const width = wide ? 360 : 200;
  const resize = [
    frame({ width, height: 260 }),
    background('#f2f2f7'),
    animation(Animation.easeInOut({ duration: 0.8 }), animKey),
  ];

  // The timers below capture the first render's `toggle`, so the current width lives in a ref.
  const wideRef = useRef(false);
  const toggle = (label: string, animated: boolean) => {
    const next = !wideRef.current;
    wideRef.current = next;
    toggledAt.current = Date.now();
    layoutsSinceToggle.current = 0;
    console.log(`[52396] ${label} ${animated ? 'ANIMATED' : 'INSTANT'} -> ${next ? 360 : 200} (t=${Date.now() - t0})`);
    setWide(next);
    if (animated) setAnimKey((k) => k + 1);
  };

  // Toggles on its own: animated at 3 s, instant at 6 s, animated at 9 s, instant at 12 s.
  useEffect(() => {
    const timers = [1, 2, 3, 4].map((i) =>
      setTimeout(() => toggle(`AUTO-TOGGLE ${i}`, i % 2 === 1), 3000 * i)
    );
    return () => timers.forEach(clearTimeout);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Logs every layout the hosted RN view receives. On `main` there is exactly one per toggle,
  // a few ms after it, already at the destination width.
  const onLayout = (e: LayoutChangeEvent) => {
    const { width: w, height: h } = e.nativeEvent.layout;
    layoutsSinceToggle.current += 1;
    const since = toggledAt.current ? `+${Date.now() - toggledAt.current}ms after toggle` : 'cold launch';
    console.log(
      `[52396] onLayout #${layoutsSinceToggle.current} width=${w.toFixed(1)} height=${h.toFixed(1)} ${since} (t=${Date.now() - t0})`
    );
  };

  if (screen === 'arrangement') {
    return (
      <View style={styles.root}>
        <View style={styles.controls}>
          <Button title="Screen 1: animated width" onPress={() => setScreen('width')} />
        </View>
        <Host style={styles.root}>
          <ArrangementView modifiers={[arrangementViewStyle('split', { axes: 'both' })]}>
            <ArrangementView.Primary>
              <VStack modifiers={[splitArrangementLayoutSize({ idealWidth: 372 }), frame({ maxHeight: Infinity })]}>
                <SwiftUICard />
              </VStack>
            </ArrangementView.Primary>
            <ArrangementView.Secondary>
              <RNHostView>
                <ReactNativeCard onLayout={onLayout} />
              </RNHostView>
            </ArrangementView.Secondary>
          </ArrangementView>
        </Host>
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <View style={styles.controls}>
        <Button title="Screen 2: iPhone Duo ArrangementView" onPress={() => setScreen('arrangement')} />
        <Button title={`Animated: make ${wide ? 'narrow' : 'wide'}`} onPress={() => toggle('TAP', true)} />
        <Button title={`Instant: make ${wide ? 'narrow' : 'wide'}`} onPress={() => toggle('TAP', false)} />
      </View>
      <Host style={styles.host}>
        <ScrollView>
          <VStack alignment="leading" spacing={16}>
            <VStack modifiers={resize}>
              <SwiftUICard />
            </VStack>
            <VStack modifiers={resize}>
              <RNHostView>
                <ReactNativeCard onLayout={onLayout} />
              </RNHostView>
            </VStack>
          </VStack>
        </ScrollView>
      </Host>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#fff', paddingTop: 60 },
  controls: { padding: 16, gap: 8 },
  host: { flex: 1, marginHorizontal: 16 },
  card: { flex: 1, padding: 12, gap: 8, backgroundColor: '#f2f2f7' },
  label: { fontSize: 12, fontWeight: '600', color: '#8e8e93' },
  photo: { width: '100%', height: 80, borderRadius: 12 },
  title: { fontSize: 17, fontWeight: '600', color: '#000' },
  body: { fontSize: 15, color: '#3c3c43' },
  button: {
    alignSelf: 'stretch',
    alignItems: 'center',
    paddingVertical: 12,
    borderRadius: 999,
    backgroundColor: '#007aff',
  },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '600' },
});
