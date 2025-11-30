# Chat System - Architecture Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         StrayCare App                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              Bottom Navigation Bar                             │ │
│  │  [Home] [Marketplace] [Messages] [Profile]                    │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              Messages Tab (Chat List Screen)                   │ │
│  │                                                                │ │
│  │  • All Chats Listed                                           │ │
│  │  • AI Vet Bot with "Ask Vet Bot" tag                          │ │
│  │  • Random User Chats                                          │ │
│  │  • Unread Badges                                             │ │
│  │  • Last Message Preview                                       │ │
│  │                                                                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                         ↓ (tap chat)                                 │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              Chat Detail Screen                                │ │
│  │                                                                │ │
│  │  • Full Message History                                       │ │
│  │  • Message Bubbles (User & Other)                            │ │
│  │  • AI Auto-Responses                                         │ │
│  │  • Message Input Field                                       │ │
│  │  • Auto-Scroll to Latest                                     │ │
│  │                                                                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Service Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  UI Layer (Screens)                              │
│  ┌──────────────────┬──────────────────┐                        │
│  │  Chat List       │  Chat Detail     │                        │
│  │  Screen          │  Screen          │                        │
│  └──────┬───────────┴────────┬─────────┘                        │
│         │                    │                                   │
└─────────┼────────────────────┼───────────────────────────────────┘
          │                    │
          └────────┬───────────┘
                   ↓ (depends on)
┌─────────────────────────────────────────────────────────────────┐
│              Service Layer (ChatService Interface)               │
│                                                                   │
│  abstract class ChatService {                                    │
│    Future<List<Chat>> getAllChats()                             │
│    Future<List<Message>> getMessagesForChat(String chatId)      │
│    Future<Message> sendMessage(String chatId, String content)   │
│    Future<Chat> createChat(...)                                 │
│    Future<void> markChatAsRead(String chatId)                   │
│    Future<void> deleteChat(String chatId)                       │
│  }                                                               │
│                                                                   │
└────────┬──────────────────────────────────┬──────────────────────┘
         │                                  │
    ┌────▼────────┐           ┌────────────▼────┐
    │              │           │                 │
┌───┴──────────┐  │      ┌────┴────────────────┐│
│Local Chat    │  │      │Backend Chat Service││ (Future)
│Service       │  │      │(HTTP API)           ││
│              │  │      │                     ││
│• In-Memory   │  │      │• HTTP Client        ││
│• Sample Data │  │      │• Token Management   ││
│• Simulated   │  │      │• Error Handling     ││
│  Delays      │  │      │• Retry Logic        ││
│              │  │      │                     ││
└──────────────┘  │      └─────────────────────┘│
                  │                             │
                  │      ┌──────────────────┐   │
                  │      │WebSocket Service │   │
                  │      │(Real-time)       │   │
                  │      │                  │   │
                  │      │• Live Updates    │   │
                  │      │• Typing Indicators
                  │      │• Presence Info   │   │
                  │      │                  │   │
                  │      └──────────────────┘   │
```

---

## Data Model Hierarchy

```
┌────────────────────────────────────┐
│            Chat Model              │
├────────────────────────────────────┤
│ id: String                         │
│ name: String                       │
│ profileImageUrl: String            │
│ lastMessage: String                │
│ lastMessageTime: DateTime          │
│ isAiBot: bool                      │
│ tag: String?                       │
│ unreadCount: int                   │
├────────────────────────────────────┤
│ toJson()     fromJson()            │
└────────────────────────────────────┘
           ↓ (contains many)
┌────────────────────────────────────┐
│         Message Model              │
├────────────────────────────────────┤
│ id: String                         │
│ chatId: String                     │
│ senderId: String                   │
│ content: String                    │
│ timestamp: DateTime                │
│ isUserMessage: bool                │
│ status: MessageStatus              │
├────────────────────────────────────┤
│ toJson()     fromJson()            │
└────────────────────────────────────┘
           ↓ (references)
