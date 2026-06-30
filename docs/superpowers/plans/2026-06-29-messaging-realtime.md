# Messaging Realtime + UX Improvements Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development or executing-plans to implement task-by-task.

**Goal:** Make messages instant via WebSocket, fix avatars/ticks/encryption indicators.

**Architecture:** Add `socket_io_client` to Flutter client connecting directly to the NestJS messaging service WebSocket. Backend adds `isRead` to message responses and emits `readUpdated` to message senders.

**Tech Stack:** Flutter (client), NestJS/Socket.io (backend messaging)

## Global Constraints

- Follow existing Flutter patterns (Singleton services, `async`/`await`, `StreamController`)
- Use `socket_io_client` package for WebSocket
- Keep SSE polling as fallback (reduce interval)
- No changes to E2EE crypto logic

---

### Task 1: Backend — add `isRead` to message responses + emit readUpdated to sender

**Files:**
- Modify: `~/Workspace/thisuite/thisecure/backend/services/messaging/src/chat/chat.service.ts`
- Modify: `~/Workspace/thisuite/thisecure/backend/services/messaging/src/chat/chat.gateway.ts`

- [ ] Add `toMessageResponse` helper in `chat.service.ts` that computes `isRead` and converts message to API shape
- [ ] Use helper in `getMessages` and `sendMessage`
- [ ] In `chat.gateway.ts`, emit `readUpdated` also to the sender of read messages
- [ ] Commit

---

### Task 2: Cliente — add `socket_io_client` dependency + MessagingSocketService

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/messaging_socket_service.dart`

- [ ] Add `socket_io_client` to pubspec.yaml
- [ ] Create `MessagingSocketService` singleton
- [ ] Implement connect/disconnect, auth via JWT handshake
- [ ] Listen `newMessage`, `readUpdated` events
- [ ] Expose `Stream<MessagingSocketEvent>`
- [ ] Auto-reconnect with backoff
- [ ] Commit

---

### Task 3: Cliente — Message model `isRead` support

**Files:**
- Modify: `lib/data/models/message.dart`

- [ ] Add `isRead` field to Message
- [ ] Parse from `json['isRead']` and fallback to `readBy`
- [ ] Commit

---

### Task 4: Cliente — ChatScreen WebSocket subscription + avatars + ticks + remove encryption

**Files:**
- Modify: `lib/screens/messages/ChatScreen.dart`

- [ ] Subscribe to `MessagingSocketService.events`
- [ ] Handle `newMessage` for this conversation
- [ ] Handle `readUpdated` (refresh isRead)
- [ ] Rewrite `_buildAvatar`: show IMAGE if avatarUrl not null, else INITIAL only (no Stack)
- [ ] Rewrite tick logic: `Icons.check` (sent) / `Icons.done_all` (read)
- [ ] Remove encryption indicator row from AppBar
- [ ] Remove "Visto" text under bubble
- [ ] Commit

---

### Task 5: Cliente — MessagesScreen avatars + remove lock icon

**Files:**
- Modify: `lib/screens/messages/MessagesScreen.dart`

- [ ] Rewrite `_buildAvatar`: show IMAGE if avatarUrl not null, else INITIAL only (no Stack)
- [ ] Remove lock icon next to conversation name
- [ ] Pass loaded `_avatars` map to ChatScreen when navigating
- [ ] Commit

---

### Task 6: Cliente — DialogUtils resolve userId for avatar

**Files:**
- Modify: `lib/utils/DialogUtils.dart`

- [ ] When creating new conversation with email, search LDAP users for matching userId
- [ ] Pass User with correct id to allow avatar loading
- [ ] Commit

---

### Task 7: Cliente — messageService.dart clean up

**Files:**
- Modify: `lib/services/messageService.dart`

- [ ] Fix misplaced `sendTyping` method (extract from inside `getConversations`)
- [ ] Add `isRead` propagation in message parsing
- [ ] Commit

---

### Task 8: Verification

**Files:**
- N/A

- [ ] Run `flutter analyze` and fix any issues
- [ ] Verify the app builds: `flutter build`
- [ ] Check WebSocket connection flow
- [ ] Commit any fixes
