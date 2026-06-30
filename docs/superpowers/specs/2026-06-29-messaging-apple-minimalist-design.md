# Messaging Apple Minimalist Redesign

## Goal
Redesign MessagesScreen and ChatScreen to an iMessage-inspired minimalist aesthetic while maintaining consistency with the app's existing Material 3 theme.

## Changes

### MessagesScreen (Conversations List)
- **Search bar**: Match NotesScreen style — 36px height, no BackdropFilter, flat container, 18px icons, constrained prefix, isDense
- **Conversation items**: Flat cards (no BackdropFilter, no blur), solid background (surfaceContainerHighest), subtle border, cleaner ListTile
- **Section headers**: Caps text, primary color, smaller letter spacing
- **Unread indicator**: Blue circle dot

### ChatScreen
- **AppBar**: Flat surface, no glassmorphism, lower alpha
- **Message bubbles**: Solid colors — `colorScheme.primary` for sent (white text), `surfaceContainerHigh` for received (onSurface text). Rounded corners with tail differentiation. No lock icon clutter.
- **Input area**: Flat, no BackdropFilter, solid surface color, subtle top border
- **Bottom sheets**: Solid backgrounds, no blur, cleaner action sheet style
- **Remove glassmorphism** from all components

### Consistency
- Search bar matches NotesScreen/HomeScreen patterns exactly
- Uses existing theme colors (colorScheme.primary, colorScheme.onSurface, etc.)
- No new dependencies

## Files Modified
- `lib/screens/messages/MessagesScreen.dart`
- `lib/screens/messages/ChatScreen.dart`
