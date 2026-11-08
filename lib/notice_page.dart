import 'package:flutter/material.dart';
import 'app_theme.dart';

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notice Explained', style: TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI explanation. Always double-check exact dates in the official notice.',
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('YOUR NOTICE 원문 (Korean)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightText)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGray),
                ),
                child: const Text(
                  '2026학년도 2학기 수강신청 정정 및 철회 안내\n\n기간: 2026. 9. 1.(화) 10:00 ~ 9. 7.(월) 23:59\n\n수강신청 철회를 원하시는 학생은 기간 내에 시스템에서 직접 철회하시기 바랍니다.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: darkText),
                ),
              ),
              const SizedBox(height: 24),

              const Text('WHAT IT MEANS 뜻', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightText)),
              const SizedBox(height: 8),
              const Text(
                "This is the add/drop period for Fall 2026. For these 3 days, you can freely add or drop classes on the student portal.",
                style: TextStyle(fontSize: 14, height: 1.5, color: darkText),
              ),
              const SizedBox(height: 24),

              const Text('SO, WHAT DO I DO? 어떻게 해야 할까요?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightText)),
              const SizedBox(height: 12),
              _buildStep(1, 'Log in to the portal', '포털에 로그인'),
              const SizedBox(height: 12),
              _buildStep(2, 'Add or drop class before Sep 7, 23:59', '9월 7일 23:59 이전에 수강신청 변경'),
              const SizedBox(height: 12),
              _buildStep(3, 'Missed it? Withdraw by 9/12', '놓쳤다면 9월 12일까지 철회 가능'),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today, size: 20),
                  label: const Text('Add deadline to calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: primaryBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: darkText)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: lightText)),
            ],
          ),
        )
      ],
    );
  }
}