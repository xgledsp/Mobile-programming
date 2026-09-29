import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  korean,
}

class SouthKoreaApp extends StatelessWidget {
  const SouthKoreaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'South Korea',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',

        scaffoldBackgroundColor:
            const Color(0xFFD9D3D5),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0969C7),
        ),
      ),

      home: const OnboardingPage(),
    );
  }
}

// ================================================================
// ONBOARDING PAGE
// ================================================================

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() =>
      _OnboardingPageState();
}

class _OnboardingPageState
    extends State<OnboardingPage> {

  // English is selected by default.
  AppLanguage selectedLanguage =
      AppLanguage.english;

  static const Color blue =
      Color(0xFF0969C7);

  static const Color darkText =
      Color(0xFF333333);

  static const Color lightText =
      Color(0xFF777777);

  static const Color border =
      Color(0xFFE2E2E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFD9D3D5),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {

              /*
                The Figma design is based around
                a 320 x 568 phone frame.

                We keep the content narrow so that
                it stays visually close to the
                supplied Figma design.
              */

              final double availableWidth =
                  constraints.maxWidth;

              final double cardWidth =
                  availableWidth < 360
                      ? availableWidth - 152
                      : 208;

              final double actualCardWidth =
                  cardWidth.clamp(208.0, 220.0);

              return SingleChildScrollView(
                child: SizedBox(
                  width: actualCardWidth,
                  child: _buildMainCard(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // MAIN WHITE CARD
  // ==============================================================

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),
      ),

      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        10,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // --------------------------------------------------------
          // SOUTH KOREA IMAGE
          // --------------------------------------------------------

          _buildSouthKoreaImage(),

          const SizedBox(height: 12),

          // --------------------------------------------------------
          // TITLE
          // --------------------------------------------------------

          Text(
            selectedLanguage ==
                    AppLanguage.english
                ? 'Your legal & living\n companion in Korea'
                : '한국에서의 법률 및 생활\n동반자',

            style: const TextStyle(
              fontSize: 16,
              height: 1.02,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 7),

          // --------------------------------------------------------
          // DESCRIPTION
          // --------------------------------------------------------

          Text(
            selectedLanguage ==
                    AppLanguage.english
                ? 'Navigate visas, housing contracts, labor rights, and '
                  'daily life in Seoul with friendly AI-guided support.'
                : '비자, 주거 계약, 노동 권리 및 서울에서의 일상생활을 '
                  '친절한 AI 안내와 함께 알아보세요.',

            style: const TextStyle(
              fontSize: 7.2,
              height: 1.35,
              color: lightText,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // LANGUAGE LABEL
          // --------------------------------------------------------

          const Text(
            'CHOOSE LANGUAGE | 언어 선택',

            style: TextStyle(
              fontSize: 6.8,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),

          const SizedBox(height: 4),

          // --------------------------------------------------------
          // LANGUAGE TOGGLE
          // --------------------------------------------------------

          _buildLanguageToggle(),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // BILINGUAL AI HELP
          // --------------------------------------------------------

          _buildInfoCard(
            icon: Icons.chat_bubble_outline_rounded,

            title:
                selectedLanguage ==
                        AppLanguage.english
                    ? 'Bilingual AI Help'
                    : '이중 언어 AI 도움',

            description:
                selectedLanguage ==
                        AppLanguage.english
                    ? 'Understand complex notices in plain English or Korean.'
                    : '복잡한 안내문을 영어 또는 한국어로 쉽게 이해하세요.',

            onTap: () {
              // //
            },
          ),

          const SizedBox(height: 6),

          // --------------------------------------------------------
          // CIVIC VERIFIED ANSWERS
          // --------------------------------------------------------

          _buildInfoCard(
            icon: Icons.shield_outlined,

            title:
                selectedLanguage ==
                        AppLanguage.english
                    ? 'Civic-Verified Answers'
                    : '공식 정보 기반 답변',

            description:
                selectedLanguage ==
                        AppLanguage.english
                    ? 'AI legal info makes back to official governmental sources.'
                    : '공식 정부 자료를 기반으로 법률 정보를 제공합니다.',

            onTap: () {
              // //
            },
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // START MY JOURNEY
          // --------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 30,

            child: ElevatedButton(
              onPressed: _startMyJourney,

              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,

                elevation: 0,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 5,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(6),
                ),
              ),

              child: Text(
                selectedLanguage ==
                        AppLanguage.english
                    ? 'Start My Journey | 시작하기  →'
                    : '시작하기 | Start My Journey  →',

                style: const TextStyle(
                  fontSize: 7.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SOUTH KOREA IMAGE
  // ==============================================================

  Widget _buildSouthKoreaImage() {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(36),

      child: SizedBox(
        width: double.infinity,
        height: 160,

        child: Image.asset(
          'assets/south_korea_panel.png',

          fit: BoxFit.fill,
        ),
      ),
    );
  }

  // ==============================================================
  // LANGUAGE TOGGLE
  // ==============================================================

  Widget _buildLanguageToggle() {
    return Container(
      height: 27,

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(6),

        border: Border.all(
          color: border,
          width: 0.7,
        ),
      ),

      child: Row(
        children: [

          // --------------------------------------------------------
          // ENGLISH
          // --------------------------------------------------------

          Expanded(
            child: _buildLanguageButton(
              label: 'English',

              selected:
                  selectedLanguage ==
                      AppLanguage.english,

              onPressed: () {
                setState(() {
                  selectedLanguage =
                      AppLanguage.english;
                });
              },

              showCheck: true,
            ),
          ),

          // --------------------------------------------------------
          // KOREAN
          // --------------------------------------------------------

          Expanded(
            child: _buildLanguageButton(
              label: '한국어 (Korean)',

              selected:
                  selectedLanguage ==
                      AppLanguage.korean,

              onPressed: () {
                setState(() {
                  selectedLanguage =
                      AppLanguage.korean;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // LANGUAGE BUTTON
  // ==============================================================

  Widget _buildLanguageButton({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
    bool showCheck = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.all(2),

      child: TextButton(
        onPressed: onPressed,

        style: TextButton.styleFrom(
          backgroundColor:
              selected
                  ? blue
                  : Colors.transparent,

          foregroundColor:
              selected
                  ? Colors.white
                  : const Color(0xFF555555),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 3,
          ),

          minimumSize:
              Size.zero,

          tapTargetSize:
              MaterialTapTargetSize.shrinkWrap,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(5),
          ),
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Flexible(
              child: Text(
                label,

                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 6.8,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            if (selected &&
                showCheck) ...[
              const SizedBox(width: 3),

              const Icon(
                Icons.check,
                size: 9,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // INFORMATION CARD
  // ==============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(7),

        child: Container(
          width: double.infinity,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(7),

            border: Border.all(
              color: border,
              width: 0.7,
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // --------------------------------------------------
              // ICON
              // --------------------------------------------------

              Container(
                width: 22,
                height: 22,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEFF3F3,
                  ),

                  borderRadius:
                      BorderRadius.circular(5),
                ),

                child: Icon(
                  icon,

                  size: 12,

                  color: blue,
                ),
              ),

              const SizedBox(width: 6),

              // --------------------------------------------------
              // TEXT
              // --------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            Color(0xFF164D73),

                        fontSize: 7.8,

                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      description,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            Color(0xFF7C7C7C),

                        fontSize: 6.1,

                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // START MY JOURNEY
  // ==============================================================

  void _startMyJourney() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return JourneyPage(
            language: selectedLanguage,
          );
        },
      ),
    );
  }
}

// ==================================================================
// JOURNEY PAGE
// ==================================================================
//
// placeholder for next page
//
// ==================================================================

class JourneyPage extends StatelessWidget {
  final AppLanguage language;

  const JourneyPage({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnglish =
        language == AppLanguage.english;

    return Scaffold(
      backgroundColor:
          const Color(0xFFD9D3D5),

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        title: Text(
          isEnglish
              ? 'My Journey'
              : '나의 여정',
        ),
      ),

      body: Center(
        child: Text(
          isEnglish
              ? 'Selected language: English'
              : '선택한 언어: 한국어',

          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}