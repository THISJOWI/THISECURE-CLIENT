# Messaging Realtime + UX Improvements Design

## Objective
- Messages are instant (WebSocket direct to messaging service)
- User profile photo shown instead of initial when available
- Fix tick status (1 tick = sent, 2 ticks = read)
- Remove encryption/not-encrypted indicators from UI

## Backend Changes

### chat.service.ts
- Add `isRead` field to message responses: `isRead: readBy.some(rb => rb.userId !== senderId)`
- Extract `toMessageResponse(msg)` helper to reuse across endpoints
- Ensure `getMessages`, `sendMessage` return `isRead`

### chat.gateway.ts
- Emit `newMessage` also to the **sender** (so they see the real-time confirmation)
- Emit `readUpdated` to the **sender** of the read messages (so they see double tick)

## Client Changes

### New: `lib/services/messaging_socket_service.dart`
- Singleton service using `socket_io_client`
- Connects to `ApiConfig.messagesUrl` base (WebSocket path)
- Auth via handshake token
- Listens: `newMessage`, `readUpdated`
- Emits: `MessagingSocketEvent` stream (newMessage, readUpdated)
- Auto-reconnect with backoff
- Starts on app init, stops on dispos

### `lib/screens/messages/ChatScreen.dart`
- Subscribe to `MessagingSocketService.events`
- On `newMessage` for this conversation: add decrypted message to `_messages`
- On `readUpdated`: refresh `isRead` flags
- Avatars: show photo ONLY if avatarUrl available, otherwise initial ONLY (no Stack)
- Quit encryption indicator row in AppBar
- Quit "Visto" text under bubble (double tick is enough)
- Ticks: `Icons.check` if `!isRead` else `Icons.done_all` (both primary color)

### `lib/screens/messages/MessagesScreen.dart`
- Avatar: show photo ONLY if available, otherwise initial ONLY
- Quit lock icon next to conversation name
- Pass loaded `_avatars` to ChatScreen to avoid flash

### `lib/data/models/message.dart`
- Add `isRead` to constructor, read from `json['isRead']`
- Fallback: calculate from `readBy` if present

### `lib/utils/DialogUtils.dart`
- Try to resolve real userId from LDAP when creating new conversation, so avatar loads

### `lib/services/messageService.dart`
- Fix misplaced `sendTyping` method (extract from inside `getConversations`)
- Add `isRead` handling