┌────────────────────────────────────┐
│    MessageStatus Enum              │
├────────────────────────────────────┤
│ • pending                          │
│ • sent                             │
│ • delivered                        │
│ • read                             │
└────────────────────────────────────┘
```

---

## Data Flow: Chat List Loading

```
┌─────────────────────────────────────────────────────┐
│  ChatListScreen.initState()                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  _chatService = LocalChatService()  (or Backend)   │
│  _chatsFuture = _chatService.getAllChats()         │
│                                                     │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  ChatService.getAllChats()                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Future<List<Chat>> getAllChats() {                │
│    // Local: return _chats from memory              │
│    // Backend: HTTP GET /api/v1/chats              │
│  }                                                  │
│                                                     │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  FutureBuilder rebuilds UI                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ConnectionState.waiting   → CircularProgressIndicator
│  hasError              → Error message + Retry btn  │
│  hasData               → Chat list items            │
│                                                     │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  ListView.builder renders chat items                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │  Profile Pic │ Name    │ Last Message     │   │
│  │  + AI Badge  │ + Tag   │ + Time + Badge   │   │
│  └─────────────────────────────────────────────┘   │
│                    ↓ (tap)                          │
│  ┌─────────────────────────────────────────────┐   │
│  │  Navigate to ChatDetailScreen(chat)         │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Data Flow: Sending a Message

```
┌──────────────────────────────────────────┐
│  User types in TextField                 │
│  Taps Send button                        │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  _sendMessage()                          │
│  Gets: _messageController.text           │
│  Clear: _messageController               │
└──────────────────┬───────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  _chatService.sendMessage(                │
│    chatId,                               │
│    content                               │
│  )                                       │
│                                          │
│  Returns: Message object                 │
└──────────────────┬───────────────────────┘
                   ↓
        ┌──────────┴──────────┐
        ↓                     ↓
┌──────────────────┐  ┌──────────────────┐
│  Local Service   │  │ Backend Service  │
├──────────────────┤  ├──────────────────┤
│ • Add to memory  │  │ • HTTP POST      │
│ • Return Message │  │ • Return Response│
└────────┬─────────┘  └────────┬─────────┘
         │                     │
         └──────────┬──────────┘
                    ↓
        ┌───────────────────────┐
        │  setState(() {        │
        │    _messagesFuture =  │
        │    refresh messages   │
        │  })                   │
        └───────────┬───────────┘
                    ↓
    ┌───────────────────────────────┐
    │ Auto-scroll to bottom          │
    │ Show new message in UI         │
    └───────────────────────────────┘
                    ↓ (if AI Bot)
    ┌───────────────────────────────┐
    │ Wait 2 seconds (typing sim)    │
    │ Generate AI response           │
    │ Send AI response message       │
    │ Refresh messages again         │
    │ Auto-scroll to AI response     │
    └───────────────────────────────┘
```

---

## Backend Integration Flow

```
CURRENT STATE (Local)
┌─────────────────────────────────────┐
│   Chat Screens                      │
└──────────────┬──────────────────────┘
               ↓
         ┌─────────────────────────────────────┐
         │ LocalChatService                    │
         │ (In-Memory)                         │
         └─────────────────────────────────────┘


FUTURE STATE (Backend)
┌─────────────────────────────────────┐
│   Chat Screens                      │
└──────────────┬──────────────────────┘
               ↓
         ┌─────────────────────────────────────┐
         │ BackendChatService                  │
         │ (HTTP + WebSocket)                  │
         └──────────────┬──────────────────────┘
                        ↓
         ┌──────────────────────────────────────────┐
         │  Your Backend API                        │
         │                                          │
         │  GET  /api/v1/chats                     │
         │  POST /api/v1/chats/{id}/messages       │
         │  POST /api/v1/ai/vet-bot/response       │
         │  ...                                     │
         │                                          │
         │  Database                               │
         │  • Users                                │
         │  • Chats                                │
         │  • Messages                             │
         │  • AI Bot Logs                          │
         │                                          │
         └──────────────────────────────────────────┘
                        ↑
         ┌──────────────────────────────────────────┐
         │  OPTIONAL: Real-time (WebSocket)         │
         │                                          │
         │  wss://your-api.com/ws/chats/:chatId    │
         │  • Live Messages                         │
         │  • Typing Indicators                     │
         │  • Online Status                         │
         │                                          │
         └──────────────────────────────────────────┘
```

---

## File Structure

