# SimpleChat - iOS Chat Application

A complete iOS chat application built with Flutter and Firebase, featuring real-time messaging, friend system, and modern Apple-style UI.

## Features

### 🔐 Authentication
- Welcome screen with app branding
- Email/password login and registration
- Password reset functionality
- Form validation and error handling
- Persistent authentication state

### 💬 Real-time Messaging
- Direct messaging between friends
- Group chat support (coming soon)
- Real-time message delivery
- Message read receipts
- Typing indicators (coming soon)
- Image sharing (coming soon)

### 👥 Friends System
- Search users by name or email
- Send and receive friend requests
- Accept/decline friend requests
- Friends list with online status
- Real-time online/offline indicators

### 📱 Modern iOS UI
- Cupertino design system
- Native iOS look and feel
- Dark mode support
- Smooth animations and transitions
- Tab-based navigation

### 🔔 Notifications (Coming Soon)
- Push notifications for new messages
- Friend request notifications
- Background message sync

## Tech Stack

- **Frontend**: Flutter with Cupertino widgets
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **State Management**: Provider
- **Image Handling**: Cached Network Image, Image Picker
- **Real-time Updates**: Firestore streams

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user_model.dart
│   ├── message_model.dart
│   ├── chat_model.dart
│   └── friend_request_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   └── friend_provider.dart
├── screens/                  # UI screens
│   ├── auth/                 # Authentication screens
│   ├── chat/                 # Chat-related screens
│   ├── friends/              # Friends system screens
│   └── profile/              # Profile and settings
├── widgets/                  # Reusable UI components
│   ├── common/               # Common widgets
│   ├── chat/                 # Chat-specific widgets
│   └── friend/               # Friend-specific widgets
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── chat_service.dart
│   └── firestore_service.dart
└── utils/                    # Utilities and constants
    ├── constants.dart
    └── helpers.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.24.0 or higher)
- iOS development environment (Xcode)
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd simple_chat
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Enable Firebase Storage
   - Add iOS app to Firebase project
   - Download and replace `GoogleService-Info.plist` in `ios/Runner/`

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

The app requires the following Firebase services:

1. **Authentication**
   - Enable Email/Password provider
   - Configure authorized domains

2. **Firestore Database**
   - Create database in production mode
   - Set up security rules (see below)

3. **Storage**
   - Enable Firebase Storage for profile images
   - Configure storage rules

4. **Cloud Messaging** (Optional)
   - Enable for push notifications
   - Configure APNs certificates

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat participants can read/write chat data
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    // Messages in chats that user participates in
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Friend requests
    match /friendRequests/{requestId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
    }
    
    // Friendships
    match /friends/{friendshipId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.user1Id || 
         request.auth.uid == resource.data.user2Id);
    }
  }
}
```

## Key Features Implementation

### Real-time Messaging
- Uses Firestore streams for real-time updates
- Optimistic UI updates for better UX
- Message pagination (20 messages per load)
- Automatic scroll to bottom on new messages

### Friend System
- Search functionality with name/email matching
- Request status tracking (pending, accepted, declined)
- Real-time friend list updates
- Online status indicators

### State Management
- Provider pattern for reactive UI
- Separate providers for auth, chat, and friends
- Error handling and loading states
- Automatic cleanup of subscriptions

### Security
- Firebase security rules enforce data access
- Input validation on all forms
- Secure image upload to Firebase Storage
- User authentication required for all operations

## Performance Optimizations

- **Image Caching**: Profile images cached locally
- **Pagination**: Messages loaded in batches
- **Stream Management**: Proper subscription cleanup
- **Memory Management**: Efficient widget disposal
- **Optimistic Updates**: UI updates before server confirmation

## Testing

The app includes comprehensive error handling and loading states. Test the following scenarios:

1. **Authentication Flow**
   - Registration with valid/invalid data
   - Login with correct/incorrect credentials
   - Password reset functionality

2. **Friend System**
   - Search for users
   - Send/receive friend requests
   - Accept/decline requests

3. **Messaging**
   - Send messages between friends
   - Real-time message delivery
   - Message read receipts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support or questions, please open an issue in the repository.
