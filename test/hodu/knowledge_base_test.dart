import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_programming/app_theme.dart';
import 'package:mobile_programming/hodu/chat_message.dart';
import 'package:mobile_programming/hodu/knowledge/kb_data.dart';
import 'package:mobile_programming/hodu/knowledge/kb_entry.dart';
import 'package:mobile_programming/hodu/knowledge/knowledge_base.dart';
import 'package:mobile_programming/hodu/knowledge_responder.dart';
import 'package:mobile_programming/hodu/text_match.dart';

final RegExp _hangul = RegExp(r'[가-힣]');

void main() {
  const KnowledgeBase kb = KnowledgeBase();

  // ------------------------------------------------------------------
  // The data itself. These tests protect the knowledge base when
  // teammates add new entries later.
  // ------------------------------------------------------------------
  group('knowledge base data', () {
    test('has entries', () {
      expect(hoduKnowledgeBase.length, greaterThanOrEqualTo(15));
    });

    test('ids are unique', () {
      final List<String> ids = hoduKnowledgeBase.map((KbEntry e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    for (final KbEntry e in hoduKnowledgeBase) {
      test('${e.id}: both languages are filled in', () {
        expect(e.questionEn.trim(), isNotEmpty);
        expect(e.answerEn.trim(), isNotEmpty);
        expect(e.questionKo, contains(_hangul));
        expect(e.answerKo, contains(_hangul));
        expect(e.keywords, isNotEmpty);
        expect((e.sourceEn == null) == (e.sourceKo == null), isTrue,
            reason: 'source must exist in both languages or in neither');
      });

      test('${e.id}: keywords are written so they can match', () {
        for (final String k in e.keywords) {
          // A keyword with capitals or removed punctuation never matches,
          // because questions are normalized before searching.
          expect(TextMatch.normalize(k), k, reason: 'keyword "$k" is not normalized');
        }
      });

      test('${e.id}: its own question finds it', () {
        expect(kb.bestAnswer(e.questionEn)?.id, e.id, reason: e.questionEn);
        expect(kb.bestAnswer(e.questionKo)?.id, e.id, reason: e.questionKo);
      });
    }
  });

  // ------------------------------------------------------------------
  // Real questions a student might type.
  // ------------------------------------------------------------------
  group('search finds the right answer', () {
    final Map<String, String> cases = {
      'how do i get an arc': 'arc_apply',
      'Where do I register as a foreigner?': 'arc_apply',
      '외국인등록증 어디서 받아요?': 'arc_apply',
      'my visa expires next month what do i do': 'visa_extend',
      '체류기간 연장하고 싶어요': 'visa_extend',
      'I moved to a new apartment, do I need to tell immigration?': 'address_change',
      'Can I work at a cafe? part time': 'part_time_work',
      '알바 해도 돼요?': 'part_time_work',
      'my boss did not pay my salary': 'wage_problem',
      'what should I bring to the dorm check in': 'dorm_check_in',
      '전세 보증금 사기 안 당하려면?': 'renting_deposit',
      'how to open a bank account': 'bank_account',
      '통장 만들고 싶어요': 'bank_account',
      'best way to send money home': 'send_money_home',
      'where can I buy a sim card': 'sim_card',
      '알뜰폰 요금제 추천': 'sim_card',
      'When is the add/drop period?': 'add_drop',
      '수강신청 정정 언제 해요?': 'add_drop',
      'do I need health insurance': 'health_insurance',
      'I have a fever, where should I go?': 'hospital_pharmacy',
      '감기 걸렸어요 병원 어디 가요?': 'hospital_pharmacy',
      'how do I top up my T-money card?': 'transport_card',
      'how do I sort food waste': 'trash_sorting',
      '분리수거 어떻게 해요?': 'trash_sorting',
      'I lost my wallet in a taxi': 'lost_item',
      'what is the number for an ambulance': 'emergency_numbers',
      'someone called and said he is police and asked for money': 'phone_scam',
      'is it rude that they asked my age?': 'honorifics_age',
      '회식 때 술 꼭 마셔야 해요?': 'dining_drinking',
      'how do you say thank you in korean': 'useful_phrases',
      'how do I use the calendar in this app': 'app_help',
    };

    cases.forEach((String question, String expectedId) {
      test(question, () {
        expect(kb.bestAnswer(question)?.id, expectedId,
            reason: 'got ${kb.search(question)}');
      });
    });
  });

  group('search edge cases', () {
    test('no match for questions outside the knowledge base', () {
      expect(kb.bestAnswer('What is the capital of France?'), isNull);
      expect(kb.bestAnswer('Where can I buy a cheap mattress?'), isNull);
    });

    test('empty question returns nothing', () {
      expect(kb.search(''), isEmpty);
      expect(kb.search('   ?!'), isEmpty);
    });

    test('results are sorted best first and limited', () {
      final List<KbMatch> results = kb.search('bank account and sim card and arc', limit: 2);
      expect(results, hasLength(2));
      expect(results.first.score, greaterThanOrEqualTo(results.last.score));
    });
  });

  group('KnowledgeResponder', () {
    test('answers in English with the source line', () async {
      const KnowledgeResponder r = KnowledgeResponder();
      final HoduReply reply = await r.reply('How do I get my ARC?', const []);
      expect(reply.source, ReplySource.knowledgeBase);
      expect(reply.text, contains('90 days'));
      expect(reply.text, contains('Check: HiKorea'));
    });

    test('answers in Korean in Korean mode', () async {
      const KnowledgeResponder r = KnowledgeResponder(language: AppLanguage.korean);
      final HoduReply reply = await r.reply('ARC 어떻게 받아요?', const []);
      expect(reply.text, contains('90일'));
      expect(reply.text, contains('확인하기: 하이코리아'));
    });

    test('no match: honest message with suggestions from the same topic', () async {
      const KnowledgeResponder r = KnowledgeResponder();
      // On-topic (school) but not in the knowledge base.
      final HoduReply reply = await r.reply('Where is the campus library?', const []);
      expect(reply.source, ReplySource.fallback);
      expect(reply.text, contains("don't have an offline answer"));
      expect(reply.text, contains('• '));
    });

    test('no match and no topic: suggests the most common questions', () async {
      const KnowledgeResponder r = KnowledgeResponder(language: AppLanguage.korean);
      final HoduReply reply = await r.reply('매트리스 어디서 사요?', const []);
      expect(reply.source, ReplySource.fallback);
      expect(reply.text, contains('오프라인 답변'));
      expect(reply.text, contains('외국인등록증'));
    });
  });
}