```
lib/
├── main.dart
│   └── Uses ChatListScreen as Messages tab
│
└── features/
    └── ai_bot/
        ├── models/
        │   └── chat_model.dart
        │       ├── class Chat
        │       ├── class Message
        │       └── enum MessageStatus
        │
        ├── services/
        │   ├── chat_service.dart
        │   │   ├── abstract ChatService
        │   │   └── class LocalChatService (impl)
        │   │
        │   └── backend_chat_service_example.dart
        │       └── Example BackendChatService (impl)
        │
        ├── screens/
        │   ├── chat_list_screen.dart
        │   │   └── Main Messages Tab UI
        │   │
        │   └── chat_detail_screen.dart
        │       └── Individual Chat UI
        │
        ├── README.md
        │   └── Overview & Usage Guide
        │
        ├── CHAT_SYSTEM_GUIDE.md
        │   └── Architecture & Design Details
        │
        ├── BACKEND_INTEGRATION_GUIDE.md
        │   └── Step-by-step Backend Setup
        │
        └── QUICK_REFERENCE.md
            └── Developer Quick Reference
```

---

## Component Interaction Diagram

```
┌──────────────────────────────────────────────────────┐
│                   ChatListScreen                      │
│                                                      │
│  • Displays all chats                               │
│  • Manages chat list state                          │
│  • Handles navigation to detail screen              │
│  • Refreshes chat list                              │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ FutureBuilder                                │   │
│  │   • Loading state                            │   │
│  │   • Error handling                           │   │
│  │   • Data display                             │   │
│  └──────────┬───────────────────────────────────┘   │
│             ↓                                        │
│  ┌──────────────────────────────────────────────┐   │
│  │ ListView.builder                             │   │
│  │   ┌─────────────────────────────────────┐    │   │
│  │   │ ChatListItem (per chat)             │    │   │
│  │   │                                     │    │   │
│  │   │ • Profile picture widget            │    │   │
│  │   │ • Chat info (name, last msg)        │    │   │
│  │   │ • Badges (unread, AI tag)           │    │   │
│  │   │ • Timestamps                        │    │   │
│  │   └──────────┬──────────────────────────┘    │   │
│  │             ↓ (tap)                          │   │
│  │   Navigate to ChatDetailScreen               │   │
│  └──────────────────────────────────────────────┘   │
│             ↑                                        │
│             └── Use ChatService.getAllChats()       │
└──────────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────────┐
│              ChatDetailScreen                        │
│                                                      │
│  • Displays message history                         │
│  • Handles message input                            │
│  • Manages message state                            │
│  • Auto-responses (AI)                              │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ ListView (messages)                          │   │
│  │   ┌─────────────────────────────────────┐    │   │
│  │   │ Message Bubble (per message)        │    │   │
│  │   │                                     │    │   │
│  │   │ • Alignment (left/right)            │    │   │
│  │   │ • Colors (user/other)               │    │   │
│  │   │ • Content text                      │    │   │
│  │   │ • Timestamp                         │    │   │
│  │   │ • Status indicator                  │    │   │
│  │   └─────────────────────────────────────┘    │   │
│  │                                              │   │
│  │   (auto-scroll to latest)                    │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ Message Input Section                        │   │
│  │                                              │   │
│  │ ┌────────────────────────┐  ┌────────────┐   │   │
│  │ │ TextField              │  │ Send Button│   │   │
│  │ │ (message text)         │  │ (Icon)     │   │   │
│  │ └────────────────────────┘  └─────┬──────┘   │   │
│  │                                   ↓         │   │
│  │                       _sendMessage()        │   │
│  │                                   ↓         │   │
│  │                  ChatService.sendMessage()  │   │
│  │                                   ↓         │   │
│  │              Refresh message list + scroll  │   │
│  └──────────────────────────────────────────────┘   │
│             ↑                                        │
│             └── Use ChatService methods             │
└──────────────────────────────────────────────────────┘
```

---

## State Management Flow

```
ChatListScreen (StatefulWidget)
│
├── _chatService: ChatService
│   └── LocalChatService() or BackendChatService()
│
├── _chatsFuture: Future<List<Chat>>
│   └── Updated by _refreshChats() when needed
│
└── FutureBuilder
    ├── Listens to _chatsFuture
    ├── Rebuilds when data changes
    └── Navigation to ChatDetailScreen


ChatDetailScreen (StatefulWidget)
│
├── _chatService: ChatService
│
├── _messageController: TextEditingController
│   └── User message input
│
├── _messagesFuture: Future<List<Message>>
│   └── Updated by setState() after sending
│
├── _scrollController: ScrollController
│   └── Auto-scroll to latest message
│
└── FutureBuilder
    ├── Listens to _messagesFuture
    └── Rebuilds when messages update
```

---

**Architecture Version**: 1.0
**Last Updated**: November 16, 2024
**Status**: Production Ready (Local) → Backend Ready

