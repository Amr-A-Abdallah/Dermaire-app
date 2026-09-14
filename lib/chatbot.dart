import 'package:flutter/material.dart';

import 'dermaire_theme.dart';
import 'dermaire_widgets.dart';

enum AssistantReplyKind { education, uncertainty, escalation }

class AssistantReply {
  const AssistantReply(this.text, this.kind);
  final String text;
  final AssistantReplyKind kind;
}

abstract final class SkinAssistantSafety {
  static const redFlags = [
    'difficulty breathing',
    'trouble breathing',
    'face swelling',
    'facial swelling',
    'swollen lips',
    'severe pain',
    'rapidly spreading',
    'bleeding',
    'infection',
    'صعوبة تنفس',
    'ضيق تنفس',
    'تورم الوجه',
    'تورم الشفاه',
    'ألم شديد',
    'انتشار سريع',
    'نزيف',
    'عدوى',
  ];

  static bool hasRedFlag(String message) {
    final normalized = message.trim().toLowerCase();
    return redFlags.any(normalized.contains);
  }

  static AssistantReply reply(String message) {
    if (hasRedFlag(message)) {
      return const AssistantReply(
        'Your symptoms may need urgent medical assessment. If you have trouble breathing, facial or lip swelling, severe pain, or a rapidly worsening reaction, contact emergency services now. You can also share your Dermaire report with your clinician.',
        AssistantReplyKind.escalation,
      );
    }
    final normalized = message.toLowerCase();
    if (normalized.contains('measurement') || normalized.contains('قياس')) {
      return const AssistantReply(
        'Measurements show changes compared with your own baseline. They are estimates affected by lighting and context, and they are not a diagnosis.',
        AssistantReplyKind.education,
      );
    }
    if (normalized.contains('product') || normalized.contains('منتج')) {
      return const AssistantReply(
        'Open Products, add the product and its active ingredients, then review the interaction check. Patch test new products and change one variable at a time.',
        AssistantReplyKind.education,
      );
    }
    return const AssistantReply(
      'I can explain Dermaire, products, journals and measurements. I cannot diagnose a condition or prescribe treatment. For a personal medical decision, contact a qualified clinician.',
      AssistantReplyKind.uncertainty,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    required this.kind,
  });
  final String text;
  final bool fromUser;
  final AssistantReplyKind kind;
}

class SkinAssistantScreen extends StatefulWidget {
  const SkinAssistantScreen({super.key});

  @override
  State<SkinAssistantScreen> createState() => _SkinAssistantScreenState();
}

class _SkinAssistantScreenState extends State<SkinAssistantScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <ChatMessage>[];
  bool typing = false;

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final value = input.text.trim();
    if (value.isEmpty || typing) return;
    setState(() {
      messages.add(
        ChatMessage(
          text: value,
          fromUser: true,
          kind: AssistantReplyKind.education,
        ),
      );
      input.clear();
      typing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final reply = SkinAssistantSafety.reply(value);
    setState(() {
      messages.add(
        ChatMessage(text: reply.text, fromUser: false, kind: reply.kind),
      );
      typing = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Dermaire guide'),
      actions: [
        IconButton(
          tooltip: 'Clear conversation',
          onPressed: messages.isEmpty ? null : () => setState(messages.clear),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          const Notice(
            icon: 'ⓘ',
            text:
                'This guide explains the app and your recorded trends. It does not diagnose or prescribe treatment.',
            color: DermaireColors.unknownBackground,
          ),
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'Ask about a measurement, your journal, or how to add a product.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final escalation =
                          message.kind == AssistantReplyKind.escalation;
                      return Align(
                        alignment: message.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: escalation
                                ? DermaireColors.conflictBackground
                                : message.fromUser
                                ? DermaireColors.caramel.withValues(alpha: .32)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: escalation
                                  ? DermaireColors.conflict
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.text),
                              if (escalation) ...[
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed: () => showDermaireSnack(
                                    context,
                                    'Clinician contact requires a connected care provider.',
                                  ),
                                  icon: const Icon(
                                    Icons.local_hospital_outlined,
                                  ),
                                  label: const Text('Contact doctor'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (typing) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('assistantInput'),
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => send(),
                    decoration: const InputDecoration(
                      hintText: 'Ask Dermaire…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send message',
                  onPressed: typing ? null : send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
