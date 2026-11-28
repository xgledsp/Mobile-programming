import '../app_theme.dart';
import 'chat_message.dart';
import 'hodu_responder.dart';
import 'topic_guard.dart';

// ================================================================
// GUARDED RESPONDER - the guard standing in front of the brain
// ================================================================
//
//   question -> TopicGuard
//                 injection / offTopic -> polite refusal  (no brain call)
//                 smallTalk            -> short friendly reply
//                 onTopic / unclear    -> inner responder answers
//
// This is a "decorator": it wraps any other HoduResponder. Later the
// inner brain will be the knowledge base or the AI, and the guard keeps
// working the same way.
// ================================================================

class GuardedResponder implements HoduResponder {
  final HoduResponder inner;
  final TopicGuard guard;
  final AppLanguage language;

  const GuardedResponder({
    required this.inner,
    this.guard = const TopicGuard(),
    this.language = AppLanguage.english,
  });

  bool get _ko => language == AppLanguage.korean;

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) {
    final TopicDecision decision = guard.classify(question);

    switch (decision.verdict) {
      case TopicVerdict.injection:
        return Future<HoduReply>.value(HoduReply(_injectionText(), ReplySource.guard));
      case TopicVerdict.offTopic:
        return Future<HoduReply>.value(HoduReply(_offTopicText(), ReplySource.guard));
      case TopicVerdict.smallTalk:
        return Future<HoduReply>.value(
          HoduReply(_smallTalkText(decision.smallTalk!), ReplySource.guard),
        );
      case TopicVerdict.onTopic:
      case TopicVerdict.unclear:
        return inner.reply(question, history);
    }
  }

  // ------------------------------------------------------------ texts

  String _offTopicText() => _ko
      ? '미안해요, 저는 한국 생활을 돕는 도우미라서 그 질문에는 답할 수 없어요. '
          '비자, 기숙사, 은행, 학교 생활, 한국 문화에 대해 물어봐 주세요!'
      : "Sorry, I can only help with life in Korea, so I can't answer that. "
          'Try asking me about visas, dorms, banks, school life or Korean culture!';

  String _injectionText() => _ko
      ? '제 역할은 바꿀 수 없어요. 저는 한국 생활 도우미 호두예요. '
          '한국 생활에 대해 궁금한 점을 물어봐 주세요.'
      : "I can't change my role — I'm Hodu, your guide to life in Korea. "
          'Ask me anything about living or studying here.';

  String _smallTalkText(SmallTalkKind kind) {
    switch (kind) {
      case SmallTalkKind.greeting:
        return _ko
            ? '안녕하세요! 오늘은 무엇을 도와드릴까요?'
            : 'Hi there! What can I help you with today?';
      case SmallTalkKind.thanks:
        return _ko
            ? '천만에요! 더 궁금한 게 있으면 언제든 물어보세요.'
            : "You're welcome! Ask me anytime if you have more questions.";
      case SmallTalkKind.goodbye:
        return _ko ? '또 만나요! 한국 생활 화이팅!' : 'See you! Good luck with life in Korea!';
      case SmallTalkKind.aboutHodu:
        return _ko
            ? '저는 호두예요! 한국에 사는 외국인 학생을 도와요. 예를 들면:\n'
                '• 비자와 외국인등록증(ARC)\n'
                '• 기숙사와 집 계약\n'
                '• 은행 계좌, 유심 카드\n'
                '• 수강신청 같은 학교 공지\n'
                '• 한국 문화와 한국어 단어'
            : "I'm Hodu! I help international students living in Korea with:\n"
                '• Visas and the ARC (alien registration card)\n'
                '• Dorms and housing contracts\n'
                '• Bank accounts and SIM cards\n'
                '• School notices like add/drop\n'
                '• Korean culture and Korean words';
    }
  }
}
