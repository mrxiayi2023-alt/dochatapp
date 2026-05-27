const fs = require('fs');
let content = fs.readFileSync('lib/pages/chat_detail_page.dart', 'utf8');

// Fix indentation: the block after getChatHistory was over-indented
content = content.replace(
  "final data = await ApiService.instance.getChatHistory(otherId);\n        final authState",
  "final data = await ApiService.instance.getChatHistory(otherId);\n      final authState"
);
content = content.replace(
  "final myId = authState.user?['id'] as String? ?? '';\n\n        final messages",
  "final myId = authState.user?['id'] as String? ?? '';\n\n      final messages"
);
content = content.replace(
  "final fromId = m['from_id'] as String? ?? '';\n          return Message(",
  "final fromId = m['from_id'] as String? ?? '';\n        return Message("
);
content = content.replace(
  "}).toList();\n\n        if (mounted)",
  "}).toList();\n\n      if (mounted)"
);
content = content.replace(
  "if (mounted) setState(() => _messages.addAll(messages));\n        return;\n      }",
  "if (mounted) setState(() => _messages.addAll(messages));\n      return;\n    }"
);
content = content.replace(
  "{\n        final fromId",
  "{\n        final fromId"
);

fs.writeFileSync('lib/pages/chat_detail_page.dart', content, 'utf8');
console.log('done');
