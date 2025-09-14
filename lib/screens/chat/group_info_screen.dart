import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/friend_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class GroupInfoScreen extends StatefulWidget {
  final String chatId;

  const GroupInfoScreen({super.key, required this.chatId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.refreshChat(widget.chatId);
      final chat = chatProvider.chats.firstWhere(
        (c) => c.id == widget.chatId,
        orElse: () => Chat(
          id: widget.chatId,
          participants: [],
          createdAt: DateTime.now(),
          createdBy: '',
        ),
      );
      _nameController.text = chat.groupName ?? '';
      // Preload members
      await chatProvider.preloadUsers(chat.participants);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChatProvider, AuthProvider, FriendProvider>(
      builder: (context, chatProvider, authProvider, friendProvider, child) {
        final chat = chatProvider.chats.firstWhere(
          (c) => c.id == widget.chatId,
          orElse: () => Chat(
            id: widget.chatId,
            participants: [],
            createdAt: DateTime.now(),
            createdBy: '',
          ),
        );
        final isAdmin = chatProvider.isAdmin(chat);
        final currentUserId = authProvider.currentUser?.uid ?? '';

        return CupertinoPageScaffold(
          backgroundColor: AppConstants.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppConstants.backgroundColor,
            border: null,
            middle: const Text('Group Info'),
            trailing: isAdmin
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isSaving ? null : () => _saveChanges(chatProvider),
                    child: _isSaving
                        ? const CupertinoActivityIndicator()
                        : const Text('Save'),
                  )
                : null,
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              children: [
                _buildHeader(chatProvider, chat, isAdmin),
                const SizedBox(height: AppConstants.paddingXLarge),
                _buildAdminRow(chatProvider, chat),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildMembersSection(chatProvider, chat, isAdmin, currentUserId),
                const SizedBox(height: AppConstants.paddingXLarge),
                _buildActionsSection(chatProvider, friendProvider, chat, isAdmin, currentUserId),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ChatProvider chatProvider, Chat chat, bool isAdmin) {
    final imageUrl = chat.groupImageUrl;
    return Row(
      children: [
        // Group avatar
        Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primaryColor.withOpacity(0.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _defaultAvatar(chat),
                    )
                  : _defaultAvatar(chat),
            ),
            if (isAdmin)
              Positioned(
                right: 0,
                bottom: 0,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(28),
                  onPressed: _pickNewImage,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.photo_camera_solid, size: 16, color: CupertinoColors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppConstants.paddingLarge),
        // Name field
        Expanded(
          child: CupertinoTextField(
            controller: _nameController,
            enabled: isAdmin,
            placeholder: 'Group name',
            style: AppConstants.titleMedium.copyWith(color: CupertinoColors.label),
            placeholderStyle: AppConstants.titleMedium.copyWith(color: CupertinoColors.secondaryLabel),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar(Chat chat) {
    final titleInitial = (chat.groupName ?? 'G').isNotEmpty ? (chat.groupName ?? 'G')[0].toUpperCase() : 'G';
    return Center(
      child: Text(
        titleInitial,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildAdminRow(ChatProvider chatProvider, Chat chat) {
    final adminUser = chatProvider.getUser(chat.createdBy);
    return Row(
      children: [
        const Icon(CupertinoIcons.person_crop_circle, color: CupertinoColors.secondaryLabel),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Admin: ${adminUser?.name ?? 'Unknown'}',
            style: AppConstants.bodyMedium.copyWith(color: CupertinoColors.label),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(ChatProvider chatProvider, Chat chat, bool isAdmin, String currentUserId) {
    final members = chat.participants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members (${members.length})',
          style: AppConstants.bodyMedium.copyWith(color: CupertinoColors.secondaryLabel, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        ...members.map((uid) => _buildMemberTile(chatProvider, chat, uid, isAdmin, currentUserId)),
      ],
    );
  }

  Widget _buildMemberTile(ChatProvider chatProvider, Chat chat, String userId, bool isAdmin, String currentUserId) {
    final user = chatProvider.getUser(userId);
    final isChatAdmin = chat.createdBy == userId;
    final canKick = isAdmin && !isChatAdmin && userId != currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.primaryColor.withOpacity(0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: (user?.profileImageUrl?.isNotEmpty == true)
                ? Image.network(user!.profileImageUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      (user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                      style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Name and admin badge
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    user?.name ?? 'Unknown',
                    style: AppConstants.bodyMedium.copyWith(color: CupertinoColors.label),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isChatAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Admin',
                      style: AppConstants.caption.copyWith(color: CupertinoColors.activeGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          if (canKick)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _confirmKick(chatProvider, chat.id, userId, user?.name ?? 'this user'),
              child: const Icon(CupertinoIcons.delete_simple, color: CupertinoColors.systemRed),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ChatProvider chatProvider, FriendProvider friendProvider, Chat chat, bool isAdmin, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin) ...[
          CupertinoButton.filled(
            onPressed: () => _showAddMembers(chatProvider, friendProvider, chat),
            child: const Text('Add Members'),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          CupertinoButton(
            color: CupertinoColors.systemGrey5,
            onPressed: () => _showTransferAdmin(chatProvider, chat),
            child: const Text('Transfer Admin'),
          ),
        ] else ...[
          CupertinoButton(
            color: CupertinoColors.systemRed,
            onPressed: () => _confirmLeave(chatProvider, chat.id),
            child: const Text('Leave Group'),
          ),
        ],
      ],
    );
  }

  Future<void> _pickNewImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (file != null) {
        if (!mounted) return;
        setState(() => _isSaving = true);
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.updateGroupInfo(widget.chatId, newImageFile: file);
      }
    } catch (e) {
      // Ignore, provider handles errors
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveChanges(ChatProvider chatProvider) async {
    setState(() => _isSaving = true);
    try {
      final newName = _nameController.text.trim();
      await chatProvider.updateGroupInfo(widget.chatId, newGroupName: newName.isEmpty ? null : newName);
    } catch (e) {
      // Errors handled in provider
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmKick(ChatProvider chatProvider, String chatId, String userId, String displayName) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $displayName from this group?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await chatProvider.removeGroupMember(chatId, userId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(ChatProvider chatProvider, String chatId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Leave group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await chatProvider.leaveGroup(chatId);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showAddMembers(ChatProvider chatProvider, FriendProvider friendProvider, Chat chat) async {
    final friends = friendProvider.getFriendsList();
    final existing = chat.participants.toSet();
    final candidates = friends.where((u) => !existing.contains(u.uid)).toList();
    if (candidates.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No friends to add'),
          content: const Text('All your friends are already in this group.'),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
      return;
    }

    await Navigator.of(context).push(CupertinoPageRoute(
      builder: (context) => _SelectUsersPage(
        title: 'Add Members',
        users: candidates,
        onConfirm: (ids) async {
          await chatProvider.addGroupMembers(chat.id, ids);
        },
      ),
    ));
  }

  void _showTransferAdmin(ChatProvider chatProvider, Chat chat) async {
    final members = chat.participants.where((uid) => uid != chat.createdBy).toList();
    final usersMap = chatProvider.usersMap;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Transfer Admin'),
        message: const Text('Select a member to make admin'),
        actions: members.map((uid) {
          final name = usersMap[uid]?.name ?? uid;
          return CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await chatProvider.transferGroupAdmin(chat.id, uid);
            },
            child: Text(name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// Simple user selection page used for Add Members
class _SelectUsersPage extends StatefulWidget {
  final String title;
  final List<UserModel> users;
  final Future<void> Function(List<String>) onConfirm;

  const _SelectUsersPage({required this.title, required this.users, required this.onConfirm});

  @override
  State<_SelectUsersPage> createState() => _SelectUsersPageState();
}

class _SelectUsersPageState extends State<_SelectUsersPage> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppConstants.backgroundColor,
        border: null,
        middle: Text(widget.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selected.isEmpty
              ? null
              : () async {
                  await widget.onConfirm(_selected.toList());
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
          child: const Text('Add'),
        ),
      ),
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          itemBuilder: (context, i) {
            final user = widget.users[i];
            final isSelected = _selected.contains(user.uid);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selected.remove(user.uid);
                  } else {
                    _selected.add(user.uid);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.primaryColor.withOpacity(0.1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (user.profileImageUrl?.isNotEmpty == true)
                          ? Image.network(user.profileImageUrl!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.name,
                        style: AppConstants.bodyMedium.copyWith(color: CupertinoColors.label),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemCount: widget.users.length,
        ),
      ),
    );
  }
}
