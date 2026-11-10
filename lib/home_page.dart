import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'character_chat_page.dart';
import 'quiz_session.dart';
import 'review_page.dart';
import 'word_data.dart';
import 'word_quiz_page.dart';

class HomePage extends StatelessWidget {
  final AppLanguage language;
  const HomePage({super.key, required this.language});

  void _openQuiz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const WordQuizPage(),
      ),
    );
  }

  // Goes straight to the review page. From there "Next word" starts the quiz.
  void _openReview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext reviewContext) => ReviewPage(
          history: List<ReviewEntry>.of(QuizSession.instance.history),
          onNextWord: () => _openQuiz(context),
        ),
      ),
    );
  }

  Widget _quizButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hi, Sarah! 안녕하세요',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: darkText),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "You've completed 2 initial steps.",
                          style: TextStyle(fontSize: 13, color: lightText),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryBlue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Ask Hodu Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CharacterChatPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ask Hodu anything',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Guide', style: TextStyle(color: Colors.white, fontSize: 10)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Ask me anything, 何でも聞いて',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search, color: Colors.white, size: 18),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy, size: 60, color: primaryBlue),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Next Quest
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEXT QUEST | 다음 퀘스트',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightText),
                    ),
                    Text('See all', style: TextStyle(fontSize: 12, color: primaryBlue)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderGray),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.home_work_outlined, color: primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Move into your dormitory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 4),
                                Text('기숙사 입주 | Deadline 4월 5일', style: TextStyle(color: lightText, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: lightText),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          value: 0.4,
                          minHeight: 6,
                          backgroundColor: Color(0xFFE0E0E0),
                          valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Word Quiz
                const Text(
                  'Word Quiz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
                ),
                const SizedBox(height: 12),
                _quizButton('Start Quiz', () => _openQuiz(context)),
                const SizedBox(height: 10),
                _quizButton('Review Quiz', () => _openReview(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}