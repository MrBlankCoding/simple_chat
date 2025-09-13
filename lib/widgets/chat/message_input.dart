import 'package:flutter/cupertino.dart';
import '../../utils/constants.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback onSendImage;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Camera/Image Button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onSendImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.camera,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
              ),
              
              const SizedBox(width: AppConstants.paddingMedium),
              
              // Text Input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CupertinoColors.separator,
                      width: 0.5,
                    ),
                  ),
                  child: CupertinoTextField(
                    controller: _textController,
                    placeholder: AppStrings.typeMessage,
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.placeholderText,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: null,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              
              const SizedBox(width: AppConstants.paddingMedium),
              
              // Send Button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _hasText ? _sendMessage : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hasText 
                      ? AppConstants.primaryColor 
                      : CupertinoColors.systemGrey4,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    color: _hasText 
                      ? CupertinoColors.white 
                      : CupertinoColors.secondaryLabel,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
